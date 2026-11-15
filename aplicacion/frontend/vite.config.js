import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

export default defineConfig({
  plugins: [react()],
  server: {
    // Solo para `npm run dev`: reenvía /api al backend local,
    // igual que el gateway de Compose y el ALB en AWS.
    proxy: {
      '/api': 'http://localhost:8000',
    },
  },
})
