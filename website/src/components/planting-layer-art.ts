/** Deterministic educational garden artwork; does not execute Scatter. */
export type LayerId='trees'|'shrubs'|'meadow'|'ground'
export type ViewMode='garden'|'layers'
export type Visibility=Record<LayerId,boolean>
type PlantType='tree'|'shrub'|'flowers'|'spires'|'grass'
type Vec2=[number,number]
type WorldPoint=[number,number,number?]
type Projection=(x:number,y:number,z?:number)=>Vec2
type LayerSpec={id:LayerId;name:string;role:string;color:string;level:number}
type Plant=Readonly<{id:string;type:PlantType;x:number;y:number;scale:number;z:number;variant:number;layer:LayerId;depth:number}>
const f=(number:number)=>Number(number.toFixed(2));
const rng=(seed:number)=>()=>{let t=seed+=0x6D2B79F5;t=Math.imul(t^t>>>15,t|1);t^=t+Math.imul(t^t>>>7,t|61);return((t^t>>>14)>>>0)/4294967296};
function botanicalSymbols() {
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
        const x=f(Math.cos(angle)*radius*dist),y=f(canopyY+Math.sin(angle)*25*dist);
        symbols+=`<ellipse cx="${x}" cy="${y}" rx="${f(.6+random()*1.5)}" ry=".7" fill="${j%3===0?'#d6d2a3':colors[j%colors.length]}" opacity=".7" transform="rotate(${f(random()*65)} ${x} ${y})"/>`;
      }
      symbols+='</g>';
    });
    symbols+=`<g id="shrub-a"><ellipse cy="2" rx="11" ry="4" fill="#334a2d" opacity=".14"/><ellipse cy="-4" rx="10" ry="8" fill="#7e9362"/><circle cx="-5" cy="-6" r="5.5" fill="#9aaa79"/><circle cx="5" cy="-5" r="6" fill="#738957"/><circle cx="0" cy="-10" r="5" fill="#99a976"/><path d="m-5-6 2-2m4 4 2-2m-3-5 1-1m-7 11 2-1m9-3 1-1" stroke="#c1c49b" stroke-width="1"/></g>`;
    symbols+=`<g id="shrub-b"><ellipse cy="3" rx="12" ry="4" fill="#334a2d" opacity=".12"/><ellipse cy="-3" rx="11" ry="7" fill="#a6aa7b"/><circle cx="-5" cy="-6" r="5" fill="#b7b788"/><circle cx="6" cy="-6" r="5" fill="#8e9b68"/><circle cy="-9" r="5.5" fill="#b8ba89"/><path d="M-5-6h2m5-2h2M1-11h2m3 9h2" stroke="#e0d6b0" stroke-width="1"/></g>`;
    symbols+=`<g id="grass-a"><ellipse cy="2" rx="7" ry="2.5" fill="#627147" opacity=".16"/><path d="M0 1Q-3-8-7-10M1 1Q0-8-2-15M1 1Q4-8 7-12M0 1Q-5-4-8-4M1 1Q6-5 10-4M0 1Q1-10 3-16" fill="none" stroke="#858f5e" stroke-width="1"/><path d="M0 1Q0-7-1-12M0 1Q3-7 6-9M0 1Q-4-4-5-7" fill="none" stroke="#b0af79" stroke-width="1.2"/><ellipse cx="-2" cy="-15" rx="1" ry="2.8" fill="#c3b58a" transform="rotate(-9 -2 -15)"/><ellipse cx="3" cy="-16" rx="1" ry="3" fill="#ccc09a" transform="rotate(9 3 -16)"/></g>`;
    symbols+=`<g id="grass-b"><ellipse cy="2" rx="6" ry="2" fill="#627147" opacity=".15"/><path d="M0 1Q-4-8-7-8M0 1Q1-7 2-13M0 1Q4-5 7-6M0 1Q-1-8-3-11M0 1Q2-10 5-13" fill="none" stroke="#a2a47e" stroke-width="1.5"/><circle cx="-3" cy="-12" r="1.6" fill="#cbc1b7"/><circle cx="2" cy="-14" r="1.8" fill="#cfc5b9"/><circle cx="5" cy="-13" r="1.3" fill="#cbc1b7"/></g>`;
    return symbols;
  }

