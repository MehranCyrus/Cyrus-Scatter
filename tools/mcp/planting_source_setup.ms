global MCPPlantingSourceSetupRun
fn MCPPlantingSourceSetupRun scenario = (
    local code="from PySide6.QtCore import QTimer\nimport runpy,pymxs,traceback\nfrom pathlib import Path\ndef planting_fixture():\n try:\n  with pymxs.undo(False):\n   runpy.run_path("+(QQuote (MCPFixtureDir+"planting_source_setup.py"))+")\n except Exception:\n  Path("+(QQuote (MCPFixtureDir+"planting-source-error.txt"))+").write_text(traceback.format_exc())\nQTimer.singleShot(100,planting_fixture)"
    python.Execute code
    QAssert true "fixture_scheduled" "Owned fixture scheduled outside nested MAXScript/Python execution"
)
