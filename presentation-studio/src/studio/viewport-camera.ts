import { Euler, Vector3 } from 'three';
import type { RenderHost } from '../render/host';

/** Focus-scoped camera flight. Uncommitted viewport motion never edits the project. */
export class ViewportCamera {
  enabled = false;
  speed = 3;
  private keys = new Set<string>();
  private pointer: { id: number; x: number; y: number; pan: boolean } | null = null;
  private raf = 0;
  private last = 0;
  private euler = new Euler(0, 0, 0, 'YXZ');
  private movement = new Set(['KeyW', 'KeyA', 'KeyS', 'KeyD', 'KeyQ', 'KeyE', 'ArrowUp', 'ArrowDown', 'ArrowLeft', 'ArrowRight']);
  constructor(private host: RenderHost) {
    host.canvas.tabIndex = 0;
    host.canvas.addEventListener('keydown', this.keyDown);
    host.canvas.addEventListener('blur', this.stop);
    host.canvas.addEventListener('pointerdown', this.pointerDown);
    host.canvas.addEventListener('pointermove', this.pointerMove);
    host.canvas.addEventListener('pointerup', this.pointerUp);
    host.canvas.addEventListener('pointercancel', this.pointerUp);
    host.canvas.addEventListener('lostpointercapture', this.pointerUp);
    host.canvas.addEventListener('wheel', this.wheel, { passive: false });
    host.canvas.addEventListener('contextmenu', this.contextMenu);
    window.addEventListener('keyup', this.keyUp);
    window.addEventListener('blur', this.stop);
    document.addEventListener('visibilitychange', this.visibility);
  }
  setEnabled(value: boolean) { if (value === this.enabled) return; this.enabled = value; if (!value) this.stop(); }
  stop = () => {
    this.keys.clear(); cancelAnimationFrame(this.raf); this.raf = 0;
    const pointer = this.pointer; this.pointer = null;
    if (pointer && this.host.canvas.hasPointerCapture(pointer.id)) this.host.canvas.releasePointerCapture(pointer.id);
  };
  private visibility = () => { if (document.hidden) this.stop(); };
  private contextMenu = (event: MouseEvent) => { if (this.enabled) event.preventDefault(); };
  private keyDown = (event: KeyboardEvent) => {
    if (!this.enabled || event.ctrlKey || event.altKey || event.metaKey) return;
    if (event.code === 'Escape') { this.stop(); this.host.canvas.blur(); event.preventDefault(); return; }
    if (!this.movement.has(event.code) && !event.code.startsWith('Shift')) return;
    event.preventDefault(); event.stopPropagation(); this.keys.add(event.code);
    if (!this.raf && [...this.keys].some(key => this.movement.has(key))) { this.last = performance.now(); this.raf = requestAnimationFrame(this.tick); }
  };
  private keyUp = (event: KeyboardEvent) => {
    this.keys.delete(event.code);
    if (![...this.keys].some(key => this.movement.has(key))) { cancelAnimationFrame(this.raf); this.raf = 0; }
  };
  private pointerDown = (event: PointerEvent) => {
    if (!this.enabled || this.pointer || event.button < 0 || event.button > 2) return;
    this.host.canvas.focus({ preventScroll: true }); event.preventDefault();
    this.pointer = { id: event.pointerId, x: event.clientX, y: event.clientY, pan: event.button === 1 || event.button === 0 && event.shiftKey }; this.host.canvas.setPointerCapture(event.pointerId);
  };
  private pointerMove = (event: PointerEvent) => {
    const pointer = this.pointer; if (!this.enabled || !pointer || pointer.id !== event.pointerId) return;
    const dx = event.clientX - pointer.x, dy = event.clientY - pointer.y; pointer.x = event.clientX; pointer.y = event.clientY;
    if (!dx && !dy) return;
    if (pointer.pan) {
      const scale = this.speed * .005 * (event.shiftKey ? 4 : 1);
      const movement = new Vector3(-dx, dy, 0).applyQuaternion(this.host.perspective.quaternion);
      this.host.perspective.position.addScaledVector(movement, scale); this.host.invalidate(); return;
    }
    this.euler.setFromQuaternion(this.host.perspective.quaternion, 'YXZ'); this.euler.y -= dx * .003;
    this.euler.x = Math.max(-Math.PI / 2 + .01, Math.min(Math.PI / 2 - .01, this.euler.x - dy * .003));
    this.host.perspective.quaternion.setFromEuler(this.euler).normalize(); this.host.invalidate();
  };
  private pointerUp = (event: PointerEvent) => {
    if (this.pointer?.id !== event.pointerId) return;
    this.pointer = null; if (this.host.canvas.hasPointerCapture(event.pointerId)) this.host.canvas.releasePointerCapture(event.pointerId);
  };
  private wheel = (event: WheelEvent) => {
    if (!this.enabled || event.ctrlKey || event.metaKey || !Number.isFinite(event.deltaY)) return;
    const units = event.deltaMode === 1 ? 16 : event.deltaMode === 2 ? this.host.canvas.clientHeight : 1;
    const delta = Math.max(-1000, Math.min(1000, event.deltaY * units)); if (!delta) return;
    event.preventDefault();
    const forward = new Vector3(0, 0, -1).applyQuaternion(this.host.perspective.quaternion);
    this.host.perspective.position.addScaledVector(forward, -delta * this.speed * .0025 * (event.shiftKey ? 4 : 1)); this.host.invalidate();
  };
  private tick = (now: number) => {
    this.raf = 0; if (!this.enabled || document.activeElement !== this.host.canvas || document.hidden) { this.stop(); return; }
    const held = (...keys: string[]) => +keys.some(key => this.keys.has(key));
    const direction = new Vector3(held('KeyD', 'ArrowRight') - held('KeyA', 'ArrowLeft'), 0, held('KeyS', 'ArrowDown') - held('KeyW', 'ArrowUp')).applyQuaternion(this.host.perspective.quaternion);
    direction.y += held('KeyE') - held('KeyQ');
    if (direction.lengthSq()) {
      const dt = Math.min(.05, Math.max(0, (now - this.last) / 1000)), boost = held('ShiftLeft', 'ShiftRight') ? 4 : 1;
      this.host.perspective.position.addScaledVector(direction.normalize(), dt * this.speed * boost); this.host.invalidate();
    }
    this.last = now;
    if ([...this.keys].some(key => this.movement.has(key))) this.raf = requestAnimationFrame(this.tick);
  };
  dispose() {
    this.stop(); const canvas = this.host.canvas;
    canvas.removeEventListener('keydown', this.keyDown); canvas.removeEventListener('blur', this.stop);
    canvas.removeEventListener('pointerdown', this.pointerDown); canvas.removeEventListener('pointermove', this.pointerMove);
    canvas.removeEventListener('pointerup', this.pointerUp); canvas.removeEventListener('pointercancel', this.pointerUp); canvas.removeEventListener('lostpointercapture', this.pointerUp); canvas.removeEventListener('contextmenu', this.contextMenu);
    canvas.removeEventListener('wheel', this.wheel);
    window.removeEventListener('keyup', this.keyUp); window.removeEventListener('blur', this.stop); document.removeEventListener('visibilitychange', this.visibility);
  }
}
