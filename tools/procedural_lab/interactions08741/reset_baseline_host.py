"""Load the copied plant scene in an already initialized owned transport."""
from pathlib import Path
root=Path(__file__).resolve().parents[3]
source=root/'tools/procedural_lab/interactions08741/baseline_host.py'
lines=source.read_text(encoding='utf-8').splitlines()
assert lines[-1].startswith("r.execute('fileIn @")
exec(compile('\n'.join(lines[:-1])+'\n',str(source),'exec'),{'__file__':str(source),'__name__':'__main__'})
