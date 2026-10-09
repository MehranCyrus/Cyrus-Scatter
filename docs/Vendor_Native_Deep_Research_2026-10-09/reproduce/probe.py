"""Question-selected references in copied Ghidra projects; no target execution."""
import argparse
import importlib.util
import json
from pathlib import Path

ROOT=Path(__file__).resolve().parents[3]
spec=importlib.util.spec_from_file_location('backend',ROOT/'docs/ForestPack_Research_2026-10-08/reproduce/backend.py')
backend=importlib.util.module_from_spec(spec);spec.loader.exec_module(backend)

JAVA=r'''
import ghidra.app.script.GhidraScript;
import ghidra.program.model.address.*;
import ghidra.program.model.listing.*;
import ghidra.program.model.symbol.*;
import java.nio.file.*;
import java.util.*;
public class NativeQuestionRefs extends GhidraScript {
 public void run() throws Exception {
  String[][] entries={__ENTRIES__};
  StringBuilder out=new StringBuilder("label\tdepth\tto\tfrom\ttype\tfunction\tname\tbytes\n");
  for(String[] e:entries) {
   ArrayDeque<Address> q=new ArrayDeque<>();ArrayDeque<Integer> levels=new ArrayDeque<>();
   HashSet<Address> visited=new HashSet<>();q.add(toAddr(e[1]));levels.add(0);
   int emitted=0;
   while(!q.isEmpty() && emitted<512) {
    Address a=q.remove();int depth=levels.remove();if(!visited.add(a))continue;
    ReferenceIterator refs=currentProgram.getReferenceManager().getReferencesTo(a);
    while(refs.hasNext() && emitted<512) {
     Reference ref=refs.next();Address from=ref.getFromAddress();Function f=getFunctionContaining(from);
     out.append(e[0]+"\t"+depth+"\t"+a+"\t"+from+"\t"+ref.getReferenceType()+"\t"+(f==null?"":f.getEntryPoint())+"\t"+(f==null?"":f.getName())+"\t"+(f==null?0:f.getBody().getNumAddresses())+"\n");emitted++;
     if(f==null && depth<__DEPTH__) { q.add(from);levels.add(depth+1); }
    }
   }
  }
  Files.writeString(Path.of(__OUTPUT__),out.toString());println(out.toString());
 }
}
'''

def main():
    parser=argparse.ArgumentParser();parser.add_argument('--run',type=Path,required=True)
    parser.add_argument('--project',choices=['ChaosOwnership','ReceivingSurfaceCore','ForestPack943'])
    parser.add_argument('--anchors',type=Path);parser.add_argument('--output',type=Path);parser.add_argument('--depth',type=int,default=0)
    args=parser.parse_args();run=args.run.resolve()
    assert run.is_relative_to(ROOT/'build') and run.is_dir()
    if args.project:
        result=backend.request(18091,'POST','/open_project',{'path':(run/'projects'/f'{args.project}.gpr').as_posix()},45)
        assert json.loads(result).get('success'),result
        (run/f'open-{args.project}.json').write_text(result)
        program={'ChaosOwnership':'ScatterMax_Release-2027.dll','ReceivingSurfaceCore':'ScatterCore.ForScatter_Release.dll','ForestPack943':'ForestPackLite.dlo'}[args.project]
        result=backend.request(18091,'POST','/load_program_from_project',{'path':'/'+program},45)
        assert json.loads(result).get('success'),result
        (run/f'load-{args.project}.json').write_text(result);print(result)
    if args.anchors:
        entries=json.loads(args.anchors.read_text(encoding='utf-8-sig'));assert len(entries)<=40
        output=args.output.resolve();assert output.is_relative_to(run) and not output.exists()
        assert 0<=args.depth<=4
        for entry in entries:int(entry['address'],16)
        code=JAVA.replace('__ENTRIES__',','.join('{'+json.dumps(e['label'])+','+json.dumps(e['address'])+'}' for e in entries)).replace('__DEPTH__',str(args.depth)).replace('__OUTPUT__',json.dumps(output.as_posix()))
        request=output.with_suffix('.request.json');request.write_text(json.dumps({'code':code}),encoding='utf-8')
        result=backend.request(18091,'POST','/run_script_inline',{'code':code},60)
        output.with_suffix('.response.json').write_text(result,encoding='utf-8')
        # This installed run_script_inline endpoint returns a textual receipt.
        assert output.exists() and output.read_text().startswith('label\tdepth\t'),result[-3000:]
        print(output.read_text()[-14000:])


if __name__=='__main__':main()
