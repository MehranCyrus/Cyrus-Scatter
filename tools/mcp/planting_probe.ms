global MCPPlantingProbeRun
fn MCPPlantingProbeRun scenario = (
    python.Execute ("import json,host_fixture\nfrom pymxs import runtime as r\nfrom PySide6.QtWidgets import QApplication\np=host_fixture.PANEL\nm=QApplication.activeModalWidget()\nfrom pathlib import Path\nPath("+(QQuote (MCPFixtureDir+"planting-host-state.json"))+").write_text(json.dumps(dict(holding=bool(r.theHold.Holding()),blocked=p.host.blocked,animation=bool(r.isAnimPlaying()),enabled=bool(p.host.is_window_enabled(int(r.windows.getMAXHWND()))),modal=str(m),modal_title=m.windowTitle() if m else None)))")
    QAssert true "busy_probe" "Private host admission facts recorded"
)