function extraSymbols(){return `<g id="rock"><ellipse cy="3" cx="5" rx="14" ry="5" fill="#415037" opacity=".12"/><path d="M-15 0l4-12 10-5 13 6 5 11-11 5-14-1Z" fill="#b6b8a3" stroke="#919883" stroke-width=".5"/><path d="m-11-12 11 4 12-3-13-6Z" fill="#d3d2be"/><path d="m0-8 6 13 11-5-5-11Z" fill="#a6ad97"/><path d="m-15 0 15-8 6 13-14-1Z" fill="#c5c6af"/><path d="m-8-7 6-5m5 1 6 2" stroke="#ebeadc" stroke-width=".8"/></g><g id="flowers"><ellipse cy="3" rx="8" ry="3" fill="#7d8d63" opacity=".14"/><path d="M0 2Q-3-7-5-13M0 2Q4-9 6-16M0 2V-18M0 1Q-7-2-9-8M0 1Q6-3 9-8" fill="none" stroke="#84956a" stroke-width=".75"/><path d="m-2-2-5-2m10-2 5-2m-7-1-4-3" stroke="#a0ae82" stroke-width="1.2"/><g fill="#e9e5cd"><circle cx="-5" cy="-13" r="2.2"/><circle cx="6" cy="-16" r="2"/><circle cy="-18" r="2.5"/><circle cx="-9" cy="-8" r="1.7"/><circle cx="9" cy="-8" r="1.7"/></g><g fill="#c3b57d"><circle cy="-18" r=".7"/><circle cx="6" cy="-16" r=".6"/><circle cx="-5" cy="-13" r=".7"/></g></g><g id="spires"><ellipse cy="2" rx="7" ry="2.5" fill="#6f805d" opacity=".13"/><path d="M0 2-4-21M0 2 4-25M0 2 8-16M0 2-8-14" stroke="#768a65" fill="none" stroke-width=".8"/><g fill="#afa3b2"><ellipse cx="-4" cy="-18" rx="1.4" ry="5.5" transform="rotate(-10 -4 -18)"/><ellipse cx="4" cy="-23" rx="1.4" ry="5.7" transform="rotate(8 4 -23)"/><ellipse cx="8" cy="-15" rx="1.2" ry="4"/><ellipse cx="-8" cy="-12" rx="1.2" ry="3.3"/></g><path d="M0 1Q-6-7-8-6M0 1Q5-7 7-6" stroke="#a0ad83" fill="none" stroke-width="1.1"/></g>`;}
const definitions = `<defs>${botanicalSymbols()}${extraSymbols()}<filter id="ground-shadow" x="-30%" y="-50%" width="180%" height="220%"><feGaussianBlur stdDeviation="8"/></filter></defs>`;

export const botanicalArtworkDefinitions = definitions;

