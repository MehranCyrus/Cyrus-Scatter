import { useEffect, useRef, useState } from 'react'
import { controls, documents, humanControl, reference } from '../content'
import { Arrow, SearchIcon } from './Icons'
import posterNotes from '../../content/gallery-reading-notes.json'

type Hit = {title: string; context: string; text: string; href: string}
const entries: Hit[] = [
  ...[
    ['First planting workflow','A small scene from layers, surfaces and models through vector painting, spacing and final review.','#/workflow'],
    ['Layers & Paint Areas lesson','See ownership, enabled state and visible representation.','#/visuals/layers'],
    ['Source containers lesson','Collection starts off. Test pivot membership and parked models.','#/visuals/containers'],
    ['Coverage & accepted plants lesson','Compare fixed coverage with simplified radius rejection.','#/visuals/coverage'],
    ['Spacing rules lesson','Independent within-layer and between-layer rules, factor and gap.','#/visuals/spacing'],
    ['Manual & Live lesson','Pending settings and the last completed result.','#/visuals/updates'],
    ['Preview & output lesson','Plant centres, Point Cloud, Proxy and Mesh; shown versus accepted.','#/visuals/viewport'],
    ['Your testing walkthrough','Local checklist, observations and exported notes.','#/checklist'],
    ['Glossary','Layers, receivers, sources, Paint Areas, instances, accepted and shown.','#/glossary'],
  ].map(([title,text,href])=>({title,text,href,context:'Visual guide · artist lesson'})),
  ...Object.values(posterNotes.posters).map(p=>({title:p.title,text:p.note,href:'#/gallery',context:'Concept poster · current reading note'})),
  ...documents.flatMap(doc => doc.search.map(r => ({title:r.title,context:doc.title,text:r.text,href:`#/guide/${doc.id}/${r.anchor}`}))),
  ...reference.changelog.map(e=>({title:`Version ${e.version} · ${e.title}`,context:'Changelog · development history',text:e.changes.map(c=>c.text).join(' '),href:`#/changelog/v${e.version}`})),
  ...controls.map(c => ({title:c.label,context:`Control · ${c.displayOwner} · ${c.section}`,text:`${humanControl(c)} Exact identifier: ${c.name}`,href:`#/controls?id=${c.id}`})),
]
export function SearchDialog({ open, onClose }: {open:boolean; onClose:()=>void}) {
  const dialog = useRef<HTMLDialogElement>(null), input = useRef<HTMLInputElement>(null), previousFocus = useRef<HTMLElement | null>(null)
  const [query, setQuery] = useState(''), [selected, setSelected] = useState(0)
  const words = query.trim().toLowerCase().split(/\s+/).filter(Boolean)
  const found = words.length ? entries.filter(e => words.every(w => `${e.title} ${e.context} ${e.text}`.toLowerCase().includes(w))) : []
  const visible = found.slice(0, 24)
  useEffect(()=>{if(open&&visible[selected])document.getElementById(`search-hit-${selected}`)?.scrollIntoView({block:'nearest'})},[open,selected,query])
  useEffect(() => {
    if (open && !dialog.current?.open) {previousFocus.current = document.activeElement as HTMLElement;setQuery('');setSelected(0);dialog.current?.showModal(); input.current?.focus()}
    if (!open && dialog.current?.open) dialog.current.close()
  }, [open])
  const close = () => {onClose(); previousFocus.current?.focus()}
  return <dialog className="search-dialog selected-search" ref={dialog} aria-labelledby="search-title" onCancel={close} onClose={close} onClick={e => { if (e.target === dialog.current) { const rect=dialog.current!.getBoundingClientRect();if(e.clientX<rect.left||e.clientX>rect.right||e.clientY<rect.top||e.clientY>rect.bottom) close() } }}><div className="search-top"><h2 id="search-title">Find your way.</h2><button className="close-button" onClick={close} aria-label="Close search">×</button></div><div className="search-input"><SearchIcon/><input ref={input} value={query} aria-label="Search all guides, lessons and controls" role="combobox" aria-expanded={open} aria-controls="search-results-list" aria-activedescendant={visible[selected]?`search-hit-${selected}`:undefined} placeholder="Try ‘brush’, ‘spline width’ or ‘Manual’…" onChange={e=>{setQuery(e.target.value);setSelected(0)}} onKeyDown={e=>{if(e.key==='ArrowDown'){e.preventDefault();setSelected(s=>Math.max(0,Math.min(s+1,visible.length-1)))}if(e.key==='ArrowUp'){e.preventDefault();setSelected(s=>Math.max(s-1,0))}if(e.key==='Enter'&&visible[selected]){location.hash=visible[selected].href;close()}}}/></div><div className="search-results" id="search-results-list" role="listbox" aria-label="Search results" aria-live="polite">{!words.length ? <div className="search-empty"><p className="eyebrow">A place to start</p><div className="search-suggestions">{['Vector painting','Include Exclude','Point radius','Manual','MCP'].map(q=><button key={q} onClick={()=>{setQuery(q);setSelected(0);input.current?.focus()}}>{q} <Arrow/></button>)}</div></div> : !found.length ? <div className="search-empty"><h3>No matches yet.</h3><p>Try a shorter phrase, a control name or a feature such as “radius”.</p></div> : <><p className="search-count">{found.length} matches{found.length>24?' · showing the first 24':''}</p>{visible.map((hit,i)=><a key={`${hit.href}-${i}`} id={`search-hit-${i}`} role="option" aria-selected={selected===i} className={selected===i?'search-hit selected':'search-hit'} href={hit.href} onClick={close} onFocus={()=>setSelected(i)}><span className="search-context">{hit.context}</span><strong>{hit.title}</strong><p>{hit.text.slice(0,190)}{hit.text.length>190?'…':''}</p><Arrow/></a>)}</>}</div><div className="search-footer"><span>↑ ↓ Select · Enter Open · Esc Close</span><a href="#/controls" onClick={close}>All controls <Arrow/></a></div></dialog>
}
