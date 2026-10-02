"""Reuse the qualified SDK build procedure in an independent experiment folder."""
from pathlib import Path
import importlib.util

ROOT=Path(__file__).resolve().parents[3]
BASE=ROOT/'build/mesh-integration-2026-10-02'
def load_helper(name):
    spec=importlib.util.spec_from_file_location('mesh_shared_'+name,ROOT/'tools/performance/retained_integration'/f'{name}.py')
    module=importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    module.BASE=BASE
    return module

if __name__=='__main__':
    load_helper('build').main()
