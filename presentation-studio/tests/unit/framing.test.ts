import { expect, test } from 'vitest';
import { fitFrame, FRAME_PRESETS, presetAspect } from '../../src/render/framing';

test('all fixed composition formats fit inside the canvas with centered, undistorted output', () => {
  for (const [w, h] of [[1440, 900], [841, 467], [360, 800], [3000, 220]]) {
    for (const preset of FRAME_PRESETS) {
      const frame = fitFrame(w, h, presetAspect(preset.id));
      expect(frame.x).toBeGreaterThanOrEqual(0); expect(frame.y).toBeGreaterThanOrEqual(0);
      expect(frame.width).toBeLessThanOrEqual(w + 1e-8); expect(frame.height).toBeLessThanOrEqual(h + 1e-8);
      expect(frame.x * 2 + frame.width).toBeCloseTo(w, 9); expect(frame.y * 2 + frame.height).toBeCloseTo(h, 9);
      expect(frame.width / frame.height).toBeCloseTo(preset.aspect ?? w / h, 9);
    }
  }
});

test('free composition uses the whole viewport and invalid dimensions cannot produce a zero projection', () => {
  expect(fitFrame(900, 600, null)).toEqual({ x: 0, y: 0, width: 900, height: 600 });
  expect(fitFrame(0, 0, null)).toEqual({ x: 0, y: 0, width: 1, height: 1 });
  expect(fitFrame(900, 600, NaN)).toEqual(fitFrame(900, 600, null));
});
