import { useEffect, useId, useMemo, useRef, useState } from 'react'
import { allEnabled, layerSpecs, renderPlantingStudy } from './planting-layer-art'
import type { ViewMode, Visibility } from './planting-layer-art'
import './planting-layer-study.css'

export function PlantingLayerStudy() {
  const id = useId()
  const prefix = `planting-${id.replace(/[^a-zA-Z0-9_-]/g, '')}`
  const artworkId = `${prefix}-artwork`
  const [mode, setMode] = useState<ViewMode>('layers')
  const [visible, setVisible] = useState<Visibility>(allEnabled)
  const [playing, setPlaying] = useState(false)
  const timers = useRef<ReturnType<typeof setTimeout>[]>([])
  const artwork = useMemo(() => renderPlantingStudy(mode, visible, prefix), [mode, visible, prefix])

  useEffect(() => () => timers.current.forEach(clearTimeout), [])

  function stop() {
    timers.current.forEach(clearTimeout)
    timers.current = []
    setPlaying(false)
  }

  function build() {
    if (playing) { stop(); setVisible(allEnabled()); return }
    stop()
    setVisible({ trees: false, shrubs: false, meadow: false, ground: false })
    setPlaying(true)
    ;([...layerSpecs].reverse()).forEach((layer, index) => {
      timers.current.push(setTimeout(() => {
        setVisible(previous => ({ ...previous, [layer.id]: true }))
        if (index === layerSpecs.length - 1) { setPlaying(false); timers.current = [] }
      }, 250 + index * 550))
    })
  }

  return <div className="planting-layer-study" data-mode={mode}>
    <div className="pls-toolbar">
      <div className="pls-view-switch" role="group" aria-label="Planting study view">
        <button type="button" data-view="garden" aria-pressed={mode === 'garden'} aria-controls={artworkId} onClick={() => setMode('garden')}>Garden</button>
        <button type="button" data-view="layers" aria-pressed={mode === 'layers'} aria-controls={artworkId} onClick={() => setMode('layers')}>Layers</button>
      </div>
      <div className="pls-actions">
        <button type="button" data-action="build" aria-controls={artworkId} onClick={build}>
          <svg viewBox="0 0 16 16" width="13" height="13" aria-hidden="true">{playing ? <path d="M4 4h8v8H4z" fill="currentColor" /> : <path d="m5 3 8 5-8 5z" fill="currentColor" />}</svg>
          {playing ? 'Stop' : 'Build up'}
        </button>

      </div>
    </div>
    <div id={artworkId} className="pls-artwork" dangerouslySetInnerHTML={{ __html: artwork }} />
    <div className="pls-caption"><span>One garden. Four planting layers.</span><span>Explanatory planting · not a plugin result</span></div>
    <p className="pls-sr-only" role="status">{mode === 'garden' ? 'Garden' : 'Separated layers'} view. Visible: {layerSpecs.filter(layer => visible[layer.id]).map(layer => layer.name).join(', ') || 'no planting layers'}.</p>
  </div>
}
