"""Search decoded instructions for one question-selected field displacement."""
import argparse
import json
from pathlib import Path
from probe import backend, ROOT

JAVA=r'''
import ghidra.app.script.GhidraScript;
import ghidra.program.model.listing.*;
import ghidra.program.model.scalar.*;
import java.nio.file.*;
public class NativeFieldRefs extends GhidraScript {
 public void run() throws Exception {
  StringBuilder out=new StringBuilder("instruction\tfunction\tbytes\ttext\n"); int count=0;
  InstructionIterator it=currentProgram.getListing().getInstructions(true);
  while(it.hasNext() && count<128) {
   Instruction inst=it.next();boolean match=false;
   for(int op=0;op<inst.getNumOperands();op++)for(Object obj:inst.getOpObjects(op))
    if(obj instanceof Scalar && ((Scalar)obj).getUnsignedValue()==__OFFSET__)match=true;
   if(!match)continue;
   Function f=getFunctionContaining(inst.getAddress());
   out.append(inst.getAddress()+"\t"+(f==null?"":f.getEntryPoint())+"\t"+(f==null?0:f.getBody().getNumAddresses())+"\t"+inst+"\n");count++;
  }
  Files.writeString(Path.of(__OUTPUT__),out.toString());println(out.toString());
 }
}
'''

def main():
    p=argparse.ArgumentParser();p.add_argument('--run',type=Path,required=True);p.add_argument('--offset',required=True)
    a=p.parse_args();run=a.run.resolve();assert run.is_relative_to(ROOT/'build') and run.is_dir()
    offset=int(a.offset,16);assert 0<offset<0x1000000
    out=run/f'field-{offset:x}.tsv';assert not out.exists()
    code=JAVA.replace('__OFFSET__',str(offset)+'L').replace('__OUTPUT__',json.dumps(out.as_posix()))
    out.with_suffix('.request.json').write_text(json.dumps({'code':code}),encoding='utf-8')
    result=backend.request(18091,'POST','/run_script_inline',{'code':code},60)
    out.with_suffix('.response.txt').write_text(result,encoding='utf-8')
    assert out.exists(),result[-2000:];print(out.read_text())

if __name__=='__main__':main()
