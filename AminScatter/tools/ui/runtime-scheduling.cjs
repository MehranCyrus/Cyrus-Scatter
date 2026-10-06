// Finish scheduling after all feature stages. Timers are deferred work queues,
// not recurring scene inspections. The retained/native algorithms stay intact.
const fs=require('fs');
module.exports=function(s) {
 const one=(a,b)=>{if(s.split(a).length!==2)throw Error('Runtime scheduling anchor: '+a.slice(0,100));s=s.replace(a,b);};
 s=fs.readFileSync('tools/ui/templates/runtime-scheduling.ms','utf8').replace(/\r/g,'')+'\n'+s;
 one('try(CyrusPFTimer.Stop())catch()','try(CyrusPFTimer.Stop();CyrusPFTimer.Dispose())catch()');
 one('try(CyrusReleaseTimer.Stop())catch()','try(CyrusReleaseTimer.Stop();CyrusReleaseTimer.Dispose())catch()');
 // No global mouse polling. A redraw that defers work arms its own release.
 s=s.replaceAll('CyrusWasDragging=true','(CyrusWasDragging=true;CyrusScheduleRelease())');
 s=s.replaceAll('CyrusPointPending=true','(CyrusPointPending=true;CyrusScheduleRelease())');
 one('fn CyrusReleaseTick sender args = (','fn CyrusReleaseTick sender args = (\n CyrusReleaseTimer.Stop()');
 one('dotNet.addEventHandler CyrusReleaseTimer "Tick" CyrusReleaseTick\nCyrusReleaseTimer.Start()',
     'dotNet.addEventHandler CyrusReleaseTimer "Tick" CyrusReleaseTick');
 one('fn CyrusViewportRedraw = (','fn CyrusViewportRedraw = (\n    CyrusScheduleUI()\n    CyrusPFRequestCheck()');
 // Assigning a scripted-plugin local through another instance emits a host
 // change even when the value is equal. Do not rewrite Pending during drawing.
 one('for e in entries where this.enabledLayer e[1] and ((CyrusUsesSharedPolicy this.groupPolicy) or e[2].overlapEnabled) do e[2].dirty=true',
     'for e in entries where this.enabledLayer e[1] and not e[2].dirty and ((CyrusUsesSharedPolicy this.groupPolicy) or e[2].overlapEnabled) do e[2].dirty=true');
 // A successful publication is the render dependency for policy 3. Building
 // a key must not reconcile containers, install texture watchers or solve.
 one('   if r.groupPolicy==3 do format "Procedural:%:%|" r.procEpoch (if r.updateMode==2 then r.procInputKey() else "published") to:s',
 `   if r.groupPolicy==3 do (
    format "Procedural:%|" r.procEpoch to:s
    for plants in r.procPublishedSources do for src in plants where isValidNode src do format "%:%|" (getHandleByAnim src) (if src.material==undefined then 0 else getHandleByAnim src.material) to:s
   )`);
 one('fn AminScatterRenderBegin = (','fn AminScatterRenderBegin = (\n if not CyrusPFBusy do CyrusPointSync()\n CyrusPFRequestCheck()');
 one('fn AminScatterRenderEnd = (','fn AminScatterRenderEnd = (CyrusPFRequestCheck();');
 one('fn CyrusPFIR = (try(CoronaRenderer.getRenderType()==3)catch(false))',
     'fn CyrusPFIR = (try(findItem #(2,3) (CoronaRenderer.getRenderType())>0)catch(false))');
 one(' CyrusPFResume=false;CyrusPFPhase=0',' CyrusPFResume=false;CyrusPFPhase=0;CyrusPFCheckPending=false;CyrusPFTimer.Stop()');
 one(' CyrusPFPhase=0;CyrusPFResume=CyrusPFIR()',
     ' CyrusPFPhase=0;CyrusPFResume=CyrusPFIR();if CyrusPFResume do CyrusPFResumeMode=CoronaRenderer.getRenderType();CyrusPFRequestCheck()');
 one('  local active=CyrusPFIR();if active do CyrusPFProduction=false',
     '  local active=CyrusPFIR();if active do (CyrusPFProduction=false;CyrusPFResumeMode=CoronaRenderer.getRenderType())');
 one('   local wanted=CyrusPFKey()',
     '   if not CyrusPFCheckPending and not CyrusPFResume do return false\n   local wanted=CyrusPFKey()');
 one('   ) else CyrusPFPendingKey=""',
     '   ) else (CyrusPFPendingKey="";CyrusPFCheckPending=false)');
 one('  ) else if CyrusPFNodes.count>0 do CyrusPFClear()',
     '  ) else (CyrusPFCheckPending=false;if CyrusPFNodes.count>0 do CyrusPFClear())');
 one('CyrusPFLastError=getCurrentException();CyrusPFPhase=0;CyrusPFResume=false;format "Cyrus IR update:',
     'CyrusPFLastError=getCurrentException();CyrusPFPhase=0;CyrusPFResume=false;CyrusPFCheckPending=false;if not CyrusPFIR() do CyrusPFClear();format "Cyrus IR update:');
 one(' CyrusPFTimer.Start()\n)',
     ' if CyrusPFCheckPending or CyrusPFPhase>0 or CyrusPFResume do CyrusPFTimer.Start()\n)');
 one('fn CyrusPFTick sender args = (',
     'fn CyrusPFTick sender args = (\n if CyrusPFTicking do return false\n CyrusPFTicking=true');
 one(' try(CyrusPFTickImpl sender args)catch(CyrusPFLastError=getCurrentException())',
     ' try(CyrusPFTickImpl sender args)catch(CyrusPFLastError=getCurrentException();CyrusPFCheckPending=false;CyrusPFPhase=0;CyrusPFResume=false)\n CyrusPFTicking=false');
 one('dotNet.addEventHandler CyrusPFTimer "Tick" CyrusPFTick;CyrusPFTimer.Start()',
     'dotNet.addEventHandler CyrusPFTimer "Tick" CyrusPFTick');
 one('CoronaRenderer.startInteractive()',
     '(local result=(if CyrusPFResumeMode==2 then CoronaRenderer.startInteractiveDocked() else CoronaRenderer.startInteractive());if result!=0 do throw ("Corona IR start failed: "+result as string);result)');
 s=s.replaceAll('CoronaRenderer.stopRender()',
     '(if not CyrusPFStopIR() do throw CyrusPFLastError)');
 // Direct scripted parameter/Edit changes need the same deferred update as UI
 // edits. This branch runs only for an actual notification of the controller.
 one('else if entry[2].externalChanged nodes do (redraw=true;CyrusPFRevision+=1)\n            )',
 `else if entry[2].externalChanged nodes do (redraw=true;CyrusPFRevision+=1)
            )
            if findItem nodes n>0 do (
                CyrusScheduleUI()
                if n.baseObject.updateMode==2 and (for leaf in n.baseObject.layerObjects where leaf.dirty collect leaf).count>0 do redraw=true
            )`);
 one('AminScatterNodeEvents=NodeEventCallback mouseUp:true',
     'AminScatterNodeEvents=NodeEventCallback hideChanged:CyrusRenderNodeChanged materialStructured:CyrusRenderNodeChanged materialOtherEvent:CyrusRenderNodeChanged nameChanged:CyrusRenderNodeChanged mouseUp:true');
 one('            groupSolving=false;accepted',
     '            CyrusScheduleUI();CyrusPFRequestCheck()\n            groupSolving=false;accepted');
 return s;
};
