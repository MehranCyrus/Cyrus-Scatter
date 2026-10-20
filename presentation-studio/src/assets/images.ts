/** Preserve aspect and original project bytes; prepare only a display/export derivative. */
export async function prepareImage(bytes: Uint8Array, profile: 'balanced' | 'mobile'): Promise<Uint8Array> {
  if (typeof createImageBitmap === 'undefined') return bytes;
  const image = await createImageBitmap(new Blob([bytes as Uint8Array<ArrayBuffer>]));
  try {
    const edge = profile === 'mobile' ? 1600 : 2560, scale = Math.min(1, edge / Math.max(image.width, image.height)), width = Math.max(1, Math.round(image.width * scale)), height = Math.max(1, Math.round(image.height * scale));
    if (typeof OffscreenCanvas !== 'undefined') { const canvas = new OffscreenCanvas(width, height); canvas.getContext('2d')!.drawImage(image, 0, 0, width, height); return new Uint8Array(await (await canvas.convertToBlob({ type: 'image/webp', quality: 0.85 })).arrayBuffer()); }
    const canvas = document.createElement('canvas'); canvas.width = width; canvas.height = height; canvas.getContext('2d')!.drawImage(image, 0, 0, width, height);
    const blob = await new Promise<Blob>((resolve, reject) => canvas.toBlob(b => b ? resolve(b) : reject(new Error('Image preparation failed')), 'image/webp', 0.85)); return new Uint8Array(await blob.arrayBuffer());
  } finally { image.close(); }
}
