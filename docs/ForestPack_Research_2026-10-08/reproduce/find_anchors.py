"""Trace selected configuration/profiling strings to containing native functions."""
import argparse
import importlib.util
import json
from pathlib import Path

JAVA = r'''
import ghidra.app.script.GhidraScript;
import ghidra.program.model.listing.*;
import ghidra.program.model.symbol.*;
import java.nio.file.*;
public class ForestAnchors extends GhidraScript {
    public void run() throws Exception {
        String[][] entries = new String[][] { __ENTRIES__ };
        StringBuilder out = new StringBuilder("anchor\taddress\tfrom\ttype\tfunction\tbytes\n");
        for(String[] e : entries) {
            ReferenceIterator it = currentProgram.getReferenceManager().getReferencesTo(toAddr(e[1]));
            while(it.hasNext()) {
                Reference ref = it.next();
                Function f = getFunctionContaining(ref.getFromAddress());
                out.append(e[0]+"\t"+e[1]+"\t"+ref.getFromAddress()+"\t"+ref.getReferenceType()+"\t"+(f==null?"":f.getEntryPoint())+"\t"+(f==null?0:f.getBody().getNumAddresses())+"\n");
            }
        }
        Files.writeString(Path.of(__OUTPUT__),out);
        println(out.toString());
    }
}
'''


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--run',type=Path,required=True)
    args = parser.parse_args()
    run = args.run.resolve()
    if not run.is_relative_to(Path.cwd()/'build'): raise ValueError('Use build/')
    strings = json.loads((run/'static/ForestPackLite/strings.json').read_text())
    wanted = ['BuildItemArray->DistributeArea(%d)->Starting %d threads','BuildItemArray->ComputeCollisions XY (%d items)',
              'BuildItemArray->DistributeImageXY (%d areas)','BuildItemArray->ComputeCollisions UV (%d items)',
              'Starting UpdateMeshForDisplay(%d)','cloudPointsByObject','cloudHitTestMaxPoints','samplesCacheLimit',
              'Forest samples cache purged (%u deleted, %u remaining)']
    entries = [(s['text'],hex(0x180000000+int(s['rva'],16))) for s in strings if s['text'] in wanted]
    source = JAVA.replace('__ENTRIES__',','.join('{'+json.dumps(a)+','+json.dumps(b)+'}' for a,b in entries)).replace('__OUTPUT__',json.dumps((run/'anchors.tsv').as_posix()))
    (run/'anchors-script.json').write_text(json.dumps({'code':source}),encoding='utf-8')
    spec = importlib.util.spec_from_file_location('backend',Path(__file__).with_name('backend.py'))
    backend = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(backend)
    response = backend.request(18091,'POST','/run_script_inline',{'code':source},60)
    (run/'anchors-response.txt').write_text(response,encoding='utf-8')
    print(response[-5000:])


if __name__ == '__main__': main()
