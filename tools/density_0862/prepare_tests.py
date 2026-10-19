"""Reuse proven host test actions, in this task's disposable profile only."""
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
for name in ('workflow.ms','examples.ms','save_roundtrip.ms'):
    source=(ROOT/'tools/library_0861'/name).read_text(encoding='utf-8-sig')
    source=source.replace('*/build/mcp-qualification/library-surface0861-*/','*/build/mcp-qualification/density0862-*/')
    source=source.replace('pattern:"*needs mesh channel*"','pattern:"*Cannot load layer*"')
    if name=='workflow.ms':
        source=source.replace('document=CyrusRecipeGet package "recipe"','document=cyrusRecipeRead (pathConfig.appendPath (io.ReadAllText (MCPFixtureDir+"mask-package.txt")) "entry.csrecipe.json")')
    if name=='save_roundtrip.ms':
        source=source.replace('makeDir SDirectory all:true;select SNode;', '''
    global SMapping=undefined,SImage=undefined
    with undo off (
        SNode.transform=(rotateZMatrix 17)*(transMatrix [20,-30,0])
        CyrusSetDensityImage SRoot.layerObjects[1] (MCPFixtureDir+"scripts/Patterns/soft-patches.png") pattern:"soft-patches" revision:"QA fixture"
        local leaf=SRoot.layerObjects[1]
        leaf.densityCoordinateMode=2;leaf.densityTileXWU=350;leaf.densityTileYWU=220;leaf.densityTileLock=false
        leaf.densityHeading=23;leaf.densityOffsetXWU=17;leaf.densityOffsetYWU=-32
        leaf.densityResponseSamples=#(0.,0.05,0.35,0.85,1.)
        SMapping=leaf.densityMappingPayload();SImage=leaf.densityMap.filename
        SRoot.layerObjects[2].densityMap=Noise size:25
        SRoot.layerObjects[2].distributionMode=3;SRoot.layerObjects[2].densityCoordinateMode=1
        CyrusBakeDensityImage SRoot.layerObjects[2] directory:(MCPFixtureDir+"saved-bake")
    )
    SRoot.refreshAll()
    makeDir SDirectory all:true;select SNode;''')
        source=source.replace('CyrusOpenReadyPreset SRoot SPackage surface:STerrain', '''
    global SBeforeHash=cyrusRecipePublicationFingerprint SRoot.groupSnapshotRows
    with undo off SNode.transform=(rotateZMatrix (-31))*(transMatrix [-90,55,10])
    CyrusOpenReadyPreset SRoot SPackage surface:STerrain''')
        source=source.replace('destroyDialog CyrusReadyPresetEditor\n', '''
    local actual=owners[1].densityMappingPayload()
    local same=true
    for i=1 to actual.count where i!=10 do if not (CyrusPresetSameValues SMapping[i] actual[i]) do same=false
    for row=1 to 4 where distance SMapping[10][row] actual[10][row]>0.0001 do same=false
    check same "Image frame, physical sizes, rotation, offsets and nonlinear response survive different-root Load" log
    check (owners[1].densityMap.filename!=SImage and doesFileExist owners[1].densityMap.filename) "Image bytes are restored from the portable package" log
    check (matchPattern owners[2].densityMapProvenance pattern:"baked 2D tile*" and classof owners[2].densityMap==Bitmaptexture) "Explicit procedural snapshot bytes and provenance survive complete Save/Load" log
    destroyDialog CyrusReadyPresetEditor
''')
        source=source.replace('local owners=CyrusReadyPresetEditor.result[2]', 'global SLoadedOwners=CyrusReadyPresetEditor.result[2],SLoadedHash=cyrusRecipePublicationFingerprint SRoot.groupSnapshotRows;local owners=SLoadedOwners')
        source=source.replace('\n  )\n  format "PASS: complete', '''
   "historyWithoutPackage":(
    local unavailable=SPackage+"-unavailable",ioDirectory=dotNetClass "System.IO.Directory"
    if ioDirectory.Exists unavailable do throw "Owned unavailable destination already exists"
    ioDirectory.Move SPackage unavailable
    try (
     max undo
     check (SRoot.layerObjects.count==SPaint.count) "One Undo removes the added image/Paint recipe" log
     check ((cyrusRecipePublicationFingerprint SRoot.groupSnapshotRows)==SBeforeHash) "Undo restores the exact previous publication" log
     max redo
     check ((cyrusRecipePublicationFingerprint SRoot.groupSnapshotRows)==SLoadedHash) "Redo restores full output while source package is unavailable" log
     check (CyrusPresetSameValues SPaint (paintData SLoadedOwners)) "Redo retains exact Paint without package files" log
     ioDirectory.Move unavailable SPackage
    )catch(if ioDirectory.Exists unavailable do ioDirectory.Move unavailable SPackage;throw())
   )
  )
  format "PASS: complete''')
    (ROOT/'tools/density_0862'/name).write_text(source,encoding='utf-8-sig')

# Reuse the integrated teaching fixture with current code and one extra image layer.
source=(ROOT/'tools/feature_demo_0824/build_scene.ms').read_text(encoding='utf-8-sig')
source=source.replace('Demo0824','Demo0862').replace('0.82.4','0.86.2').replace('0824','0862')
source=source.replace('        updateShape node\n        local bounds=nodeGetBoundingBox', '        convertToSplineShape node;updateShape node\n        local bounds=nodeGetBoundingBox')
source=source.replace('*/build/mcp-qualification/foundation-roadmap-feature-demo0862-*/','*/build/mcp-qualification/density0862-*/')
source=source.replace('stage "04/05 Mountain', '''
        stage "06 Image-only pattern density with no numeric channel requirement." log
        local imageLayer=makeLayer "06 Image pattern only - World XY" Demo0862Plane #(modelA) 6000 orange
        CyrusSetDensityImage imageLayer (MCPFixtureDir+"scripts/Patterns/soft-patches.png") pattern:"soft-patches" revision:"Generated QA fixture only"
        imageLayer.densityTileXWU=5.5;imageLayer.densityHeading=20
        imageLayer.areaNodes=#(densityInclude);imageLayer.areaModes=#(2)
        local imageStrip=rectangleGuide "INCLUDE | Image pattern zone" 24 3 [-19,6,0.03] orange
        imageLayer.areaNodes=#(imageStrip);imageLayer.areaModes=#(1)
        stage "04/05 Mountain''')
source=source.replace('leaf.slopeEnabled=true;', '''if leaf==normalOff do (
                CyrusSetDensityImage leaf (MCPFixtureDir+"scripts/Patterns/wide-bands.png") pattern:"wide-bands" revision:"Generated QA fixture only"
                leaf.densityTileXWU=5;leaf.densityHeading=25
            )
            leaf.slopeEnabled=true;''')
source=source.replace('five feature layers','six feature layers').replace('Five editable','Six editable')
source=source.replace('FLAT PLANE / THREE LAYERS','FLAT PLANE / FOUR LAYERS')
source=source.replace('Demo0862Root.populationUI.open=true;Demo0862Root.mainUI.bindSection Demo0862Root.populationUI', 'Demo0862Root.mainUI.slots[6].open=true;Demo0862Root.mainUI.bindSection Demo0862Root.mainUI.editors[6]')
(ROOT/'tools/density_0862/demo.ms').write_text(source,encoding='utf-8-sig')
print('Prepared task-owned workflow, eight-example, complete Paint/image and integrated demo drivers.')
