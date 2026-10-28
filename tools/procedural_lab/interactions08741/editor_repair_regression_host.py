"""Use the existing private transport for the current editor regression checks."""
from pathlib import Path
import runpy
runpy.run_path(str(Path(__file__).resolve().parents[3]/'tools/procedural_lab/interactions08742/editor_regression_host.py'))
