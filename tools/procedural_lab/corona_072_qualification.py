"""Exercise actual Corona lifecycle in an explicitly launched private host.

Uses renderer/MAXScript APIs through the private fixture transport. No computer
use, screenshots, artist scenes, installation or presented-FPS measurement.
"""
import argparse
import json
from pathlib import Path
import time

from runtime_driver import ROOT,run_script


def qualify(folder):
    metadata=json.loads((folder/'launch.json').read_text())
    stages=[]
    def execute(label,code):
        result=run_script(folder,code,timeout=120)
        stages.append(dict(stage=label,result=result))
        (folder/'corona072-stages.json').write_text(json.dumps(stages,indent=2)+'\n')
        print(label+': '+result.strip(),flush=True)
        if not result.startswith('SUCCESS '):raise RuntimeError(result)
    def state(label):
        execute(label,'IR072Sample "'+label+'"')
        return json.loads((folder/(label+'.json')).read_text())
    execute('setup',r'''
        if CSIdleRemove!=undefined do CSIdleRemove()
        P07New count:120;P07Case="Corona 0.72 lifecycle"
        P07Root.updateMode=2;P07Root.autoRender=true;P07Root.refreshAll()
        renderers.current=CoronaRenderer()
        renderWidth=96;renderHeight=96
        local cam=targetCamera name:"IR072_Camera" pos:[0,-1400,1100] target:(targetObject pos:[0,0,0])
        viewport.setCamera cam
        P07Source.material=standardMaterial diffuse:green
        P07Surface.material=standardMaterial diffuse:(color 180 180 180)
        skylight name:"IR072_Light" multiplier:1
        global IR072Camera=cam,IR072Sample
        fn IR072Sample label = (
            CSPWriteText (MCPFixtureDir+label+".json") (CSPObject #(
                #("label",label),#("render_type",CoronaRenderer.getRenderType()),
                #("passes",CoronaRenderer.getStatistic 0),#("epoch",P07Root.procEpoch),
                #("bridge_builds",CyrusPFBuilds),#("bridge_instances",for rows in CyrusPFData collect rows.count),
                #("phase",CyrusPFPhase),#("timer",CyrusPFTimer.Enabled),#("pending",CyrusPFCheckPending),
                #("resume",CyrusPFResume),#("error",CyrusPFLastError),#("helper_nodes",CyrusPFNodes.count)
            ))
        )
        cyrusDiagnosticStop();cyrusDiagnosticStart "ir072_lifecycle" 4096 4194304 600000
        local before=CoronaRenderer.getRenderType(),raw=CoronaRenderer.stopRender(),after=CoronaRenderer.getRenderType()
        CSPWriteText (MCPFixtureDir+"corona072-inactive-stop.json") (CSPObject #(#("before",before),#("status",raw),#("after",after),#("guarded_stop",CyrusPFStopIR())))
        local result=CoronaRenderer.startInteractive()
        CSPWriteText (MCPFixtureDir+"corona072-start.json") (CSPObject #(#("status",result),#("type",CoronaRenderer.getRenderType())))
        if result!=0 do throw ("Actual Corona floating IR unavailable: "+result as string)
        -- Leave floating IR's VFB owned by this private host. A previous fixture
        -- hid it and no render remained active; that run did not qualify IR.
    ''')
    time.sleep(6)
    before=state('ir072-before-idle')
    assert before['render_type']==3 and before['passes']>0 and before['bridge_instances']==[120],before
    time.sleep(8)
    after=state('ir072-after-idle')
    assert after['passes']>before['passes'] and after['bridge_builds']==before['bridge_builds'] and after['epoch']==before['epoch'],(before,after)
    assert not after['timer'] and not after['pending'] and not after['error'],after
    execute('actual Live population edit','P07Layer.amount=180')
    time.sleep(6)
    edited=state('ir072-after-edit')
    assert edited['render_type']==3 and edited['passes']>0 and edited['epoch']==after['epoch']+1,edited
    assert edited['bridge_builds']==after['bridge_builds']+1 and edited['bridge_instances']==[180] and not edited['error'],edited
    time.sleep(5)
    settled=state('ir072-edit-settled')
    assert settled['bridge_builds']==edited['bridge_builds'] and settled['passes']>edited['passes'] and not settled['timer'],settled
    execute('save during actual IR','P07Assert (saveMaxFile (MCPFixtureDir+"ir072-disposable.max") quiet:true) "IR save failed"')
    time.sleep(6)
    saved=state('ir072-after-save')
    assert saved['render_type']==3 and saved['passes']>0 and saved['epoch']==edited['epoch'] and not saved['error'],saved
    execute('repeated guarded Stop','P07Assert (CyrusPFStopIR()) "Actual guarded stop failed";P07Assert (CyrusPFStopIR()) "Repeated stop failed"')
    time.sleep(2)
    stopped=state('ir072-stopped')
    assert stopped['render_type']==0 and not stopped['error'],stopped
    execute('production render',r'''
        renderers.current.progressive_passLimit=2
        local image=render camera:IR072Camera vfb:false outputFile:(MCPFixtureDir+"ir072-production.png")
        P07Assert (image!=undefined) "Corona production produced no bitmap"
        P07Assert (image.width==96 and image.height==96) "Production bitmap has unexpected dimensions"
        close image
    ''')
    time.sleep(3)
    production=state('ir072-production')
    # Corona can retain IR's statistic 0 after a synchronous production render.
    # Completed render + bitmap dimensions are evidence; that statistic cannot
    # certify production pass count or image quality.
    assert production['render_type']==0 and production['epoch']==edited['epoch'] and not production['error'] and not production['timer'],production
    execute('scene reset and diagnostic export',r'''
        select P07Node;max modify mode
        if not P07Root.mainUI.controlsReady do P07Root.mainUI.mountTimer.tick()
        P07Root.diagnosticsUI.saveReport (MCPFixtureDir+"corona072-trace.json")
        resetMaxFile #noPrompt
        P07Assert (CyrusPFNodes.count==0 and not CyrusPFTimer.Enabled and not CyrusPFResume) "Reset retained renderer work"
    ''')
    report=dict(passed=True,computer_use=False,artist_scene_opened=False,visual_qualification=False,
                script_sha256=metadata['script_sha256'],floating_IR=True,docked_IR=False,
                inactive_stop=json.loads((folder/'corona072-inactive-stop.json').read_text()),
                snapshots=[before,after,edited,settled,saved,stopped,production],stages=stages)
    (folder/'corona072-result.json').write_text(json.dumps(report,indent=2)+'\n')
    print('PASS actual Corona floating IR / idle / edit / save / stop / production / reset',flush=True)


if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__);parser.add_argument('folder',type=Path)
    folder=parser.parse_args().folder.resolve()
    if folder.parent!=ROOT/'build/mcp-qualification':raise ValueError('Private Max fixture required')
    qualify(folder)
