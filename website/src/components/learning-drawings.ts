import { botanicalArtworkDefinitions } from './planting-layer-art'

export type LessonId = 'layers' | 'containers' | 'coverage' | 'spacing' | 'updates' | 'viewport'
export type Scope = 'within' | 'layers'
export type LessonState = {
  layers: { count: number; enabled: boolean; visible: boolean }
  containers: { position: number; enabled: boolean }
  coverage: { radius: number; feedback: boolean; rejected: boolean }
  spacing: { scope: Scope; rules: Record<Scope, boolean>; values: Record<Scope, {factor: number; gap: number}> }
  updates: { mode: 'Manual' | 'Live'; requested: number; completed: number; pending: boolean }
  viewport: { budget: number; mode: string; visible: boolean }
}
type Point = { x: number; y: number; id: number }
const n = (x: number) => Number(x.toFixed(2))
const esc = (value: string) => value.replace(/[&<>"']/g, c => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]!))
function random(seed: number) { return () => { seed = (seed * 1664525 + 1013904223) >>> 0; return seed / 4294967296 } }
function points(count: number, x: number, y: number, w: number, h: number, seed: number): Point[] {
  const r = random(seed)
  return Array.from({length: count}, (_, id) => ({id, x: n(x + r() * w), y: n(y + r() * h)}))
}
const text = (x: number, y: number, value: string, size = 12, extra = '') => `<text x="${x}" y="${y}" font-family="Segoe UI,Arial,sans-serif" font-size="${size}" fill="#52694b" ${extra}>${esc(value)}</text>`
const plant = (kind: string, x: number, y: number, scale = 1, attrs = '') => `<use href="#${kind}" transform="translate(${n(x)} ${n(y)}) scale(${scale})" ${attrs}/>`
function svg(body: string, description: string, height = 360) {
  return `<svg viewBox="0 0 620 ${height}" role="img" aria-label="${esc(description)}" xmlns="http://www.w3.org/2000/svg">${botanicalArtworkDefinitions}<defs><pattern id="learning-grid" width="24" height="24" patternUnits="userSpaceOnUse"><path d="M24 0H0V24" fill="none" stroke="#dce3d1" stroke-width=".6"/></pattern></defs><rect width="620" height="${height}" fill="#f1f4ea"/><rect width="620" height="${height}" fill="url(#learning-grid)"/>${body}</svg>`
}
const frame = '<rect x="28" y="52" width="564" height="260" rx="12" fill="#fafbf5" stroke="#c8d3bd"/>'
const midline = Array.from({length:105}, (_, i) => ({x:50+i*5, y:180+Math.sin(i/104*Math.PI*2)*52}))
function centreY(x: number) {
  const at = Math.max(0, Math.min(103, Math.floor((x-50)/5)))
  const t = (x-midline[at].x)/5
  return midline[at].y+(midline[at+1].y-midline[at].y)*t
}
const bandPoints = [...midline.map(p=>`${n(p.x)},${n(p.y-42)}`), ...[...midline].reverse().map(p=>`${n(p.x)},${n(p.y+42)}`)].join(' ')
export function coverageModel(radius: number) {
  const accepted: Point[] = [], rejected: Point[] = [], outside: Point[] = []
  for (const p of points(80, 60, 76, 500, 210, 901)) {
    if (Math.abs(p.y-centreY(p.x))>42) { outside.push(p); continue }
    if (accepted.some(a => Math.hypot(a.x-p.x,a.y-p.y)<radius*2)) rejected.push(p)
    else accepted.push(p)
  }
  return {accepted, rejected, outside}
}
function coverage(s: LessonState['coverage']) {
  const model = coverageModel(s.radius)
  return svg(`${frame}${s.feedback?`<polygon class="coverage-region" points="${bandPoints}" fill="#dce7c9"/>`:''}<polygon points="${bandPoints}" fill="none" stroke="#9db584" stroke-dasharray="4 5" stroke-width=".8"/>${s.rejected?model.outside.map(p=>`<circle class="outside-candidate" cx="${p.x}" cy="${p.y}" r="2" fill="#b7c1ab"/>`).join(''):''}${model.accepted.map(p=>`<g class="accepted-candidate" data-candidate="${p.id}"><circle cx="${p.x}" cy="${p.y}" r="${s.radius}" fill="#b7cda71a" stroke="#88a671" stroke-width=".8"/>${plant(p.id%2?'shrub-a':'flowers',p.x,p.y+6,1.15)}<circle cx="${p.x}" cy="${p.y}" r="1.7" fill="#45674b"/></g>`).join('')}${s.rejected?model.rejected.map(p=>`<path class="rejected-candidate" data-candidate="${p.id}" d="M${p.x-3} ${p.y-3}l6 6m-6 0l6-6" fill="none" stroke="#a58456" stroke-width="1.6"/>`).join(''):''}${text(30,30,'ONE FIXED REGION · 80 FIXED CANDIDATES',11)}${text(30,340,'● Accepted     × Spacing rejection     · Outside the region',11)}`,`${model.accepted.length} accepted, ${model.rejected.length} rejected by spacing and ${model.outside.length} outside coverage. Radius ${s.radius} diagram units.`)
}
function containers(s: LessonState['containers']) {
  const inside=s.position>=160&&s.position<=480, eligible=s.enabled&&inside
  return svg(`${frame}<rect x="160" y="70" width="320" height="222" rx="6" fill="${s.enabled?'#dce7cb':'#edf0e6'}" stroke="#8fa67a" stroke-dasharray="6 5"/>${text(177,95,s.enabled?'COLLECTION ON':'COLLECTION OFF',11)}<path d="M55 205H565" stroke="#b2bfa6" stroke-dasharray="3 5"/>${plant('tree-b',s.position,205,1.5,`class="source-original" opacity="${eligible?1:.55}"`)}<circle class="source-pivot" cx="${s.position}" cy="205" r="4" fill="#fff" stroke="#45674b" stroke-width="1.6"/>${text(s.position,235,'Pivot',11,'text-anchor="middle"')}${text(30,30,'ORIGINAL MODEL · LOCAL RECTANGLE FOOTPRINT',11)}${text(30,340,!s.enabled?'Collection disabled → no collected sources':inside?'Inside → eligible source':'Outside → parked source; settings retained',12)}`,!s.enabled?'Collection is disabled; no models are collected.':inside?'Source pivot inside: eligible source.':'Source pivot outside: parked source.')
}
const layerCandidates = (() => {
  const all=points(4000,65,126,490,150,312)
  return all.filter(p=>((p.x-215)/140)**2+((p.y-210)/64)**2<=1||((p.x-430)/100)**2+((p.y-186)/65)**2<=1).slice(0,400)
})()
function layers(s: LessonState['layers']) {
  const shown = s.enabled&&s.visible?s.count:0
  return svg(`${frame}${text(30,30,'MEADOW LAYER · SHARED MODELS, AMOUNT & RULES',11)}${plant('grass-a',72,96,1.5)}${plant('flowers',107,96,1.5)}${text(136,91,'One model palette',12)}<ellipse cx="215" cy="210" rx="140" ry="64" fill="#dce7cb" stroke="#9bb184" stroke-dasharray="4 4"/><ellipse cx="430" cy="186" rx="100" ry="65" fill="#e5dfc7" fill-opacity=".6" stroke="#b8ab86" stroke-dasharray="4 4"/>${layerCandidates.slice(0,shown).sort((a,b)=>a.y-b.y).map(p=>plant(p.id%3?'grass-a':'flowers',p.x,p.y,.65,`class="layer-plant" data-candidate="${p.id}"`)).join('')}${text(92,293,'Paint Area · Along the path',11)}${text(380,115,'Paint Area · Sunny corner',11)}${text(30,340,`${s.count} requested · ${s.enabled?s.count:0} illustrative placements · ${shown} shown`,12)}`,`Layer recipe requests ${s.count} plants; ${s.enabled?'enabled':'disabled'}, ${s.visible?'visible':'hidden'}. ${shown} shown. Both Paint Areas use the same layer models.`)
}
function spacing(s: LessonState['spacing']) {
  const rule=s.values[s.scope],required=.8*rule.factor+rule.gap,enabled=s.rules[s.scope],conflict=enabled&&required>1.00001
  const marker=70+required/2.6*480, distance=70+1/2.6*480
  return svg(`${frame}${text(30,30,s.scope==='within'?'WITHIN ONE LAYER':'BETWEEN TWO INDEPENDENT LAYERS',11)}<circle cx="210" cy="163" r="75" fill="#dce7cb" stroke="#9bb184"/><circle cx="360" cy="163" r="45" fill="#e8dfc5" stroke="#b7a77d"/>${plant('tree-a',210,202,1.2)}${plant('shrub-b',360,170,2.4)}<path d="M210 73v-8h150v8" fill="none" stroke="#8da27a"/>${text(285,59,'1 m between centres',11,'text-anchor="middle"')}${text(210,256,'Radius 0.5 m',11,'text-anchor="middle"')}${text(360,232,'Radius 0.3 m',11,'text-anchor="middle"')}${conflict?'<path class="spacing-conflict" d="m351 152 18 18m-18 0 18-18" stroke="#a58456" stroke-width="3"/>':''}<path d="M70 291H550" stroke="#d6dfcb" stroke-width="6" stroke-linecap="round"/><path class="clearance-gauge" d="M70 291H${n(marker)}" stroke="${enabled?conflict?'#ad8d62':'#6b8c59':'#c4cdbb'}" stroke-width="6" stroke-linecap="round"/><path d="M${n(distance)} 281v20" stroke="#45674b" stroke-width="1.5"/><circle cx="${n(marker)}" cy="291" r="5" fill="${enabled?'#526f44':'#b8c4ab'}"/>${text(70,334,`Required ${required.toFixed(2)} m · ${!enabled?'rule disabled':conflict?'conflict':'clear'}`,12)}${text(550,334,'Scale 0–2.6 m',10,'text-anchor="end"')}`,`${s.scope} rule: required clearance ${required.toFixed(2)} metres; ${!enabled?'disabled':conflict?'conflict':'clear'}.`)
}
function updates(s: LessonState['updates']) {
  return svg(`${frame}${text(30,30,`Last completed: ${s.completed}`,12)}${text(590,30,`Current request: ${s.requested}`,12,'text-anchor="end"')}${points(s.completed,55,100,510,192,180).sort((a,b)=>a.y-b.y).map(p=>plant(p.id%3?'grass-a':'flowers',p.x,p.y,1,`class="completed-plant" data-candidate="${p.id}"`)).join('')}${text(30,340,s.pending?'Pending edit: the completed planting is retained.':'The completed planting is current.',12)}`,`Completed example: ${s.completed} plants. Current request: ${s.requested}${s.pending?', pending update':''}.`)
}
function viewport(s: LessonState['viewport']) {
  const pts=points(64,45,87,225,210,672)
  const item=(p:Point,shift:number,model=false) => {
    const x=p.x+shift,y=p.y
    if(model||s.mode==='Mesh')return plant(p.id%2?'shrub-a':'grass-a',x,y,.7)
    if(s.mode==='Proxy')return `<path d="M${x-4} ${y-5}h8v10h-8ZM${x-4} ${y-5}l3-3h8l-3 3m3-3v10l-3 3" fill="#e2e9d6" stroke="#81966b" stroke-width=".7"/>`
    if(s.mode==='Point Cloud')return [[0,0],[-3,-3],[3,-3],[-2,3],[2,3]].map(([a,b])=>`<circle cx="${x+a}" cy="${y+b}" r="1" fill="#658446"/>`).join('')
    return `<circle cx="${x}" cy="${y}" r="2" fill="#5b7c45"/>`
  }
  return svg(`<rect x="20" y="52" width="278" height="260" rx="10" fill="#fafbf5" stroke="#c8d3bd"/><rect x="322" y="52" width="278" height="260" rx="10" fill="#e8efdd" stroke="#c8d3bd"/>${text(30,30,'VIEWPORT',11)}${text(334,30,'COMPLETED PLANTING',11)}${s.visible?pts.slice(0,s.budget).map(p=>`<g class="preview-plant" data-candidate="${p.id}">${item(p,0)}</g>`).join(''):text(159,180,'Preview hidden',14,'text-anchor="middle"')}${pts.map(p=>`<g class="accepted-plant" data-candidate="${p.id}">${item(p,302,true)}</g>`).join('')}${text(159,340,`${s.visible?s.budget:0} shown`,12,'text-anchor="middle"')}${text(461,340,'64 accepted model instances',12,'text-anchor="middle"')}`,`Viewport shows ${s.visible?s.budget:0} represented plants. Completed planting retains 64 model instances.`)
}
export function lessonDrawing(id: LessonId, state: LessonState) {
  switch(id){case'layers':return layers(state.layers);case'containers':return containers(state.containers);case'coverage':return coverage(state.coverage);case'spacing':return spacing(state.spacing);case'updates':return updates(state.updates);case'viewport':return viewport(state.viewport)}
}
export function exampleArt(id: string) {
  if(id==='palette')return svg(`<rect x="65" y="50" width="350" height="226" rx="7" fill="#dce7cb" stroke="#8fa67a" stroke-dasharray="6 5"/>${text(84,76,'SOURCE RECTANGLE',11)}${plant('tree-a',155,215,1.6)}${plant('tree-b',300,218,1.35)}${plant('tree-c',505,213,1.5,'opacity=".55"')}${[155,300,505].map(x=>`<circle cx="${x}" cy="215" r="3" fill="#fff" stroke="#52694b"/>`).join('')}${text(225,305,'Collect deliberately',12,'text-anchor="middle"')}${text(505,270,'Parked',12,'text-anchor="middle"')}`,'Two original sources within the rectangle and one parked source outside.',330)
  if(id==='hero-tree')return svg(`<circle cx="275" cy="190" r="101" fill="#dce7cb" stroke="#8fa67a" stroke-dasharray="5 4"/>${plant('tree-a',275,230,1.8)}${[[80,135],[100,270],[480,80],[480,235],[397,280]].map(([x,y],i)=>plant(i%2?'grass-a':'shrub-b',x,y,1.7)).join('')}<path d="M345 160H390L410 130" fill="none" stroke="#8fa67a"/>${text(420,130,'One tree',13,'dominant-baseline="middle"')}${text(420,150,'More clearance',11)}`,'One tree with a larger clearance radius; neighboring planting remains outside it.',330)
  if(id==='border')return svg(`<rect x="65" y="65" width="490" height="205" rx="14" fill="#e4ebd8" stroke="#b2c49e"/><path class="spline-guide" d="M95 235V110Q95 95 110 95H510V235H95Z" fill="none" stroke="#8fa67a" stroke-width="24" stroke-opacity=".18"/><path d="M95 235V110Q95 95 110 95H510V235H95Z" fill="none" stroke="#6f8e58" stroke-dasharray="4 5"/>${Array.from({length:9},(_,i)=>plant('shrub-a',120+i*45,103,1.6)).join('')}${[145,190,235].map(y=>plant('shrub-b',95,y,1.5)).join('')}${text(310,188,'A CLOSED GUIDE · A PER-SIDE WIDTH',11,'text-anchor="middle"')}${text(310,305,'Guide the assignment. Keep the boundary clear.',12,'text-anchor="middle"')}`,'Shrubs assigned along a closed spline guide with a world-space band width.',330)
  const borderPts=points(150,45,65,530,215,55).filter(p=>Math.abs(p.y-centreY(p.x))<32)
  return svg(`<polygon points="${bandPoints}" fill="#dce7cb" stroke="#b5c79f"/>${borderPts.sort((a,b)=>a.y-b.y).map(p=>plant(p.id%3?'spires':'flowers',p.x,p.y,n(.8+.6*(1-Math.abs(p.y-centreY(p.x))/42)),`opacity="${n(.4+.6*(1-Math.abs(p.y-centreY(p.x))/42))}"`)).join('')}${text(30,30,'ONE PAINT AREA · A CONTINUOUS FLOWER BORDER',11)}${text(30,310,'A vector region, with a softer planted edge.',12)}`,'A continuous planted flower border inside one vector region.',330)
}
