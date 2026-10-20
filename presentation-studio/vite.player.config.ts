import { defineConfig } from 'vite';
import { fileURLToPath } from 'node:url';
export default defineConfig({
  root: fileURLToPath(new URL('./player', import.meta.url)), base: './',
  publicDir: false,
  server: { host: '127.0.0.1', port: 5191, strictPort: true, fs: { allow: [fileURLToPath(new URL('.', import.meta.url))] } },
  build: { outDir: '../dist/player', emptyOutDir: true, sourcemap: false },
});
