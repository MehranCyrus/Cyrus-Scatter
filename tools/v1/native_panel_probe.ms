-- Private native-rollout feasibility fixture. Run only in its disposable host.
global CyrusV1ProbeNode
plugin simpleObject CyrusV1NativePanelProbe
name:"Cyrus Native Panel Probe" classID:#(0x69dd1201,0x3148e933) category:"Cyrus Tests" version:1
(
    parameters model rollout:layerUI (
        layerCounts type:#intTab tabSize:0 tabSizeVariable:true
        layerLabels type:#stringTab tabSize:0 tabSizeVariable:true
        activeLayer type:#integer default:1
    )
    parameters editorState rollout:generationUI (
        editorMarker type:#integer default:0
    )
    local bindingPasses=0
    fn bindEditor = (
        if this.generationUI.controlsReady do this.generationUI.bind()
    )
    rollout layerUI "Cyrus Scatter v1 - Layers" width:#cmdPanel (
        listbox layers "Selected layer" items:#() width:210 height:6
        label help "One reusable editor below." width:210
        on layers selected i do (activeLayer=i;bindEditor())
        on layerUI open do (layers.items=layerLabels as array;layers.selection=activeLayer)
    )
    rollout generationUI "Generation" width:#cmdPanel (
        local controlsReady=false,binding=false
        spinner count "Plants:" type:#integer range:[0,100000,0] width:210 fieldWidth:76
        checkbox enabled "Enabled" checked:true
        fn bind = (
            binding=true
            count.value=layerCounts[activeLayer]
            bindingPasses+=1
            binding=false
        )
        on count changed value do if not binding do undo "Cyrus plants" on layerCounts[activeLayer]=value
        on generationUI open do (controlsReady=true;bind())
        on generationUI close do controlsReady=false
    )
    on buildMesh do setMesh mesh vertices:#([0,0,0],[10,0,0],[0,10,0]) faces:#([1,2,3])
    tool create (
        on mousePoint click do (nodeTM.translation=gridPoint;if click>1 do #stop)
    )
)
CyrusV1ProbeNode=CyrusV1NativePanelProbe name:"CYRUS_V1_NATIVE_UI_PROBE"
CyrusV1ProbeNode.layerCounts=#(100,200,300)
CyrusV1ProbeNode.layerLabels=#("Grass","Shrubs","Trees")
select CyrusV1ProbeNode
setCommandPanelTaskMode #modify
max modify mode
(
local model=CyrusV1ProbeNode.baseObject
local before=model.generationUI.hwnd
for i=1 to 30 do (
    model.activeLayer=1+mod (i-1) 3
    model.bindEditor()
    if model.generationUI.count.value!=model.layerCounts[model.activeLayer] do throw "Native editor binding mismatch"
    if model.generationUI.hwnd!=before do throw "Native editor was remounted"
)
model.activeLayer=1;model.bindEditor()
CSPWriteText (BLDir+"native-panel-probe.json") (CSPObject #(#("same_editor_hwnd",true),#("bindings",model.bindingPasses),#("counts",model.layerCounts as array),#("layer_width",(windows.getWindowPos model.layerUI.hwnd).w),#("editor_width",(windows.getWindowPos model.generationUI.hwnd).w)))
)
