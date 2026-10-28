#!/usr/bin/env python3
"""Executed weighted-score arithmetic; scores are judgments, not benchmark data."""
import json
from decimal import Decimal

def weighted(scores,weights):
    assert sum(weights)==100
    return {k:str(sum(Decimal(s)*Decimal(w) for s,w in zip(v,weights))/100)
            for k,v in scores.items()}

architecture={'A1_CPU':[5,5,5,2,3,5], 'A2_CPU_shader':[5,4,5,3,5,5],
              'A3_local_GPU':[3,2,2,5,4,2], 'A4_full_GPU':[3,1,2,5,4,2],
              'A5_proxy_refine':[3,2,3,5,4,2]}
api={'CUDA':[5,5,2,1,3,5], 'OpenCL':[3,5,2,5,3,3], 'D3D11':[2,5,2,4,4,2]}
interop={k:list(v) for k,v in api.items()}
for k,v in interop.items():v[2]=5 if k=='D3D11' else 1
out={'status':'Executed arithmetic of proposed judgment scores; no performance measurement',
     'architecture':weighted(architecture,[25,25,15,15,10,10]),
     'api':weighted(api,[25,20,20,15,10,10]),
     'portability_sensitivity':weighted(api,[10,20,20,30,10,10]),
     'D3D11_interop_sensitivity':weighted(interop,[25,20,20,15,10,10])}
assert out['architecture']['A2_CPU_shader']=='4.45'
assert out['api']['CUDA']=='3.6'
assert out['portability_sensitivity']['OpenCL']=='3.8'
assert out['D3D11_interop_sensitivity']['D3D11']=='3.7'
print(json.dumps(out,indent=2,sort_keys=True))
