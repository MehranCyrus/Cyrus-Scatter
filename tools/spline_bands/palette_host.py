"""Band palettes, immutable CPU snapshots and actual Nitrous stream reuse."""
from pathlib import Path
import hashlib
import json
import traceback
import uuid
from pymxs import runtime as r

ROOT = Path(__file__).resolve().parents[2]
OUT = Path(str(r.MCPFixtureDir)).resolve()
if OUT.parent != ROOT / 'build/mcp-qualification' or not OUT.name.startswith('foundation-spline-'):
    raise RuntimeError('Owned spline host required')
receipt = OUT / ('spline-palette-' + uuid.uuid4().hex + '.json')
report = {'checks': [], 'launch': json.loads((OUT / 'launch.json').read_text()),
          'fixture_sha256': hashlib.sha256(Path(__file__).read_bytes()).hexdigest()}


def save():
    receipt.write_text(json.dumps(report, indent=2) + '\n', encoding='utf-8')


def check(ok, label):
    report['checks'].append({'passed': bool(ok), 'label': label}); save()
    if not ok:
        raise AssertionError(label)


def ms(code):
    return r.execute('(\n' + code + '\n)')


def redraw():
    ms('for i=1 to 4 do (completeRedraw();windows.processPostedMessages();sleep .05)')


def streams():
    return list(map(int, r.cyrusRetainedStreamStats()))


def colors(cache):
    return [tuple(round(float(c), 3) for c in (row[1].r, row[1].g, row[1].b))
            for row in r.aminScatterPreviewPoints(cache)]


