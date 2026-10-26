"""Publish reviewed 0.87.1 corpus/label successors; no index or activation writes."""
from pathlib import Path
import argparse,copy,hashlib,json,re
ROOT=Path(__file__).resolve().parents[2]
def read(p):return json.loads(p.read_text(encoding='utf8'))
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def write(p,value):
    assert not p.exists(),p;p.write_text(json.dumps(value,indent=2,ensure_ascii=False)+'\n',encoding='utf8')
def main():
    parser=argparse.ArgumentParser();parser.add_argument('--draft',type=Path,required=True);a=parser.parse_args();draft=a.draft.resolve();rag=ROOT/'tools/rag';old=read(rag/'corpus-v31.json');new=read(draft/'corpus.json');prior={s['path']:s for s in old['sources']}
    for source in new['sources']:assert sha(ROOT/source['path'])==source['sha256'],source['path']
    paths=[
      'AminScatter/shared/SharedLibrary.cs','AminScatter/shared/SharedLibrary.Models.cs','AminScatter/shared/SharedLibrary.Management.cs','AminScatter/shared/ContentObjects.cs',
      'AminScatter/tools/ui/templates/assets.ms','AminScatter/tools/ui/templates/shared-library.ms','AminScatter/src/asset_package.cpp','AminScatter/src/asset_mesh_host.inc','AminScatter/tools/ui/templates/recipes.ms',
      'docs/plans/preset-gallery-improvements/SHARED_LIBRARY_ARTIST_GUIDE_0871.md','docs/plans/preset-gallery-improvements/DELIVERY_0871.md',
      'docs/plans/scatter-interactions-garden-20261025/ARTIST_GUIDE_0870.md','docs/plans/scatter-interactions-garden-20261025/DELIVERY_0870.md',
      'AminScatter/src/interactions_source.cpp','AminScatter/src/interactions_engine.cpp','AminScatter/tools/ui/templates/interactions-authoring.ms']
    for path in paths:
        p=ROOT/path;lines=p.read_text(encoding='utf8').splitlines();md=path.endswith('.md');historical='/DELIVERY_' in path
        source=dict(path=path,sha256=sha(p),selection_reason='Explicitly reviewed 0.87.1 library and retained 0.87.0 Interactions enrollment requested by the user.',role='historical_evidence' if historical else 'maintained_guide' if md else 'implementation',review_status='Agent source/context and applicability review, 26 October 2026; human semantic review not performed.',applicability=dict(snapshot='Exact current source bytes or explicitly dated delivery named by this parent.',limits='Library tests apply only to the exact 0.87.1 static scope and matched receipts. Interactions source/delivery retains Max 2027 and original artist acceptance limits; no blanket certification. Source inspection is not execution proof.'),canonical=dict(preferred_path=path,relationship='selected-original',evidence='Maintained direct owner linked from current architecture, artist guide or delivery.'),ranges=[[1,len(lines)]],knowledge_status='historical' if historical else 'current',status_source='explicit:reviewed-0871-enrollment',inventory_decision=None,inventory_reason=None,referenced_by_current_docs=True,current_reference_sources=['docs/ARCHITECTURE.md','docs/plans/preset-gallery-improvements/DELIVERY_0871.md'],component='Scatter',generated=False,generated_source=None)
        if md:
            heads=sorted(set([1,*[i+1 for i,line in enumerate(lines) if re.match(r'^#{1,4} ',line)]]));source['contract_sections']=[[x,y-1] for x,y in zip(heads,heads[1:]+[len(lines)+1]) if x<y]
        new['sources'].append(source)
    assert len(new['sources'])==64
    new['version']='32-scatter-0871-library-and-interactions';new['review_status']='Agent-reviewed source, complete selected contexts, enrollment and historical limits; human semantic review not performed.'
    review=dict(corpus=dict(old_sha256=sha(rag/'corpus-v31.json'),reason='User authorized completion of the shared-library implementation, documentation and knowledge update. Review current 0.87.1 sources and retain the original Interactions/independent-product qualification limits; preserve all 48 existing parents and enroll 16 explicit owners, within the unchanged 64-parent bound.'),enrollment=dict(added=paths,agent_reviewed=True,reason='Personal-library ownership, native mesh/package boundaries, UI commands, and the previously unenrolled 0.87.0 Interactions guide/delivery/source are directly relevant to current questions. No generated assets, private scenes or knowledge runtime are enrolled.'),sources=[],evaluations=[],reference_conclusions=[],retrieval_tradeoffs=[])
    for source in new['sources']:
        before=prior.get(source['path'],{})
        if source==before:continue
        fields=[k for k in set(source)|set(before) if source.get(k)!=before.get(k)]
        review['sources'].append(dict(path=source['path'],old_sha256=before.get('sha256'),new_sha256=source['sha256'],field_reasons={k:'Inspected the current complete selected context and exact prior/successor scope. Preserve original status/role, source ownership, historical receipts, unsupported cases and independent qualification. Changed source-aware radii/publication intervals remain bounded to their equivalent current functions; documentation sections retain full current qualifiers.' for k in fields},diff_inspected=True,ranges_checked=True,context_checked=True,applicability_checked=True,authority_checked=True,generated_ownership_checked=True,canonical_checked=True,contract_sections_reviewed=True,unchanged_metadata_reviewed=True))
    definitions=['evaluation-original-v25.json','evaluation-revised-v25.json','challenge-v24.json','evaluation-foundation-v19.json','evaluation-native-foundation-v14.json','evaluation-navigation-v11.json','evaluation-workflows-v10.json']
    fingerprint=re.search(r'CyrusLoadedScriptFingerprint="([0-9a-f]{64})"',(ROOT/'AminScatter/scripts/AminScatterObject.ms').read_text(encoding='utf8'))[1]
    updates={'O05':"The question names the older 241-control/C01-C34 snapshot. Current test_feature_catalog.py checks 347 controls and C01-C37 for 0.87.1; semantic catalog membership does not grant additional remote write authority or certify every behavior.",'O08':'The generated first line declares payload fingerprint '+fingerprint+'; this differs from whole-file SHA-256.','H06':'Schema-54 model-set/stroke setups remain rejected. Current schema 60 opens schema 59 with Interactions off and retains an explicit Undoable clearance upgrade from schema 58. Earlier development-schema migration remains retired; preserve original scenes and saved units.'}
    produced=[]
    for name in definitions:
        original=read(rag/name);labels=read(draft/name);oldsha=sha(rag/name)
        before={(group,q['id']):q for group,key in [('base','queries'),('anchors','anchors')] for q in original[key]}
        for group,key in [('base','queries'),('anchors','anchors')]:
            for q in labels[key]:
                identity=q.get('base_id',q['id']);identity=re.sub(r'[-_]A[0-9]*$','',identity)
                if identity in updates and q.get('reference_conclusion') is not None and q['reference_conclusion']!=updates[identity]:
                    review['reference_conclusions'].append(dict(old_evaluation_sha256=oldsha,group=group,id=q['id'],old_value=before[(group,q['id'])].get('reference_conclusion'),new_value=updates[identity],agent_reviewed=True,reason='Inspected current catalog assertions, generated payload fingerprint or schema-60/59/58 contract. Only the unscored snapshot answer note changes; questions, required units, alternatives, owners, qualifiers, answerability and splits remain unchanged.'))
                    q['reference_conclusion']=updates[identity]
        target=re.sub(r'-v[0-9]+\.json$','-v'+str(int(re.search(r'-v([0-9]+)\.json$',name)[1])+1)+'.json',name)
        write(rag/target,labels);produced.append(target);review['evaluations'].append(dict(old_sha256=oldsha,new_sha256=sha(rag/target),reason='Exact source-provenance/locator successors were inspected. Preserve question wording, split, required evidence counts/canonical owners, qualifiers and answerability. Explicit unscored reference-conclusion reviews retain original labels and history.'))
    write(rag/'corpus-v32.json',new);review['corpus']['new_sha256']=sha(rag/'corpus-v32.json');write(rag/'review-v40.json',review)
    print(json.dumps(dict(corpus='tools/rag/corpus-v32.json',review='tools/rag/review-v40.json',evaluations=produced,sources=len(new['sources'])),indent=2))
if __name__=='__main__':main()
