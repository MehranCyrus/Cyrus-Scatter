with undo off (
    global SPFile=GardenRun+"native-merge.max"
    local sample=box name:"ScenePresetProbe" pos:[0,30,0]
    saveNodes #(sample) SPFile quiet:true
    delete sample
)
undo "Previous artist action" on (global SPSentinel=box name:"EarlierObject" pos:[10,0,0])
