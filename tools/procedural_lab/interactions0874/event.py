"""One bounded owned-host event, for Undo/Redo across actual event boundaries."""
from pathlib import Path
from argparse import ArgumentParser
import time
p=ArgumentParser();p.add_argument('--host',required=True,type=Path);p.add_argument('--name',required=True);p.add_argument('--event',choices=['undo','redo','use','close'],required=True);a=p.parse_args()
root=Path(__file__).resolve().parents[3];host=a.host.resolve();assert host.is_relative_to(root/'build') and (host/'launch.json').exists()
file=host/(a.name+'.ms');assert not file.exists();body={'undo':'max undo','redo':'max redo','use':'CyrusPreparationEditorCommit()','close':'cyrusPreparationEditorClose()'}[a.event];file.write_text(body,encoding='utf-8');(host/'dev-request.txt').write_text(file.as_posix())
until=time.monotonic()+60
while True:
    result=(host/'dev-result.txt').read_text() if (host/'dev-result.txt').exists() else ''
    if file.as_posix() in result:assert result.startswith('SUCCESS'),result;print(result);break
    assert time.monotonic()<until,'Event timed out';time.sleep(.2)
