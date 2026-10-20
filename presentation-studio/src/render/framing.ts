export const FRAME_PRESETS = [
  { id: 'free', label: 'Viewport · free', aspect: null },
  { id: 'fhd', label: 'FHD · 16:9', aspect: 16 / 9 },
  { id: 'vertical', label: 'Vertical · 9:16', aspect: 9 / 16 },
  { id: 'square', label: 'Square · 1:1', aspect: 1 },
  { id: 'classic', label: 'Classic · 4:3', aspect: 4 / 3 },
  { id: 'cinema', label: 'Cinema · 2.39:1', aspect: 2.39 },
] as const;
export type FramePreset = typeof FRAME_PRESETS[number]['id'];
export function presetAspect(preset: FramePreset): number | null { return FRAME_PRESETS.find(p => p.id === preset)?.aspect ?? null; }
/** Shared top-left CSS-pixel frame used by the renderer and studio safe guides. */
export function fitFrame(width: number, height: number, aspect: number | null) {
  width = Math.max(1, width); height = Math.max(1, height);
  if (!aspect || !Number.isFinite(aspect) || aspect <= 0) return { x: 0, y: 0, width, height };
  const w = Math.min(width, height * aspect), h = Math.min(height, w / aspect);
  return { x: (width - w) / 2, y: (height - h) / 2, width: w, height: h };
}
