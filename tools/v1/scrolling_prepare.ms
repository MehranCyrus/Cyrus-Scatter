-- Disposable Max 2027 host only. The artist's live scene must not run this.
if not matchPattern BLDir pattern:"*/hosts/classic-layout-scroll-*/*" do throw "Private scrolling fixture only"
global CFNode=getNodeByName "Cyrus_Scatter_1_Demo",CFRoot,CSScrollBefore,CSScrollRead,CSScrollCheck,CSScrollArm
if CFNode==undefined do throw "Expected frozen layers demo"
CFRoot=CFNode.baseObject
if CFRoot.uiVersion()!="1.2.3" do throw "Expected scrolling patch 1.2.3"
saveMaxFile (BLDir+"Cyrus_Scroll_1.2.3_Test.max") quiet:true
select CFNode
max modify mode
modPanel.setCurrentObject CFRoot
windows.processPostedMessages()
CFRoot.mainUI.open=true
CFRoot.mainUI.bind()
for r in CFRoot.nativeEditors() do r.open=false
for p in CFRoot.layerPanels do p.open=false
CFRoot.layerPanels[1].open=true
CFRoot.layerPanels[1].mount()
CFRoot.layerPanels[1].editors[2].open=true
CFRoot.layerPanels[1].editors[3].open=true
CFRoot.mainUI.layoutPanels()
CFRoot.mainUI.scrollPos=350
completeRedraw()
fn CSScrollRead = (
    local display=CyrusPointOwner CFNode
    #(
        CFRoot.mainUI.scrollPos,
        for leaf in CFRoot.layerObjects collect (leaf.cacheSnapshot())[6],
        for leaf in CFRoot.layerObjects collect (leaf.paintCacheStats())[1],
        if isValidNode display then cyrusRetainedStats display else undefined,
        (for leaf in CFRoot.layerObjects collect (for field in AminScatterLayerFields collect getProperty leaf field)) as string,
        (for p in CFRoot.layerPanels collect #(p.hwnd,for r in p.editors collect r.hwnd)) as string,
        for p in CFRoot.layerPanels where p.mounted collect #(p.scrollPos,for r in p.editors collect r.scrollPos)
    )
)
fn CSScrollArm = (CSScrollBefore=CSScrollRead())
fn CSScrollCheck label direction:0 = (
    local after=CSScrollRead(),before=CSScrollBefore
    if direction!=0 and (after[1]-before[1])*direction<=0 do throw (label+": outer scroll did not move in the expected direction")
    for k in #(2,3,5,6,7) do if before[k] as string!=after[k] as string do throw (label+": navigation changed authoring, cache, handles or inner scroll positions at "+(k as string))
    if before[4]!=undefined do for k in #(3,4,5,6,7) do if before[4][k]!=after[4][k] do throw (label+": navigation uploaded display buffers")
    CSPWriteText (BLDir+"scroll-"+label+".json") (CSPObject #(#("passed",true),#("version",CFRoot.uiVersion()),#("before",before[1]),#("after",after[1]),#("generations",after[2]),#("paint_evaluations",after[3]),#("authoring_unchanged",true),#("handles_retained",true),#("inner_scroll_unchanged",true),#("no_display_upload",true)))
    CSScrollArm()
)
CSScrollArm()
fileIn (BLRoot+"tools/v1/identity_fixture.ms")
CSPWriteText (BLDir+"scroll-prepared.json") (CSPObject #(#("version",CFRoot.uiVersion()),#("bindings",cyrusBindRolloutScroll CFRoot.mainUI.hwnd),#("scroll",CFRoot.mainUI.scrollPos)))
