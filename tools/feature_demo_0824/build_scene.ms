-- Run only through the redirected private Max 2027 host. Creates an editable demo.
(
    if not matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/foundation-roadmap-feature-demo0824-*/" do throw "Owned feature-demo host required."
    if (maxVersion())[1]!=29000 or cyrusMeshDensityVersion()!=1 do throw "Use the qualified 0.82.4 Max 2027 script/native pair."
    global Demo0824Node,Demo0824Root,Demo0824Plane,Demo0824Mountain,Demo0824PaintArea,Demo0824BandPath,Demo0824DC
    global Demo0824Overview,Demo0824PlaneCamera,Demo0824MountainCamera,Demo0824TopCamera
    CyrusPerfHeadless=true;resetMaxFile #noPrompt
    units.SystemType=#meters;units.SystemScale=1;units.DisplayType=#metric;units.MetricType=#meters
    local log=createFile (MCPFixtureDir+"demo-build.txt")
    fn stage message log = (format "%\n" message to:log;flush log)
    fn sceneLayer name = (local layer=LayerManager.getLayerFromName name;if layer==undefined do layer=LayerManager.newLayerFromName name;layer)
    local receivers=sceneLayer "DEMO | Surfaces",sources=sceneLayer "DEMO | Pyramid sources",guides=sceneLayer "DEMO | Editable guides",labels=sceneLayer "DEMO | Labels",cameras=sceneLayer "DEMO | Cameras",controllerLayer=sceneLayer "DEMO | Scatter controller"
    fn makeDemoMaterial name tint = (standardMaterial name:name diffuse:tint specularLevel:18 glossiness:28)
    fn tag node layer note = (layer.addNode node;setUserProp node "Demo_Notes" note;node)
    fn rectangleGuide name width length location tint = (
        local node=rectangle name:name width:width length:length pos:location wirecolor:tint
        node.renderable=false;tag node (sceneLayer "DEMO | Editable guides") "Live include/Path guide; Paint import shapes are independent snapshots."
    )
    fn textLabel name value location size tint = (
        local node=text name:name text:value size:size pos:location wirecolor:tint alignment:0 font:"Arial"
        updateShape node
        local bounds=nodeGetBoundingBox node (matrix3 1)
        move node [location.x-bounds[1].x,0,0]
        node.renderable=false;tag node (sceneLayer "DEMO | Labels") "Teaching label; does not affect scattering."
    )
    fn pyramidSource name location tint = (
        local node=pyramid name:name width:0.30 depth:0.30 height:0.95 pos:location wirecolor:tint
        node.material=makeDemoMaterial (name+" material") tint
        tag node (sceneLayer "DEMO | Pyramid sources") "Editable source pyramid. Live placements use this object."
    )
    fn makeLayer caption receiver models count tint = (
        Demo0824Root.newLayer();local leaf=Demo0824Root.selectedLayer()
        Demo0824Root.layerNames[Demo0824Root.activeLayer]=caption
        Demo0824Root.setLayerSurfaces leaf #(receiver);leaf.sources=models;leaf.ensureSourceRows()
        leaf.amount=count;leaf.procPopulation=1;leaf.procSelfOverride=true;leaf.procSelfEnabled=false
        leaf.sourceColors=for node in models collect node.wirecolor
        leaf.sourceRadiiWU=for node in models collect 0.15
        leaf.sourceAutoRadius=for node in models collect false
        leaf.sourceFollowScale=for node in models collect true
        leaf.layerIDColor=tint;leaf.scaleMinimum=1;leaf.scaleMaximum=1
        leaf.tiltDegrees=0;leaf.yawMinimum=0;leaf.yawMaximum=360
        leaf.alignNormal=true;leaf.projectMove=true;leaf.paintEnabled=false
        leaf
    )
    fn aimCamera name eye target fov = (
        local look=normalize(target-eye),upHint=if abs(dot look [0,0,1])>0.99 then [0,1,0] else [0,0,1]
        local right=normalize(cross look upHint),up=cross right look
        local cam=freeCamera name:name
        cam.transform=matrix3 right up (-look) eye;cam.fov=fov
        tag cam (sceneLayer "DEMO | Cameras") "Saved demonstration viewpoint. Select with C."
    )
    try (
        stage "Create one flat plane and one deformed mountain." log
        Demo0824Plane=plane name:"01 FLAT PLANE | Channel 2 = left-to-right ramp" width:28 length:28 widthsegs:28 lengthsegs:28 pos:[-19,0,0] wirecolor:(color 145 152 160)
        convertToMesh Demo0824Plane
        Demo0824Plane.material=makeDemoMaterial "Flat plane - slate" (color 145 152 160)
        tag Demo0824Plane receivers "Mesh Channel 2 / X stores a numeric left-to-right 0..1 ramp. Three planting demonstrations share this receiver."
        meshop.setNumMaps Demo0824Plane 3 keep:true;meshop.setMapSupport Demo0824Plane 2 true
        meshop.setNumMapVerts Demo0824Plane 2 Demo0824Plane.numverts;meshop.setNumMapFaces Demo0824Plane 2 Demo0824Plane.numfaces
        for i=1 to Demo0824Plane.numverts do (
            local p=in coordsys local (getVert Demo0824Plane i),t=(p.x+14.0)/28.0
            meshop.setMapVert Demo0824Plane 2 i [t,0,0]
        )
        for i=1 to Demo0824Plane.numfaces do meshop.setMapFace Demo0824Plane 2 i (getFace Demo0824Plane i)
        update Demo0824Plane
        Demo0824Mountain=plane name:"02 MOUNTAIN | Data Channel Curvature to Channel 3" width:28 length:28 widthsegs:80 lengthsegs:80 pos:[17,0,0] wirecolor:(color 170 166 153)
        convertToMesh Demo0824Mountain
        for i=1 to Demo0824Mountain.numverts do (
            local p=in coordsys local (getVert Demo0824Mountain i),x=p.x,y=p.y
            local envelope=(amax 0 (1-(abs x/14.0)^4))*(amax 0 (1-(abs y/14.0)^4))
            local z=5.8*exp(-1.0*(((x+4)/4.0)^2+(y/5.0)^2))+7.0*exp(-1.0*(((x-4)/3.0)^2+((y-2)/3.6)^2))+2.0*exp(-1.0*((x/8.0)^2+((y+7)/2.8)^2))+0.35*sin(x*45.84)*cos(y*31.51)+0.36
            p.z=envelope*z;in coordsys local (setVert Demo0824Mountain i p)
        )
        update Demo0824Mountain
        Demo0824DC=DataChannelModifier();Demo0824DC.name="Curvature -> Mesh Channel 3 / X"
        Demo0824DC.AddOperator 0x0e12bb44 0 0;Demo0824DC.AddOperator 2882382387L 0 1
        Demo0824DC.operators[1].convex=-8;Demo0824DC.operators[1].flat=0.5;Demo0824DC.operators[1].concave=12
        Demo0824DC.operators[1].scale=1;Demo0824DC.operators[1].hardEdgesOnly=false
        Demo0824DC.operators[2].output=2;Demo0824DC.operators[2].channelNum=3;Demo0824DC.operators[2].xyz=0;Demo0824DC.operators[2].replace=0
        Demo0824DC.display=false;addModifier Demo0824Mountain Demo0824DC
        Demo0824Mountain.material=makeDemoMaterial "Mountain - warm stone" (color 170 166 153)
        tag Demo0824Mountain receivers "Editable mesh terrain plus real Curvature/Vertex Output. Channel 3/X drives both mountain planting layers."

        local orange=color 245 158 55,cyan=color 66 205 215,violet=color 176 99 232,pink=color 237 107 170,green=color 85 193 115,blue=color 89 155 245
        local modelA=pyramidSource "SOURCE 01 | Orange - mesh density" [-29,-19,0] orange
        local modelB=pyramidSource "SOURCE 02 | Cyan - Paint fade" [-23,-19,0] cyan
        local modelC=pyramidSource "SOURCE 03 | Violet - outer Band" [-17,-19,0] violet
        local modelD=pyramidSource "SOURCE 04 | Pink - inner Band" [-11,-19,0] pink
        local modelE=pyramidSource "SOURCE 05 | Green - normal aligned" [-5,-19,0] green
        local modelF=pyramidSource "SOURCE 06 | Blue - world upright" [1,-19,0] blue
        Demo0824Node=AminScatterObject name:"CYRUS 0.82.4 | SELECT ME - five feature layers" pos:[-1,-15,0]
        Demo0824Root=Demo0824Node.baseObject;Demo0824Root.iconSize=0.7
        if Demo0824Root.uiVersion()!="0.82.4" do throw "Wrong Scatter script version."
        Demo0824Root.updateMode=1;Demo0824Root.autoRender=false;Demo0824Root.viewportMode=3
        Demo0824Root.viewportFaces=2000000;Demo0824Root.viewportNavigationFaces=1000000;Demo0824Root.viewportInstances=0
        tag Demo0824Node controllerLayer "Five editable Scatter layers. See bundled START HERE.txt. Native Mesh preview; no baked replacement plants."
        stage "01 Mesh density gradient with an explicit include rectangle." log
        local density=makeLayer "01 Mesh density" Demo0824Plane #(modelA) 7000 orange
        local densityInclude=rectangleGuide "INCLUDE | 01 density zone" 24 7 [-19,9,0.025] orange
        density.areaNodes=#(densityInclude);density.areaModes=#(1)
        density.meshMaskEnabled=true;density.meshMaskChannel=2;density.meshMaskComponent=1
        density.meshMaskMinimum=0;density.meshMaskMaximum=1
        density.meshMaskSamples=for i=0 to 16 collect (i/16.0)^1.5
        density.wholeScaleMin=0.8;density.wholeScaleMax=1.2

        stage "02 Paint with independent density and scale fades." log
        local paint=makeLayer "02 Paint density + scale" Demo0824Plane #(modelB) 10000 cyan
        local paintShape=rectangleGuide "PAINT IMPORT SNAPSHOT | 02 cyan strip" 24 4 [-19,1,0.03] cyan
        Demo0824PaintArea=Demo0824Root.addPaintArea paint target:Demo0824Plane
        Demo0824PaintArea.paintSetName="Cyan strip | density + size fade";Demo0824PaintArea.paintColor=cyan;Demo0824PaintArea.paintView=0
        Demo0824Root.importPaintSpline Demo0824PaintArea paintShape tolerance:0.01
        cyrusBrushSetFalloff Demo0824PaintArea.paintDocument #(1.2,0.6,true,true,0.2,1.4,#(0,0.05,0.3,0.65,1),#(0,0.25,0.5,0.8,1))
        Demo0824PaintArea.paintDensity=0.9;Demo0824PaintArea.publishPaint();paint.paintEnabled=true

        stage "03 One spline Band layer with opposite density and scale profiles." log
        local bands=makeLayer "03 Bands density + scale" Demo0824Plane #(modelC,modelD) 12000 violet
        Demo0824BandPath=rectangleGuide "PATH | 03 inside spline Bands" 24 7 [-19,-9,0.035] violet
        bands.diversityMode=3;bands.bandArrangement=1
        bands.addStroke Demo0824BandPath side:2;bands.addStroke Demo0824BandPath side:2
        bands.patternWidths[1]=1.4;bands.strokeStarts[1]=0;bands.strokeEnds[1]=1.4
        bands.patternWidths[2]=1.3;bands.strokeStarts[2]=1.4;bands.strokeEnds[2]=2.7
        bands.setStrokeSelection 1 2 #(bands.sourceRowIDs[1]);bands.setStrokeSelection 2 2 #(bands.sourceRowIDs[2])
        bands.strokeCurveEnabled[1]=true;bands.strokeCurveSamples[1]="1,0.85,0.5,0.2,0.08"
        bands.strokeCurveEnabled[2]=true;bands.strokeCurveSamples[2]="0.1,0.2,0.5,0.85,1"
        bands.strokeScaleModes[1]=3;bands.strokeScaleSamples[1]="0.3,0.6,1,1.35,1.6"
        bands.strokeScaleModes[2]=3;bands.strokeScaleSamples[2]="1.6,1.3,1,0.6,0.3"
        bands.strokeDisplayColors[1]=violet;bands.strokeDisplayColors[2]=pink

        stage "04/05 Mountain Curvature, slopes, altitude, include/exclude and normal orientation." log
        local hole=splineShape name:"EXCLUDE | Mountain clearing" wirecolor:(color 250 100 100)
        addNewSpline hole
        for i=0 to 63 do (
            local x=17+2.2*cos(i*360.0/64),y=-9+2.2*sin(i*360.0/64),hit=intersectRay Demo0824Mountain (ray [x,y,100] [0,0,-1])
            if hit==undefined do throw "Clearing outline missed the mountain."
            addKnot hole 1 #corner #line (hit.pos+[0,0,0.045])
        )
        close hole 1;updateShape hole
        hole.renderable=false;tag hole guides "Both mountain layers exclude this projected circle. Move/resize it and Update scatter."
        local normalOn=makeLayer "04 Mountain | Normals ON" Demo0824Mountain #(modelE) 10000 green
        local onInclude=rectangleGuide "INCLUDE | Mountain normals ON half" 13.4 26 [10.1,0,0.03] green
        normalOn.areaNodes=#(onInclude,hole);normalOn.areaModes=#(1,2)
        local normalOff=makeLayer "05 Mountain | Normals OFF" Demo0824Mountain #(modelF) 10000 blue
        local offInclude=rectangleGuide "INCLUDE | Mountain normals OFF half" 13.4 26 [23.9,0,0.03] blue
        normalOff.areaNodes=#(offInclude,hole);normalOff.areaModes=#(1,2);normalOff.alignNormal=false
        for leaf in #(normalOn,normalOff) do (
            leaf.meshMaskEnabled=true;leaf.meshMaskChannel=3;leaf.meshMaskComponent=1
            leaf.meshMaskMinimum=0;leaf.meshMaskMaximum=1;leaf.meshMaskSamples=#(0.0,0.15,0.5,0.85,1.0)
            leaf.slopeEnabled=true;leaf.slopeMinimum=0;leaf.slopeMaximum=45;leaf.slopeLowerFade=0;leaf.slopeUpperFade=12
            leaf.altitudeEnabled=true;leaf.altitudeMinimum=0;leaf.altitudeMaximum=5.5;leaf.altitudeLowerFade=0;leaf.altitudeUpperFade=1
            leaf.wholeScaleMin=0.65;leaf.wholeScaleMax=1.25
        )
        textLabel "TITLE" "CYRUS SCATTER 0.82.4  /  FEATURE LAB" [-33,17,0.03] 1.05 (color 235 238 245)
        textLabel "Plane heading" "FLAT PLANE / THREE LAYERS" [-33,14.6,0.03] 0.65 (color 205 212 225)
        textLabel "Mountain heading" "MOUNTAIN / CURVATURE + SLOPE + ALTITUDE" [3,14.6,0.03] 0.52 (color 205 212 225)
        textLabel "Density heading" "01  DENSITY  /  SPARSE -> DENSE" [-31,12.9,0.03] 0.55 orange
        textLabel "Paint heading" "02  PAINT  /  FEWER + SMALLER AT THE EDGES" [-31,4.1,0.03] 0.5 cyan
        textLabel "Bands heading" "03  INSIDE BANDS  /  OPPOSITE DENSITY + SIZE CURVES" [-31,-4.9,0.03] 0.45 violet
        textLabel "On heading" "04  NORMALS ON" [3.5,13.2,0.03] 0.56 green
        textLabel "Off heading" "05  NORMALS OFF" [18.0,13.2,0.03] 0.56 blue
        textLabel "Clearing heading" "RED CIRCLE = EXCLUDE CLEARING" [8,-13.7,0.03] 0.48 (color 250 100 100)
        textLabel "Sources heading" "SOURCE PYRAMIDS  /  EDITABLE MODELS" [-31,-17.8,0.03] 0.52 (color 205 212 225)
        textLabel "Usage" "SELECT CYRUS CONTROLLER  >  PICK A LAYER  >  EDIT  >  UPDATE SCATTER" [-33,-21.2,0.03] 0.63 (color 235 238 245)
        Demo0824Overview=aimCamera "CAM 01 | Overview" [-8,-65,85] [-1,-1,1] 48
        Demo0824PlaneCamera=aimCamera "CAM 02 | Plane - density Paint Bands" [-19,-27,38] [-19,0,0] 52
        Demo0824MountainCamera=aimCamera "CAM 03 | Mountain - normals and filters" [39,-30,28] [17,0,2] 53
        Demo0824TopCamera=aimCamera "CAM 04 | Top plan" [-1,0,105] [-1,0,0] 44
        cameras.isHidden=true
        renderWidth=1600;renderHeight=1000
        Demo0824Root.refreshAll()
        for leaf in Demo0824Root.layerObjects do if leaf.generatedCount<=0 or leaf.previewError!="" do throw ("Empty/failed demo layer: "+Demo0824Root.layerCaption leaf+" / "+leaf.previewError)
        stage "Publish Mesh display and save editable scene." log
        CyrusPerfHeadless=false;Demo0824Root.updateMode=1
        select Demo0824Node;max modify mode;modPanel.setCurrentObject Demo0824Root
        if not Demo0824Root.mainUI.controlsReady do Demo0824Root.mainUI.mountTimer.tick()
        Demo0824Root.selectLayer 1;Demo0824Root.populationUI.open=true;Demo0824Root.mainUI.bindSection Demo0824Root.populationUI
        viewport.setLayout #layout_1;viewport.setCamera Demo0824Overview;viewport.setRenderLevel #smoothhighlights
        viewport.setGridVisibility viewport.activeViewport false
        CyrusPointSync();completeRedraw()
        local path=MCPFixtureDir+"Feature Demo 0.82.4 - working.max"
        saveMaxFile path quiet:true
        for i=1 to Demo0824Root.layerObjects.count do format "LAYER % | % | % accepted\n" i Demo0824Root.layerNames[i] Demo0824Root.layerObjects[i].generatedCount to:log
        stage "COMPLETE" log;close log
    )catch(stage ("ERROR: "+getCurrentException()) log;close log;throw())
)
