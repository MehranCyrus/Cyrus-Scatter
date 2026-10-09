"""Inspect bounded candidate vtable slots; RTTI references require manual validation."""
import argparse
import json
from pathlib import Path
from probe import ROOT,backend

JAVA=r'''
import ghidra.app.script.GhidraScript;
import ghidra.program.model.address.*;
import ghidra.program.model.listing.*;
import java.nio.file.*;
public class NativeVtableSlots extends GhidraScript {
 public void run() throws Exception {
  String[][] entries={__ENTRIES__};
  StringBuilder out=new StringBuilder("label\tvtable\tslot\ttarget\texecutable\tfunction\tbytes\n");
  for(String[] e:entries) {
   Address start=toAddr(e[1]);
   for(int i=0;i<__SLOTS__;i++) {
    Address target=toAddr(currentProgram.getMemory().getLong(start.add(i*8)));
    Function f=getFunctionContaining(target);
    boolean code=currentProgram.getMemory().getBlock(target)!=null && currentProgram.getMemory().getBlock(target).isExecute();
    out.append(e[0]+"\t"+start+"\t"+i+"\t"+target+"\t"+code+"\t"+(f==null?"":f.getEntryPoint())+"\t"+(f==null?0:f.getBody().getNumAddresses())+"\n");
   }
  }
  Files.writeString(Path.of(__OUTPUT__),out.toString());println(out.toString());
 }
}
'''

def main():
    p=argparse.ArgumentParser();p.add_argument('--run',type=Path,required=True);p.add_argument('--selection',type=Path,required=True);p.add_argument('--output',type=Path,required=True);p.add_argument('--slots',type=int,default=4);a=p.parse_args()
    run=a.run.resolve();output=a.output.resolve();assert run.is_relative_to(ROOT/'build') and output.is_relative_to(run) and not output.exists()
    entries=json.loads(a.selection.read_text());assert len(entries)<=30 and 1<=a.slots<=16
    code=JAVA.replace('__ENTRIES__',','.join('{'+json.dumps(e['label'])+','+json.dumps(e['address'])+'}' for e in entries)).replace('__OUTPUT__',json.dumps(output.as_posix())).replace('__SLOTS__',str(a.slots))
    output.with_suffix('.request.json').write_text(json.dumps({'code':code}))
    result=backend.request(18091,'POST','/run_script_inline',{'code':code},60)
    output.with_suffix('.response.txt').write_text(result)
    assert output.exists(),result
    print(output.read_text())


if __name__=='__main__':main()
