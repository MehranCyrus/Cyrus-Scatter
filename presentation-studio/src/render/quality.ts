/** Runtime display quality only. Never edits project geometry, density, timing or visibility. */
export class QualityGovernor {
  scale = 1;
  private slow = 0;
  private fast = 0;
  sample(cpuMs: number, frameInterval: number, elapsed: number, mobile: boolean): boolean {
    if (frameInterval > 250 || elapsed <= 0) return false;
    const bad = cpuMs > (mobile ? 15 : 9) || frameInterval > (mobile ? 42 : 24);
    this.slow = bad ? this.slow + Math.min(elapsed, 0.1) : 0;
    this.fast = !bad && cpuMs < (mobile ? 8 : 5) ? this.fast + Math.min(elapsed, 0.1) : 0;
    if (this.slow >= 3 && this.scale > 0.6) { this.scale = Math.max(0.6, this.scale - 0.15); this.slow = this.fast = 0; return true; }
    if (this.fast >= 12 && this.scale < 1) { this.scale = Math.min(1, this.scale + 0.1); this.slow = this.fast = 0; return true; }
    return false;
  }
}
