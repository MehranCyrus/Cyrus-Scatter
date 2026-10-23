import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import { execFileSync } from 'node:child_process'
import { fileURLToPath } from 'node:url'
export default defineConfig({plugins:[react(),{
  name:'verified-installer-download',apply:'build',
  closeBundle(){execFileSync('python',[fileURLToPath(new URL('./tools/stage_release.py',import.meta.url))],{stdio:'inherit'})},
}],base:'./',build:{outDir:'dist',rolldownOptions:{output:{codeSplitting:{groups:[{name:'react-vendor',test:/node_modules/}]}}}}})
