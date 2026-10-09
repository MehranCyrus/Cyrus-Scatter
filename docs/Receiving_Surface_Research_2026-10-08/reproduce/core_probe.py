"""Find exact question anchors in the copied Chaos core; preserve raw listings privately."""
import argparse
import importlib.util
import json
from pathlib import Path

ROOT=Path(__file__).resolve().parents[3]
JAVA=r'''
import ghidra.app.script.GhidraScript;
import ghidra.program.model.address.*;
import ghidra.program.model.listing.*;
import ghidra.program.model.symbol.*;
import java.nio.file.*;
public class SurfaceCoreAnchors extends GhidraScript {
 public void run() throws Exception {
  String[][] entries={__ENTRIES__};
  StringBuilder out=new StringBuilder("label\tanchor\tfrom\tfunction\tname\tbytes\n");
  for(String[] e:entries) {
   Address a=toAddr(e[1]);
   ReferenceIterator refs=currentProgram.getReferenceManager().getReferencesTo(a);
   while(refs.hasNext()) {
    Reference ref=refs.next(); Function f=getFunctionContaining(ref.getFromAddress());
    out.append(e[0]+"\t"+a+"\t"+ref.getFromAddress()+"\t"+(f==null?"":f.getEntryPoint())+"\t"+(f==null?"":f.getName())+"\t"+(f==null?0:f.getBody().getNumAddresses())+"\n");
   }
  }
  Files.writeString(Path.of(__OUTPUT__),out.toString());println(out.toString());
 }
}
'''
def main():
 p=argparse.ArgumentParser(description=__doc__);p.add_argument('--run',type=Path,required=True);a=p.parse_args();run=a.run.resolve()
 if not run.is_relative_to(ROOT/'build'): raise ValueError('Ignored owned run only')
 spec=importlib.util.spec_from_file_location('backend',ROOT/'docs/ForestPack_Research_2026-10-08/reproduce/backend.py')
 backend=importlib.util.module_from_spec(spec);spec.loader.exec_module(backend)
 image=run/'static/ScatterCore.ForScatter_Release'
 strings=json.loads((image/'strings.json').read_text());base=int(json.loads((image/'summary.json').read_text())['image_base'],16)
 names=['Legion::Scatter::generateInstanceIds','Legion::Scatter::ScatterCore::applyInstanceFilters',
        'Legion::Scatter::ScatterCore::gatherPlacedInstanceData','Legion::Scatter::MeshScatter::scatterInstances',
        'Legion::Scatter::MeshScatter::generateRandom','Legion::Scatter::MeshScatter::scatterPlacedInstances']
 anchors=[dict(label=n.split('::')[-1],address=hex(base+int(s['rva'],16))) for n in names for s in strings if s['text']==n]
 code=JAVA.replace('__ENTRIES__',','.join('{'+json.dumps(e['label'])+','+json.dumps(e['address'])+'}' for e in anchors)).replace('__OUTPUT__',json.dumps((run/'core-anchors.tsv').as_posix()))
 (run/'SurfaceCoreAnchors.java').write_text(code)
 response=backend.request(18091,'POST','/run_script_inline',{'code':code},60)
 (run/'anchors-response.json').write_text(response);print(response[-5000:])
 exports=json.loads((image/'exports.json').read_text())
 selected=[dict(label='core_'+name,address=hex(base+int(e['rva'],16))) for name in ['generate','getInstanceTargetIndex','getInstance','setInstanceOverride'] for e in exports if e['name'].startswith('?'+name+'@ScatterCore')]
 for line in (run/'core-anchors.tsv').read_text().splitlines()[1:]:
  cols=line.split('\t')
  if cols[3] and not any(e['address'].removeprefix('0x').lower()==cols[3].lower() for e in selected): selected.append(dict(label=cols[0],address='0x'+cols[3]))
 (run/'core-selection.json').write_text(json.dumps(selected,indent=2))
 print('Selected',len(selected),'functions')
if __name__=='__main__':main()
