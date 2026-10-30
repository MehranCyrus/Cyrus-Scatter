// Max constructs every plugin-level rollout even while collapsed. Keep twelve
// lightweight command-panel slots; create each body only on its first opening.
// Bodies keep the existing component handlers and explicit model owners.
const blocks=require('./maxscript-blocks.cjs');
function measured(text,method,stage,page){
 const [a,b]=blocks.span(text,new RegExp('^        fn '+method+'[^\\n]*= \\(','m'));
 const original=text.slice(a,b),open=original.indexOf('(');
 const body=original.slice(open+1,-1);
 const measured=original.slice(0,open+1)+`
            local measurement=CyrusMeasureBegin ${stage},measuredOwner=if owner==undefined then "" else owner.layerID,measuredEpoch=if root==undefined then 0 else root.procEpoch
            try (
                local measuredResult=(
${body}
                )
                CyrusMeasureEnd measurement measuredOwner measuredEpoch "${page}.${method}"
                measuredResult
            )catch(CyrusMeasureEnd measurement measuredOwner measuredEpoch "${page}.${method}" failed:true;throw())
        )`;
 return text.slice(0,a)+measured+text.slice(b);
}
module.exports=function(page,index){
 const name=page.name,slot=name+'Slot',factory='create'+name;
 let body=page.text.replace(new RegExp('rollout '+name+' "[^"\\n]*"'), 'rollout '+name+' ""');
 body=body.replace('local layout,lastLayoutStamp=undefined,lastLayoutWidth=0','local hostPage=undefined\n        local layout,lastLayoutStamp=undefined,lastLayoutWidth=0');
 body=body.replace('panel=this.mainUI;root=undefined;controlsReady=false','controlsReady=false');
 // The inner #cmdPanel HWND can exceed its visible subrollout clipping area.
 // Respect the shell's usable width as well as the child's logical UI width.
 body=body.replaceAll('amax 140 '+name+'.width','amax 64 (amin (hostPage.width-8) (windows.getWindowPos '+name+'.hwnd removeUIScaling:true).w)');
 body=body.replace(new RegExp('        on '+name+' rolledUp[^\\n]*'), '');
 body=body.replace(name+'.open,#(', '(if hostPage==undefined then false else hostPage.open),#(');
 body=body.replace(name+'.open=state[1]', 'if state[2]==undefined do return true');
 body=body.replace(name+'.height=y+4;',name+'.height=ceil ((y+4)*GetUIScaleFactor());if hostPage!=undefined do (hostPage.body.height=y+4+hostPage.headerInset;hostPage.height=ceil ((y+6)*GetUIScaleFactor()));if panel!=undefined do panel.requestRepaint();');
 body=measured(measured(body,'layout',14,name),'bind',13,name);
 const shell=`    rollout ${slot} ${JSON.stringify(page.title)} width:#cmdPanel height:4 category:${index*10} autoLayoutOnResize:false (
        local view=undefined,headerInset=0
        subRollout body "" pos:[0,0] width:200 height:2 autoLayoutOnResize:false scrollBar:#off
        on ${slot} open do view=this
        on ${slot} close do view=undefined
        on ${slot} rolledUp state do if view!=undefined and view.mainUI.controlsReady and not view.mainUI.binding and not view.mainUI.layerBinding do (
            view.mainUI.bindSection view.mainUI.editors[${index}] refresh:false
            view.mainUI.rememberViews()
        )
        on ${slot} resized size do if view!=undefined and view.mainUI.controlsReady do view.mainUI.resizeSection ${index}
    )`;
 return {declaration:`    local ${name}=undefined`,factory:`    fn ${factory} = (\n${body}\n        ${name}\n    )`,shell};
};
