// Compose presentation only. The existing component handlers remain the sole
// writers of authored settings; namespacing lets several owners share a page.
const fs=require('fs'), blocks=require('./maxscript-blocks.cjs');
const controlKinds='label|groupBox|button|checkbox|checkbutton|colorpicker|dropdownlist|edittext|listbox|mapbutton|multiListBox|pickbutton|radiobuttons|spinner';
const layouts=require('./approved-layout-rows.cjs');
const identifier=/[A-Za-z_][A-Za-z_0-9]*/g;
function caption(c){
 const label=layouts.labels[c.key+'.'+c.name];
 if(label!==undefined)return label;
 const match=/^\s*\w+ \w+ @?("(?:\\.|[^"\\])*")/.exec(c.declaration||'');
 return match?JSON.parse(match[1]):'';
}
function cellMinimum(c){
 // Group rows only when their complete captions and native fields fit.
 // Max columns are often under 220 px; a universal 300 px breakpoint
 // unnecessarily turned even Add/Copy/Remove into three full-width rows.
 const text=caption(c).length*5.2;
 if(c.kind==='spinner')return caption(c)?text+78:70;
 if(c.kind==='edittext')return text+84;
 if(c.kind==='checkbox')return text+22;
 if(['button','pickbutton','checkbutton','mapbutton'].includes(c.kind))return text+14;
 return 54;
}
function rename(text,names){
 // Do not rename property names, strings, comments or symbols (#property).
 return text.replace(/--[^\n]*|\/\*[\s\S]*?\*\/|"(?:\\.|[^"\\])*"|[A-Za-z_][A-Za-z_0-9]*/g,(token,at)=>{
  if(!identifier.test(token[0])){identifier.lastIndex=0;return token;}
  identifier.lastIndex=0;
  const previous=text.slice(0,at).trimEnd().slice(-1);
  return previous==='.'||previous==='#'||/^\s*:/.test(text.slice(at+token.length))?token:(names.get(token.toLowerCase())||token);
 });
}
function statements(body){
 // Declaration boundaries are at rollout scope, never inside handler bodies.
 const starts=[];let depth=0,string=false,line=false,block=false;
 for(let i=0;i<body.length;i++){
  const c=body[i],n=body[i+1];
  if(line){if(c==='\n')line=false;else continue;}
  if(block){if(c==='*'&&n==='/'){block=false;i++;}continue;}
  if(string){if(c==='\\'){i++;continue;}if(c==='"')string=false;continue;}
  if(c==='-'&&n==='-'){line=true;i++;continue;}
  if(c==='/'&&n==='*'){block=true;i++;continue;}
  if(c==='"'){string=true;continue;}
  if(c==='('||c==='['||c==='{')depth++;
  if(c===')'||c===']'||c==='}')depth--;
  if((i===0||body[i-1]==='\n')&&depth===0){
   const m=/^[ \t]+(local|fn|on|label|groupBox|button|checkbox|checkbutton|colorpicker|dropdownlist|edittext|listbox|mapbutton|multiListBox|pickbutton|radiobuttons|spinner)\b/.exec(body.slice(i));
   if(m)starts.push(i);
  }
 }
 return starts.map((at,i)=>body.slice(at,starts[i+1]??body.length).trimEnd().replace(/^[ \t]+/,'        '));
}
function component(s,key){
 const old=key.startsWith('flow_')||key==='diagnosticsUI'?key:'selected_'+key;
 const [a,b]=blocks.span(s,new RegExp('^    rollout '+old+' "[^"\\n]+"[^\\n]*\\(','m'));
 const source=s.slice(a,b),body=source.slice(source.indexOf('(')+1,-1);
 const parts=statements(body), controls=[],locals=[],handlers=[];
 for(const part of parts){
  const m=new RegExp('^        ('+controlKinds+') (\\w+)\\b').exec(part);
  if(m){controls.push({kind:m[1],name:m[2],declaration:part.split('\n')[0]});continue;}
  if(/^        local\b/.test(part)){locals.push(part);continue;}
  if(new RegExp('^        on '+old+' (?:open|close|rolledUp)\\b').test(part))continue;
  handlers.push(part);
 }
 const names=new Map(),declared=new Set();
 for(const c of controls)names.set(c.name.toLowerCase(),key+'_'+c.name);
 for(const local of locals)for(const m of local.matchAll(/\b(\w+)\s*=/g)){names.set(m[1].toLowerCase(),key+'_'+m[1]);declared.add(m[1].toLowerCase());}
 for(const h of handlers){const m=/^        fn (\w+)/.exec(h);if(m)names.set(m[1].toLowerCase(),key+'_'+m[1]);}
 for(const name of ['root','owner','panel','controlsReady','binding'])if(!names.has(name))names.set(name,key+'_'+name);
 names.set(old.toLowerCase(),'__PAGE__');
 // Old component folds are replaced by the page's Advanced disclosure.
 let code=[...locals,...handlers].join('\n');
 code=code.replaceAll(old+'.controls','#('+controls.map(c=>c.name).join(',')+')');
 code=code.replaceAll(old+'.height',key+'_bodyHeight');
 code=rename(code,names);
 code='        local '+['root','owner','panel','controlsReady','binding'].filter(n=>!declared.has(n)).map(n=>names.get(n)+'='+(n==='controlsReady'||n==='binding'?'false':'undefined')).join(',')+'\n'+code;
 code=code.replace(/^        local \n/,'');
 return {key,old,controls,names,code,hasBind:handlers.some(h=>/^        fn bind\b/.test(h)),setSpecific:/\bsetSpecific=true\b/.test(source)};
}
function page(s,definition,{name=definition.name,category=0,popup=false}={}){
 const components=definition.parts.map(key=>component(s,key));
 const controls=components.flatMap(p=>p.controls.map(c=>({...c,key:p.key,id:p.names.get(c.name.toLowerCase())})));
 const used=new Set(),rows=[];
 const resolve=name=>{
  const c=controls.find(c=>c.key+'.'+c.name===name);if(!c)throw Error('Unknown layout control '+name);
  if(used.has(c.id))throw Error('Duplicate layout control '+name);used.add(c.id);return c;
 };
 for(const name of definition.hidden||[])resolve(name);
 for(const entry of definition.rows){
  if(entry.heading){rows.push({heading:entry.heading,advanced:!!entry.advanced});continue;}
  if(entry.toggle){rows.push({...entry,controls:[{id:entry.toggle,kind:'checkbutton'}]});continue;}
  rows.push({...entry,when:entry.when||(entry.controls.length===1?layouts.conditions[entry.controls[0]]:undefined),controls:entry.controls.map(resolve)});
 }
 // Every existing field is accounted for, including uncommon Analyzer channels.
 for(const p of components){
  const remaining=p.controls.filter(c=>!used.has(p.names.get(c.name.toLowerCase())));
  if(remaining.some(c=>c.name!=='detailsToggle'&&c.name!=='containersToggle'))rows.push({heading:layouts.captions[p.key]||p.key,advanced:!definition.noAdvanced});
  remaining.sort((a,b)=>{
   const y=c=>Number(/pos:\[[^,]+,(\d+)\]/.exec(c.declaration)?.[1]||0);
   return y(a)-y(b);
  });
  for(const c of remaining){
   const full=resolve(p.key+'.'+c.name);
   if(c.name==='detailsToggle'||c.name==='containersToggle')continue;
   rows.push({advanced:!definition.noAdvanced,controls:[full],when:layouts.conditions[p.key+'.'+c.name]});
  }
 }
 // Each list has a view-only grip immediately below it, using the same
 // visibility condition. Native list heights are pixels at runtime.
 const lists=controls.filter(c=>['listbox','multiListBox'].includes(c.kind));
 for(const c of lists){
  const at=rows.findIndex(r=>r.controls?.includes(c));
  if(at>=0)rows.splice(at+1,0,{advanced:rows[at].advanced,when:rows[at].when,height:8,controls:[{id:c.id+'_grip',kind:'dotNetControl'}]});
 }
 let declarations=controls.map(c=>{
  let line=rename(c.declaration,components.find(p=>p.key===c.key).names).replaceAll('__PAGE__',name);
  // Layout is event driven. Remove the old absolute coordinates and widths.
  line=line.replace(/pos:\[[^\]]+\]/,'pos:[8,8]').replace(/width:\([^\n]+?\)(?=\s+(?:height|fieldWidth|tooltip|range|type|scale|modal|notifyAfterAccept|checked|items|columns|labels|color)|$)/,'width:('+name+'.width-16)');
  const row=rows.find(r=>r.controls?.some(item=>item.id===c.id));
  const count=row?.controls.length||1;
  const table=count===3&&row.controls[0].kind==='label';
  const minimum=Math.max(...(row?.controls||[c]).map(cellMinimum));
  const columns=table?count:'(amin '+count+' (amax 1 (floor (('+name+'.width-8)/'+(minimum+4)+'))))';
  line=line.replace(/width:\([^\n]+?\)(?=\s+(?:height|fieldWidth|tooltip|range|type|scale|modal|notifyAfterAccept|checked|items|columns|labels|color|pos)|$)/,'width:(('+name+'.width-16-('+columns+'-1)*4)/'+columns+')');
  line=line.replace(/fieldWidth:\d+/g,'fieldWidth:58');
  if(['button','pickbutton','checkbutton','mapbutton'].includes(c.kind)){
   line=/\bheight:\d+/.test(line)?line.replace(/\bheight:\d+/,'height:22'):line+' height:22';
  }
  const caption=layouts.labels[c.key+'.'+c.name];
  if(caption!==undefined)line=line.replace(/^(        \w+ \w+ )"(?:\\.|[^"\\])*"/,'$1'+JSON.stringify(caption));
  // .pos for a spinner addresses its arrows; edittext and list controls
  // position their fields independently of their captions. Separate labels
  // keep captions inside the reserved row when the host changes columns.
  if(['spinner','edittext','dropdownlist','listbox','multiListBox'].includes(c.kind)){
   const match=/^(        \w+ \w+ )("(?:\\.|[^"\\])*"|@"[^"]*")/.exec(line);
   if(match&&match[2]!=='""'){
    c.captionID=c.id+'_caption';
    c.inlineCaption=['spinner','edittext'].includes(c.kind);
    line=line.replace(match[0],match[1]+'""');
    line+='\n        label '+c.captionID+' '+match[2]+' pos:[6,6] width:('+name+'.width-12) height:18';
   }
   if(table&&c.kind==='spinner')line=line.replace('fieldWidth:58','fieldWidth:42');
  }
  return line;
 }).join('\n');
 const headingRows=rows.filter(r=>r.heading);
 headingRows.forEach((r,i)=>{r.id='heading_'+i;declarations+='\n        label '+r.id+' '+JSON.stringify(r.heading)+' pos:[6,6] width:('+name+'.width-12) height:18';});
 const disclosures=rows.filter(r=>r.toggle);
 for(const r of disclosures)declarations+='\n        checkbutton '+r.toggle+' '+JSON.stringify(r.caption)+' pos:[6,6] width:('+name+'.width-12) height:22';
 for(const c of lists)declarations+='\n        dotNetControl '+c.id+'_grip "System.Windows.Forms.Panel" pos:[6,6] width:100 height:8';
 declarations+='\n        checkbutton advancedToggle "Advanced" pos:[6,6] width:('+name+'.width-12) height:22 tooltip:"Show less-used controls. Expanding this section does not calculate or change saved settings."';
 let code=components.map(p=>'        local '+p.key+'_bodyHeight=0\n'+p.code.replaceAll('__PAGE__',name)).join('\n');
 const reset=components.map(p=>['root','owner','panel','controlsReady','binding'].map(v=>p.key+'_'+v+'='+v).join(';')).join('\n            ');
 const binding=components.map(p=>{
  const ownerRequired=!p.key.startsWith('flow_')&&p.key!=='diagnosticsUI';
  const arr='#('+p.controls.map(c=>p.names.get(c.name.toLowerCase())).join(',')+')';
  const folds=p.controls.filter(c=>c.name==='detailsToggle'||c.name==='containersToggle').map(c=>p.names.get(c.name.toLowerCase())+'.checked=true').join(';');
  const empty=p.key==='setsUI'?'setsUI_setList.items=#();setsUI_members=#();setsUI_nameEdit.text="";':p.key==='detailsUI'?'detailsUI_info.text="Add a layer to inspect its last completed build.";':'';
  return `            ${folds?folds+';':''}${ownerRequired?'if owner!=undefined then (':''}${p.hasBind?p.key+'_bind '+(p.setSpecific?(p.key==='brushUI'?'(root.selectedPaintArea owner)':'(root.selectedPaintSet owner)'):'owner')+';':''}${p.key==='diagnosticsUI'?'diagnosticsUI_refresh();diagnosticsUI_controlsReady=true;':''}${ownerRequired?') else (for c in '+arr+' do c.enabled=false;'+empty+p.key+'_controlsReady=false)':''}`;
 }).join('\n');
 const delegates=[];
 for(const method of ['refreshStats','refreshHistory','status','syncRelaxAvailability','syncFinalRelaxAvailability']){
  const owners=components.filter(p=>p.names.has(method.toLowerCase()));
  if(owners.length)delegates.push('        fn '+method+' = ('+owners.map(p=>'if '+p.key+'_controlsReady do '+p.key+'_'+method+'()').join(';')+(['refreshStats','refreshHistory'].includes(method)?';if controlsReady do layout()':'')+';true)');
 }
 const rowText=rows.map(r=>{
  // Row conditions use fully qualified generated identifiers, intentionally
  // separate from authored scene fields.
  let when=r.when||'true';
  for(const p of components)for(const [a,b] of p.names)when=when.replace(new RegExp('\\b'+p.key+'\\.'+a+'\\b','gi'),b);
  const items=r.heading?[{id:r.id,kind:'label'}]:r.controls;
  const ids=items.map(c=>c.id),vis='('+(!r.advanced?'true':'advancedToggle.checked')+' and ('+when+'))';
  const labels=items.filter(c=>c.kind==='label').map(c=>c.id);
  // Help/status text gets only its wrapped height, not the old fixed 40–80 px
  // reservation. Lists keep their real native field height (not a guessed 112).
  const fitLabels=labels.map(id=>`fitLabel ${id} 18 cellWidth`).join(';');
  const captioned=items.filter(c=>c.captionID),inline=captioned.filter(c=>c.inlineCaption);
  const top=captioned.filter(c=>!c.inlineCaption);
  const minimum=Math.max(...items.map(cellMinimum));
  const heights=items.map(c=>{
   if(c.kind==='label'||c.kind==='listbox'||c.kind==='multiListBox')return c.id+'.height';
   if(c.kind==='radiobuttons'){
    const count=(/labels:#\(([^\n]*?)\)/.exec(c.declaration)?.[1].match(/"(?:\\.|[^"\\])*"/g)||[]).length;
    const columns=Number(/columns:(\d+)/.exec(c.declaration)?.[1]||1);
    return (caption(c)?18:0)+20*Math.ceil(count/columns);
   }
   return c.kind==='checkbox'?20:22;
  });
  const dynamic=r.height||'(amax #('+heights.join(',')+'))';
  const table=items.length===3&&items[0].kind==='label';
  const swatch=items.length===2&&items[1].kind==='colorpicker';
  const columns=r.pair?2:swatch?2:table?items.length:labels.length===items.length?items.length:'(amin rowControls.count (amax 1 (floor ((widthValue-8)/'+(minimum+4)+'))))';
  const captions=captioned.map(c=>`${c.captionID}.visible=show`).join(';');
  const fitCaptions=captioned.map(c=>`fitLabel ${c.captionID} 18 cellWidth`).join(';');
  const captionPositions=captioned.map(c=>{
   const i=items.indexOf(c);
   const base=`6+(mod ${i} columns)*(cellWidth+4)`,cy=`y+(floor (${i}/columns))*rowHeight`;
   const inlineLayout=c.kind==='spinner'
    ? `${c.captionID}.pos=[${base},${cy}+1];${c.captionID}.width=${r.pair?'32':'cellWidth-78'}`
    : `${c.captionID}.pos=[${base},${cy}+1];${c.captionID}.width=amin (cellWidth/2) ${caption(c).length*6+8};${c.id}.pos=[${base}+${c.captionID}.width+4,${cy}];${c.id}.width=cellWidth-${c.captionID}.width-4`;
   const above=`${c.captionID}.pos=[${base},${cy}];${c.captionID}.width=cellWidth`;
   return `${c.inlineCaption?'if not stackedCaption then ('+inlineLayout+') else ('+above+')':above};${c.captionID}.enabled=${c.id}.enabled`;
  }).join(';');
  const reserved=top.length?'(amax #('+top.map(c=>c.captionID+'.height').join(',')+'))':'0';
  const stacked=inline.length?'(amax #('+inline.map(c=>c.captionID+'.height').join(',')+'))':'0';
  const positions=swatch
   ? `rowControls[1].pos=[6,y+captionHeight];fitWidth rowControls[1] cellWidth;rowControls[2].pos=[widthValue-28,y]`
   : table
   ? `rowControls[1].pos=[6,y];rowControls[1].width=18;for i=2 to 3 do (rowControls[i].pos=[28+(i-2)*(cellWidth+4)+cellWidth-12,y];fitWidth rowControls[i] cellWidth)`
   : `for i=1 to rowControls.count do (rowControls[i].pos=[6+(mod (i-1) columns)*(cellWidth+4)+(if classof rowControls[i]==SpinnerControl then cellWidth-12 else 0),y+(floor ((i-1)/columns))*rowHeight+captionHeight];fitWidth rowControls[i] cellWidth)`;
  return `            rowControls=#(${ids.join(',')});show=${vis}\n            for c in rowControls do c.visible=show\n${captions?'            '+captions+'\n':''}            if show do (\n${r.heading?'                if y>6 do y+=4\n':''}                columns=${columns};cellWidth=${swatch?'widthValue-40':table?'(widthValue-38)/2':'(widthValue-12-(columns-1)*4)/columns'}\n${fitLabels?'                '+fitLabels+'\n':''}${fitCaptions?'                '+fitCaptions+'\n':''}                stackedCaption=${!r.pair&&inline.length?'cellWidth<'+minimum:'false'};captionHeight=amax ${reserved} (if stackedCaption then ${stacked} else 0)\n                rowHeight=${dynamic}+2+captionHeight\n                ${positions}\n${r.pair?'                for c in rowControls do fitPairField c cellWidth\n':''}${captionPositions?'                '+captionPositions+'\n':''}                y+=${table||swatch?'rowHeight':'(ceil (rowControls.count as float/columns))*rowHeight'}\n            )`;
 }).join('\n');
 const folded=controls.filter(c=>c.name==='detailsToggle'||c.name==='containersToggle'||(definition.hidden||[]).includes(c.key+'.'+c.name)).map(c=>c.id+'.visible=false').join(';');
 // Insert Advanced between basic rows and advanced rows, never as a page.
 const basicEnd=rows.findIndex(r=>r.advanced);
 const parts=rowText.split(/(?=            rowControls=#)/);
 if(basicEnd<0)parts.push('');
 if(basicEnd>=0)parts.splice(basicEnd,0,`            advancedToggle.visible=true;advancedToggle.pos=[6,y+4];advancedToggle.width=widthValue-12;y+=28\n`);
 else parts.push('\n            advancedToggle.visible=false\n');
 const scope=definition.layerPage?'Layer':'Setup';
 const out=`    rollout ${name} ${JSON.stringify(definition.title)} width:${popup?146:'#cmdPanel'} category:${category} autoLayoutOnResize:false (\n        local root=undefined,owner=undefined,panel=undefined,controlsReady=false,binding=false,obj=undefined,layerPage=${definition.layerPage?'true':'false'},setSpecific=false\n        local layout\n${declarations}\n${code}\n        fn fitLabel control minimum available = (\n            local capacity=amax 1 (floor ((available-4)/5.2)),lines=0\n            for paragraph in filterString control.text "\\n" splitEmptyTokens:true do (\n                local occupied=0;lines+=1\n                for word in filterString paragraph " " do (\n                    local size=word.count+(if occupied==0 then 0 else 1)\n                    if occupied>0 and occupied+size>capacity do (lines+=1;occupied=0;size=word.count)\n                    lines+=floor ((amax 0 (size-1))/capacity);occupied=(mod (amax 0 (size-1)) capacity)+1+occupied\n                )\n            )\n            control.height=amax minimum (lines*14+2);true\n        )\n        fn layout = (\n            local widthValue=amax 140 ${name}.width,y=6,rowControls=#(),show=false,cellWidth=0,columns=1,rowHeight=0,captionHeight=0,stackedCaption=false\n${folded?'            '+folded+'\n':''}${parts.join('')}\n            ${name}.height=y+4;true\n        )\n        fn bind layer = (\n            if root==undefined do return false\n            binding=true;controlsReady=false\n            try (\n                if owner==undefined do (local leaf=root.selectedLayer();if leaf!=undefined do owner=root.logicalParent leaf)\n                obj=owner\n                ${reset}\n${binding}\n                controlsReady=true;binding=false;layout();true\n            )catch(binding=false;controlsReady=false;throw())\n        )\n${delegates.join('\n')}\n        on advancedToggle changed value do layout()\n        on ${name} open do (${popup?'root=CyrusLayerUIRoot;owner=CyrusLayerUIOwner;panel=CyrusLayerUIPanel;bind owner':'panel=this.mainUI;root=undefined;controlsReady=false'})\n        on ${name} close do (controlsReady=false;root=undefined;owner=undefined;obj=undefined;${components.map(p=>p.key+'_controlsReady=false;'+p.key+'_root=undefined;'+p.key+'_owner=undefined'+(p.names.has('obj')?';'+p.key+'_obj=undefined':'')).join(';')})\n        on ${name} rolledUp state do (${popup?'if controlsReady do bind owner':'if panel!=undefined and panel.controlsReady and not panel.binding and not panel.layerBinding do panel.bindSection '+name})\n    )`;
 // Visibility-changing component handlers must re-apply the presentation fold.
 // Bind/sync helpers are also callable directly by Brush callbacks.
 // These two single-window native controls expose no writable width. Their
 // creation width can precede Max's final column allocation, so resize only
 // their own HWND through the documented SDK API during explicit layout.
 const widthHelper=`        fn fitPairField control available = (
            local arrow=windows.getWindowPos control.hwnd[1],fieldWidth=amax 14 (available-46)
            for handle in control.hwnd do (
                local data=windows.getHWNDData handle
                if data[4]=="CustEdit" do (
                    local rectangle=windows.getWindowPos handle,position=windows.screenToClient data[2] (arrow.x-fieldWidth) arrow.y
                    windows.setWindowPos handle position.x position.y fieldWidth rectangle.h true
                )
            )
            true
        )
        fn fitWidth control available = (
            if isProperty control #width then control.width=available
            else if classof control==CheckBoxControl or classof control==PickerControl do for handle in control.hwnd do (
                local rectangle=windows.getWindowPos handle,target=amax 1 (available as integer)
                if rectangle.w!=target do (
                    local data=windows.getHWNDData handle,position=windows.screenToClient data[2] rectangle.x rectangle.y
                    windows.setWindowPos handle position.x position.y target rectangle.h true
                )
            )
            true
        )\n`;
 const remember=popup?'':'if panel!=undefined do panel.rememberViews();';
 const toggles=['advancedToggle',...disclosures.map(r=>r.toggle)];
 const presentation=`        local dragList=undefined,dragGrip=undefined,dragStartY=0,dragStartHeight=0
        fn captureView = #(${name}.open,#(${toggles.map(id=>id+'.checked').join(',')}),#(${lists.map(c=>c.id+'.height').join(',')}))
        fn restoreView state = (
            ${name}.open=state[1]
            ${toggles.map((id,i)=>id+'.checked=state[2]['+(i+1)+']').join(';')}
            ${lists.map((c,i)=>c.id+'.height=state[3]['+(i+1)+']').join(';')}
            true
        )
        fn stopListDrag = (
            local previous=dragGrip
            dragGrip=undefined;dragList=undefined
            if previous!=undefined do previous.Capture=false
            true
        )
        fn gripScreenY sender args = (
            local point=dotNetObject "System.Drawing.Point" args.X args.Y
            (sender.PointToScreen point).Y
        )
        fn beginListDrag sender args target = (
            if not controlsReady or binding or root==undefined or not sender.Visible or not sender.Enabled do return false
            if args.Button!=(dotNetClass "System.Windows.Forms.MouseButtons").Left do return false
            stopListDrag()
            dragStartY=gripScreenY sender args;dragStartHeight=target.height
            dragList=target;dragGrip=sender;sender.Capture=true;true
        )
        fn moveListDrag sender args = (
            if dragGrip!=sender or dragList==undefined or not sender.Capture do return false
            if not controlsReady or binding or root==undefined or not sender.Visible do return stopListDrag()
            local nextHeight=amin 900 (amax 42 (dragStartHeight+(gripScreenY sender args)-dragStartY))
            if nextHeight!=dragList.height do (dragList.height=nextHeight;layout();${remember}true)
            true
        )
        fn paintListGrip sender args = (
            local pen=dotNetObject "System.Drawing.Pen" ((dotNetClass "System.Drawing.Color").FromArgb 135 135 135)
            local center=(sender.ClientSize.Width/2) as integer
            args.Graphics.DrawLine pen (center-10) 3 (center+10) 3
            args.Graphics.DrawLine pen (center-10) 5 (center+10) 5
            pen.Dispose()
        )
        fn setupGrips = (
            for grip in #(${lists.map(c=>c.id+'_grip').join(',')}) do (
                grip.Cursor=(dotNetClass "System.Windows.Forms.Cursors").SizeNS
                grip.BorderStyle=(dotNetClass "System.Windows.Forms.BorderStyle").None
                grip.BackColor=(dotNetClass "System.Drawing.Color").FromArgb 65 65 65
                grip.TabStop=false
            )
            true
        )
${lists.map(c=>`        on ${c.id}_grip MouseDown sender args do beginListDrag sender args ${c.id}
        on ${c.id}_grip MouseMove sender args do moveListDrag sender args
        on ${c.id}_grip MouseUp sender args do (stopListDrag();${remember}true)
        on ${c.id}_grip MouseCaptureChanged sender args do if not sender.Capture and dragGrip==sender do stopListDrag()
        on ${c.id}_grip Paint sender args do paintListGrip sender args`).join('\n')}
`;
 let final=require('./colored-lists.cjs')(out,components).replace('        fn layout = (',presentation+widthHelper+'        fn layout = (').replace('        on advancedToggle changed value do layout()',disclosures.map(r=>'        on '+r.toggle+' changed value do (layout();'+remember+'true)').join('\n')+'\n        on advancedToggle changed value do (layout();'+remember+'true)');
 final=final.replace('            binding=true;controlsReady=false','            stopListDrag();binding=true;controlsReady=false').replace('on '+name+' close do (','on '+name+' close do (stopListDrag();');
 final=final.replace('                controlsReady=true;binding=false;layout();true','                setupGrips();controlsReady=true;binding=false;layout();true');
 if(!popup)final=final.replace('do panel.bindSection '+name,'do (panel.bindSection '+name+';panel.rememberViews())');
 // Max may allocate a scrollbar after the parent layout finishes. Reflow
 // only on a real width change; our own height update must not recurse.
 final=final.replace('        local layout\n','        local layout,lastLayoutWidth=0\n')
  .replace('            '+name+'.height=y+4','            lastLayoutWidth=widthValue;'+name+'.height=y+4')
  .replace('        on '+name+' open do','        on '+name+' resized size do if controlsReady and not binding and (amax 140 '+name+'.width)!=lastLayoutWidth do layout()\n        on '+name+' open do');
 // Each control event has one guarded expression. The action can close the
 // rollout, so its follow-up layout must check the current lifetime again.
 const bodyStart=final.indexOf('(')+1,bodyEnd=final.lastIndexOf(')');
 const eventParts=statements(final.slice(bodyStart,bodyEnd));
 for(const part of eventParts){
  const event=/^        on (\w+) (?!open\b|close\b|rolledUp\b)[^\n]*? do /.exec(part);
  if(!event||event[1]===name||event[1].endsWith('_grip')||event[0].includes(' DrawItem ')||event[0].includes(' SelectedIndexChanged '))continue;
  const expression=part.slice(event[0].length);
  const component=components.find(p=>event[1].startsWith(p.key+'_'));
  const ready=component?component.key+'_controlsReady and not '+component.key+'_binding and ':'';
  final=final.replace(part,event[0]+'if controlsReady and not binding and root!=undefined and '+ready+'true do ('+expression+'\n            if controlsReady and root!=undefined do layout()\n        )');
 }
 return {text:final,components,controls,rows,name,scope};
}
module.exports=function(s,{check=false}={}){
 const definitions=layouts.pages;
 const pages=definitions.map((d,i)=>page(s,d,{category:(i+1)*10}));
 const manifest={schema:'cyrus.ui-layout/1',version:'0.75',source:'approved single-file HTML study',sections:pages.map(p=>({name:p.name,title:definitions.find(d=>d.name===p.name).title,scope:p.scope,controls:p.controls.map(c=>({component:c.key,control:c.name,presentation:c.id,advanced:!!p.rows.find(r=>r.controls?.some(x=>x.id===c.id))?.advanced}))}))};
 const output=JSON.stringify(manifest,null,2)+'\n',path='tools/ui/approved-layout-manifest.json';
 if(check){if(fs.readFileSync(path,'utf8')!==output)throw Error('Layout manifest is stale');}else fs.writeFileSync(path,output);
 // Replace the old native pages as one contiguous UI block, keeping calculation
 // code and scene class identifiers byte-for-byte.
 const [a]=blocks.span(s,/^    rollout mainUI "[^"\n]+"[^\n]*\(/m);
 const [,b]=blocks.span(s,/^    rollout diagnosticsUI "[^"\n]+"[^\n]*\(/m);
 const main=fs.readFileSync('tools/ui/templates/approved-main-ui.ms','utf8').replace(/\r/g,'');
 s=s.slice(0,a)+main+'\n'+pages.map(p=>p.text).join('\n\n')+s.slice(b);
 // Optional floating editors use the exact same composed handlers and rows.
 const popupDefs=[...definitions.filter(d=>['surfacesUI','modelsUI','layoutUI','populationUI','coverageUI','areasUI','transformsUI','spacingUI','statisticsUI'].includes(d.name)),layouts.popupSets];
 const factories=popupDefs.map(d=>`fn CyrusLayerEditor_${d.name}_1 = (\n${page(safeOriginal,d,{name:d.name+'_1',popup:true}).text}\n    ${d.name}_1\n)`);
 const popupStart=s.indexOf('fn CyrusLayerEditor_setsUI_1 = ('),popupEnd=s.indexOf('fn CyrusCreateLayerEditorSection');
 s=s.slice(0,popupStart)+factories.join('\n\n')+'\n'+s.slice(popupEnd);
 const [fa,fb]=blocks.span(s,/^fn CyrusCreateLayerEditorSection\b[^\n]*= \(/m);
 s=s.slice(0,fa)+`fn CyrusCreateLayerEditorSection component root owner panel = (\n    CyrusLayerUIRoot=root;CyrusLayerUIOwner=owner;CyrusLayerUIPanel=panel\n    case component of (\n${popupDefs.map(d=>'        #'+d.name+': CyrusLayerEditor_'+d.name+'_1()').join('\n')}\n        default: throw "Unknown layer UI section."\n    )\n)`+s.slice(fb);
 const sections=/^            pageSections=#\(/m.exec(s);
 if(!sections)throw Error('Missing popup topic layout');
 const sectionsEnd=blocks.close(s,s.indexOf('(',sections.index));
 s=s.slice(0,sections.index)+'            pageSections=#(#(#(#(#modelsUI,false),#(#layoutUI,false)),#(#(#surfacesUI,false))),#(#(#(#populationUI,false)),#(#(#areasUI,false))),#(#(#(#coverageUI,false)),#()),#(#(#(#transformsUI,false)),#()),#(#(#(#spacingUI,false)),#()),#(#(#(#statisticsUI,false)),#()))'+s.slice(sectionsEnd);
 s=s.replace('        fn showTopic index rebind:false = (',`        fn layoutPages index = (
            for p=1 to pages.count do (
                local single=pageSections[p][2].count==0
                pages[p][1].visible=p==index;pages[p][2].visible=p==index and not single
                pages[p][1].width=if single then clientSize.x-16 else (clientSize.x-24)/2
            )
            for r in (activeEditors()) where r.controlsReady do r.layout()
            true
        )
        fn showTopic index rebind:false = (`);
 s=s.replace('            for p=1 to pages.count do for c in pages[p] do c.visible=p==index','            layoutPages index');
 s=s.replace('                layingOut=false\n            )','                layoutPages topic;layingOut=false\n            )');
 return s;
};
let safeOriginal;
const compose=module.exports;
module.exports=(s,args)=>{safeOriginal=s;return compose(s,args);};
module.exports.statements=statements;
module.exports.rename=rename;
