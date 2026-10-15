"""Current compact UI and retained upload witness; movement has a native-event fixture."""
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
source=(ROOT/'tools/terrace_0815/containers_host.py').read_text()
start=source.index('    positions=[r.copy(n.pos) for n in models]')
end=source.index('    r.CyrusPerfHeadless=False;r.CyrusPointSync();r.completeRedraw()',start)
source=source[:start]+source[end:]
source=source.replace("'containers-host.json'","'containers-final.json'")
exec(compile(source,str(ROOT/'tools/terrace_0815/containers_host.py'),'exec'))
