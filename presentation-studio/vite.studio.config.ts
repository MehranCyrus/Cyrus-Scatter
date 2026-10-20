import { defineConfig } from 'vite';
import { fileURLToPath } from 'node:url';
export default defineConfig({
  root: fileURLToPath(new URL('./studio', import.meta.url)), base: './',
  publicDir: fileURLToPath(new URL('./public', import.meta.url)),
  server: { host: '127.0.0.1', port: 5190, strictPort: true, fs: { allow: [fileURLToPath(new URL('.', import.meta.url))] } },
  build: { outDir: '../dist/studio', emptyOutDir: true, sourcemap: false },
});
