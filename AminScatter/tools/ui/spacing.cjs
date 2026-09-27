module.exports=function(s) {
const fields=['collisionEnabled','collisionRadius','relaxEnabled','relaxSpacing','relaxIterations','relaxStrength'];
s=s.replace('AminScatterLayerFields=#(',`AminScatterLayerFields=#(${fields.map(x=>'#'+x).join(',')},`);
s=s.replace('version:16','version:17');
const params=`    parameters spacingSettings (
        collisionEnabled type:#boolean default:false
        collisionRadius type:#worldUnits default:0.1
        relaxEnabled type:#boolean default:false
        relaxSpacing type:#worldUnits default:0.2
        relaxIterations type:#integer default:10
        relaxStrength type:#float default:0.5
${fields.map(x=>`        on ${x} set v do dirty=true`).join('\n')}
    )\n`;
s=s.replace('    parameters randomization (',params+'    parameters randomization (');
s=s.replace('if not advancedAxes and areas[1].count==0', 'if not collisionEnabled and not relaxEnabled and not advancedAxes and areas[1].count==0');
s=s.replace('(lineInputs plants)\n','(lineInputs plants) #(collisionEnabled,collisionRadius,relaxEnabled,relaxSpacing,relaxIterations,relaxStrength)\n');
for(let i=1;i<=10;i++) {
 const name='spacingUI_'+i;
 const ui=`global CyrusMake_${name}
fn CyrusMake_${name} target view = (
    rollout ${name} "Collision / Relax" width:136 (
        local obj=CyrusUIBuildTarget,parentView=CyrusUIBuildView,ready=false
        checkbox collisionCheck "Enable collision" pos:[8,8] width:120
        spinner radiusSpin "Radius: " pos:[8,34] width:120 fieldWidth:54 type:#worldUnits range:[0.00001,1e9,0.1]
        label radiusHint "Min gap = 2 x radius" pos:[8,62] width:120
        checkbox relaxCheck "Enable relax" pos:[8,94] width:120
        spinner spacingSpin "Spacing: " pos:[8,120] width:120 fieldWidth:54 type:#worldUnits range:[0.00001,1e9,0.2]
        spinner iterationsSpin "Iterations: " pos:[8,146] width:120 fieldWidth:45 type:#integer range:[1,100,10]
        spinner strengthSpin "Strength %: " pos:[8,172] width:120 fieldWidth:45 range:[0,100,50]
        label orderHint "Relax, then collision" pos:[8,202] width:120
        label layerHint "Within this layer only" pos:[8,224] width:120
        fn syncControls = (
            ready=false
            collisionCheck.checked=obj.collisionEnabled;radiusSpin.value=obj.collisionRadius;radiusSpin.enabled=obj.collisionEnabled
            relaxCheck.checked=obj.relaxEnabled;spacingSpin.value=obj.relaxSpacing;iterationsSpin.value=obj.relaxIterations;strengthSpin.value=obj.relaxStrength*100
            spacingSpin.enabled=obj.relaxEnabled;iterationsSpin.enabled=obj.relaxEnabled;strengthSpin.enabled=obj.relaxEnabled
            ready=true
        )
        on collisionCheck changed v do if ready do (obj.collisionEnabled=v;syncControls();redrawViews())
        on radiusSpin changed v do if ready do (obj.collisionRadius=v;redrawViews())
        on relaxCheck changed v do if ready do (obj.relaxEnabled=v;syncControls();redrawViews())
        on spacingSpin changed v do if ready do (obj.relaxSpacing=v;redrawViews())
        on iterationsSpin changed v do if ready do (obj.relaxIterations=v;redrawViews())
        on strengthSpin changed v do if ready do (obj.relaxStrength=v/100.0;redrawViews())
        on ${name} open do syncControls()
        on ${name} close do ready=false
        on ${name} rolledUp state do (parentView.layoutPanels();for c in ${name}.controls do c.visible=false;for c in ${name}.controls do c.visible=true)
    )
    ${name}.obj=target;${name}.parentView=view;${name}
)
`;
 s=s.replace('global CyrusMakeLayer_'+i+'\n',ui+'\nglobal CyrusMakeLayer_'+i+'\n');
 s=s.replace(`CyrusMake_distributionUI_${i} obj parentView,`,`CyrusMake_distributionUI_${i} obj parentView,CyrusMake_${name} obj parentView,`);
}
if(!s.includes('CyrusMake_spacingUI_10 obj parentView')) throw Error('Missing layer UI');
return s;

};
