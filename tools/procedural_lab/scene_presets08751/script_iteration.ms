-- Development only: native APIs/managed code are unchanged by these script
-- iterations. Final acceptance uses a fresh installed exact source/native pair.
if cyrusScenePresetVersion()!=1 or cyrusInteractionVersion()!=12 or cyrusEditSceneRemap==undefined do throw "This development host has the wrong native API."
fileIn @"F:\Cursor\_Cyrus_Apps\CyrusScatter\AminScatter\tools\ui\templates\scene-presets.ms"
fn CyrusPointBeforeSave = (if CyrusScenePresetCapturing do return false;CyrusPointSuspended=true;for node in objects where classof node.baseObject==AminScatterObject do node.baseObject.interactionsBeforeSave();CyrusPointClear())
fn CyrusPointAfterSave = (if CyrusScenePresetCapturing do return false;CyrusPointSuspended=false;(CyrusPointPending=true;CyrusScheduleRelease()))
