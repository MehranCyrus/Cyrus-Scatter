import type { Project, Vec3, Quat, Asset } from '../core/model';
import type { FramePreset } from '../render/framing';
export type Mode = 'explore' | 'plan' | 'playback' | 'preview';
export type NavigationMode = 'orbit' | 'camera';
export interface ViewState {
  project: Project; time: number; duration: number; mode: Mode; playing: boolean;
  selectedLayer: string | null; selectedStop: string | null; selectedInstance: string | null;
  pending: boolean; status: string; error: string | null; storageStatus: string;
  canUndo: boolean; canRedo: boolean;
  stats: { renders: number; rebuilds: number; uploads: number; calls: number; triangles: number; gpuBytes: number };
  replacement: null | { asset: Asset; instanceId: string; suggestions: Record<string, string>; previousNames: Record<string, string> };
  photoStale: boolean; reducedMotion: boolean;
  framing: 'auto' | 'landscape' | 'portrait';
  framePreset: FramePreset; safeFrame: boolean; effectiveFrameAspect: number | null;
  navigationMode: NavigationMode; cameraSpeed: number; cameraFov: number; cameraEditingStopId: string | null;
  cameraSession: 'new' | 'edit';
  cameraImport: null | { name: string; duration: number; sampleCount: number; fps: number; aspect: number };
}
export interface StudioActions { act(name: string, payload?: any): void; }
export interface StudioView {
  viewport: HTMLElement;
  preview: HTMLIFrameElement;
  update(state: ViewState): void;
  dispose(): void;
}
export type CameraPose = { position: Vec3; quaternion: Quat; fov: number; aspect?: number };
