"""Reuse the actual UI reproduction, then measure mounted panels alone."""
from pathlib import Path
script=Path(__file__).with_name('ui_probe.py').read_text(encoding='utf-8')
prefix=script.split("    report['epoch_before_panels']")[0]
exec(prefix+"\nexcept Exception:\n    raise\n",globals())
fixture_report=dict(report)
exec(Path(__file__).with_name('ui_warm.py').read_text(encoding='utf-8'),globals())
(out/'ui-fixture.json').write_text(json.dumps(fixture_report,indent=2),encoding='utf-8')
