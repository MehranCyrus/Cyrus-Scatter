// Native list controls retain the component selection contract. The visible
// list draws identification markers and forwards selection to those handlers.
module.exports=function(text,components){
 const specs=[];
 if(components.some(p=>p.key==='sourceUI'))specs.push({id:'sourceUI_plantList',multi:true,color:'sourceUI_obj.sourceIDColor (args.Index+1)',select:'if newFocus>0 do sourceUI_focusedRow=newFocus;sourceUI_showSelectedColor()',tip:'sourceUI_obj.sourceBandDetails (row+1)'});
 if(components.some(p=>p.key==='flow_layersUI'))specs.push({id:'flow_layersUI_layerList',multi:false,color:'flow_layersUI_members[args.Index+1].layerIDColor',select:'if view.SelectedIndex>=0 do panel.selectLayerView flow_layersUI_members[view.SelectedIndex+1]',open:'if view.SelectedIndex>=0 do panel.selectLayerView flow_layersUI_members[view.SelectedIndex+1] expand:true'});
 if(components.some(p=>p.key==='diversityUI')){
  specs.push({id:'diversityUI_strokesList',multi:false,color:'diversityUI_obj.strokeDisplayColors[diversityUI_strokeRows[args.Index+1]]',select:'diversityUI_selectedBandID=if view.SelectedIndex>=0 then diversityUI_obj.strokeIDs[diversityUI_strokeRows[view.SelectedIndex+1]] else 0;diversityUI_showStroke()'});
  specs.push({id:'diversityUI_strokeChoices',multi:true,color:'diversityUI_choiceColor (args.Index+1)',select:'local row=diversityUI_selectedStroke();if row>0 and CyrusLicenseCanEdit() do diversityUI_obj.setStrokeSelection row diversityUI_obj.strokeModes[row] (for i in diversityUI_strokeChoices.selection collect diversityUI_choiceValues[i]);CyrusViewportRedraw()'});
 }
 if(!specs.length)return text;
 let declarations='        local syncingColorLists=false\n',methods='';
 for(const s of specs){
  const id=s.id+'_colored';
  declarations+=`        dotNetControl ${id} "System.Windows.Forms.ListBox" pos:[6,6] width:100 height:100\n`;
  if(s.open)methods+=`        on ${id} DoubleClick view args do if controlsReady and not binding and root!=undefined do (${s.open})\n`;
  if(s.tip){
   declarations+=`        local ${id}_tip=undefined,${id}_tipRow=-1\n`;
   methods+=`        on ${id} MouseMove view args do if controlsReady and not binding and root!=undefined and not syncingColorLists do (
            local row=view.IndexFromPoint args.Location
            if row!=${id}_tipRow do (
                ${id}_tipRow=row
                if ${id}_tip==undefined do ${id}_tip=dotNetObject "System.Windows.Forms.ToolTip"
                ${id}_tip.SetToolTip view (if row>=0 then ${s.tip} else "")
            )
        )
        on ${id} HandleDestroyed view args do (if ${id}_tip!=undefined do (${id}_tip.Dispose();${id}_tip=undefined);${id}_tipRow=-1)
`;
  }
  methods+=`        on ${id} SelectedIndexChanged view args do if controlsReady and not binding and root!=undefined and not syncingColorLists do (
            ${s.multi?`local indices=#{},newFocus=0;for i=0 to view.SelectedIndices.Count-1 do (local row=view.SelectedIndices.Item[i]+1;indices[row]=true;if not ${s.id}.selection[row] do newFocus=row);${s.id}.selection=indices`:`${s.id}.selection=view.SelectedIndex+1`}
            ${s.select}
            if controlsReady and root!=undefined do layout()
        )
        on ${id} DrawItem view args do if controlsReady and root!=undefined and args.Index>=0 and args.Index<view.Items.Count do (
            args.DrawBackground()
            local shade=${s.color},rectangle=args.Bounds
            local ink=dotNetObject "System.Drawing.SolidBrush" ((dotNetClass "System.Drawing.Color").FromArgb (shade.r as integer) (shade.g as integer) (shade.b as integer))
            args.Graphics.FillRectangle ink (rectangle.X+3) (rectangle.Y+3) 10 (amax 1 (rectangle.Height-6))
            ink.Dispose()
            (dotNetClass "System.Windows.Forms.TextRenderer").DrawText args.Graphics (view.Items.Item[args.Index] as string) view.Font (dotNetObject "System.Drawing.Point" (rectangle.X+17) rectangle.Y) args.ForeColor
            args.DrawFocusRectangle()
        )
`;
 }
 methods+=`        fn syncColorLists = (
            if syncingColorLists do return false
            syncingColorLists=true
            try (
${specs.map(s=>{const id=s.id+'_colored';return `                setHostedVisible ${id} ${s.id}.visible;${id}.enabled=${s.id}.enabled
                ${id}.pos=${s.id}.pos;${id}.width=${s.id}.width;${id}.height=${s.id}.height
                ${s.id}.visible=false
                ${id}.DrawMode=(dotNetClass "System.Windows.Forms.DrawMode").OwnerDrawFixed
                ${id}.SelectionMode=(dotNetClass "System.Windows.Forms.SelectionMode").${s.multi?'MultiExtended':'One'}
                ${id}.IntegralHeight=false;${id}.ItemHeight=16
                ${id}.BackColor=(dotNetClass "System.Drawing.Color").FromArgb 65 65 65
                ${id}.ForeColor=(dotNetClass "System.Drawing.Color").FromArgb 230 230 230
                local itemsChanged=${id}.Items.Count!=${s.id}.items.count
                if not itemsChanged do for i=1 to ${s.id}.items.count where (${id}.Items.Item[i-1] as string)!=${s.id}.items[i] do itemsChanged=true
                if itemsChanged do (${id}.BeginUpdate();${id}.Items.Clear();for value in ${s.id}.items do ${id}.Items.Add value;${id}.EndUpdate())
                for i=0 to ${id}.Items.Count-1 do (
                    local selected=${s.multi?`${s.id}.selection[i+1]`:`${s.id}.selection==i+1`}
                    if (${id}.GetSelected i)!=selected do ${id}.SetSelected i selected
                )
                ${s.tip?`${id}_tipRow=-1;`:''}${id}.Invalidate()`;}).join('\n')}
                syncingColorLists=false;true
            )catch(syncingColorLists=false;throw())
        )
`;
 return text.replace('        local layout\n','        local layout\n'+declarations)
  .replace('        fn layout = (',methods+'        fn layout = (')
  .replace(/(            \w+\.height=y\+4);true/,'$1;syncColorLists();true');
};
