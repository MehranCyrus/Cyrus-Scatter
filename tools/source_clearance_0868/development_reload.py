"""Recover only the recorded disposable parse-test host; never release evidence."""
from pathlib import Path
import sys
ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'tools/native_placement'))
from run_generation import send
host=ROOT/'build/mcp-qualification/update08671-test-clearance-new-2027'
script=host/'development-reload.ms'
script.write_text('CyrusPointSuspended=true\nresetMaxFile #noPrompt\nfileIn @"'+(ROOT/'AminScatter/scripts/AminScatterObject.ms').as_posix()+'"\n'
 '(dotNetClass "System.IO.File").WriteAllText (MCPFixtureDir+"ready.json") "{}"\n')
send(host,script,'development-parse-reload')
