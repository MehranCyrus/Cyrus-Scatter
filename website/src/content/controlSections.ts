import layout from '../../../AminScatter/tools/ui/approved-layout-manifest.json'
import { controls } from './index'
import type { Control } from './index'

const guide = '#/guide/artist-guide/'
const descriptions: Record<string, { summary: string; links: [string, string][] }> = {
  managerUI: { summary: 'Create and order layers. Each layer owns its receivers, models, population and rules; its visibility is separate from generation.', links: [['Layer ownership', guide+'start-with-a-layer']] },
  surfacesUI: { summary: 'Assign receiving surfaces to the selected layer. Ordinary scattering supports curved receivers; vector painting has separate projection limits. Advanced global source-container links collect models rather than receiving scatter.', links: [['Receiving surfaces', guide+'surfaces-models-and-optional-containers']] },
  modelsUI: { summary: 'Add models or Point placeholders, set source weights and per-source settings, and choose the layer’s model palette.', links: [['Models & Points', guide+'surfaces-models-and-optional-containers']] },
  containersUI: { summary: 'Collect source models from rectangles. Collection starts disabled; pivot membership and saved per-source settings are distinct.', links: [['Source containers', guide+'surfaces-models-and-optional-containers']] },
  layoutUI: { summary: 'Choose Random mix, Clusters, Spline bands or Surface Analyzer assignment. Ordered bands select explicit sources or assignment groups.', links: [['Layout & assignment', '#/guide/layout-falloff/assignment-and-guides'], ['Boundary & street controls', '#/guide/layout-falloff/boundary-and-street-controls']] },
  populationUI: { summary: 'Set Count or Density, seed, masks and bounded retry policy. Requested, accepted and displayed counts can differ.', links: [['Layout & Amount', guide+'layout-and-amount']] },
  coverageUI: { summary: 'Create receiver-bound Paint Areas and draw vector coverage. Areas share the layer’s models; inside/outside fades shape density and scale.', links: [['Vector painting', guide+'vector-painting']] },
  areasUI: { summary: 'Constrain placement with Include and Exclude shapes. Exclude takes precedence; Analyzer masks and per-line falloff have separate settings.', links: [['Masks & falloff', '#/guide/layout-falloff/masks-and-falloff']] },
  transformsUI: { summary: 'Vary rotation, scale and movement per axis, then apply surface alignment and projection settings. Source-specific transforms remain in Models & Points.', links: [['Transforms', guide+'area-limits-transforms-and-spacing']] },
  spacingUI: { summary: 'Configure independent within-layer and between-layer clearance, instance radii, candidate Relax and accepted-result cleanup.', links: [['Spacing & cleanup', guide+'area-limits-transforms-and-spacing'], ['CS Edit distinctions', '#/guide/layout-falloff/edit-and-preview-distinctions']] },
  displayUI: { summary: 'Choose the preview representation, display budgets and output actions. Display limits do not change the accepted population. Multiple Scatters applies the chosen property to selected or all setups; explicit Update applies pending Manual changes.', links: [['Preview & output', guide+'preview-updates-output-and-diagnostics'], ['Selection & shared controls', guide+'select-instances-and-multiple-setups']] },
  statisticsUI: { summary: 'Read the last completed result and diagnostic recording. Cached reads do not calculate pending Manual edits.', links: [['Statistics & diagnostics', guide+'preview-updates-output-and-diagnostics']] },
  interactionsUI: { summary: 'Prepare each source once, then choose Bend, Trim or Bend and trim. Trunk bend, Fixed base and Bend fade shape the flexible region. Detailed contact (slow) and neighboring-tree adaptation remain optional.', links: [['Plant response', guide+'plants-that-respond-to-nearby-objects'], ['Tree colliders', guide+'lightweight-tree-colliders'], ['Shared assets', guide+'shared-models-recipes-and-textures']] },
  collidersUI: { summary: 'Enroll ordinary scene walls and stones for this Scatter setup. Keep them where they are and move or scale them with normal Max tools; no collider scatter layer is required.', links: [['Scene collider workflow', guide+'plants-that-respond-to-nearby-objects'], ['Closed geometry and proxies', guide+'lightweight-tree-colliders']] },
}
const ids: Record<string,string> = {managerUI:'layers',surfacesUI:'surfaces',modelsUI:'models',containersUI:'containers',layoutUI:'layout',populationUI:'amount',coverageUI:'painting',areasUI:'areas',transformsUI:'transforms',spacingUI:'spacing',displayUI:'viewport',statisticsUI:'statistics',interactionsUI:'interactions',collidersUI:'scene-colliders'}
const componentPrefix: Record<string, string> = {
  flow_layersUI: 'general.manager', flow_surfaceUI: 'general.surface',
  flow_previewUI: 'general.previewUI', diagnosticsUI: 'general.diagnostics',
}

// The approved presentation manifest supplies section order and exact control ownership.
export const controlSections = layout.sections.map((section, index) => ({
  id: ids[section.name], title: section.title, number: String(index+1).padStart(2,'0'),
  sourceName: section.name, ...descriptions[section.name],
  keys: section.controls.map(c => `${componentPrefix[c.component] || 'layer.'+c.component}.${c.control}`),
}))
const assignment = new Map(controlSections.flatMap(s => s.keys.map(key => [key, s.id] as const)))
export const controlSectionId = (control: Control) => control.group === 'container' ? 'containers' : assignment.get(control.sourceKey)
export const controlsInSection = (id: string) => controls.filter(c => controlSectionId(c) === id)
export const orderedControls = [...controls].sort((a,b) => {
  const rank = (c: Control) => c.section === 'host' || c.section === 'updateUI' ? -1 : c.section === 'editor' ? 99 : controlSections.findIndex(s => s.id === controlSectionId(c))
  const difference = rank(a) - rank(b)
  if (difference) return difference
  const section = controlSections.find(s=>s.id===controlSectionId(a))
  const position = (c: Control) => { const index=section?.keys.indexOf(c.sourceKey) ?? -1; return index<0?999:index }
  return position(a)-position(b)
})
