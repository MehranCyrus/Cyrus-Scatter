global CyrusPrepareFixtureOutput,CyrusPrepareFixtureRestore
(
    if MCPFixtureDir==undefined or CyrusPrepareFixtureOutput==undefined or not doesFileExist CyrusPrepareFixtureRestore do throw "Owned fixture request required."
    try (
        resetMaxFile #noPrompt
        units.SystemType=#centimeters;units.SystemScale=1
        local reduce=LayerManager.newLayerFromName "Reduce",protected=LayerManager.newLayerFromName "Protected",details=LayerManager.newLayerFromName "Details"
        local red=glTFMaterial name:"FixtureRed" baseColor:(color 160 40 30),blue=glTFMaterial name:"FixtureBlue" baseColor:(color 30 70 150)
        red.baseColorMap=BitmapTexture filename:(CyrusPrepareFixtureOutput+"checker.png")
        InstanceMgr.autoMtlPropagation=false
        local a=sphere name:"Hidden prototype A" radius:8 segments:64 mapCoords:true
        local b=instance a;b.name="Visible protected B";b.pos=[30,0,0]
        reduce.addNode a;protected.addNode b;a.isHidden=true;a.material=red;b.material=blue
        local parent=dummy name:"Source hierarchy" pos:[80,0,0]
        local c=sphere name:"Reduced owner C" radius:6 segments:64 mapCoords:true pos:[60,0,0]
        local d=instance c;d.name="Reduced placement D";d.pos=[80,10,3];d.scale=[-1,2,1];d.rotation=angleaxis 25 [0,0,1]
        c.parent=parent;d.parent=parent;reduce.addNode c;reduce.addNode d;c.material=red;d.material=blue;c.isFrozen=true
        local multi=MultiMaterial numsubs:2 name:"FixtureMulti"
        multi.materialIDList=#(3,7);multi.materialList=#(red,blue)
        local boxNode=box name:"Material ID witness" width:10 length:8 height:12 mapCoords:true pos:[5,25,0]
        convertToMesh boxNode
        local edit=boxNode.mesh
        for i=1 to edit.numfaces do setFaceMatID edit i (if i<=6 then 3 else 7)
        boxNode.mesh=edit;boxNode.material=multi;details.addNode boxNode
        local coating=box name:"Explicit coating witness" width:8 length:8 height:10 pos:[25,25,0]
        coating.material=StandardMaterial name:"Artist Coating" diffuse:(color 140 150 160);details.addNode coating
        local empty=mesh name:"Empty mesh witness" vertices:#() faces:#();details.addNode empty
        local camera=FreeCamera name:"Existing animated camera" pos:[0,-100,60]
        animationRange=interval 0f 30f;frameRate=30
        with animate on (at time 0f camera.pos=[0,-100,60];at time 30f camera.pos=[60,-80,45])
        if not saveMaxFile (CyrusPrepareFixtureOutput+"source.max") quiet:true do throw "Fixture save failed."
        if not loadMaxFile CyrusPrepareFixtureRestore useFileUnits:true quiet:true allowPrompts:false missingDLLsAction:#logmsg missingExtFilesAction:#logmsg do throw "Prepared building did not restore."
        (dotNetClass "System.IO.File").WriteAllText (CyrusPrepareFixtureOutput+"fixture-complete.txt") "PASS"
    ) catch (
        try(loadMaxFile CyrusPrepareFixtureRestore useFileUnits:true quiet:true allowPrompts:false missingDLLsAction:#logmsg missingExtFilesAction:#logmsg)catch()
        throw()
    )
)
