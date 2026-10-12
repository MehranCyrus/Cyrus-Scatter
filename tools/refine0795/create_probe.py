"""Inspect actual creation-mode entry in an owned host without mouse automation."""
from pathlib import Path
import sys,time,json,traceback
sys.path.insert(0,str(Path(__file__).resolve().parent))
from common import *
rec=Recorder('create-probe')
try:
    r.resetMaxFile(r.Name('noPrompt'));r.clearSelection()
    rec.step('Enter actual Scatter Create command',lambda:r.startObjectCreation(r.AminScatterObject),redraw=False)
    rec.step('Drain creation panel mount',lambda:pump(500),redraw=False)
    rec.data['panel_mode']=str(r.getCommandPanelTaskMode())
    rec.data['tool_mode']=str(r.toolMode.commandMode)
    rec.data['nodes']=len(list(r.objects))
    rec.data['objects']=[]
    for obj in r.getClassInstances(r.AminScatterObject,processAllAnimatables=True):
        row=dict(object=str(obj),main_ready=bool(obj.mainUI.controlsReady),main_displayed=bool(obj.mainUI.isDisplayed))
        stream=r.stringStream('');r.showProperties(obj,to=stream);row['properties']=str(stream)
        rec.data['objects'].append(row)
    rec.write()
except Exception:rec.error(traceback.format_exc())
