// Opt-in diagnostic hooks. The collector is undefined outside an active recording.
module.exports = function trace(s) {
  function replace(a,b) { if(s.split(a).length!==2) throw Error('Trace anchor must be unique: '+a); s=s.replace(a,b); }
  s='global CyrusPerfTraceBegin,CyrusPerfTraceEnd,CyrusPerfTraceInput\n'+s;
  function wrap(name,args,next,call,stage,detail) {
    replace(`    fn ${name}${args} = (`,`    fn cspImpl_${name}${args} = (`);
    const wrapper=`    fn ${name}${args} = (
        local token=undefined
        if CyrusPerfTraceBegin!=undefined do try(token=CyrusPerfTraceBegin this "${stage}")catch()
        try (
            local answer=${call}
            if token!=undefined and CyrusPerfTraceEnd!=undefined do try(CyrusPerfTraceEnd token ${detail})catch()
            answer
        )catch(
            if token!=undefined and CyrusPerfTraceEnd!=undefined do try(CyrusPerfTraceEnd token ("EXCEPTION: "+getCurrentException()))catch()
            throw()
        )
    )
`;
    replace(next,wrapper+next);
  }
  wrap('externalChanged',' changedNodes','    fn invalidateLive', 'cspImpl_externalChanged changedNodes','external_invalidation','("changed="+(answer as string))');
  wrap('placements',' plants previewOnly:false rawOnly:false finalPass:undefined','    fn refreshPreview = (','cspImpl_placements plants previewOnly:previewOnly rawOnly:rawOnly finalPass:finalPass','placements','#("",answer.count,previewOnly,rawOnly,finalPass!=undefined)');
  wrap('refreshPreview','','    fn checkAnalyzerRevision = (','cspImpl_refreshPreview()','preview_rebuild','#(previewError,generatedCount,cachedPointCount,previewBuildCount)');
  replace('    fn cacheSnapshot = (','    fn performanceTraceVersion = 1\n    fn cacheSnapshot = (');
  replace('fn AminScatterLiveChanged event handles = (','fn AminScatterLiveChanged event handles = (\n    if CyrusPerfTraceInput!=undefined do try(CyrusPerfTraceInput "scatter_input_received" event handles)catch()');
  return s;
};
