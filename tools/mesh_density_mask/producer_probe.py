"""Inspect actual Max 2027 Data Channel/VertexPaint classes in the owned host."""
from pathlib import Path
import json,traceback
from pymxs import runtime as r
ROOT=Path(__file__).resolve().parents[2];OUT=Path(str(r.MCPFixtureDir)).resolve()
assert OUT.parent==ROOT/'build/mcp-qualification' and OUT.name.startswith('foundation-roadmap-meshmask-')
data={}
data['modifier_classes']=[str(c) for c in r.execute('for c in modifier.classes where matchPattern (c as string) pattern:"*Data*" collect c')]
for name in ['DataChannelModifier','VertexPaint']:
    try:
        obj=getattr(r,name)();data[name]={'properties':[str(p) for p in r.getPropNames(obj)]}
        if name=='DataChannelModifier':
            r.MeshMaskDC=obj
            obj.AddOperator(0x0e12bb44,0,0)
            obj.AddOperator(0xabcdaa33,0,1)
            data[name]['operators']=[{'class':str(r.classOf(x)),'properties':[str(p) for p in r.getPropNames(x)]} for x in obj.operators]
        if name=='Operator_Curvature':r.MeshMaskCurvature=obj
        if name=='Operator_VertexOutput':r.MeshMaskOutput=obj
        if name=='VertexPaint':r.MeshMaskVertexPaint=obj
    except Exception: data[name]={'error':traceback.format_exc()}
(OUT/'producer-probe.json').write_text(json.dumps(data,indent=2)+'\n')
