import json
from copy import deepcopy
import pytest

from cyrus_mcp.contracts import Fault
from cyrus_mcp.diagnostics import collect_report, save_report, validate_page
from cyrus_mcp.service import Service, Journal
from test_service import Host


def recording(count=1001, evicted=4):
    events=[dict(sequence=i, elapsed_ms=i, epoch=3, name="publication.committed",
                 origin="engine", owner_id="set_a", detail="complete") for i in range(evicted+1,count+evicted+1)]
    meta=dict(schema="cyrus.diagnostic-page/1.0", purpose="engineering", session_id="trace_test",
              started_unix_ms=1234567, elapsed_ms=count+evicted+10, active=False, expired=False,
              limits=dict(events=4096,bytes=4194304,duration_ms=600000),
              health=dict(retained=count,retained_bytes=count*250,high_water_bytes=count*250,
                          evicted=evicted,lock_drops=0,failures=0,truncated=0),
              oldest_sequence=events[0]["sequence"] if events else 0,last_sequence=count+evicted,training_eligible=False)
    def page(after,limit):
        rows=[v for v in events if v["sequence"]>after][:limit]
        nxt=rows[-1]["sequence"] if rows else after
        return json.dumps(dict(meta,events=rows,next_sequence=nxt,has_more=nxt<meta["last_sequence"]))
    return meta,page


def test_collect_pages_reports_loss_and_atomic_export(tmp_path):
    meta,reader=recording()
    report=collect_report(reader,"trace_test",{"fixture":True})
    assert len(report["events"])==1001 and report["events"][0]["sequence"]==5
    assert not report["lossless"] and report["complete_retained_history"]
    path=tmp_path/"report.json"
    save_report(path,report)
    assert json.loads(path.read_text())==report
    assert list(tmp_path.iterdir())==[path]


def test_active_or_replaced_or_mutated_recording_refuses_export():
    meta,reader=recording()
    meta["active"]=True
    with pytest.raises(Fault,match="Stop recording"):collect_report(reader,"trace_test",{})
    meta["active"]=False
    with pytest.raises(Fault,match="session changed"):collect_report(reader,"other_session",{})
    def changing(after,limit):
        if after:meta["health"]["lock_drops"]+=1
        return reader(after,limit)
    with pytest.raises(Fault,match="changed during"):collect_report(changing,"trace_test",{})


@pytest.mark.parametrize("change",[
    lambda p:p.update(next_sequence=9999),
    lambda p:p["events"][0].update(sequence=0),
    lambda p:p["events"][0].update(detail="x"*513),
    lambda p:p.update(training_eligible=True),
    lambda p:p.update(events=[]),
    lambda p:p["health"].update(high_water_bytes=99999999),
])
def test_corrupt_pages_rejected(change):
    _,reader=recording()
    page=json.loads(reader(0,100));change(page)
    with pytest.raises(Fault):validate_page(json.dumps(page),"trace_test")


def test_empty_session_and_cursor_bounds():
    _,reader=recording(0,0)
    report=collect_report(reader,"trace_test",{})
    assert report["events"]==[] and report["lossless"]
    with pytest.raises(Fault,match="ahead"):validate_page(reader(9,100),"trace_test",9,100)
    for limit in (0,501,True):
        with pytest.raises(Fault):validate_page(reader(0,100),"trace_test",0,limit)


def test_valid_heavily_escaped_native_page_stays_readable():
    _,reader=recording(500,0)
    page=json.loads(reader(0,500))
    for event in page["events"]:
        event.update(name="\x01"*64,origin="\x01"*32,owner_id="\x01"*96,detail="\x01"*512)
    assert len(validate_page(json.dumps(page),"trace_test",0,500)["events"])==500


def test_failed_atomic_export_preserves_old_report(tmp_path,monkeypatch):
    path=tmp_path/"report.json";path.write_text("old report")
    def denied(*args):raise OSError("injected full disk / sharing violation")
    monkeypatch.setattr("cyrus_mcp.diagnostics.os.replace",denied)
    with pytest.raises(OSError):save_report(path,{"new":True})
    assert path.read_text()=="old report" and list(tmp_path.iterdir())==[path]


def test_event_tool_requires_exact_revocable_local_grant_and_is_passive(tmp_path):
    host=Host()
    _,reader=recording()
    host.diagnostic_page=reader
    service=Service(host,Journal(tmp_path/"journal.json"))
    service.observe(None)
    args=dict(scene_epoch=service.epoch,session_id="trace_test",after_sequence=0,limit=100)
    with pytest.raises(Fault,match="Share"):service.dispatch("scatter.read_diagnostic_events",args)
    service.diagnostic_session="trace_test"
    def cannot_evaluate():raise AssertionError("Diagnostic reads must not fingerprint/evaluate")
    host.fingerprint=cannot_evaluate
    result=service.dispatch("scatter.read_diagnostic_events",args)
    assert len(result["page"]["events"])==100 and host.generated==0
    service.diagnostic_session=None
    with pytest.raises(Fault,match="Share"):service.dispatch("scatter.read_diagnostic_events",args)
    service.diagnostic_session="trace_test";service.reset()
    assert service.diagnostic_session is None