export const layerSpecs:readonly LayerSpec[]=[
 {id:'trees',name:'Trees',role:'Structure & shade',color:'#45674b',level:3},
 {id:'shrubs',name:'Shrubs',role:'Mass & rhythm',color:'#829768',level:2},
 {id:'meadow',name:'Meadow',role:'Color & movement',color:'#b5a17e',level:1},
 {id:'ground',name:'Ground cover',role:'Detail & continuity',color:'#a4b38b',level:0}
];
const planting:Plant[]=[];
function add(type:PlantType,x:number,y:number,scale=1,z=0,variant=0){
 const layer=type==='tree'?'trees':type==='shrub'?(scale>=.9?'shrubs':'ground'):'meadow';
 planting.push(Object.freeze({id:'plant-'+planting.length,type,x,y,scale,z,variant,layer,depth:x+y}));
}
function scatter(count:number,inside:(x:number,y:number)=>boolean,seed=0){
 const r=rng(1991+5*511+seed),occupied:Vec2[]=[];let n=0;
 for(let i=0;i<count*50&&n<count;i++){
  const x=4+r()*102,y=4+r()*102;
  if(!inside(x,y)||occupied.some(q=>(q[0]-x)**2+(q[1]-y)**2<4))continue;
  occupied.push([x,y]);const v=r(),type=v<.24?'shrub':v<.42?'flowers':v<.58?'spires':'grass';
  add(type,x,y,.62+r()*.56,0,Math.floor(r()*3));n++;
 }
}
scatter(275,(x,y)=>((x-59)/39)**2+((y-59)/35)**2>1&&x>3&&x<107&&y>3&&y<107&&!(y>83&&x>74&&x<101));
scatter(42,(x,y)=>((x-59)/22)**2+((y-59)/18)**2<.9,101);
[[13,20,1.42,0],[31,15,1.48,1],[73,13,1.29,2],[94,26,1.2,0],[14,57,1.32,1],[20,91,.95,2],[97,66,.93,1]].forEach(([x,y,s,v])=>add('tree',x,y,s,0,v));
planting.sort((a,b)=>a.depth-b.depth||a.id.localeCompare(b.id));
Object.freeze(planting);
export const allEnabled=():Visibility=>Object.fromEntries(layerSpecs.map(l=>[l.id,true])) as Visibility;
function projection(exploded=false):Projection{return(x:number,y:number,z=0)=>[f((exploded?440:500)+(x-y)*(exploded?2.65:3.25)),f((exploded?180:168)+(x+y)*(exploded?.58:1.5)-z)]}
function geometry(p:Projection){
 const points=(rows:WorldPoint[])=>rows.map(q=>p(...q).join(',')).join(' ');
 const poly=(rows:WorldPoint[],attrs:string)=>`<polygon points="${points(rows)}" ${attrs}/>`;
 const line=(a:WorldPoint,b:WorldPoint,attrs:string)=>`<path d="M${p(...a)}L${p(...b)}" fill="none" ${attrs}/>`;
 const rect=(x:number,y:number,w:number,h:number,z=0):WorldPoint[]=>[[x,y,z],[x+w,y,z],[x+w,y+h,z],[x,y+h,z]];
 const ellipse=(cx:number,cy:number,rx:number,ry:number,z=0):WorldPoint[]=>Array.from({length:65},(_,i)=>{const a=i/64*Math.PI*2;return[cx+Math.cos(a)*rx,cy+Math.sin(a)*ry,z] as WorldPoint});
 const d=(rows:WorldPoint[])=>rows.map((q,i)=>(i?'L':'M')+p(...q)).join(' ');
 return{poly,line,rect,ellipse,d};
}
function fixedGarden(p:Projection,{exploded=false,z=0}={}){
 const g=geometry(p);let s='';
 const top='#c3cdb1';
 s+=g.poly([[0,110,z],[110,110,z],[110,110,z-4],[0,110,z-4]],'fill="#bbc4ae"');
 s+=g.poly([[110,0,z],[110,110,z],[110,110,z-4],[110,0,z-4]],'fill="#aebba2"');
 s+=g.poly(g.rect(0,0,110,110,z),`fill="${top}" stroke="#a5b499" stroke-width=".65"`);
 s+=`<path d="${g.d(g.ellipse(59,59,36,32,z))}Z" fill="#e9e8dc" stroke="#c0c7b0" stroke-width=".65"/><path d="${g.d(g.ellipse(59,59,25,21,z))}Z" fill="#d5dcc5" stroke="#becbab" stroke-width=".65"/>`;
 const walk=g.d([[76,84,z],[84,95,z],[92,110,z]]),width=exploded?21:25;
 s+=`<path d="${walk}" stroke="#c0c5b0" stroke-width="${width+1.3}" fill="none" stroke-linejoin="round"/><path d="${walk}" stroke="#eceadd" stroke-width="${width}" fill="none" stroke-linejoin="round"/>`;
 s+=g.poly(g.rect(56,86,14,3,z+8),'fill="#a2a38b" stroke="#818c76" stroke-width=".65"');
 for(let k=1;k<3;k++)s+=g.line([56,86+k,z+8],[70,86+k,z+8],'stroke="#d3cfb6" stroke-width=".5"');
 s+=g.line([57,86,z+8],[57,86,z+1],'stroke="#737f6d" stroke-width="1.6"')+g.line([69,86,z+8],[69,86,z+1],'stroke="#737f6d" stroke-width="1.6"');
 for(const[x,y,scale]of[[41,55,1.05],[66,69,.75],[35,94,.65]]){const pt=p(x,y,z);s+=`<use href="#rock" transform="translate(${pt}) scale(${scale})"/>`}
 return s;
}
function plantMarkup(q:Plant,p:Projection,z=0){
 const[x,y]=p(q.x,q.y,q.z+z);
 const symbol=q.type==='tree'?'tree-'+['a','b','c'][q.variant%3]:q.type==='shrub'?'shrub-'+(q.variant===1?'b':'a'):q.type==='grass'?'grass-'+(q.variant===2?'b':'a'):q.type;
 const size=q.scale*(q.type==='tree'?1.17:q.type==='shrub'?.95:1.03);
 return `<use class="plant" data-owner="${q.layer}" data-instance="${q.id}" data-world="${f(q.x)},${f(q.y)}" href="#${symbol}" transform="translate(${x} ${y}) scale(${f(size)})"/>`;
}
function gardenView(visible:Visibility){
 const p=projection(),g=geometry(p);let s='';
 for(let n=-20;n<=130;n+=10){s+=g.line([n,-20],[n,130],'stroke="#dce2d4" stroke-width=".55" opacity=".58"');s+=g.line([-20,n],[130,n],'stroke="#dce2d4" stroke-width=".55" opacity=".58"')}
 s+=`<path d="${g.d(g.rect(0,0,110,110,-5))}Z" transform="translate(12 10)" fill="#4f6340" opacity=".12" filter="url(#ground-shadow)"/>`;
 s+=`<g data-fixed="true">${fixedGarden(p)}</g>`;
 s+=planting.filter(q=>visible[q.layer]).map(q=>plantMarkup(q,p)).join('');
 s+=g.line([-3,113],[113,113],'stroke="#9aa98e" stroke-width=".65"')+g.line([-3,111],[-3,115],'stroke="#9aa98e" stroke-width=".65"')+g.line([113,111],[113,115],'stroke="#9aa98e" stroke-width=".65"');
 return `<svg viewBox="50 65 900 560" role="img" aria-label="Complete circular garden, with independently visible planting layers" xmlns="http://www.w3.org/2000/svg">${definitions}${s}</svg>`;
}
function layerView(visible:Visibility){
 const p=projection(true),g=geometry(p);let s='';
 for(const[x,y]of[[0,0],[110,0],[0,110],[110,110]])s+=g.line([x,y,-5],[x,y,354],'stroke="#c1ccba" stroke-dasharray="3 6" stroke-width=".8"');
 for(const layer of [...layerSpecs].reverse()){
  const z=layer.level*118,active=visible[layer.id];
  s+=`<g class="layer-plane" data-plane="${layer.id}">`;
  if(layer.id==='ground')s+=`<g data-fixed="true">${fixedGarden(p,{exploded:true})}</g>`;
  else{
   s+=g.poly(g.rect(0,0,110,110,z),`fill="#edf1e5" fill-opacity="${active?.95:.45}" stroke="${active?'#aebb9e':'#d1d9c7'}" stroke-width=".9"${active?'':' stroke-dasharray="4 4"'}`);
   s+=`<path d="${g.d(g.ellipse(59,59,36,32,z))}Z" fill="none" stroke="#c6cfbb" stroke-width=".65"/><path d="${g.d(g.ellipse(59,59,25,21,z))}Z" fill="none" stroke="#c6cfbb" stroke-width=".65"/>`;
  }
  if(active)s+=planting.filter(q=>q.layer===layer.id).map(q=>plantMarkup(q,p,z)).join('');
  const anchor=p(110,45,z),labelX=780,labelY=anchor[1]-14;
  s+=`<g class="plane-label"><path class="label-leader" d="M${anchor}h24L744 ${labelY}H${labelX-16}" fill="none" stroke="${active?layer.color:'#bdc8b0'}" stroke-width=".8"/><circle cx="${anchor[0]}" cy="${anchor[1]}" r="2.6" fill="${active?layer.color:'#a3ae97'}"/><text x="${labelX}" y="${labelY}" dominant-baseline="middle" fill="${active?'#52694b':'#a3ae97'}" font-family="Segoe UI,Arial,sans-serif" font-size="22">${layer.name}</text></g></g>`;
 }
 return `<svg viewBox="0 -320 1000 680" role="img" aria-label="The same garden separated into four illustrative planting planes: trees, shrubs, meadow and ground cover" xmlns="http://www.w3.org/2000/svg">${definitions}${s}</svg>`;
}


/** Namespace local SVG definitions so separate React instances cannot collide. */
export function renderPlantingStudy(mode:ViewMode,visible:Visibility,prefix:string){
 return (mode==='garden'?gardenView(visible):layerView(visible))
  .replace(/id="([^"]+)"/g,`id="${prefix}-$1"`)
  .replace(/href="#([^"]+)"/g,`href="#${prefix}-$1"`)
  .replace(/url\(#([^)]+)\)/g,`url(#${prefix}-$1)`)
}
