"""Meaningful offline checks for complete content, deep links and local assets.

This verifies the website, not any 3ds Max/plugin behavior. It needs Python 3
only and writes a small report under website/verification/.
"""
from pathlib import Path
from html.parser import HTMLParser
import hashlib
import json
import re
import subprocess
import sys

ROOT=Path(__file__).resolve().parents[1]


class Markup(HTMLParser):
    def __init__(self):
        super().__init__()
        self.ids=[]
        self.links=[]
        self.assets=[]
    def handle_starttag(self,tag,attrs):
        values=dict(attrs)
        if 'id' in values: self.ids.append(values['id'])
        if tag=='a' and 'href' in values: self.links.append(values['href'])
        if tag in ('script','img') and 'src' in values: self.assets.append(values['src'])
        if tag=='link' and 'href' in values: self.assets.append(values['href'])


def main():
    subprocess.run([sys.executable,str(ROOT/'tools/import_reference.py'),'--check'],check=True)
    text=(ROOT/'content/reference.js').read_text(encoding='utf-8')
    data=json.loads(text.split('window.CYRUS_GUIDE = ',1)[1].rstrip().removesuffix(';'))
    coverage=json.loads((ROOT/'content/coverage.json').read_text(encoding='utf-8'))
    docs={d['id']:d for d in data['documents']}
    parsed={}
    for key,doc in docs.items():
        parsed[key]=Markup();parsed[key].feed(doc['html'])
        assert len(set(parsed[key].ids))==len(parsed[key].ids),f'Duplicate anchors in {key}'
    links=0
    for doc in parsed.values():
        for href in doc.links:
            if href.startswith('#/doc/'):
                parts=href.split('/')
                assert parts[2] in docs,href
                if len(parts)>3: assert parts[3] in parsed[parts[2]].ids,href
                links+=1
    for entry in data['inventory']:
        assert entry['anchor'] in parsed[entry['doc']].ids,entry
    for source in coverage['sources']:
        assert hashlib.sha256((ROOT/'sources'/source['file']).read_bytes()).hexdigest()==source['sha256']
    assert len(data['inventory'])==240
    assert coverage['walkthroughSteps']==28
    assert len(docs)==16
    assert all(e['scope']=='Layer' for e in data['inventory'] if e['section']=='Layers')
    assert all(e['scope']=='Paint set' for e in data['inventory'] if e['section']=='Paint sets')
    assert all(e['scope']=='Session' for e in data['inventory'] if e['section']=='Local recording')
    # Distinct same-label Analyzer links must not collapse to the same target.
    analyzers=[e for e in data['inventory'] if e['section']=='Areas and falloff' and e['label']=='Pick Surface Analyzer']
    assert len({e['anchor'] for e in analyzers})==2
    index=Markup();index.feed((ROOT/'index.html').read_text(encoding='utf-8'))
    assets=index.assets[:]
    for url in re.findall(r'url\([\'\"]?([^\)\'\"]+)',(ROOT/'styles.css').read_text(encoding='utf-8')):
        assets.append(url)
    for asset in assets:
        assert not asset.startswith(('http:','https:','//')),'Remote runtime dependency: '+asset
        assert (ROOT/asset).is_file(),'Missing asset: '+asset
    for asset in (ROOT/'assets/fonts').glob('*.woff2'):
        assert asset.read_bytes()[:4]==b'wOF2',asset
    manifests=json.loads((ROOT/'assets/image-manifest.json').read_text(encoding='utf-8'))
    for image in manifests:
        file=ROOT/'assets'/(image['name']+'.webp')
        assert hashlib.sha256(file.read_bytes()).hexdigest()==image['webp_sha256']
        assert file.read_bytes()[:4]==b'RIFF' and file.read_bytes()[8:12]==b'WEBP'
    script=(ROOT/'app.js').read_text(encoding='utf-8')
    authored=0
    for match in re.finditer(r"route\('([^']+)'(?:,\s*'([^']+)')?\)",script):
        doc,anchor=match.groups()
        assert doc in docs,doc
        if anchor: assert anchor in parsed[doc].ids,(doc,anchor)
        authored+=1
    # The first-planting workflow also stores route pairs inside its step records.
    steps=script.split('const workflowSteps=[',1)[1].split('];',1)[0]
    for doc,anchor in re.findall(r",'([^']+)','([^']+)'\]",steps):
        assert doc in docs and anchor in parsed[doc].ids,(doc,anchor)
        authored+=1
    # Authored routes and the small feature map sit outside generated Markdown.
    demos={'shares','containers','coverage','spacing','updates','output'}
    families=script.split('const families=[',1)[1].split('];',1)[0]
    family_links=re.findall(r",'([^']+)','([^']+)'\]",families)
    assert len(family_links)==6
    for doc,demo in family_links:
        assert doc in docs and demo in demos,(doc,demo)
    routes={'workflow','controls','visuals','walkthrough','about','status'}
    for path in re.findall(r'''href=["'](\#/[^"'${} ]*)["']''',script):
        parts=path[2:].split('/')
        if parts[0]: assert parts[0] in routes,path
        if parts[0]=='visuals' and len(parts)>1: assert parts[1] in demos,path
    status=ROOT/'content/WEBSITE_STATUS.md'
    assert status.is_file(),'Missing local status source'
    status_original=ROOT.parent/'docs/Status_0.73_And_Website_2026-10-07/WEBSITE_STATUS.md'
    if status_original.is_file(): assert status.read_bytes()==status_original.read_bytes(),'Status source snapshot needs deliberate refresh'
    report={
        'date':'2026-10-07','scope':'Offline website checks only; no Max qualification.',
        'result':'passed','sourceDocuments':len(docs),'inventoryEntries':240,'walkthroughSteps':28,
        'sourceLinksChecked':links,'authoredChapterLinksChecked':authored,
        'uniqueDeepLinksChecked':sum(len(p.ids) for p in parsed.values()),
        'localShellAssetsChecked':len(assets),'generatedImagesChecked':len(manifests),
        'authoredFeatureFamiliesChecked':len(family_links),'visualStudyRoutesChecked':len(demos),
        'websiteRevision':'final combined landing, guide and status iteration',
        'fileHashes':{name:hashlib.sha256((ROOT/name).read_bytes()).hexdigest() for name in ['index.html','app.js','styles.css','content/reference.js','content/WEBSITE_STATUS.md']},
        'checks':['Reference regeneration exactly matches checked-in website data','All source snapshots retain original hashes','Every inventory entry has an existing explanatory anchor','Same-label controls preserve section and owner context','All rendered source links resolve','All authored chapter/anchor links resolve','No duplicate IDs within a chapter','Walkthrough contains all 28 source steps','Main shell and fonts use local assets','Generated-image hashes match the supplied manifest','WOFF2 and WebP file signatures are correct'],
        'notChecked':['Browser layout and interaction need a browser run','3ds Max, plugin behavior, rendering and performance are not tested by this script']
    }
    (ROOT/'verification').mkdir(exist_ok=True)
    (ROOT/'verification/final-static-checks.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
    print(json.dumps(report,indent=2))


if __name__=='__main__':main()
