"""Export bounded function evidence through the existing v6 headless backend.

Only the analysis database is annotated. The target binary is never executed.
Selection records must carry an unwind region or an explicitly verified bound.
"""
import argparse
import hashlib
import json
import urllib.request
from pathlib import Path


def request(endpoint, params, timeout=600):
    query = urllib.request.Request(
        "http://127.0.0.1:18089" + endpoint,
        data=json.dumps(params).encode("utf-8"),
        headers={"Content-Type": "application/json"}, method="POST",
    )
    with urllib.request.urlopen(query, timeout=timeout) as response:
        return response.read().decode("utf-8", errors="replace")


JAVA = r'''
import ghidra.app.script.GhidraScript;
import ghidra.app.cmd.disassemble.DisassembleCommand;
import ghidra.app.decompiler.*;
import ghidra.program.model.address.*;
import ghidra.program.model.listing.*;
import ghidra.program.model.symbol.*;
import java.nio.file.*;

public class ScatterVendorResearch extends GhidraScript {
    @Override public void run() throws Exception {
        String[][] entries = new String[][] { __ENTRIES__ };
        Path folder = Path.of(__FOLDER__);
        Files.createDirectories(folder);
        DecompInterface decompiler = new DecompInterface();
        decompiler.openProgram(currentProgram);
        try {
            for (String[] entry : entries) {
                Address start = toAddr(entry[1]), end = toAddr(entry[2]);
                AddressSet range = new AddressSet(start, end);
                boolean ok = false;
                String error = "";
                int tx = currentProgram.startTransaction("Bounded research " + entry[0]);
                Function function = null;
                try {
                    ok = true;
                    // Re-enter at each unwind fragment: an already decoded root
                    // does not necessarily cause Ghidra to follow newly expanded bounds.
                    for (String part : entry[3].split(",")) {
                        ok &= new DisassembleCommand(toAddr(part), range, true).applyTo(currentProgram, monitor);
                    }
                    // Only explicit chained unwind fragments may have their old
                    // analysis-created placeholder function folded into the root.
                    for (String part : entry[3].split(",")) {
                        Address fragment = toAddr(part);
                        Function placeholder = getFunctionAt(fragment);
                        if (!fragment.equals(start) && placeholder != null) {
                            if (!range.contains(placeholder.getBody())) {
                                throw new IllegalStateException("Fragment function extends beyond approved bounds");
                            }
                            currentProgram.getFunctionManager().removeFunction(fragment);
                        }
                    }
                    function = getFunctionAt(start);
                    if (function == null) {
                        function = currentProgram.getFunctionManager().createFunction(null, start, range, SourceType.ANALYSIS);
                    } else {
                        function.setBody(range);
                    }
                } catch (Exception problem) {
                    error = problem.toString();
                } finally {
                    currentProgram.endTransaction(tx, true);
                }
                StringBuilder assembly = new StringBuilder(
                    "; STATIC x64 instructions; selected region is not guaranteed complete function ownership\n");
                InstructionIterator instructions = currentProgram.getListing().getInstructions(range, true);
                int count = 0, bytes = 0;
                while (instructions.hasNext()) {
                    Instruction instruction = instructions.next();
                    assembly.append(instruction.getAddress()).append("  ").append(instruction).append("\n");
                    count++;
                    bytes += instruction.getLength();
                }
                Files.writeString(folder.resolve(entry[0] + ".asm.txt"), assembly);
                StringBuilder refs = new StringBuilder("direction\tfrom\tto\ttype\tsymbol\n");
                ReferenceIterator incoming = currentProgram.getReferenceManager().getReferencesTo(start);
                while (incoming.hasNext()) {
                    Reference ref = incoming.next();
                    refs.append("in\t").append(ref.getFromAddress()).append("\t")
                        .append(ref.getToAddress()).append("\t").append(ref.getReferenceType()).append("\t\n");
                }
                InstructionIterator instructionRefs = currentProgram.getListing().getInstructions(range, true);
                while (instructionRefs.hasNext()) {
                    Instruction instruction = instructionRefs.next();
                    for (Reference ref : currentProgram.getReferenceManager().getReferencesFrom(instruction.getAddress())) {
                        Symbol symbol = currentProgram.getSymbolTable().getPrimarySymbol(ref.getToAddress());
                        refs.append("out\t").append(ref.getFromAddress()).append("\t")
                            .append(ref.getToAddress()).append("\t").append(ref.getReferenceType()).append("\t")
                            .append(symbol == null ? "" : symbol.getName(true)).append("\n");
                    }
                }
                Files.writeString(folder.resolve(entry[0] + ".refs.tsv"), refs);
                boolean completed = false;
                String decompileError = "";
                if (function != null) {
                    decompiler.flushCache();
                    DecompileResults result = decompiler.decompileFunction(function, 30, monitor);
                    completed = result.decompileCompleted();
                    decompileError = result.getErrorMessage();
                    if (completed && result.getDecompiledFunction() != null) {
                        Files.writeString(folder.resolve(entry[0] + ".c"), result.getDecompiledFunction().getC());
                    }
                }
                println(entry[0] + "\t" + start + "\t" + end + "\t" + ok + "\t" + count + "\t" + bytes
                    + "\t" + completed + "\t" + error + "\t" + decompileError);
            }
        } finally {
            decompiler.dispose();
        }
    }
}
'''


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("selection", type=Path)
    parser.add_argument("output", type=Path)
    args = parser.parse_args()
    args.output.mkdir(parents=True, exist_ok=False)
    entries = json.loads(args.selection.read_text(encoding="utf-8-sig"))
    java_entries = []
    base = 0x180000000
    for entry in entries:
        start, end = int(entry["begin"], 16), int(entry["end_exclusive"], 16)
        if end <= start or end - start > 65536:
            raise ValueError("Invalid or excessively large selected region")
        label = entry["label"]
        if not label.replace("_", "").isalnum():
            raise ValueError("Label must be a simple filename")
        parts = entry.get("unwind_regions", [{"begin": entry["begin"]}])
        for part in parts:
            if not start <= int(part["begin"], 16) < end:
                raise ValueError("Unwind fragment outside selected bound")
        java_entries.append("{" + ",".join(json.dumps(value) for value in (
            label, hex(base + start), hex(base + end - 1),
            ",".join(hex(base + int(part["begin"], 16)) for part in parts)
        )) + "}")
    source = JAVA.replace("__ENTRIES__", ",\n".join(java_entries)).replace(
        "__FOLDER__", json.dumps(args.output.resolve().as_posix())
    )
    (args.output / "ResearchBatch.java").write_text(source, encoding="utf-8")
    print(f"Exporting {len(entries)} bounded regions to {args.output}", flush=True)
    result = request("/run_script_inline", {"code": source}, timeout=max(600, 35 * len(entries)))
    (args.output / "script-response.txt").write_text(result, encoding="utf-8")
    print(result[-12000:], flush=True)
    files = [
        dict(name=path.name, bytes=path.stat().st_size,
             sha256=hashlib.sha256(path.read_bytes()).hexdigest())
        for path in sorted(args.output.iterdir()) if path.is_file()
    ]
    (args.output / "manifest.json").write_text(json.dumps(
        dict(selection=entries, files=files), indent=2
    ), encoding="utf-8")


if __name__ == "__main__":
    main()
