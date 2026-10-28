"""Adapter for the existing bounded campaign transport; work lives with 0.87.4.2."""
from pathlib import Path
import runpy
runpy.run_path(str(Path(__file__).resolve().parents[3]/'tools/procedural_lab/interactions08742/editor_controls_host.py'))
