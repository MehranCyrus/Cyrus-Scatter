import content from './reference.json'
export const reference = content
export const documents = content.documents
export const controls = content.controls
export const features = content.features
export type GuideDocument = typeof documents[number]
export type Control = typeof controls[number]
export const asset = (path: string) => `${import.meta.env.BASE_URL}assets/${path}`
export const friendlyGroup: Record<string, string> = {
  general: 'Controller & shared views', layer: 'Layer controls', container: 'Source-container properties', sources: 'Models & sources', population: 'Amount', layout: 'Layout',
  coverage: 'Painting', areas: 'Include / Exclude', transforms: 'Transforms', spacing: 'Spacing & cleanup',
  display: 'Viewport & render', diagnostics: 'Diagnostics', recording: 'Recording',
}
export const groupLabel = (group: string) => friendlyGroup[group] || group.replace(/[_-]/g, ' ').replace(/^./, s => s.toUpperCase())
export const humanControl = (control: Control) => control.description
