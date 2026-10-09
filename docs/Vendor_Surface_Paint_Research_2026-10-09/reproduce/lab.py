"""Reuse the pinned private-profile launcher; keep this pass's transport and scripts separate."""
import importlib.util
from pathlib import Path
HERE=Path(__file__).resolve().parent
spec=importlib.util.spec_from_file_location('prior_surface_lab',HERE.parents[1]/'Receiving_Surface_Research_2026-10-08/reproduce/lab.py')
prior=importlib.util.module_from_spec(spec);spec.loader.exec_module(prior)
prior.HERE=HERE
if __name__=='__main__': prior.main()
