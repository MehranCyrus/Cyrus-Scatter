"""Define one bounded straight-line leaf in an owned analysis copy, then export it."""
import argparse
import json
from pathlib import Path
from probe import backend, ROOT

JAVA = r'''
import ghidra.app.script.GhidraScript;
import ghidra.program.model.address.*;
import ghidra.program.model.listing.*;
import java.nio.file.*;
public class NativeLeafWitness extends GhidraScript {
 public void run() throws Exception {
  Address start=toAddr(__ADDRESS__); Address cursor=start;
  if(getFunctionContaining(start)!=null)throw new Exception("Already owned by a function");
  disassemble(start); StringBuilder out=new StringBuilder(); boolean ended=false;
  for(int i=0;i<16 && cursor.subtract(start)<32;i++) {
   Instruction inst=getInstructionAt(cursor);
   if(inst==null)throw new Exception("Missing instruction");
   String op=inst.getMnemonicString();
   if(inst.getFlowType().isCall() || inst.getFlowType().isJump())throw new Exception("Not a straight-line leaf");
   out.append(inst.getAddress()+"  "+inst+"\n");
   if(op.equals("RET")){ended=true;break;}
   cursor=cursor.add(inst.getLength());
  }
  if(!ended)throw new Exception("No bounded return");
  Function f=createFunction(start,null);
  if(f==null || f.getBody().getNumAddresses()>32)throw new Exception("Unexpected body");
  Files.writeString(Path.of(__OUTPUT__),out.toString());println(out.toString());
 }
}
'''

def main():
    p=argparse.ArgumentParser();p.add_argument('--run',type=Path,required=True);p.add_argument('--address',required=True)
    a=p.parse_args();run=a.run.resolve();assert run.is_relative_to(ROOT/'build') and run.is_dir()
    int(a.address,16);out=run/f'leaf-{a.address}.txt';assert not out.exists()
    code=JAVA.replace('__ADDRESS__',json.dumps(a.address)).replace('__OUTPUT__',json.dumps(out.as_posix()))
    (run/f'leaf-{a.address}.request.json').write_text(json.dumps({'code':code}),encoding='utf-8')
    result=backend.request(18091,'POST','/run_script_inline',{'code':code},60)
    (run/f'leaf-{a.address}.response.txt').write_text(result,encoding='utf-8')
    assert out.exists(),result[-2000:];print(out.read_text())

if __name__=='__main__':main()
