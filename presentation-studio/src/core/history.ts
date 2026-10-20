import { validateProject, type Project } from './model';
export class History {
  private past: Project[] = [];
  private future: Project[] = [];
  pruned = 0;
  constructor(public current: Project, private maxBytes = 16 * 1024 * 1024) {}
  get canUndo() { return this.past.length > 0; }
  get canRedo() { return this.future.length > 0; }
  get retained() { return [...this.past, this.current, ...this.future]; }
  pruneOldest(): boolean { if (this.past.length) { this.past.shift(); this.pruned++; return true; } if (this.future.length) { this.future.shift(); this.pruned++; return true; } return false; }
  commit(mutator: (draft: Project) => void) {
    const next = structuredClone(this.current); mutator(next); next.revision = this.current.revision + 1;
    const validated = validateProject(next);
    this.past.push(this.current); this.current = validated; this.future = [];
    while (this.past.length > 1 && JSON.stringify(this.past).length * 2 > this.maxBytes) { this.past.shift(); this.pruned++; }
  }
  undo() { const previous = this.past.pop(); if (previous) { this.future.push(this.current); this.current = previous; } }
  redo() { const next = this.future.pop(); if (next) { this.past.push(this.current); this.current = next; } }
  replace(project: Project) { this.current = validateProject(project); this.past = []; this.future = []; }
}
