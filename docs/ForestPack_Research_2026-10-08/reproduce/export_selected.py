"""Export selected, analysis-defined functions; never copies listings into Git.

Only functions <=64 KiB are decompiled; each receives a 30-second timeout.
The selected addresses are discoveries for a pinned binary, not original names.
"""
import argparse
import hashlib
import importlib.util
import json
from pathlib import Path


JAVA = r'''
import ghidra.app.script.GhidraScript;
import ghidra.app.decompiler.*;
import ghidra.program.model.address.*;
import ghidra.program.model.listing.*;
import ghidra.program.model.symbol.*;
import java.nio.file.*;

public class ForestSelectedResearch extends GhidraScript {
    public void run() throws Exception {
        Path folder = Path.of(__FOLDER__);
        Files.createDirectories(folder);
        String[][] entries = new String[][] { __ENTRIES__ };
        DecompInterface decompiler = new DecompInterface();
        decompiler.openProgram(currentProgram);
        StringBuilder ledger = new StringBuilder("label\trequested\tentry\tbytes\tinstructions\tdecoded_bytes\tcompleted\terror\n");
        try {
            for (String[] entry : entries) {
                Address address = toAddr(entry[1]);
                Function f = getFunctionContaining(address);
                if (f == null) { ledger.append(entry[0]+"\t"+address+"\tmissing\n"); continue; }
                long size = f.getBody().getNumAddresses();
                if (size > 65536) { ledger.append(entry[0]+"\t"+address+"\t"+f.getEntryPoint()+"\toversize:"+size+"\n"); continue; }
                StringBuilder assembly = new StringBuilder("; Ghidra analysis-defined function bounds; verify ownership.\n");
                StringBuilder refs = new StringBuilder("from\tto\ttype\tsymbol\tfunction\n");
                int count = 0, bytes = 0;
                InstructionIterator instructions = currentProgram.getListing().getInstructions(f.getBody(),true);
                while (instructions.hasNext()) {
                    Instruction inst = instructions.next();
                    assembly.append(inst.getAddress()+"  "+inst+"\n"); ++count; bytes += inst.getLength();
                    for (Reference ref : currentProgram.getReferenceManager().getReferencesFrom(inst.getAddress())) {
                        Symbol sym = currentProgram.getSymbolTable().getPrimarySymbol(ref.getToAddress());
                        Function callee = getFunctionContaining(ref.getToAddress());
                        refs.append(ref.getFromAddress()+"\t"+ref.getToAddress()+"\t"+ref.getReferenceType()+"\t"+(sym==null?"":sym.getName(true))+"\t"+(callee==null?"":callee.getName(true))+"\n");
                    }
                }
                Files.writeString(folder.resolve(entry[0]+".asm.txt"),assembly);
                Files.writeString(folder.resolve(entry[0]+".refs.tsv"),refs);
                DecompileResults result = decompiler.decompileFunction(f,30,monitor);
                boolean completed = result.decompileCompleted() && result.getDecompiledFunction()!=null;
                if (completed) Files.writeString(folder.resolve(entry[0]+".c"),result.getDecompiledFunction().getC());
                ledger.append(entry[0]+"\t"+address+"\t"+f.getEntryPoint()+"\t"+size+"\t"+count+"\t"+bytes+"\t"+completed+"\t"+result.getErrorMessage().replace('\n',' ')+"\n");
            }
        } finally { decompiler.dispose(); }
        Files.writeString(folder.resolve("ledger.tsv"),ledger);
        println(ledger.toString());
    }
}
'''


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--run',type=Path,required=True)
    parser.add_argument('--selection',type=Path,required=True)
    parser.add_argument('--output',type=Path,required=True)
    args = parser.parse_args()
    run,output = args.run.resolve(),args.output.resolve()
    if not run.is_relative_to(Path.cwd()/'build') or not output.is_relative_to(run): raise ValueError('Use ignored run')
    entries = json.loads(args.selection.read_text(encoding='utf-8-sig'))
    if len(entries)>30: raise ValueError('At most 30 selected functions per batch')
    for e in entries:
        if not e['label'].replace('_','').isalnum(): raise ValueError('Simple labels only')
        int(e['address'],16)
    output.mkdir(parents=True,exist_ok=False)
    source = JAVA.replace('__FOLDER__',json.dumps(output.as_posix())).replace('__ENTRIES__',
        ','.join('{'+','.join(json.dumps(e[k]) for k in ['label','address'])+'}' for e in entries))
    (output/'ForestSelectedResearch.java').write_text(source,encoding='utf-8')
    spec = importlib.util.spec_from_file_location('backend',Path(__file__).with_name('backend.py'))
    backend = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(backend)
    result = backend.request(18091,'POST','/run_script_inline',{'code':source},max(120,len(entries)*35))
    (output/'response.json').write_text(result,encoding='utf-8')
    manifest = dict(selection=entries,files=[dict(name=p.name,bytes=p.stat().st_size,sha256=hashlib.sha256(p.read_bytes()).hexdigest()) for p in sorted(output.iterdir()) if p.is_file()])
    (output/'manifest.json').write_text(json.dumps(manifest,indent=2),encoding='utf-8')
    print(result[-6000:])


if __name__ == '__main__': main()
