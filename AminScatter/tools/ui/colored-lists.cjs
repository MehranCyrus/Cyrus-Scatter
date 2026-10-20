// Native list controls retain the component selection contract. The visible
// list draws identification markers and forwards selection to those handlers.
module.exports=function(text,components){
 const specs=[];
 if(components.some(p=>p.key==='sourceUI'))specs.push({id:'sourceUI_plantList',multi:true,name:'sourceUI_obj.sourceLabel (args.Index+1)',color:'sourceUI_obj.sourceIDColor (args.Index+1)',select:'if newFocus>0 do sourceUI_focusedRow=newFocus;sourceUI_showSelectedColor()',tip:'(sourceUI_obj.sourceLabel (row+1))+"\\n"+(sourceUI_obj.sourceBandDetails (row+1))'});
 if(components.some(p=>p.key==='flow_layersUI'))specs.push({id:'flow_layersUI_layerList',multi:false,name:'root.layerCaption flow_layersUI_members[args.Index+1]',color:'flow_layersUI_members[args.Index+1].layerIDColor',select:'if view.SelectedIndex>=0 do panel.selectLayerView flow_layersUI_members[view.SelectedIndex+1]',open:'if view.SelectedIndex>=0 do panel.selectLayerView flow_layersUI_members[view.SelectedIndex+1]',tip:'root.layerCaption flow_layersUI_members[row+1]'});
 if(components.some(p=>p.key==='diversityUI')){
  specs.push({id:'diversityUI_strokesList',multi:false,color:'diversityUI_obj.strokeDisplayColors[diversityUI_strokeRows[args.Index+1]]',select:'diversityUI_selectedBandID=if view.SelectedIndex>=0 then diversityUI_obj.strokeIDs[diversityUI_strokeRows[view.SelectedIndex+1]] else 0;diversityUI_showStroke()'});
  specs.push({id:'diversityUI_strokeChoices',multi:true,toggle:true,color:'diversityUI_choiceColor (args.Index+1)',select:'diversityUI_setBandChoices indices'});
 }
 if(!specs.length)return text;
 let declarations='        local syncingColorLists=false\n',methods='';
 for(const s of specs){
  const id=s.id+'_colored';
  declarations+=`        dotNetControl ${id} "System.Windows.Forms.ListBox" pos:[6,6] width:100 height:100\n`;
  declarations+=`        local ${id}_configured=false,${id}_colors=#(),${id}_scale=1.0,${id}_layoutVisible=false\n`;
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
            local action=CyrusBeginAction root "${id}.selection"
            try (
            ${s.multi?`local indices=#{},newFocus=0;for i=0 to view.SelectedIndices.Count-1 do (local row=view.SelectedIndices.Item[i]+1;indices[row]=true;if not ${s.id}.selection[row] do newFocus=row);${s.id}.selection=indices`:`${s.id}.selection=view.SelectedIndex+1`}
            ${s.select}
            if controlsReady and root!=undefined do layout()
            CyrusEndAction action
            )catch(CyrusEndAction action;throw())
        )
        on ${id} DrawItem view args do if controlsReady and root!=undefined and args.Index>=0 and args.Index<view.Items.Count do (
            args.DrawBackground()
            local shade=if args.Index<${id}_colors.count then ${id}_colors[args.Index+1] else (color 100 100 100),rectangle=args.Bounds
            local ink=dotNetObject "System.Drawing.SolidBrush" ((dotNetClass "System.Drawing.Color").FromArgb (shade.r as integer) (shade.g as integer) (shade.b as integer))
            local inset=(ceil (3*${id}_scale)) as integer,swatch=(ceil (10*${id}_scale)) as integer
            args.Graphics.FillRectangle ink (rectangle.X+inset) (rectangle.Y+inset) swatch (amax 1 (rectangle.Height-2*inset))
            ink.Dispose()
            ${s.name?`local fullText=view.Items.Item[args.Index] as string,fullName=${s.name}
            local suffix=substring fullText (fullName.count+1) -1
            local textRenderer=dotNetClass "System.Windows.Forms.TextRenderer",flags=dotNetClass "System.Windows.Forms.TextFormatFlags"
            local plain=dotNet.combineEnums flags.SingleLine flags.VerticalCenter flags.NoPrefix flags.NoPadding
            local start=rectangle.X+(ceil (17*${id}_scale)),available=amax 1 (rectangle.Right-start-2)
            local suffixWidth=amin available ((textRenderer.MeasureText suffix view.Font (dotNetObject "System.Drawing.Size" 32767 rectangle.Height) plain).Width)
            local nameWidth=amax 0 (available-suffixWidth)
            if nameWidth>0 do textRenderer.DrawText args.Graphics fullName view.Font (dotNetObject "System.Drawing.Rectangle" start rectangle.Y nameWidth rectangle.Height) args.ForeColor (dotNet.combineEnums plain flags.EndEllipsis)
            textRenderer.DrawText args.Graphics suffix view.Font (dotNetObject "System.Drawing.Rectangle" (start+nameWidth) rectangle.Y suffixWidth rectangle.Height) args.ForeColor plain`:`(dotNetClass "System.Windows.Forms.TextRenderer").DrawText args.Graphics (view.Items.Item[args.Index] as string) view.Font (dotNetObject "System.Drawing.Point" (rectangle.X+(ceil (17*${id}_scale))) rectangle.Y) args.ForeColor`}
            args.DrawFocusRectangle()
        )
`;
 }
 methods+=`        fn syncColorLists layoutChanged:false = (
            if syncingColorLists do return false
            local measurement=CyrusMeasureBegin 15,measuredOwner=if owner==undefined then "" else owner.layerID,measuredEpoch=if root==undefined then 0 else root.procEpoch
            syncingColorLists=true
            try (
${specs.map(s=>{const id=s.id+'_colored';return `                -- The native list is always hidden after synchronization. Only
                -- a completed geometry layout supplies new visibility intent.
                if layoutChanged do ${id}_layoutVisible=${s.id}.visible
                setHostedVisible ${id} ${id}_layoutVisible;${id}.enabled=${s.id}.enabled
                if ${id}.pos!=${s.id}.pos do ${id}.pos=${s.id}.pos
                if ${id}.width!=${s.id}.width do ${id}.width=${s.id}.width
                if ${id}.height!=${s.id}.height do ${id}.height=${s.id}.height
                ${s.id}.visible=false
                if not ${id}_configured do (
                ${id}.DrawMode=(dotNetClass "System.Windows.Forms.DrawMode").OwnerDrawFixed
                ${id}.SelectionMode=(dotNetClass "System.Windows.Forms.SelectionMode").${s.multi?(s.toggle?'MultiSimple':'MultiExtended'):'One'}
                ${id}_scale=GetUIScaleFactor()
                -- Match the host control's actual font. Multiplying point size
                -- by UI scale again double-scales managed text on some profiles.
                local nativeFont=windows.sendMessage ${s.id}.hwnd[1] 0x0031 0 0
                if nativeFont!=0 do ${id}.Font=(dotNetClass "System.Drawing.Font").FromHfont (dotNetObject "System.IntPtr" nativeFont)
                ${id}.IntegralHeight=false;${id}.ItemHeight=amax ((ceil (16*${id}_scale)) as integer) (${id}.Font.Height+((ceil (4*${id}_scale)) as integer))
                ${id}.BackColor=(dotNetClass "System.Drawing.Color").FromArgb 65 65 65
                ${id}.ForeColor=(dotNetClass "System.Drawing.Color").FromArgb 230 230 230
                ${id}_configured=true
                )
                local itemsChanged=${id}.Items.Count!=${s.id}.items.count
                if not itemsChanged do for i=1 to ${s.id}.items.count where (${id}.Items.Item[i-1] as string)!=${s.id}.items[i] do itemsChanged=true
                if itemsChanged do (
                    ${id}.BeginUpdate()
                    try(${id}.Items.Clear();for value in ${s.id}.items do ${id}.Items.Add value)catch(${id}.EndUpdate();throw())
                    ${id}.EndUpdate()
                )
                local colors=for row=1 to ${s.id}.items.count collect (${s.color.replaceAll('args.Index+1','row')})
                local colorsChanged=colors.count!=${id}_colors.count
                if not colorsChanged do for row=1 to colors.count while not colorsChanged do colorsChanged=colors[row]!=${id}_colors[row]
                if colorsChanged do ${id}_colors=colors
                for i=0 to ${id}.Items.Count-1 do (
                    local selected=${s.multi?`${s.id}.selection[i+1]`:`${s.id}.selection==i+1`}
                    if (${id}.GetSelected i)!=selected do ${id}.SetSelected i selected
                )
                if colorsChanged or itemsChanged do (${s.tip?`${id}_tipRow=-1;`:''}${id}.Invalidate())`;}).join('\n')}
                syncingColorLists=false;CyrusMeasureEnd measurement measuredOwner measuredEpoch "color_lists";true
            )catch(syncingColorLists=false;CyrusMeasureEnd measurement measuredOwner measuredEpoch "color_lists" failed:true;throw())
        )
`;
 return text.replace('        local layout\n','        local layout\n'+declarations)
  .replace('        fn layout = (',methods+'        fn layout = (')
  .replace(/(            \w+\.height=y\+4);true/,'$1;syncColorLists layoutChanged:true;true');
};
