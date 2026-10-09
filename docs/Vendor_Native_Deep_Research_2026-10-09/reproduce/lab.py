"""Reuse the vendor-only disposable launcher; this pass adds read-only saved-scene probes."""
import importlib.util
from pathlib import Path
HERE=Path(__file__).resolve().parent
spec=importlib.util.spec_from_file_location('prior',HERE.parents[1]/'Receiving_Surface_Research_2026-10-08/reproduce/lab.py')
prior=importlib.util.module_from_spec(spec);spec.loader.exec_module(prior)
prior.HERE=HERE
if __name__=='__main__':prior.main()
