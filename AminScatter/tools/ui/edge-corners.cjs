module.exports=function(s){
 s=s.replace('version:33','version:34');
 s=s.replace('AminScatterLayerFields=#(','AminScatterLayerFields=#(#edgeKeepCorners,#edgeCornerAngle,#edgeCornerCount,');
 s=s.replace('    parameters edgeRowSettings (',`    parameters edgeRowSettings (
        edgeKeepCorners type:#boolean default:false
        edgeCornerAngle type:#float default:45
        edgeCornerCount type:#integer default:1
        on edgeKeepCorners set v do dirty=true
        on edgeCornerAngle set v do dirty=true
        on edgeCornerCount set v do dirty=true`);
 s=s.replace('#(edgeOffsets[i],edgeAlong[i],edgeAcross[i])','#(edgeOffsets[i],edgeAlong[i],edgeAcross[i],edgeKeepCorners,edgeCornerAngle,edgeCornerCount)');
 s=s.replace(/rollout ((?:diversityUI|lineUI)(?:_\d+)?) "[^]*?\n    \)/g,b=>{
  const y=Number(b.match(/label edgeRowHelp[^\n]*pos:\[\d+,(\d+)\]/)[1])+42;
  b=b.replace('        checkbox faceOutCheck',`        checkbox keepCornerCheck "Keep corner points" pos:[8,${y}] width:123
        spinner cornerAngleSpin "Min turn:" range:[0,180,45] type:#float pos:[8,${y+28}] width:123 fieldWidth:52
        spinner cornerCountSpin "Points/corner:" range:[1,64,1] type:#integer pos:[8,${y+56}] width:123 fieldWidth:52
        label cornerHelp "Turn angle in degrees. 0 = straight." pos:[8,${y+84}] width:123 height:36
        checkbox faceOutCheck`);
  b=b.replace('edgeAcrossSpin,edgeRowHelp)','edgeAcrossSpin,edgeRowHelp,keepCornerCheck,cornerAngleSpin,cornerCountSpin,cornerHelp)');
  b=b.replace('            strokeWidth.text=',`            keepCornerCheck.checked=obj.edgeKeepCorners
            cornerAngleSpin.value=obj.edgeCornerAngle;cornerCountSpin.value=obj.edgeCornerCount
            cornerAngleSpin.enabled=obj.edgeKeepCorners;cornerCountSpin.enabled=obj.edgeKeepCorners
            strokeWidth.text=`);
  b=b.replace('        on strokeWidth changed',`        on keepCornerCheck changed v do if not loadingStroke do (obj.edgeKeepCorners=v;cornerAngleSpin.enabled=v;cornerCountSpin.enabled=v;redrawViews())
        on cornerAngleSpin changed v do if not loadingStroke do (obj.edgeCornerAngle=v;redrawViews())
        on cornerCountSpin changed v do if not loadingStroke do (obj.edgeCornerCount=v;redrawViews())
        on strokeWidth changed`);
  return b;
 });return s;
};
