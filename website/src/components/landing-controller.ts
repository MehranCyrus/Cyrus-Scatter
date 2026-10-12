// @ts-nocheck
// Faithful supplied explanatory study; DOM ownership is isolated to the React ref and disposed on unmount.
/* Cyrus Scatter — a lightweight art-direction study, not the plugin runtime.
 * No dependencies, analytics, local storage, random network calls, or WebGL.
 * Positions are deterministic. Controls change only this SVG illustration.
 */
export function mountLanding(root: HTMLElement) {
  const abort = new AbortController();
  const disposers = [];
  const frames = new Set();
  const originalDefs = root.querySelector('.svg-library defs').innerHTML;
  const frame = fn => { const id = requestAnimationFrame(() => {frames.delete(id); if (!abort.signal.aborted) fn();}); frames.add(id); return id; };
  const $ = (selector, scope = root) => scope.querySelector(selector);
  const $$ = (selector, scope = root) => Array.from(scope.querySelectorAll(selector));
  const NS = 'http://www.w3.org/2000/svg';
  const motionQuery = window.matchMedia('(prefers-reduced-motion: reduce)');
  const clamp = (value, min, max) => Math.min(max, Math.max(min, value));
  const f = number => Number(number.toFixed(2));
  const rng = seed => () => { let t = seed += 0x6D2B79F5; t = Math.imul(t ^ t >>> 15, t | 1); t ^= t + Math.imul(t ^ t >>> 7, t | 61); return ((t ^ t >>> 14) >>> 0) / 4294967296; };
  const p = (x, y, z = 0) => [f(455 + (x - y) * 3.25), f(69 + (x + y) * 1.55 - z)];
  const coords = points => points.map(q => q.join(',')).join(' ');
  const rectWorld = (x,y,w,h,z=0) => [[x,y],[x+w,y],[x+w,y+h],[x,y+h]].map(q => p(...q,z));
  const polygon = (points, attributes = '') => `<polygon points="${coords(points)}" ${attributes}/>`;
  const line = (a, b, attributes = '') => `<path d="M${a.join(',')}L${b.join(',')}" fill="none" ${attributes}/>`;

  function setupNavigation() {
    const toggle = $('.menu-button');
    const nav = $('#mobile-nav');
    const setMenu = open => { toggle.setAttribute('aria-expanded', String(open)); toggle.setAttribute('aria-label', open ? 'Close navigation' : 'Open navigation'); nav.hidden = !open; };
    toggle.addEventListener('click', () => setMenu(toggle.getAttribute('aria-expanded') !== 'true'), {signal: abort.signal});
    $$('a', nav).forEach(a => a.addEventListener('click', () => setMenu(false), {signal: abort.signal}));
    document.addEventListener('keydown', e => { if(e.key === 'Escape' && !nav.hidden) { setMenu(false); toggle.focus(); } }, {signal: abort.signal});
    window.matchMedia('(min-width: 701px)').addEventListener('change', e => { if(e.matches) setMenu(false); }, {signal: abort.signal});
  }

  // Shared, original botanical symbols. They are diagram geometry, not product assets.
  function installSymbols() {
    const defs = $('.svg-library defs');
    const temp = document.createElementNS(NS, 'g');
    let symbols = `<radialGradient id="leaf-light" cx="35%" cy="25%" r="76%"><stop offset="0" stop-color="#9ca47a"/><stop offset=".58" stop-color="#778b61"/><stop offset="1" stop-color="#476347"/></radialGradient><radialGradient id="leaf-deep" cx="30%" cy="20%" r="85%"><stop offset="0" stop-color="#839777"/><stop offset=".6" stop-color="#526f50"/><stop offset="1" stop-color="#324f3c"/></radialGradient><radialGradient id="leaf-silver" cx="30%" cy="20%" r="80%"><stop offset="0" stop-color="#b2b79a"/><stop offset=".56" stop-color="#939f7a"/><stop offset="1" stop-color="#647b57"/></radialGradient><pattern id="stone-hatch" width="7" height="7" patternUnits="userSpaceOnUse"><path d="M0 7 7 0" stroke="#738065" stroke-width=".4" opacity=".12"/></pattern>`;
    ['a','b','c'].forEach((name, i) => {
      const random = rng(16+i*202);
      const colors = i === 0 ? ['#79936c','#68845d','#95a380','#849b74','#486549'] : i === 1 ? ['#909e6f','#b0b587','#86935f','#a0a673','#6b814f'] : ['#778b6d','#9da990','#6c8264','#b3b99a','#8c9c7d'];
      const radius = i === 1 ? 23 : 28;
      const canopyY = i === 1 ? -53 : -48;
      symbols += `<g id="tree-${name}"><ellipse cx="13" cy="5" rx="29" ry="9" fill="#223321" opacity=".105" transform="rotate(-15 13 5)"/><path d="M0 1Q-2-18 1-38M0-14-15-40M0-17 17-40M0-24 8-49" stroke="#796f51" stroke-width="2.8" stroke-linecap="round" fill="none"/><path d="M1 0Q2-15 2-37" stroke="#a69a70" stroke-width=".85" fill="none"/><ellipse cx="0" cy="${canopyY}" rx="${radius}" ry="${i===1?32:24}" fill="url(#${i===0?'leaf-deep':i===1?'leaf-light':'leaf-silver'})"/>`;
      for(let j=0;j<35;j++){
        const angle=random()*Math.PI*2, dist=Math.sqrt(random());
        const x=Math.cos(angle)*radius*dist, y=canopyY+Math.sin(angle)*(i===1?31:23)*dist;
        symbols+=`<circle cx="${f(x)}" cy="${f(y)}" r="${f(3+random()*5)}" fill="${colors[j%colors.length]}" opacity="${f(.5+random()*.4)}"/>`;
      }
      for(let j=0;j<40;j++){
        const angle=random()*Math.PI*2, dist=Math.sqrt(random());
        symbols+=`<ellipse cx="${f(Math.cos(angle)*radius*dist)}" cy="${f(canopyY+Math.sin(angle)*25*dist)}" rx="${f(.6+random()*1.5)}" ry=".7" fill="${j%3===0?'#d6d2a3':colors[j%colors.length]}" opacity=".7" transform="rotate(${f(random()*65)})"/>`;
      }
      symbols+='</g>';
    });
    symbols+=`<g id="shrub-a"><ellipse cy="2" rx="11" ry="4" fill="#334a2d" opacity=".14"/><ellipse cy="-4" rx="10" ry="8" fill="#7e9362"/><circle cx="-5" cy="-6" r="5.5" fill="#9aaa79"/><circle cx="5" cy="-5" r="6" fill="#738957"/><circle cx="0" cy="-10" r="5" fill="#99a976"/><path d="m-5-6 2-2m4 4 2-2m-3-5 1-1m-7 11 2-1m9-3 1-1" stroke="#c1c49b" stroke-width="1"/></g>`;
    symbols+=`<g id="shrub-b"><ellipse cy="3" rx="12" ry="4" fill="#334a2d" opacity=".12"/><ellipse cy="-3" rx="11" ry="7" fill="#a6aa7b"/><circle cx="-5" cy="-6" r="5" fill="#b7b788"/><circle cx="6" cy="-6" r="5" fill="#8e9b68"/><circle cy="-9" r="5.5" fill="#b8ba89"/><path d="M-5-6h2m5-2h2M1-11h2m3 9h2" stroke="#e0d6b0" stroke-width="1"/></g>`;
    symbols+=`<g id="grass-a"><ellipse cy="2" rx="7" ry="2.5" fill="#627147" opacity=".16"/><path d="M0 1Q-3-8-7-10M1 1Q0-8-2-15M1 1Q4-8 7-12M0 1Q-5-4-8-4M1 1Q6-5 10-4M0 1Q1-10 3-16" fill="none" stroke="#858f5e" stroke-width="1"/><path d="M0 1Q0-7-1-12M0 1Q3-7 6-9M0 1Q-4-4-5-7" fill="none" stroke="#b0af79" stroke-width="1.2"/><ellipse cx="-2" cy="-15" rx="1" ry="2.8" fill="#c3b58a" transform="rotate(-9 -2 -15)"/><ellipse cx="3" cy="-16" rx="1" ry="3" fill="#ccc09a" transform="rotate(9 3 -16)"/></g>`;
    symbols+=`<g id="grass-b"><ellipse cy="2" rx="6" ry="2" fill="#627147" opacity=".15"/><path d="M0 1Q-4-8-7-8M0 1Q1-7 2-13M0 1Q4-5 7-6M0 1Q-1-8-3-11M0 1Q2-10 5-13" fill="none" stroke="#a2a47e" stroke-width="1.5"/><circle cx="-3" cy="-12" r="1.6" fill="#cbc1b7"/><circle cx="2" cy="-14" r="1.8" fill="#cfc5b9"/><circle cx="5" cy="-13" r="1.3" fill="#cbc1b7"/></g>`;
    temp.innerHTML=symbols;
    while(temp.firstChild)defs.appendChild(temp.firstChild);
  }

  const beds = [
    {x:18,y:29,w:36,h:25}, {x:74,y:30,w:28,h:30},
    {x:13,y:73,w:34,h:29}, {x:69,y:78,w:33,h:25}
  ];
  const treePositions = [[26,39],[47,45],[84,43],[96,55],[20,84],[40,96],[80,91],[96,87]];
  function makePool(count, seed, type){
    const random=rng(seed), output=[];
    for(let i=0;i<count;i++){
      const bed=beds[Math.floor(random()*beds.length)];
      const x=bed.x+2+random()*(bed.w-4), y=bed.y+2+random()*(bed.h-4);
      output.push({x,y,key:random(),variant:Math.floor(random()*3),scale:.7+random()*.5,type,id:`${type}-${i}`});
    }
    return output;
  }
  const pool = { canopy:treePositions.map(([x,y],i)=>({x,y,key:i===0?0:(i*.137)%1,variant:i%3,scale:.86+(i%4)*.08,type:'canopy',id:`tree-${i}`})),understory:makePool(96,415,'understory'),ground:makePool(212,318,'ground') };
  const sceneState={stage:3,density:70,variation:1,canopy:true,understory:true,ground:true};
  const steps=[
    ['Start with a place, not a population.','A surface gives the composition its setting. Begin with the architecture and the space between.'],
    ['Decide where the planting belongs.','Define regions around the courtyard. Keep circulation clear and give each area a purpose.'],
    ['See the rhythm before the detail.','Placement points reveal the distribution. Adjust density to find the balance between open and abundant.'],
    ['Build a conversation between layers.','Canopy for structure. Understory for rhythm. Ground cover to bring it together.'],
    ['Let every decision become a place.','The same surface, shaped by your choices. Keep the composition open—or let the planting gather.']
  ];
  function visiblePlants(){
    const rows=[];Object.entries(pool).forEach(([kind,items])=>{if(sceneState[kind])items.forEach(q=>{if(q.key<=sceneState.density/100)rows.push(q);});});
    return rows.sort((a,b)=>(a.x+a.y)-(b.x+b.y)||a.id.localeCompare(b.id));
  }
  function botanical(q,project=p, scaleMultiplier=1){
    const [x,y]=project(q.x,q.y);const v=sceneState.variation?q.variant:0;
    const symbol=q.type==='canopy'?`tree-${['a','b','c'][v]}`:q.type==='understory'?`shrub-${v===1?'b':'a'}`:`grass-${v===2?'b':'a'}`;
    const size=q.type==='canopy'?q.scale:q.type==='understory'?q.scale*.8:q.scale*.68;
    return `<use href="#${symbol}" transform="translate(${x} ${y}) scale(${f(size*scaleMultiplier)})"/>`;
  }
  function building(){
    let s='';
    s+=polygon(rectWorld(7,2,97,19,65),'fill="#d5d5c9" stroke="#9b9f91" stroke-width=".6"');
    s+=polygon([p(104,2,65),p(104,21,65),p(104,21,0),p(104,2,0)],'fill="#b6baad" stroke="#8d9684" stroke-width=".7"');
    s+=polygon([p(7,21,60),p(104,21,60),p(104,21,0),p(7,21,0)],'fill="#c9cbbb" stroke="#929b89" stroke-width=".7"');
    s+=polygon([p(16,21,49),p(90,21,49),p(90,21,6),p(16,21,6)],'fill="#819184" opacity=".79"');
    s+=polygon([p(16,21,49),p(90,21,49),p(90,21,34),p(16,21,34)],'fill="#b2bbaa" opacity=".37"');
    [17,29,41,53,65,77,89].forEach(x=>s+=line(p(x,21,49),p(x,21,6),'stroke="#5d7061" stroke-width="1.15"'));
    s+=line(p(16,21,6),p(90,21,6),'stroke="#727e6b" stroke-width="1.7"');
    s+=polygon([p(7,21,65),p(104,21,65),p(104,21,57),p(7,21,57)],'fill="#ddded0" stroke="#9b9f91" stroke-width=".6"');
    [12,95].forEach(x=>s+=polygon([p(x,21,57),p(x+3,21,57),p(x+3,21,0),p(x,21,0)],'fill="#d8d9ca"'));
    s+=polygon(rectWorld(9,5,93,13,66),'fill="#e2e2d6"');
    s+=line(p(10,7,67),p(100,7,67),'stroke="#efefe6" stroke-width="1"');
    return s;
  }
  function courtyardBase(stage){
    let s=`<ellipse cx="461" cy="349" rx="344" ry="84" fill="#687657" opacity=".055"/>`;
    s+=polygon([p(0,110),p(110,110),p(110,110,-15),p(0,110,-15)],'fill="#bfc3b2"');
    s+=polygon([p(110,0),p(110,110),p(110,110,-15),p(110,0,-15)],'fill="#bdc3b2"');
    s+=polygon(rectWorld(0,0,110,110),`fill="${stage===4?'#dddfcc':'#dddfd2'}" stroke="#a2ac96" stroke-width=".7"`);
    for(let n=0;n<=110;n+=11){s+=line(p(n,0),p(n,110),'stroke="#acb59e" stroke-width=".45" opacity=".5"');s+=line(p(0,n),p(110,n),'stroke="#acb59e" stroke-width=".45" opacity=".5"');}
    s+=polygon(rectWorld(54,21,15,89),'fill="#e6e5d7" stroke="#c2c6b3" stroke-width=".5"');
    s+=polygon(rectWorld(0,59,110,12),'fill="#e6e5d7" stroke="#c2c6b3" stroke-width=".5"');
    beds.forEach((b,i)=>{
      const fill=stage===0?'#d5d8c7':stage===1?['#aab99b','#b8be97','#a5b99b','#b4c3a0'][i]:stage===4?'#bac3a6':'#bbc6ae';
      s+=polygon(rectWorld(b.x,b.y,b.w,b.h),`fill="${fill}" stroke="${stage===1?'#688461':'#a8b299'}" stroke-width="${stage===1?1.35:.7}"`);
      if(stage===4)s+=polygon(rectWorld(b.x+1,b.y+1,b.w-2,b.h-2),'fill="url(#stone-hatch)" opacity=".3"');
      if(stage===1){const [x,y]=p(b.x+b.w/2,b.y+b.h/2);s+=`<text x="${x}" y="${y+4}" text-anchor="middle" fill="#52684b" font-family="Arial,sans-serif" font-size="9" letter-spacing="1.2">REGION 0${i+1}</text>`;}
    });
    // Low edging and benches are part of the fixed scene, not generated sources.
    s+=polygon([p(3,38),p(3,65),p(3,65,12),p(3,38,12)],'fill="#c4c9b8" stroke="#a2ae99" stroke-width=".6"');
    [[54,84,10,2],[78,67,13,2]].forEach(([x,y,w,h])=>{s+=polygon(rectWorld(x,y,w,h,7),'fill="#a7a48a" stroke="#8a9279" stroke-width=".5"');s+=line(p(x+1,y,7),p(x+1,y,1),'stroke="#838c75" stroke-width="1.5"');s+=line(p(x+w-1,y,7),p(x+w-1,y,1),'stroke="#838c75" stroke-width="1.5"');});
    for(let k=0;k<3;k++)s+=polygon(rectWorld(53,106+k*2,17,2,-k*4),'fill="#dedfd1" stroke="#aab19b" stroke-width=".55"');
    s+=building();
    if(stage===0){const [x,y]=p(56,58);s+=`<text x="${x}" y="${y}" fill="#828d77" font-family="Arial,sans-serif" font-size="8" letter-spacing="2" text-anchor="middle">THE SURFACE</text>`;}
    return s;
  }
  let renderFrame=0, playTimer=null, lastRenderedStage=null;
  function requestScene(){ if(renderFrame)return;renderFrame=frame(()=>{renderFrame=0;renderScene();}); }
  function renderScene(){
    const plants=visiblePlants(), stage=sceneState.stage;
    let s=`<svg viewBox="20 -10 855 490" xmlns="${NS}" role="img" aria-labelledby="courtyard-title courtyard-description"><title id="courtyard-title">${['Empty courtyard surface','Courtyard planting boundaries','Courtyard placement points','Layered courtyard planting','Composed courtyard environment'][stage]}</title><desc id="courtyard-description">Fixed-camera workflow illustration. ${plants.length} illustrative placements at ${sceneState.density} percent density. This is not the Cyrus Scatter plugin.</desc>`;
    s+=courtyardBase(stage);
    if(stage===2){plants.forEach(q=>{const[x,y]=p(q.x,q.y);const r=q.type==='canopy'?3.3:q.type==='understory'?2:1.4;s+=`<circle cx="${x}" cy="${y}" r="${r}" fill="${q.type==='canopy'?'#385c40':q.type==='understory'?'#788d5c':'#91a278'}" stroke="#f0f0e3" stroke-width=".4"/>`;});}
    if(stage>=3){s+=`<g class="plant" opacity="${stage===3?.83:1}">`;plants.forEach(q=>s+=botanical(q));s+='</g>';}
    if(stage===3){beds.forEach(b=>s+=polygon(rectWorld(b.x,b.y,b.w,b.h),'fill="none" stroke="#788c66" stroke-width=".7" stroke-dasharray="3 3" opacity=".55"'));}
    if(stage===4){s+=`<path d="M744 341h27v-27" fill="none" stroke="#7c9067" stroke-width=".75"/><text x="773" y="355" text-anchor="end" font-family="Arial,sans-serif" font-size="7" letter-spacing="1.2" fill="#607854">YOUR COMPOSITION</text>`;}
    s+='</svg>';
    $('#courtyard-scene').innerHTML=s;
    if(lastRenderedStage!==null && lastRenderedStage!==stage && !motionQuery.matches) $('#courtyard-scene').animate([{opacity:.65},{opacity:1}],{duration:210,easing:'ease-out'});
    lastRenderedStage=stage;
    $('#scene-count').textContent=stage<2?(stage===0?'One surface. A place to begin.':'4 defined planting regions'):`${plants.length} illustrative ${stage===2?'points':'placements'}`;
    $('#scene-panel').setAttribute('aria-labelledby',`step-${stage}`);
    $$('.workflow-stages [role=tab]').forEach(el=>{const selected=Number(el.dataset.stage)===stage;el.setAttribute('aria-selected',String(selected));el.tabIndex=selected?0:-1;});
    $('#step-number').textContent=`0${stage+1} / 05`;
    $('#step-title').textContent=steps[stage][0];$('#step-copy').textContent=steps[stage][1];
    $('#density-value').value=`${sceneState.density}%`;
    $$('.variation-buttons button').forEach(el=>el.setAttribute('aria-pressed',String(Number(el.dataset.variation)===sceneState.variation)));
  }
  function stopPlayback(){if(playTimer){clearInterval(playTimer);playTimer=null;}$('#play-workflow').setAttribute('aria-pressed','false');$('#play-workflow span').textContent=motionQuery.matches?'Next step':'Walk through';$('#play-workflow').setAttribute('aria-label',motionQuery.matches?'Advance to the next workflow stage':'Play the five workflow stages');}
  function setupWorkflow(){
    $$('.workflow-stages button').forEach(el=>{
      el.addEventListener('click',()=>{stopPlayback();sceneState.stage=Number(el.dataset.stage);renderScene();}, {signal: abort.signal});
      el.addEventListener('keydown',e=>{let next=null;const current=Number(el.dataset.stage);if(e.key==='ArrowRight')next=(current+1)%5;if(e.key==='ArrowLeft')next=(current+4)%5;if(e.key==='Home')next=0;if(e.key==='End')next=4;if(next!==null){e.preventDefault();stopPlayback();sceneState.stage=next;renderScene();$(`#step-${next}`).focus();}}, {signal: abort.signal});
    });
    ['canopy','understory','ground'].forEach(kind=>{$(`#layer-${kind}`).addEventListener('change',e=>{stopPlayback();sceneState[kind]=e.target.checked;if(sceneState.stage<2)sceneState.stage=3;requestScene();}, {signal: abort.signal});});
    $('#density').addEventListener('input',e=>{stopPlayback();sceneState.density=Number(e.target.value);if(sceneState.stage<2)sceneState.stage=3;$('#density-value').value=`${sceneState.density}%`;requestScene();}, {signal: abort.signal});
    $$('.variation-buttons button').forEach(el=>el.addEventListener('click',()=>{stopPlayback();sceneState.variation=Number(el.dataset.variation);if(sceneState.stage<3)sceneState.stage=3;renderScene();}, {signal: abort.signal}));
    $('#reset-scene').addEventListener('click',()=>{stopPlayback();Object.assign(sceneState,{stage:3,density:70,variation:1,canopy:true,understory:true,ground:true});$('#density').value='70';['canopy','understory','ground'].forEach(kind=>$(`#layer-${kind}`).checked=true);renderScene();}, {signal: abort.signal});
    $('#play-workflow').addEventListener('click',()=>{
      if(motionQuery.matches){sceneState.stage=(sceneState.stage+1)%5;renderScene();return;}
      if(playTimer){stopPlayback();return;}
      sceneState.stage=0;renderScene();$('#play-workflow').setAttribute('aria-pressed','true');$('#play-workflow').setAttribute('aria-label','Pause the workflow');$('#play-workflow span').textContent='Pause walkthrough';
      playTimer=setInterval(()=>{sceneState.stage++;renderScene();if(sceneState.stage===4)stopPlayback();},1850);
    }, {signal: abort.signal});
    document.addEventListener('visibilitychange',()=>{if(document.hidden)stopPlayback();}, {signal: abort.signal});motionQuery.addEventListener('change',stopPlayback, {signal: abort.signal});
    if('IntersectionObserver' in window){const observer=new IntersectionObserver(entries=>{if(!entries[0].isIntersecting)stopPlayback();},{threshold:0});observer.observe($('#workflow'));disposers.push(()=>observer.disconnect());}
    stopPlayback();renderScene();
  }

  function renderExploded(){
    const proj=(x,y,offset)=>[f(400+(x-y)*2.45),f(27+(x+y)*.73+offset)];
    let s=`<svg viewBox="60 -20 685 540" xmlns="${NS}" role="img" aria-labelledby="exploded-title"><title id="exploded-title">An exploded composition: canopy, understory and ground cover occupy separate layers over the same courtyard footprint.</title>`;
    [[0,0],[110,0],[110,110],[0,110]].forEach(([x,y])=>s+=line(proj(x,y,0),proj(x,y,290),'stroke="#a5b299" stroke-width=".6" stroke-dasharray="3 5" opacity=".5"'));
    [['ground',290,'#d4dac7'],['understory',145,'#dce0d1'],['canopy',0,'#e4e7dc']].forEach(([kind,offset,fill])=>{
      const pr=(x,y)=>proj(x,y,offset);
      s+=polygon([[0,0],[110,0],[110,110],[0,110]].map(q=>pr(...q)),`fill="${fill}" fill-opacity=".78" stroke="#95a68a" stroke-width=".7"`);
      beds.forEach(b=>s+=polygon([[b.x,b.y],[b.x+b.w,b.y],[b.x+b.w,b.y+b.h],[b.x,b.y+b.h]].map(q=>pr(...q)),'fill="#becbb0" opacity=".25" stroke="#879d74" stroke-width=".5"'));
      const items=pool[kind].filter(q=>q.key<.6).sort((a,b)=>a.x+a.y-b.x-b.y);
      items.forEach(q=>s+=botanical(q,pr,kind==='canopy'?.87:.66));
      const labelY=offset+101;
      s+=`<path d="M640 ${labelY-20}h43" stroke="#8b9e7f" stroke-width=".6"/><text x="687" y="${labelY-17}" font-family="Arial,sans-serif" font-size="9" fill="#6a7e5d">0${kind==='canopy'?1:kind==='understory'?2:3}</text>`;
    });
    s+='</svg>';$('#exploded-scene').innerHTML=s;
  }

  // A prepared point pool with exact 2D polygon containment / segment distances.
  const planRegions=[[[50,64],[222,48],[273,110],[224,187],[130,193],[65,150]],[[358,54],[523,87],[570,176],[463,218],[335,164]],[[46,246],[206,232],[250,307],[196,408],[60,380]],[[337,263],[456,242],[566,297],[536,408],[344,391],[297,325]]];
  function inside(x,y,poly){let result=false;for(let i=0,j=poly.length-1;i<poly.length;j=i++){const[xi,yi]=poly[i],[xj,yj]=poly[j];if(((yi>y)!==(yj>y))&&(x<(xj-xi)*(y-yi)/(yj-yi)+xi))result=!result;}return result;}
  function edgeDistance(x,y,poly){let best=Infinity;for(let i=0;i<poly.length;i++){const a=poly[i],b=poly[(i+1)%poly.length],dx=b[0]-a[0],dy=b[1]-a[1];const t=clamp(((x-a[0])*dx+(y-a[1])*dy)/(dx*dx+dy*dy),0,1);best=Math.min(best,Math.hypot(x-(a[0]+t*dx),y-(a[1]+t*dy)));}return best;}
  const planRandom=rng(490),planPoints=[];
  for(let i=0;i<940;i++){const x=40+planRandom()*540,y=45+planRandom()*367;for(let j=0;j<planRegions.length;j++){if(inside(x,y,planRegions[j])){planPoints.push({x,y,dist:edgeDistance(x,y,planRegions[j]),r:1.5+planRandom()*1.7,region:j});break;}}}
  function renderBoundary(inset){
    let s=`<svg viewBox="0 20 620 422" xmlns="${NS}" role="img" aria-labelledby="boundary-diagram-title"><title id="boundary-diagram-title">Planting points inside four regions with ${inset} illustrative units of edge clearance. The crossing paths stay open.</title>`;
    s+='<path d="M20 220Q210 191 294 218T600 232M303 28Q278 140 289 220T272 430" stroke="#697961" stroke-width="16" opacity=".13" fill="none"/>';
    planRegions.forEach((region,i)=>{
      s+=polygon(region,`fill="${['#59764b','#75835a','#73815a','#59764b'][i]}" fill-opacity=".25" stroke="#99ad84" stroke-width="1"`);
      region.forEach(([x,y])=>s+=`<path d="M${x-3} ${y}h6m-3-3v6" stroke="#a6b995" stroke-width=".7"/>`);
    });
    const points=planPoints.filter(q=>q.dist>=inset);
    points.forEach(q=>s+=`<circle cx="${f(q.x)}" cy="${f(q.y)}" r="${f(q.r)}" fill="${q.region%2?'#d1d6ab':'#b7c49b'}" opacity=".8"/>`);
    s+='<path d="M288 193v22h37" stroke="#d0d7bd" stroke-width=".6" fill="none"/><text x="331" y="219" fill="#d0d7bd" font-size="8" letter-spacing="1.4" font-family="Arial,sans-serif">KEEP OPEN</text>';
    s+='<path d="M560 365v44h-44" fill="none" stroke="#9aaf87" stroke-width=".6"/><text x="552" y="431" text-anchor="end" fill="#a8b99a" font-size="7" font-family="Arial,sans-serif" letter-spacing="1.1">SPACE IS A DECISION</text>';
    s+='</svg>';$('#boundary-scene').innerHTML=s;$('#boundary-count').textContent=`${points.length} STUDY POINTS`;$('#boundary-value').value=String(inset);
  }
  function setupBoundary(){renderBoundary(6);let queued=false;$('#boundary-inset').addEventListener('input',()=>{if(queued)return;queued=true;frame(()=>{queued=false;renderBoundary(Number($('#boundary-inset').value));});}, {signal: abort.signal});}

  function renderAnalyzer(mode){
    const pr=(x,y,z=0)=>[f(335+(x-y)*2.3),f(72+(x+y)*1.18-z)];
    const elements=[{x:4,y:4,w:46,h:44,z:24},{x:62,y:5,w:39,h:49,z:12},{x:5,y:62,w:42,h:36,z:9},{x:63,y:67,w:40,h:33,z:0}];
    let s=`<svg viewBox="55 8 552 355" xmlns="${NS}" role="img" aria-labelledby="analyzer-diagram-title"><title id="analyzer-diagram-title">Surface analysis illustration showing ${mode} on four pieces of a terraced surface.</title>`;
    elements.forEach((e,i)=>{
      const points=[[e.x,e.y],[e.x+e.w,e.y],[e.x+e.w,e.y+e.h],[e.x,e.y+e.h]].map(q=>pr(...q,e.z));
      s+=polygon([points[2],points[3],pr(e.x,e.y+e.h,e.z-7),pr(e.x+e.w,e.y+e.h,e.z-7)],'fill="#bac4ad" stroke="#a0b093" stroke-width=".5"');
      s+=polygon([points[1],points[2],pr(e.x+e.w,e.y+e.h,e.z-7),pr(e.x+e.w,e.y,e.z-7)],'fill="#aebca0" stroke="#98ac8b" stroke-width=".5"');
      s+=polygon(points,`fill="${mode==='elements'?['#a9bf98','#c1caaa','#9eb895','#bac79f'][i]:'#d7dfcd'}" stroke="#9bb18f" stroke-width=".6"`);
      for(let n=1;n<7;n++){let x=e.x+e.w*n/7,y=e.y+e.h*n/7;s+=line(pr(x,e.y,e.z),pr(x,e.y+e.h,e.z),'stroke="#839e76" opacity=".42" stroke-width=".6"');s+=line(pr(e.x,y,e.z),pr(e.x+e.w,y,e.z),'stroke="#839e76" opacity=".42" stroke-width=".6"');}
      if(mode==='boundaries'){s+=polygon(points,'fill="none" stroke="#527545" stroke-width="2"');points.forEach(([x,y])=>s+=`<rect x="${x-2.5}" y="${y-2.5}" width="5" height="5" fill="#f1f1e6" stroke="#527545" stroke-width="1"/>`);}
      if(mode==='guides'){
        const a=pr(e.x+e.w*.2,e.y+e.h*.5,e.z+1), b=pr(e.x+e.w*.8,e.y+e.h*.5,e.z+1);
        s+=line(a,b,'stroke="#678751" stroke-width="2.2" stroke-dasharray="5 3"');
        for(let n=0;n<6;n++){const t=n/5;s+=`<circle cx="${f(a[0]+(b[0]-a[0])*t)}" cy="${f(a[1]+(b[1]-a[1])*t)}" r="3" fill="#4d7040" stroke="#e5ebdc" stroke-width="1"/>`;}
      }
      if(mode==='elements'){const[x,y]=pr(e.x+e.w/2,e.y+e.h/2,e.z+1);s+=`<text x="${x}" y="${y}" text-anchor="middle" font-family="Arial,sans-serif" fill="#425d37" font-size="9" letter-spacing="1">0${i+1}</text>`;}
    });
    const [lx,ly]=pr(100,100);s+=`<path d="M${lx+7} ${ly-6}h35" fill="none" stroke="#809770" stroke-width=".7"/><text x="${lx+48}" y="${ly-3}" font-size="8" fill="#627b55" font-family="Arial,sans-serif" letter-spacing=".7">${mode==='guides'?'GUIDE PATH':mode==='elements'?'ELEMENT 04':'BOUNDARY'}</text>`;
    s+='</svg>';$('#analyzer-scene').innerHTML=s;
    $('#analyzer-description').textContent={elements:'Work with the distinct parts that make up a surface.',boundaries:'Let the outline of a surface inform the planting.',guides:'Use extracted paths to introduce direction and rhythm.'}[mode];
    $$('.analyzer-tabs button').forEach(el=>el.setAttribute('aria-pressed',String(el.dataset.analysis===mode)));
  }
  function setupAnalyzer(){renderAnalyzer('boundaries');$$('.analyzer-tabs button').forEach(el=>el.addEventListener('click',()=>renderAnalyzer(el.dataset.analysis), {signal: abort.signal}));}

  function setupEdit(){
    let s=`<svg id="edit-svg" viewBox="0 0 600 300" xmlns="${NS}" aria-labelledby="edit-diagram-title edit-help"><title id="edit-diagram-title">Local instance editing illustration. One tree can be moved or rotated without moving its neighbours.</title><ellipse cx="300" cy="231" rx="217" ry="51" fill="#d7ddca"/><path d="M110 219 294 165 517 227 329 280Z" fill="#d7ddcb" stroke="#b1bfa2" stroke-width=".7"/><path d="m270 185 122 36 32-9-122-35Z" fill="#e6e6d7" stroke="#b9c3aa" stroke-width=".6"/>`;
    const random=rng(755);
    const rows=[];for(let i=0;i<42;i++)rows.push({x:130+random()*340,y:184+random()*72,kind:random()>.4?'grass':'shrub',scale:.5+random()*.4});
    rows.sort((a,b)=>a.y-b.y).forEach(q=>s+=`<use href="#${q.kind}-a" transform="translate(${f(q.x)} ${f(q.y)}) scale(${f(q.scale)})"/>`);
    s+='<use href="#tree-c" transform="translate(175 190) scale(1.22)"/><use href="#tree-a" transform="translate(422 207) scale(1.3)"/>';
    s+='<g id="selected-instance" class="selected-tree" role="button" tabindex="0" aria-label="Selected tree. Drag or use arrow keys to move; R to rotate; Home to reset." transform="translate(302 223)"><rect class="selection-bounds" x="-44" y="-108" width="88" height="124" fill="#82956d" fill-opacity=".045" stroke="#537443" stroke-width="1" stroke-dasharray="4 3"/><use id="editable-botanical" href="#tree-b" transform="scale(1.4)"/><g fill="#f0f0e5" stroke="#587b45" stroke-width="1"><rect x="-46.5" y="-110.5" width="5" height="5"/><rect x="41.5" y="-110.5" width="5" height="5"/><rect x="-46.5" y="13.5" width="5" height="5"/><rect x="41.5" y="13.5" width="5" height="5"/></g><path d="M0 14v-22m0 22h29m-29 0-13 11" fill="none" stroke="#718858" stroke-width="1"/><circle cy="14" r="2" fill="#526e3d"/></g>';
    s+='</svg>';$('#edit-scene').innerHTML=s;
    const selected=$('#selected-instance'),svg=$('#edit-svg');let state={x:302,y:223,rotation:0};let drag=null;
    function apply(announce=false){selected.setAttribute('transform',`translate(${f(state.x)} ${f(state.y)})`);$('#editable-botanical').setAttribute('transform',`scale(1.4) rotate(${state.rotation} 0 -35)`);if(announce)$('#edit-status').textContent=`Selected tree moved. Horizontal position ${Math.round(state.x)}, vertical position ${Math.round(state.y)}, rotation ${state.rotation} degrees. Other instances are unchanged.`;}
    function reset(){state={x:302,y:223,rotation:0};apply(true);}
    function point(event){const matrix=svg.getScreenCTM();if(!matrix)return null;return new DOMPoint(event.clientX,event.clientY).matrixTransform(matrix.inverse());}
    selected.addEventListener('pointerdown',e=>{if(e.button!==0)return;const q=point(e);if(!q)return;drag={x:q.x-state.x,y:q.y-state.y,id:e.pointerId};selected.setPointerCapture(e.pointerId);selected.focus({preventScroll:true});e.preventDefault();}, {signal: abort.signal});
    selected.addEventListener('pointermove',e=>{if(!drag||e.pointerId!==drag.id)return;const q=point(e);if(!q)return;state.x=clamp(q.x-drag.x,225,375);state.y=clamp(q.y-drag.y,170,252);apply();}, {signal: abort.signal});
    const endDrag=e=>{if(drag&&e.pointerId===drag.id){drag=null;apply(true);}};
    selected.addEventListener('pointerup',endDrag, {signal: abort.signal});selected.addEventListener('pointercancel',endDrag, {signal: abort.signal});selected.addEventListener('lostpointercapture',()=>{drag=null;}, {signal: abort.signal});
    selected.addEventListener('keydown',e=>{let handled=true;const step=e.shiftKey?15:5;switch(e.key){case'ArrowLeft':state.x-=step;break;case'ArrowRight':state.x+=step;break;case'ArrowUp':state.y-=step;break;case'ArrowDown':state.y+=step;break;case'r':case'R':state.rotation=(state.rotation+15)%360;break;case'Home':reset();break;case'Enter':case' ':state.x=state.x<325?352:275;break;default:handled=false;}if(handled){e.preventDefault();state.x=clamp(state.x,225,375);state.y=clamp(state.y,170,252);apply(true);}}, {signal: abort.signal});
    $('#move-instance').addEventListener('click',()=>{state.x=state.x<325?352:275;apply(true);}, {signal: abort.signal});
    $('#rotate-instance').addEventListener('click',()=>{state.rotation=(state.rotation+15)%360;apply(true);}, {signal: abort.signal});$('#reset-instance').addEventListener('click',reset, {signal: abort.signal});
  }

  function setupGallery(){
    const data=[{src:'./assets/concepts/courtyard-20261011.webp',title:'A quiet courtyard',alt:'Limestone steps and layered planting beside a contemporary pavilion. Generated concept imagery.'},{src:'./assets/concepts/coastal-20261011.webp',title:'A looser rhythm',alt:'A natural coastal landscape with irregular planting and pale stone. Generated concept imagery.'},{src:'./assets/concepts/perennial-20261011.webp',title:'The close-up matters',alt:'Grasses and flowering plants create texture alongside a limestone path. Generated concept imagery.'}];
    const dialog=$('#gallery-dialog');let index=0,opener=null;
    function show(i){index=(i+data.length)%data.length;$('#gallery-dialog-image').src=data[index].src;$('#gallery-dialog-image').alt=data[index].alt;$('#gallery-dialog-title').textContent=data[index].title;$('#gallery-dialog-index').textContent=`0${index+1} / 03`;}
    $$('.gallery-open').forEach(el=>el.addEventListener('click',()=>{opener=el;show(Number(el.dataset.gallery));dialog.showModal();document.body.classList.add('modal-open');$('#close-gallery').focus();}, {signal: abort.signal}));
    function close(){dialog.close();}
    $('#close-gallery').addEventListener('click',close, {signal: abort.signal});$('#next-image').addEventListener('click',()=>show(index+1), {signal: abort.signal});$('#previous-image').addEventListener('click',()=>show(index-1), {signal: abort.signal});
    dialog.addEventListener('close',()=>{document.body.classList.remove('modal-open');if(opener)opener.focus({preventScroll:true});}, {signal: abort.signal});
    dialog.addEventListener('click',e=>{if(e.target!==dialog)return;const r=dialog.getBoundingClientRect();if(e.clientX<r.left||e.clientX>r.right||e.clientY<r.top||e.clientY>r.bottom)close();}, {signal: abort.signal});
    dialog.addEventListener('keydown',e=>{if(e.key==='ArrowRight'){e.preventDefault();show(index+1);}if(e.key==='ArrowLeft'){e.preventDefault();show(index-1);}}, {signal: abort.signal});
  }


  setupNavigation();installSymbols();setupWorkflow();renderExploded();setupBoundary();setupAnalyzer();setupEdit();setupGallery();
  return () => { stopPlayback(); abort.abort(); frames.forEach(cancelAnimationFrame); disposers.forEach(fn=>fn()); root.querySelectorAll('dialog[open]').forEach(d=>d.close()); root.querySelector('.svg-library defs').innerHTML=originalDefs; document.body.classList.remove('modal-open'); };
}
