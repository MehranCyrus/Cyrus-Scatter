"""Verify current sources, complete semantic controls, resolved links and local assets.

This checks the website contract; it does not qualify any Max runtime behavior.
"""
from pathlib import Path
from html.parser import HTMLParser
import hashlib
import json
import os
import re
import subprocess
import sys
import tempfile

SITE=Path(__file__).resolve().parents[1]
REPO=SITE.parent

class Markup(HTMLParser):
    def __init__(self):
        super().__init__();self.ids=[];self.links=[]
    def handle_starttag(self,tag,attrs):
        attrs=dict(attrs)
        if 'id' in attrs:self.ids.append(attrs['id'])
        if tag=='a':self.links.append(attrs.get('href',''))

def sha(data):return hashlib.sha256(data).hexdigest()

def main():
    subprocess.run([sys.executable,str(SITE/'tools/import_reference.py'),'--check'],check=True)
    manifest=json.loads((SITE/'content/source-manifest.json').read_text(encoding='utf-8'))
    data=json.loads((SITE/'src/content/reference.json').read_text(encoding='utf-8'))
    catalog_bytes=(REPO/manifest['catalog']).read_bytes();catalog=json.loads(catalog_bytes)
    editorial_bytes=(SITE/'content/control-explanations.json').read_bytes();editorial=json.loads(editorial_bytes)
    for path, fingerprint in manifest['reviewedSourceHashes'].items():
        assert sha((REPO/path).read_bytes())==fingerprint,'Source changed; review public wording: '+path
    release_text=(REPO/'docs/Release_Versioning.md').read_text(encoding='utf-8')
    release_ui=re.search(r'\| Scatter UI \| ([0-9.]+) \|',release_text).group(1)
    assert data['developmentVersion']==catalog['development_version']==release_ui
    release=json.loads((SITE/'content/release.json').read_text(encoding='utf-8'))
    assert release['version']==data['developmentVersion']
    assert release['analyzer']['version']==data['analyzerVersion']
    assert release['analyzer']['included'] is True
    assert release['installer']['path']=='downloads/'+release['installer']['filename']
    assert release['installer']['filename']==f'CyrusScatter-{release["version"]}-Setup.exe'
    assert re.fullmatch('[0-9a-f]{64}',release['installer']['sha256'])
    assert release['content']['included'] is False
    assert len(data['documents'])==len(manifest['documents'])==5
    assert len(data['controls'])==len(catalog['controls'])==len(editorial)
    assert len(data['features'])==len(catalog['features'])==36
    assert len({c['id'] for c in data['controls']})==len(catalog['controls'])
    assert len({c['sourceKey'] for c in data['controls']})==len(catalog['controls'])
    feature_ids={f['feature_id'] for f in data['features']}
    for raw,current in zip(catalog['controls'],data['controls']):
        assert all(current[k]==v for k,v in raw.items()),current['sourceKey']
        assert current['id']=='control-'+re.sub(r'[^a-z0-9]+','-',current['sourceKey'].lower()).strip('-')
        assert current['label'] and current['description'] and current['displayOwner']
        assert 'explanationEvidence' not in current
        assert set(current['capabilities']).issubset(feature_ids)
        for evidence in editorial[current['sourceKey']]['evidence']:
            path,_,line=evidence.rpartition(':')
            assert (REPO/path).is_file(),evidence
            assert 0<int(line)<=len((REPO/path).read_bytes().splitlines()),evidence
    docs={d['id']:d for d in data['documents']}
    checked_links=0
    for doc in data['documents']:
        assert not {'path','snapshot','sha256'}.intersection(doc)
        parsed=Markup();parsed.feed(doc['html'])
        assert len(parsed.ids)==len(set(parsed.ids))
        assert doc['search'] and doc['headings'] and len(doc['html'])>1000
        for link in parsed.links:
            if link.startswith(('https://','http://','mailto:')):continue
            assert link.startswith('#/'),link
            parts=link[2:].split('?')[0].split('/')
            if parts[0]=='guide':
                assert parts[1] in docs,link
                if len(parts)>2:assert parts[2] in {h['anchor'] for h in docs[parts[1]]['headings']},link
            else:assert parts[0] in ('controls','changelog','checklist','troubleshooting','download','library'),link
            checked_links+=1
    assert 'references' not in data
    assert not (SITE/'public/sources').exists()
    assert not list((SITE/'public').rglob('*.md')),'No Markdown belongs in the public website.'
    history=json.loads((SITE/'content/changelog.json').read_text(encoding='utf-8'))
    assert len(data['changelog'])==len(history['entries'])>=53
    assert data['changelog'][0]['version']==data['developmentVersion']
    assert len({e['version'] for e in data['changelog']})==len(data['changelog'])
    for private,public in zip(history['entries'],data['changelog']):
        assert 'evidence' not in public
        assert private['evidence'] and public['changes']
        for path in private['evidence']:assert path in manifest['reviewedSourceHashes']
        assert all(c['kind'] in ('Added','Fixed','Improved','Changed') and c['text'] for c in public['changes'])
        if public['era']=='early':assert public['date'] is None
    for path in (SITE/'src').rglob('*.tsx'):
        text=path.read_text(encoding='utf-8')
        for link in re.findall(r'href="(#/guide/[^"{]+)"',text):
            parts=link[2:].split('?')[0].split('/');assert parts[1] in docs,link
            if len(parts)>2:assert parts[2] in {h['anchor'] for h in docs[parts[1]]['headings']},link
        for asset in re.findall(r"asset\('([^']+)'\)",text):
            path=SITE/'public/assets'/asset
            # Responsive srcSet builders also pass a shared filename prefix to asset().
            assert path.is_file() or (not path.suffix and any(path.parent.glob(path.name+'*'))),asset
    stories=(SITE/'src/content/featureStories.ts').read_text(encoding='utf-8')
    for doc,anchor in re.findall(r"guide:'([^']+)',anchor:'([^']+)'",stories):assert anchor in {h['anchor'] for h in docs[doc]['headings']},(doc,anchor)
    for collection in ('concepts', 'hero-studies'):
        for image in json.loads((SITE/'public/assets'/collection/'manifest.json').read_text(encoding='utf-8')):
            raw=(SITE/'public/assets'/collection/image['file']).read_bytes()
            assert raw[:4]==b'RIFF' and raw[8:12]==b'WEBP' and sha(raw)==image['sha256']
    brand=json.loads((SITE/'public/assets/brand/manifest.json').read_text(encoding='utf-8'))
    assert sha((SITE/brand['source']).read_bytes())==brand['originalSha256']
    for icon in brand['assets']:
        raw=(SITE/'public/assets/brand'/icon['file']).read_bytes()
        assert sha(raw)==icon['sha256']
        assert raw.startswith(b'\x00\x00\x01\x00') if icon['file'].endswith('.ico') else raw.startswith(b'\x89PNG\r\n\x1a\n')
    for image in json.loads((SITE/'public/assets/captures/manifest.json').read_text(encoding='utf-8')):
        raw=(SITE/'public/assets/captures'/image['file']).read_bytes()
        if image['file'].endswith('.png'):assert raw[:8]==b'\x89PNG\r\n\x1a\n'
        else:
            assert raw[:4]==b'RIFF' and raw[8:12]==b'WEBP'
            assert len(raw)<=1_500_000 and image['encoding']['alpha']=='preserved'
            assert len(image['originalSha256'])==64
            assert not (SITE/'public/assets/captures/garden-study-075.png').exists()
        assert sha(raw)==image['sha256']
        assert image['kind'] and image['source'] and image['scatterVersion']
    for name in ['instrument-serif-latin.woff2','instrument-serif-italic-latin.woff2','manrope-latin.woff2']:
        assert (SITE/'public/assets/fonts'/name).read_bytes()[:4]==b'wOF2'
    gallery=json.loads((SITE/'content/gallery-reading-notes.json').read_text(encoding='utf-8'))
    poster_manifest=json.loads((SITE/'public/assets/posters/manifest.json').read_text(encoding='utf-8'))
    assert gallery['developmentVersion']==data['artistWorkflowVersion']==manifest['artistWorkflowVersion'] and len(gallery['posters'])==len(poster_manifest)==19
    for image in poster_manifest:
        raw=(SITE/'public/assets/posters'/image['file']).read_bytes()
        assert raw[:4]==b'RIFF' and raw[8:12]==b'WEBP' and sha(raw)==image['sha256']
    for poster in gallery['posters'].values():
        assert poster['note'] and poster['provenance'] and poster['recommendation']
        for evidence in poster['evidence']:
            assert (REPO/evidence['path']).is_file()
            assert 0<evidence['line']<=len((REPO/evidence['path']).read_bytes().splitlines())
        for link in poster['guideLinks']:
            parts=link['href'][2:].split('/')
            assert parts[0]=='guide' and parts[1] in docs
            if len(parts)>2:assert parts[2] in {h['anchor'] for h in docs[parts[1]]['headings']},link
    known_routes={'home','features','library','download','guide','workflow','visuals','gallery','examples','checklist','glossary','troubleshooting','controls','roadmap','status','about','changelog'}
    nav_links=set()
    for path in list((SITE/'src').rglob('*.tsx'))+list((SITE/'src').rglob('*.html')):
        for link in re.findall(r'''["'](#/[^"'{}\s<>]*)["']''',path.read_text(encoding='utf-8')):
            nav_links.add(link)
            route,*tail=link[2:].split('?')[0].split('/')
            if not route:continue
            assert route in known_routes,link
            if route=='guide' and tail:
                assert tail[0] in docs,link
                if len(tail)>1:assert tail[1] in {h['anchor'] for h in docs[tail[0]]['headings']},link
            if route=='controls' and '?' in link:
                from urllib.parse import parse_qs
                params=parse_qs(link.split('?',1)[1])
                candidates=data['controls']
                for key in ('group','section','owner','feature','q'):
                    if key not in params:continue
                    value=params[key][0]
                    if key=='feature':candidates=[c for c in candidates if value in c['capabilities']]
                    elif key=='owner':candidates=[c for c in candidates if c['displayOwner']==value]
                    elif key=='q':candidates=[c for c in candidates if value.lower() in str(c).lower()]
                    else:candidates=[c for c in candidates if c[key]==value]
                assert candidates,link
    # Named destinations must use the matching semantic family, not merely a nonempty one.
    for cap,title in [('C19','Rotation/scale/movement'),('C21','Edit/instance radius'),('C27','Statistics')]:
        assert next(f for f in data['features'] if f['feature_id']==cap)['title'].startswith(title)
    for retired in ['app.js','styles.css','content/reference.js']:assert not (SITE/retired).exists()
    report={'scope':'Website static/content verification only; no plugin qualification','development_version':data['developmentVersion'],'documents':len(docs),'semantic_controls':len(data['controls']),'capability_families_including_retired_and_experimental':len(data['features']),'bundled_supporting_references':0,'public_markdown_files':0,'changelog_versions':len(data['changelog']),'reviewed_local_sources':len(manifest['reviewedSourceHashes']),'resolved_generated_local_links':checked_links,'source_catalog_sha256':sha(catalog_bytes),'editorial_sha256':sha(editorial_bytes),'status':'PASS'}
    report['concept_posters_with_current_notes']=len(poster_manifest)
    report['resolved_static_navigation_destinations']=len(nav_links)
    target=SITE/'verification/react-static-checks.json'
    # Publish once, after validation, without truncating an observed receipt.
    with tempfile.NamedTemporaryFile(mode='w',encoding='utf-8',dir=target.parent,prefix='.static-checks-',suffix='.tmp',delete=False) as stream:
        stream.write(json.dumps(report,indent=2)+'\n')
        temporary=Path(stream.name)
    try:os.replace(temporary,target)
    finally:
        if temporary.exists():temporary.unlink()
    print(json.dumps(report,indent=2))

if __name__=='__main__':main()
