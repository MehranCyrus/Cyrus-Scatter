import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
export default defineConfig({plugins:[react()],base:'./',build:{outDir:'dist',rolldownOptions:{output:{codeSplitting:{groups:[{name:'react-vendor',test:/node_modules/}]}}}}})
