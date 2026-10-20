"""Close only an owned installer qualification host, never an artist process."""
from pathlib import Path
import argparse,json,sys
ROOT=Path(__file__).resolve().parents[2];sys.path.insert(0,str(ROOT/'tools/native_placement'))
from run_generation import send
p=argparse.ArgumentParser();p.add_argument('host');a=p.parse_args();assert a.host.startswith('density0862-installer-')
host=ROOT/'build/mcp-qualification'/a.host;meta=json.loads((host/'launch.json').read_text())
profile=Path(meta['short_profile']).resolve();assert profile.parent==ROOT/'build' and profile.name.startswith('if')
script=host/'close-owned.ms'
script.write_text('''(
if MCPFixtureDir!=@"'''+host.as_posix()+'''/" do throw "Not the owned profile"
local process=(dotNetClass "System.Diagnostics.Process").GetCurrentProcess()
if process.Id!='''+str(meta['pid'])+''' do throw "Owned PID differs"
for d in #(CyrusRecipeBrowser,CyrusReadyPresetEditor,CyrusRecipeSaveEditor,CyrusPresetSaveEditor) where d!=undefined do try(destroyDialog d)catch()
resetMaxFile #noPrompt
MCPFixtureTimer.Stop()
(dotNetClass "System.IO.File").WriteAllText (MCPFixtureDir+"dev-result.txt") ("SUCCESS "+MCPFixtureLast)
(dotNetClass "System.IO.File").WriteAllText (MCPFixtureDir+"shutdown.txt") "Closed this disposable process; artist sessions preserved."
quitMax #noPrompt
)''',encoding='utf-8-sig');send(host,script,'Close owned installer host')