try:
    r.resetMaxFile(r.Name('noPrompt'))
    script = ROOT / 'AminScatter/scripts/AminScatterObject.ms'
    report['script_sha256'] = hashlib.sha256(script.read_bytes()).hexdigest()
    r.fileIn(str(script))
    for _ in range(16):
        if not r.isSceneRedrawDisabled(): break
        r.enableSceneRedraw()
    check(not r.isSceneRedrawDisabled(), 'Owned host starts with drawing enabled')
    ms('''
global PaletteController=box name:"Palette test controller" width:1 length:1 height:1 pos:[0,100,0]
global PaletteSource=box name:"Shared palette source" width:10 length:10 height:20 pos:[150,0,0]
PaletteSource.material=standardMaterial name:"Preserved render material"
global PaletteRows=for i=1 to 3 collect #((transMatrix [(i-2)*25.,0,0]),1,("palette-"+(i as string)),1,[1,0,0],#(17,25,0)[i],false,2)
global PaletteA=#(1,3,#(white),#(#(17,red),#(25,blue)),false)
global PaletteB=#(1,3,#(white),#(#(17,green),#(25,blue)),false)
global PaletteStyle=#(#(false,white))
global PalettePoints=aminScatterBuildPreview PaletteRows #(#([0,0,0])) PaletteA 100
global PaletteOwner=cyrusRetainedCreate()
hideByCategory.helpers=false
viewport.setType #view_top;viewport.ZoomToBounds false [-100,-100,-20] [100,100,30]
''')
    check(colors(r.PalettePoints) == [(255.,0.,0.),(0.,0.,255.),(127.5,127.5,127.5)],
          'Point colors preserve two Band owners and the explicit Unbanded sentinel')
    ms('if not (cyrusRetainedPublish PaletteOwner PaletteController #(PalettePoints) PaletteStyle) do throw "Initial point publication failed"')
    redraw();before = streams()
    check(int(r.cyrusRetainedStats(r.PaletteOwner)[11]) == 1, 'Actual point shader and owner stream realize')
    ms('global PaletteChanged=cyrusRecolorPreview PalettePoints PaletteB;cyrusRetainedPublish PaletteOwner PaletteController #(PaletteChanged) PaletteStyle')
    redraw();after = streams()
    check(before[1:4] == after[1:4] and after[4] > before[4] and after[5] > before[5],
          'Point palette edits submit new material parameters and reuse all vertex/owner buffers')
    check(colors(r.PalettePoints)[0] == (255.,0.,0.) and colors(r.PaletteChanged)[0] == (0.,255.,0.),
          'Recolor preserves the preceding immutable point palette')
    check(ms('local denied=false;try(cyrusRecolorPreview PaletteChanged #(1,3,#(white),#(#(18,red),#(25,blue)),false))catch(denied=true);denied'),
          'Recolor rejects a changed owner dictionary')
    check(ms('local denied=false;try(aminScatterBuildPreview PaletteRows #(#([0,0,0])) #(1,3,#(white),#(#(17,red)),false) 100)catch(denied=true);denied'),
          'A missing required owner cannot silently become Unbanded')
    check(ms('local denied=false;try(aminScatterBuildPreview PaletteRows #(#([0,0,0])) #(1,3,#(white),#(#(17,red),#(25,blue)),true) 100)catch(denied=true);denied'),
          'Ordinary Band publications reject the zero owner sentinel')
    check(ms('local denied=false;try(aminScatterBuildPreview #(#((matrix3 1),1)) #(#([0,0,0])) PaletteA 100)catch(denied=true);denied'),
          'Preview rejects retired two-field placement rows')
    ms('global PaletteMesh=cyrusBuildGeometryPreview PaletteRows #(PaletteSource) PaletteA 4 100 10000;cyrusRetainedPublish PaletteOwner PaletteController #(PaletteMesh) PaletteStyle')
    redraw();before = streams()
    check(int(r.cyrusRetainedStats(r.PaletteOwner)[11]) == 1, 'Actual instanced mesh shader and owner stream realize')
    check(ms('(cyrusRetainedMeshStats PaletteOwner)[3]==12 and (cyrusRetainedMeshStats PaletteOwner)[2]==3'),
          'One shared source mesh serves all three differently colored instances')
    ms('global PaletteMeshChanged=cyrusRecolorPreview PaletteMesh PaletteB;cyrusRetainedPublish PaletteOwner PaletteController #(PaletteMeshChanged) PaletteStyle')
    redraw();after = streams()
    check(before[1:4] == after[1:4] and after[4] > before[4],
          'Mesh recolor uploads zero source geometry, transforms and owner streams')
    check(ms('local old=cyrusPreviewTriangles PaletteMesh 36,next=cyrusPreviewTriangles PaletteMeshChanged 36;old.count==36 and next.count==36 and old[1][5]==[1,0,0] and next[1][5]==[0,1,0] and next[13][5]==[0,0,1]'),
          'Fallback triangle data retains owner colors and the preceding material palette')
    material = r.PaletteSource.material
    ms('''
global PaletteRootNode=AminScatterObject name:"Published Band palette"
global PaletteRoot=PaletteRootNode.baseObject
PaletteRoot.updateMode=1;PaletteRoot.autoRender=false;PaletteRoot.groupCenters=true;PaletteRoot.identificationMode=3;PaletteRoot.newLayer()
global PaletteLeaf=PaletteRoot.selectedLayer()
local receiver=plane width:500 length:500 widthsegs:1 lengthsegs:1,path=rectangle width:100 length:100
PaletteRoot.setLayerSurfaces PaletteLeaf #(receiver)
PaletteLeaf.sources=#(PaletteSource);PaletteLeaf.amount=2000;PaletteLeaf.diversityMode=3
PaletteLeaf.addStroke path;PaletteLeaf.addStroke path;PaletteLeaf.patternWidths=#(20.,40.)
PaletteLeaf.setStrokeSelection 1 2 #(PaletteSource);PaletteLeaf.setStrokeSelection 2 2 #(PaletteSource)
PaletteLeaf.strokeDisplayColors=#(red,blue)
PaletteRoot.evaluateProcedural();CyrusViewportRedraw()
''')
    redraw();before = streams();epoch=int(r.PaletteRoot.procEpoch);builds=int(r.PaletteLeaf.procPreparedBuilds)
    signature=str(r.cyrusEditFingerprint(r.PaletteRoot.groupSnapshotRows[0], 'palette'))
    check(set(colors(r.PaletteLeaf.cachedPoints)) == {(255.,0.,0.),(0.,0.,255.)},
          'One source used by two authored Bands displays both owner colors')
    ms('PaletteLeaf.strokeDisplayColors[1]=green;PaletteRoot.refreshIdentification()')
    redraw();after=streams()
    check(before[1:4] == after[1:4] and int(r.PaletteRoot.procEpoch)==epoch and int(r.PaletteLeaf.procPreparedBuilds)==builds,
          'Authored Band recolor changes no solve, preparation or geometry/owner uploads')
    ms('PaletteLeaf.removeStroke 1;PaletteRoot.refreshIdentification()')
    check(set(colors(r.PaletteLeaf.cachedPoints)) == {(0.,255.,0.),(0.,0.,255.)} and
          str(r.cyrusEditFingerprint(r.PaletteRoot.groupSnapshotRows[0], 'palette')) == signature,
          'Manual deletion retains published placements and their last complete Band colors')
    check(len(r.PaletteRoot.procPublishedMetadata[0][1]) == 2,
          'The deleted authored Band remains in published metadata until Update')
    ms('PaletteRoot.evaluateProcedural()')
    check(len(r.PaletteRoot.procPublishedMetadata[0][1]) == 1 and set(colors(r.PaletteLeaf.cachedPoints)) == {(0.,0.,255.)},
          'Explicit Update publishes the successor owner dictionary and colors together')
    check(r.PaletteSource.material == material, 'Identification never changes the source render material')
    before_epoch=int(r.PaletteRoot.procEpoch)
    ms('global PaletteCopy=PaletteRoot.copyLogicalLayer PaletteLeaf;PaletteRoot.procEnsureDisplay();PaletteCopy.addStroke PaletteCopy.patternPaths[1];PaletteCopy.setSourceIDColor #{1} (color 30 180 240);PaletteRoot.procEnsureDisplay()')
    check(int(r.PaletteRoot.procEpoch)==before_epoch and int(r.aminScatterPreviewCount(r.PaletteCopy.cachedPoints))==0,
          'Unpublished copied layers stay empty while their authored Band dictionary and colors change')
    report['streams_final']=streams();report['passed']=True
except Exception:
    report['passed']=False;report['error']=traceback.format_exc()
finally:
    save()
if not report['passed']:
    raise RuntimeError(report['error'])
