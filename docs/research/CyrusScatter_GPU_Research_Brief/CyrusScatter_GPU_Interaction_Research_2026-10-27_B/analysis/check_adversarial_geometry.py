#!/usr/bin/env python3
"""Analytic counterexample oracles only. This is not a fitter or production test."""
import json
import math

def sub(a,b): return tuple(x-y for x,y in zip(a,b))
def dot(a,b): return sum(x*y for x,y in zip(a,b))
def norm(a): return math.sqrt(dot(a,a))
def sphere_distance(p,c,r): return norm(sub(p,c))-r
def segment_distance(a,b,c,r):
    d=sub(b,a); l2=dot(d,d)
    if l2==0: return sphere_distance(a,c,r),0.0
    t=max(0.0,min(1.0,dot(sub(c,a),d)/l2))
    p=tuple(a[i]+t*d[i] for i in range(3))
    return sphere_distance(p,c,r),t

def main():
    out=[]
    a,b,c,r=(-2.,0.,0.),(2.,0.,0.),(0.,0.,0.),1.
    endpoints=[sphere_distance(a,c,r),sphere_distance(b,c,r)]
    d,t=segment_distance(a,b,c,r)
    assert min(endpoints)>0 and d<0 and t==0.5
    out.append({'id':'span_crosses_sphere','endpoint_signed_distances':endpoints,
                'segment_min_signed_distance':d,'segment_parameter':t,'result':'point-only test misses contact'})
    a,b=(-2.,1.1,0.),(2.,1.1,0.)
    d,t=segment_distance(a,b,c,r)
    width=0.2
    assert d>0 and d-width<0
    out.append({'id':'width_envelope','centerline_clearance':d,'width_envelope_radius':width,
                'capsule_clearance':d-width,'result':'guide clear; admitted envelope intersects'})
    p=(0.,0.,0.)
    d=sphere_distance(p,c,r)
    assert d==-1 and norm(sub(p,c))==0
    out.append({'id':'root_at_sphere_center','signed_distance':d,
                'radial_gradient_denominator':0,'root_inverse_mass':0,
                'result':'fixed root conflicts; radial normal undefined; do not fabricate feasible result'})
    a,b=(-0.2,0.,0.),(0.2,0.,0.)
    assert sphere_distance(a,c,r)<0 and sphere_distance(b,c,r)<0
    out.append({'id':'span_entirely_inside','endpoint_signed_distances':[
        sphere_distance(a,c,r),sphere_distance(b,c,r)],
        'result':'surface-crossing-only test needs occupancy to distinguish contained span'})
    gap=0.03; radius=0.02
    assert 2*radius>gap
    out.append({'id':'narrow_parallel_gap','gap_m':gap,'capsule_diameter_m':2*radius,
                'result':'this capsule cannot fit between these planes; says nothing about alternative routes'})
    # Unit quaternion antipodes encode the same rotation. No interpolation implementation is tested.
    q=(0.,0.,math.sin(0.3),math.cos(0.3)); minus=tuple(-x for x in q)
    assert abs(dot(q,minus)+1)<1e-12
    out.append({'id':'quaternion_antipodes','dot':dot(q,minus),
                'result':'same rotation; zero linear midpoint before sign handling is invalid'})
    print(json.dumps({'execution_scope':'Six independent analytic counterexample oracles; no solver, Max or GPU execution',
                      'passed_assertions':True,'cases':out},indent=2,sort_keys=True))

if __name__=='__main__': main()
