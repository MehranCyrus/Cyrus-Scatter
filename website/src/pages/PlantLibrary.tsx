import { useEffect, useRef, useState } from 'react'
import { showcasePlants, plantCategories, type ShowcasePlant } from '../content/plantShowcase'
import { currentRelease } from '../content/release'
import '../product-pages.css'

function PlantImage({ plant, eager = false }: { plant: ShowcasePlant; eager?: boolean }) {
  const [failed, setFailed] = useState(false)
  return failed ? <span className="specimen-image-error">Preview unavailable</span> : <img src={plant.image} alt={`${plant.name}, individual Corona model preview`} width="640" height="640" loading={eager ? 'eager' : 'lazy'} onError={() => setFailed(true)}/>
}

export default function PlantLibrary() {
  const [category, setCategory] = useState('All')
  const [selected, setSelected] = useState<ShowcasePlant | null>(null)
  const dialog = useRef<HTMLDialogElement>(null)
  const opener = useRef<HTMLElement | null>(null)
  const visible = showcasePlants.filter(plant => category === 'All' || plant.category === category)
  useEffect(() => {
    if (!selected) return
    const element = dialog.current
    const prior = document.body.style.overflow
    element?.showModal()
    document.body.style.overflow = 'hidden'
    return () => { element?.close(); document.body.style.overflow = prior; opener.current?.focus() }
  }, [selected])
  return <div className="product-page plant-library">
    <header className="product-heading"><p className="product-kicker">THE PLANT LIBRARY / A SELECTED COLLECTION</p><h1>Every landscape starts<br/>with <em>an individual.</em></h1><div className="product-heading-bottom"><p>Canopy, flower, blade and fallen leaf. Explore twelve specimens from the {currentRelease.models}-model library, ready to become part of your own composition.</p><span className="specimen-edition">12 SPECIMENS<br/><b>06 BOTANICAL CATEGORIES</b></span></div></header>
    <div className="specimen-toolbar"><div role="group" aria-label="Filter plant categories" className="specimen-filters">{['All', ...plantCategories].map(value => <button key={value} aria-pressed={category === value} onClick={() => setCategory(value)}>{value}</button>)}</div><p aria-live="polite">{String(visible.length).padStart(2, '0')} / 12 shown</p></div>
    <div className="specimen-grid">{visible.map((plant, index) => <figure className="specimen" key={plant.id}><button className="specimen-open" onClick={event => { opener.current = event.currentTarget; setSelected(plant) }} aria-label={`Enlarge ${plant.name}`}><PlantImage plant={plant} eager={index < 3}/><span className="specimen-enlarge" aria-hidden="true">↗</span></button><figcaption><span>{plant.category}</span><h2>{plant.name}</h2><p>Individual model <i aria-hidden="true">/</i> Corona render</p></figcaption></figure>)}</div>
    {!visible.length && <div className="specimen-empty"><h2>No specimens in this selection.</h2><button className="product-link" onClick={() => setCategory('All')}>View all specimens →</button></div>}
    <p className="specimen-note">Actual rendered model previews. These show individual assets; the planting design is yours. This website selection is a showcase, not a separate downloadable plant pack.</p>
    <section className="recipe-story" aria-labelledby="recipe-story-title"><div><p className="product-kicker">FROM SPECIMEN TO COMPOSITION</p><h2 id="recipe-story-title">Choose the ingredients.<br/><em>Keep your recipe.</em></h2><p>A model gives you a source. A recipe keeps your artist-authored scatter setup so you can return to it and build on it.</p><a className="product-link" href="#/guide/artist-guide/complete-planting-recipes">Explore the library workflow ↗</a></div><ol>{[
      ['Browse', 'Find an individual in Plant models. Filter by category and inspect its preview.'],
      ['Bring it into the scene', 'Merge the model, or add it as a source to the selected Scatter layer.'],
      ['Compose in layers', 'Combine your chosen models with surfaces, spacing, boundaries and variation.'],
      ['Save & reuse', 'Save a personal recipe, then load and adapt it for your next composition.'],
    ].map(([title, copy], index) => <li key={title}><span>{String(index + 1).padStart(2, '0')}</span><div><h3>{title}</h3><p>{copy}</p></div></li>)}</ol></section>
    <section className="texture-story"><div><p className="product-kicker">SUPPORTED VIEWPORT APPEARANCE</p><h2>See the leaf.<br/><em>Through the viewport.</em></h2><p>Choose <strong>Textured mesh</strong> in Display mode for supported base color and leaf cutouts. Colored Mesh also keeps supported opacity silhouettes. Refine the composition before your final render.</p><p className="texture-boundary">A practical viewport preview of base color and cutout opacity. Final Corona shading, translucency and per-instance Forest color can differ.</p><a className="product-link" href="#/download">Meet the current build ↗</a></div><figure><img src="./assets/release-evidence/materials-textures-leaves.png" width="1104" height="750" loading="lazy" alt="Actual Max 2027 viewport showing scattered bent leaves with Color Correction and opacity cutouts"/><figcaption>Actual 3ds Max 2027 viewport · Materials / Textures · Color Correction applied</figcaption></figure></section>
    <dialog className="specimen-dialog" ref={dialog} aria-labelledby="specimen-title" onCancel={event => { event.preventDefault(); setSelected(null) }} onClick={event => { if (event.target === event.currentTarget) setSelected(null) }} onClose={() => setSelected(null)}>{selected && <><div className="specimen-dialog-top"><span>{selected.category} / INDIVIDUAL MODEL</span><button autoFocus onClick={() => setSelected(null)} aria-label="Close specimen preview">Close ×</button></div><PlantImage plant={selected} eager/><div className="specimen-dialog-caption"><h2 id="specimen-title">{selected.name}</h2><p>Corona render · Supplied library model</p></div></>}</dialog>
  </div>
}
