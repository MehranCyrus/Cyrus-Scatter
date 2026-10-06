"""Main-thread-only private panel qualification helpers; definitions only."""
import json
from pathlib import Path

STATE={}


def setup(directory,expected_payload):
    from pymxs import runtime as rt
    from PySide6 import QtCore, QtWidgets
    from cyrus_mcp import panel
    directory=Path(directory).resolve()
    assert directory==Path(str(rt.MCPFixtureDir)).resolve()
    assert directory.parent.name=="mcp-qualification"
    assert str(rt.CyrusLoadedScriptFingerprint)==expected_payload
    assert panel.PANEL is None
    value=panel.start(directory/"panel-connection")
    value.inspect_selected()
    value.start_diagnostics()
    STATE.update(panel=value,directory=directory,ticks=0,wrong_thread=False)
    value.timer.timeout.disconnect(value.tick)
    def counted():
        STATE["ticks"]+=1
        if QtCore.QThread.currentThread()!=QtWidgets.QApplication.instance().thread():
            STATE["wrong_thread"]=True
            raise RuntimeError("Panel dispatch escaped the host thread")
        value.tick()
    STATE["counter"]=counted
    value.timer.timeout.connect(counted)
    manifest=value.service.publication(value.service.epoch,next(iter(value.service.observed)))
    STATE["initial_publication"]=manifest["manifest"]
    result=dict(scene_epoch=value.service.epoch,controller_id=next(iter(value.service.observed)),
                session_id=value.trace_session,publication=manifest["manifest"])
    (directory/"panel-fixture.json").write_text(json.dumps(result,indent=2))
    return result


def sample(label):
    from pymxs import runtime as rt
    value=STATE["panel"]
    nodes=[n for n in rt.objects if str(rt.classOf(n.baseObject))=="AminScatterObject"]
    result=dict(label=label,ticks=STATE["ticks"],wrong_thread=STATE["wrong_thread"],
                timer_active=value.timer.isActive(),queued=value.bridge.queue.qsize(),
                epochs=[int(n.baseObject.procEpoch) for n in nodes],
                prepared=[[int(leaf.procPreparedBuilds) for leaf in n.baseObject.layerObjects] for n in nodes],
                recording=bool(rt.cyrusDiagnosticActive()),shared=value.service.diagnostic_session,
                closed=value.closing)
    (STATE["directory"]/(label+".json")).write_text(json.dumps(result,indent=2))
    return result


def share(allowed):
    STATE["panel"].diagnostic_permission(allowed)


def busy(value):
    STATE["panel"].host.blocked=value


def setup_design():
    """Use the existing private fixture; never register its polling timer."""
    import sys
    from pymxs import runtime as rt
    directory=STATE["directory"]
    root=directory.parents[2]
    sys.path.insert(0,str(root/"tools/mcp"))
    import host_fixture
    host_fixture.PANEL=STATE["panel"]
    host_fixture.OUTPUT=directory
    result=host_fixture.setup()
    STATE["fixture"]=host_fixture
    assert not rt.cyrusDiagnosticActive()
    assert STATE["panel"].service.diagnostic_session is None
    return result


def approve(validation_id):
    STATE["panel"].service.approve(validation_id)
    return True


def save_reopen():
    from pymxs import runtime as rt
    value=STATE["panel"]
    value.start_diagnostics()
    value.diagnostic_permission(True)
    result=STATE["fixture"].command({"action":"save_reopen"})
    assert result["match"] and result["scope_cleared"]
    assert not rt.cyrusDiagnosticActive()
    assert value.service.diagnostic_session is None and not value.trace_share.isChecked()
    return result


def close():
    from cyrus_mcp.diagnostics import collect_report,save_report
    value=STATE["panel"]
    value.stop_diagnostics()
    save_report(STATE["directory"]/"panel-diagnostics.json",
                collect_report(value.host.diagnostic_page,value.trace_session,value.host.version()))
    value.close()
    assert value.bridge.closed
    assert not value.timer.isActive()
    assert not (STATE["directory"]/"panel-connection/connection.json").exists()
    return True
