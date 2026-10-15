"""Gracefully close only the owned terrace process receiving this request."""
from pathlib import Path
from pymxs import runtime as r
ROOT=Path(__file__).resolve().parents[2]
OUT=Path(str(r.MCPFixtureDir)).resolve()
assert OUT.parent==ROOT/'build/mcp-qualification' and OUT.name.startswith('foundation-terrace0815-')
r.execute('''(
global TerraceExitTimer=dotNetObject "System.Windows.Forms.Timer"
fn TerraceExitTick sender args=(sender.Stop();quitMAX #noPrompt)
TerraceExitTimer.Interval=1000
dotNet.addEventHandler TerraceExitTimer "Tick" TerraceExitTick
TerraceExitTimer.Start()
)''')
