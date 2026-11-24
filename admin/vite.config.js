import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

// Disajikan dalam 1 service bersama backend Express pada path /admin/
export default defineConfig({
  base: '/admin/',
  plugins: [react()],
  server: {
    port: 5173,
    proxy: {
      '/api': {
        target: 'http://localhost:3000',
        changeOrigin: true,
      },
    },
  },
});
