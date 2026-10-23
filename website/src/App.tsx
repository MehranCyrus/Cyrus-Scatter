import { useEffect, useState } from 'react'
import { Eyebrow } from './components/Shell'
import { SearchDialog } from './components/Search'
import Features from './pages/Features'
import Guide from './pages/Guide'
import Controls from './pages/Controls'
import Roadmap from './pages/Roadmap'
import About from './pages/About'
import Changelog from './pages/Changelog'
import { Arrow } from './components/Icons'
import SelectedLanding from './components/SelectedLanding'
import { DocsShell } from './components/DocsShell'
import { DocsHome, Workflow, VisualLessons, PosterLibrary, PracticalExamples, ReviewChecklist, Glossary, Troubleshooting } from './pages/Documentation'
import { controlSections } from './content/controlSections'
import PlantLibrary from './pages/PlantLibrary'
import Download from './pages/Download'

export default function App(){
 const [hash,setHash]=useState(location.hash.slice(1)||'/'),[search,setSearch]=useState(false)
 const [path,query='']=hash.split('?'), parts=path.split('/').filter(Boolean)
 useEffect(()=>{const change=()=>setHash(location.hash.slice(1)||'/');window.addEventListener('hashchange',change);window.addEventListener('popstate',change);return()=>{window.removeEventListener('hashchange',change);window.removeEventListener('popstate',change)}},[])
 useEffect(()=>{const key=(e:KeyboardEvent)=>{if((e.ctrlKey||e.metaKey)&&e.key.toLowerCase()==='k'){e.preventDefault();setSearch(s=>!s)}};document.addEventListener('keydown',key);return()=>document.removeEventListener('keydown',key)},[])
 useEffect(()=>{
   const anchor=parts[0]==='guide'?parts[2]:parts[1]
   const selected=parts[0]==='controls'?new URLSearchParams(query).get('id'):null
   requestAnimationFrame(()=>{if(anchor||selected){document.getElementById(selected||anchor)?.scrollIntoView({block:'start'})}else window.scrollTo({top:0,behavior:'instant'})})
   const names:Record<string,string>={home:'Scatter with intention',features:'Features',library:'Plant library',download:'Download',guide:'Visual guide',workflow:'First planting workflow',visuals:'Visual explanations',gallery:'Feature posters',examples:'Practical examples',checklist:'Your testing walkthrough',glossary:'Glossary',troubleshooting:'Troubleshooting & limits',controls:'Control reference',roadmap:'Roadmap',status:'Roadmap',about:'Sources & credits',changelog:'Changelog'}
   const topic=parts[0]==='controls'?controlSections.find(s=>s.id===new URLSearchParams(query).get('topic')):undefined
   document.title=topic?`${topic.title} — Control reference — Cyrus Scatter`:parts[0]?`${names[parts[0]]||'Page not found'} — Cyrus Scatter`:'Cyrus Scatter — Scatter with intention.'
 },[hash])
 let page
 switch(parts[0]){case undefined:case'home':page=<SelectedLanding/>;break;case'features':page=<Features/>;break;case'library':page=<PlantLibrary/>;break;case'download':page=<Download/>;break;case'guide':page=parts[1]?<Guide docId={parts[1]} openSearch={()=>setSearch(true)}/>:<DocsHome/>;break;case'workflow':page=<Workflow/>;break;case'visuals':page=<VisualLessons/>;break;case'gallery':page=<PosterLibrary/>;break;case'examples':page=<PracticalExamples/>;break;case'checklist':page=<ReviewChecklist/>;break;case'glossary':page=<Glossary/>;break;case'troubleshooting':page=<Troubleshooting/>;break;case'controls':page=<Controls params={new URLSearchParams(query)}/>;break;case'roadmap':case'status':page=<Roadmap/>;break;case'about':page=<About/>;break;case'changelog':page=<Changelog key={path}/>;break;default:page=<div className="wrap not-found"><Eyebrow>A different path</Eyebrow><h1>This page hasn’t<br/><em>taken root.</em></h1><p>Return to the overview or find your next step in the guide.</p><a className="button" href="#/guide">Open the field guide <Arrow/></a></div>}
 const landing=!parts[0]||parts[0]==='home'
 return <><a className="skip-link" href="#main" onClick={e=>{e.preventDefault();document.getElementById('main')?.focus()}}>Skip to content</a>{landing?page:<DocsShell route={path} openSearch={()=>setSearch(true)}>{page}</DocsShell>}<SearchDialog open={search} onClose={()=>setSearch(false)}/></>
}
