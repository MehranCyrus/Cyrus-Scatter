"""Read-only brush anchors and MSVC RTTI inventory; raw outputs stay ignored."""
import argparse
import importlib.util
import json
import re
import struct
from pathlib import Path


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--run',type=Path,required=True)
    args=parser.parse_args()
    run=args.run.resolve()
    if not run.is_relative_to(Path.cwd()/'build'): raise ValueError('Use ignored build run')
    prior=Path('docs/TyFlow_Architecture_Research_2026-10-06/reproduce/static_pe.py')
    spec=importlib.util.spec_from_file_location('pe_helper',prior)
    module=importlib.util.module_from_spec(spec);spec.loader.exec_module(module)
    pe=module.PE((run/'inputs/Contents/plugins/2027/ForestPackLite.dlo').read_bytes())
    strings=json.loads((run/'static/ForestPackLite/strings.json').read_text())
    anchors=[s for s in strings if re.search(r'paint|brush|painter',s['text'],re.I)
             and not re.search(r'QWidget|QPaint|QToolBar|repaint|CreateSolidBrush|SetBrush|SetDCBrush|BeginPaint|EndPaint|paintEvent|paintEngine',s['text'])]
    names=['.?AVTForest@@','.?AVAreaPaintRestore@@','.?AVTPaintRestore@@','.?AVClipper@clipper@@','.?AVClipperBase@clipper@@']
    # Locate the callback owner through inheritance, not a class-name assumption.
    type_name=b'.?AVIPainterCanvasInterface_V5@@\0'
    painter_td=pe.rva(pe.data.find(type_name))-16
    for name in json.loads((run/'static/ForestPackLite/rtti-candidates.json').read_text()):
        for r in pe.rtti([name]):
            for col in r['locators'][:1]:
                h=pe.offset(int(col['hierarchy_rva'],16))
                _,_,count,array=struct.unpack_from('<IIII',pe.data,h)
                for i in range(min(count,100)):
                    bd=struct.unpack_from('<I',pe.data,pe.offset(array)+i*4)[0]
                    if struct.unpack_from('<I',pe.data,pe.offset(bd))[0]==painter_td and name not in names:names.append(name)
    records=pe.rtti(names)
    # Decode base-class PMD offsets; these locate the painter subobject without guessing.
    for record in records:
        for col in record['locators']:
            hierarchy=pe.offset(int(col['hierarchy_rva'],16))
            _,attributes,count,array=struct.unpack_from('<IIII',pe.data,hierarchy)
            bases=[]
            for i in range(min(count,100)):
                descriptor=struct.unpack_from('<I',pe.data,pe.offset(array)+i*4)[0]
                td,contained,mdisp,pdisp,vdisp,flags=struct.unpack_from('<IIiiiI',pe.data,pe.offset(descriptor))
                bases.append(dict(name=pe.string(td+16),contained=contained,mdisp=mdisp,pdisp=pdisp,vdisp=vdisp,flags=flags))
            col['bases']=bases
    (run/'brush-anchors.json').write_text(json.dumps(anchors,indent=2),encoding='utf-8')
    (run/'brush-rtti.json').write_text(json.dumps(records,indent=2),encoding='utf-8')
    concise=[]
    for r in records:
        for c in r['locators']:
            painters=[b for b in c['bases'] if 'Painter' in b['name']]
            if r['name'] not in ['.?AVAreaPaintRestore@@','.?AVTPaintRestore@@','.?AVClipper@clipper@@','.?AVClipperBase@clipper@@'] and (not painters or c['object_offset']!=painters[0]['mdisp']):continue
            concise.append(dict(name=r['name'],offset=c['object_offset'],painter_bases=painters,
                tables=[dict(rva=t['vtable_rva'],slots=[dict(slot=s['slot'],rva=s['rva']) for s in t['slots'][:10]]) for t in c['vtables']]))
    print(json.dumps(dict(anchor_count=len(anchors),classes=concise),indent=2))


if __name__=='__main__':main()
