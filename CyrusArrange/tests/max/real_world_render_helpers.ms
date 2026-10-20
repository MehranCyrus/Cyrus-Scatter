/* Only owned cameras, lights and backdrop are authored here. Source furniture,
   accessories, Corona materials and accepted native output poses stay intact. */
global CA_TEST_OUTPUT,caRWFixtures,caRWRenders
global CoronaShadows
global caRWStageScene,caRWRenderScene,caRWCamera,caRWRenderOne
global caRWRequire,caRWCheck,caRWNote,caRWHash,caRWContext

fn caRWCamera name position target lens =
(
    local marker=TargetObject name:(name+"_Target")pos:target
    TargetCamera name:name pos:position target:marker lens:lens
)
fn caRWStageScene =
(
    caRWContext="owned studio stage, source Corona materials retained"
    local floor=box name:"REAL_Studio_Floor"width:4200 length:2700 height:30 pos:[-350,0,-30]
    floor.material=standardMaterial name:"REAL_Stage_Only_WarmGrey"diffuse:(color 183 178 168)specularLevel:12 glossiness:35
    local stage=LayerManager.newLayerFromName"REAL_80_STUDIO"
    stage.addNode floor
    caRWCamera "REAL_Overview"[-2150,-3250,2200][-400,0,360]45
    caRWCamera "REAL_Coffee_Detail"[-1800,-1950,1500][-800,0,460]52
    caRWCamera "REAL_Side_Detail"[1200,-1250,1170][500,0,570]52
    local key=omniLight name:"REAL_Studio_Key"pos:[-1100,-1900,2500]multiplier:0.65 color:(color 255 244 226)
    local fill=omniLight name:"REAL_Studio_Fill"pos:[1300,-400,1800]multiplier:0.25 color:(color 223 234 255)
    key.baseObject.castShadows=true;key.shadowGenerator=CoronaShadows()
    caRWRequire "Studio key uses the actual CoronaShadows generator" ((classOf key.shadowGenerator)==CoronaShadows)
    fill.baseObject.castShadows=false
    stage.addNode key;stage.addNode fill
    renderers.current=CoronaRenderer()
    caRWRequire "Actual Corona renderer is available" (matchPattern((classOf renderers.current)as string)pattern:"*Corona*")
    caRWRequire "Corona exposes bounded pass-limit control" (isProperty renderers.current #progressive_passLimit)
    setProperty renderers.current #progressive_passLimit 32
    if isProperty renderers.current #progressive_timeLimit do setProperty renderers.current #progressive_timeLimit 0
    if isProperty renderers.current #progressive_noiseLevelLimit do setProperty renderers.current #progressive_noiseLevelLimit 0.0
    backgroundColor=color 155 155 155;useEnvironmentMap=false;environmentMap=undefined;ambientColor=black
    rendWidth=1280;rendHeight=900;rendPixelAspect=1.0;rendSaveFile=false
    viewport.setCamera(getNodeByName"REAL_Overview"exact:true)
    select caRWFixtures[1][2]
    caRWCheck "Saved artist selection is the coffee arrangement icon"(selection.count==1 and selection[1]==caRWFixtures[1][2])
    setUserProp caRWFixtures[1][2]"CyrusArrangeExample""Prepared real coffee table / full-size book + potted plant + decor. Source models: hidden REAL_90_ORIGINAL_PROP_SOURCES layer."
    setUserProp caRWFixtures[2][2]"CyrusArrangeExample""Prepared real side table / full-size original decor. Open Cyrus Arrange with furniture selected."
    caRWNote "STAGE_SCOPE only backdrop/lights/cameras authored; actual source/output materials are independently checked before and after save/reopen"
)
fn caRWRenderOne cameraName filename =
(
    local camera=getNodeByName cameraName exact:true
    caRWRequire(cameraName+" saved camera exists")(isValidNode camera)
    local path=CA_TEST_OUTPUT+filename,bitmapValue=undefined
    caRWContext="actual Corona render "+filename;caRWNote("STAGE "+caRWContext)
    try
    (
        bitmapValue=render camera:camera outputSize:[1280,900]outputfile:path vfb:false
        if bitmapValue!=undefined do close bitmapValue
    )
    catch(if bitmapValue!=undefined do try(close bitmapValue)catch();throw())
    caRWRequire(filename+" actual renderer writes an image")(doesFileExist path)
    local imageValue=openBitmap path
    caRWCheck(filename+" is a real 1280x900 bitmap")(imageValue.width==1280 and imageValue.height==900)
    close imageValue
    append caRWRenders #(filename,(classOf renderers.current)as string,(getProperty renderers.current #progressive_passLimit),1280,900,(caRWHash path))
)
fn caRWRenderScene =
(
    caRWRenderOne "REAL_Overview""real-models-overview.png"
    caRWRenderOne "REAL_Coffee_Detail""real-models-coffee.png"
    caRWRenderOne "REAL_Side_Detail""real-models-side.png"
)
