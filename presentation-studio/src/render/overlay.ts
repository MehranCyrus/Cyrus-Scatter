import type { Project } from '../core/model';
import type { Evaluation } from '../presentation/evaluate';
export class PresentationOverlay {
  private root = document.createElement('div');
  private plan = document.createElement('img');
  private photo = document.createElement('img');
  private label = document.createElement('div');
  private cache = new Map<string, { url: string; ready: Promise<void>; retired: boolean }>();
  private active = '';
  private disposed = false;
  constructor(mount: HTMLElement, private resolve: (hash: string) => Promise<{ bytes: Uint8Array; mime: string }>) {
    this.root.style.cssText = 'position:absolute;inset:0;pointer-events:none;overflow:hidden;z-index:2';
    for (const image of [this.plan, this.photo]) { image.style.cssText = 'position:absolute;inset:0;width:100%;height:100%;object-fit:contain;opacity:0;background:#f4f2e9'; image.alt = ''; image.draggable = false; }
    this.plan.alt = 'Calibrated landscape plan'; this.photo.alt = 'Artist impression';
    this.label.style.cssText = 'position:absolute;bottom:30px;left:50%;transform:translateX(-50%);padding:8px 14px;border-radius:2px;background:#f4f2e9e8;color:#31473b;font:12px system-ui;opacity:0;max-width:80%;text-align:center';
    this.root.append(this.plan, this.photo, this.label); mount.append(this.root);
  }
  private async resource(hash: string): Promise<string> {
    if (!this.cache.has(hash)) {
      const entry = { url: '', ready: Promise.resolve(), retired: false };
      entry.ready = this.resolve(hash).then(async ({ bytes, mime }) => {
        if (this.disposed || entry.retired) throw new Error('Overlay resource released');
        entry.url = URL.createObjectURL(new Blob([bytes as Uint8Array<ArrayBuffer>], { type: mime }));
        const img = new Image(); img.src = entry.url; await img.decode();
        if (this.disposed || entry.retired) throw new Error('Overlay resource released');
      });
      this.cache.set(hash, entry);
    }
    const entry = this.cache.get(hash)!; await entry.ready; return entry.url;
  }
  update(project: Project, evaluation: Evaluation, enabled = true) {
    this.root.hidden = !enabled; if (!enabled) return;
    const planHash = project.plan?.hash;
    if (planHash && evaluation.planOpacity > 0) {
      this.plan.style.opacity = String(evaluation.planOpacity);
      if (this.plan.dataset.hash !== planHash) { this.plan.dataset.hash = planHash; this.resource(planHash).then(url => { if (this.plan.dataset.hash === planHash) this.plan.src = url; }).catch(() => { this.plan.style.opacity = '0'; }); }
    } else this.plan.style.opacity = '0';
    const photo = evaluation.photo; this.active = photo?.hash ?? '';
    if (!photo) { this.photo.style.opacity = '0'; this.label.style.opacity = '0'; }
    else {
      this.photo.style.opacity = this.photo.dataset.hash === photo.hash && this.photo.complete ? String(photo.opacity) : '0';
      this.label.textContent = `Artist impression${photo.caption ? ` · ${photo.caption}` : ''}`; this.label.style.opacity = this.photo.style.opacity;
      this.resource(photo.hash).then(url => {
        if (this.active !== photo.hash || this.disposed) return;
        this.photo.src = url; this.photo.dataset.hash = photo.hash; this.photo.style.opacity = String(photo.opacity); this.label.style.opacity = String(photo.opacity);
      }).catch(() => { if (this.active === photo.hash) { this.photo.style.opacity = '0'; this.label.style.opacity = '0'; } });
    }
    const index = project.stops.findIndex(stop => stop.id === evaluation.stopId);
    const next = index < 0 ? undefined : project.stops.slice(index + 1).find(stop => stop.photo)?.photo;
    const nextHash = evaluation.aspect < 1 && next?.portraitHash ? next.portraitHash : next?.hash;
    if (nextHash) void this.resource(nextHash).catch(() => {});
    const keep = new Set([planHash, photo?.hash, nextHash]);
    for (const [hash, entry] of this.cache) if (!keep.has(hash) && this.cache.size > 3) { entry.retired = true; if (entry.url) URL.revokeObjectURL(entry.url); this.cache.delete(hash); }
  }
  hide() { this.root.hidden = true; this.active = ''; }
  dispose() { this.disposed = true; for (const entry of this.cache.values()) { entry.retired = true; if (entry.url) URL.revokeObjectURL(entry.url); } this.cache.clear(); this.root.remove(); }
}
