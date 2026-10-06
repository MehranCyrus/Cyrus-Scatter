// Passive causal events augment the existing performance hooks. No start,
// filesystem write, input-key query, evaluation or redraw occurs on script load.
module.exports = function diagnostics(s) {
  const one = (a,b) => { if(s.split(a).length!==2) throw Error('Diagnostics anchor: '+a.slice(0,100)); s=s.replace(a,b); };
  s = `global CyrusDiagnosticEmit
fn CyrusDiagnosticEmit event origin owner epoch detail = (
    if cyrusDiagnosticActive!=undefined do try (
        if cyrusDiagnosticActive() do cyrusDiagnosticEvent event origin owner epoch detail
    )catch()
    undefined
)
` + s;
  one('fn AminScatterLiveChanged event handles = (', `fn AminScatterLiveChanged event handles = (
    CyrusDiagnosticEmit "input.received" "host_callback" "" 0 (event as string)`);
  one('fn CyrusDensityMapChanged texture = (', `fn CyrusDensityMapChanged texture = (
    CyrusDiagnosticEmit "density.changed" "host_callback" "" 0 "parameter_notification"`);
  one('        if key==procPreparedKey do (procPreparedHits+=1;return procPreparedRows)', `        if key==procPreparedKey do (CyrusDiagnosticEmit "prepare.reused" "engine" layerID procEpoch "key_match";procPreparedHits+=1;return procPreparedRows)
        CyrusDiagnosticEmit "prepare.started" "engine" layerID procEpoch "key_changed"`);
  one('        local key=this.procInputKey()\n        if key==groupSnapshotKey do (', `        local key=this.procInputKey()
        if key==groupSnapshotKey do (
            CyrusDiagnosticEmit "publication.reused" "engine" layerID procEpoch "key_match"`);
  one('        local mods=this.procModifiers(),active=for m in mods where m.enabled collect m', `        CyrusDiagnosticEmit "solve.started" "engine" layerID procEpoch "input_changed"
        local mods=this.procModifiers(),active=for m in mods where m.enabled collect m`);
  one('            groupSolving=false;accepted', `            CyrusDiagnosticEmit "publication.committed" "engine" layerID procEpoch "complete"
            groupSolving=false;accepted`);
  one('            for i=1 to layerObjects.count do (layerObjects[i].procPreparedKey="";layerObjects[i].procCandidateCount=undefined;layerObjects[i].procBindingKey=previousBindings[i])\n            groupSolving=false;throw()', `            for i=1 to layerObjects.count do (layerObjects[i].procPreparedKey="";layerObjects[i].procCandidateCount=undefined;layerObjects[i].procBindingKey=previousBindings[i])
            CyrusDiagnosticEmit "publication.retained" "engine" layerID procEpoch "successor_failed"
            groupSolving=false;throw()`);
  one('    fn procInstallPreview state pending = (', `    fn procInstallPreview state pending = (
        CyrusDiagnosticEmit "preview.installed" "engine" layerID procEpoch (if pending then "pending" else "current")`);
  one('fn CyrusPFBuild = (', `fn CyrusPFBuild = (
 CyrusDiagnosticEmit "bridge.build_requested" "renderer" "" 0 (if CyrusPFBusy then "busy" else "admitted")`);
  one('  CyrusPFSignature=CyrusPFKey();CyrusPFBuilds+=1;CyrusPFLastError=""', `  CyrusPFSignature=CyrusPFKey();CyrusPFBuilds+=1;CyrusPFLastError=""
  CyrusDiagnosticEmit "bridge.completed" "renderer" "" 0 "particle_count_verified"`);
  one('  CyrusPFClear();CyrusPFLastError=reason', `  CyrusPFClear();CyrusPFLastError=reason
  CyrusDiagnosticEmit "bridge.failed" "renderer" "" 0 "inspect_local_error"`);
  one('fn AminScatterRenderBegin = (', `fn AminScatterRenderBegin = (
 CyrusDiagnosticEmit "render.pre" "host_callback" "" 0 (if CyrusPFBusy then "bridge_busy" else "setup_allowed")`);
  one('fn AminScatterRenderEnd = (', `fn AminScatterRenderEnd = (CyrusDiagnosticEmit "render.post" "host_callback" "" 0 "restore";`);
  // Each call site keeps its original control flow. These events distinguish
  // our explicit start/stop requests from renderer-owned restart notifications.
  s=s.replaceAll('CoronaRenderer.stopRender()', '(CyrusDiagnosticEmit "ir.stop_requested" "renderer" "" 0 "bridge";CoronaRenderer.stopRender())');
  s=s.replaceAll('CoronaRenderer.startInteractive()', '(CyrusDiagnosticEmit "ir.start_requested" "renderer" "" 0 "bridge";CoronaRenderer.startInteractive())');
  s=s.replaceAll('CoronaRenderer.startInteractiveDocked()', '(CyrusDiagnosticEmit "ir.start_requested" "renderer" "" 0 "bridge_docked";CoronaRenderer.startInteractiveDocked())');
  return s;
};
