import {defineConfig} from 'vite'
import vue from '@vitejs/plugin-vue'
import AutoImport from 'unplugin-auto-import/vite';
import Components from 'unplugin-vue-components/vite';
import { TDesignResolver } from '@tdesign-vue-next/auto-import-resolver';

// https://vitejs.dev/config/
export default defineConfig({
  root: '.', // 明确指定根目录为当前目录
  publicDir: 'public',
  server: {
    port: 5173,
    strictPort: true,
    host: true
  },
  plugins: [
      vue(),
      AutoImport({
          resolvers: [TDesignResolver({
              library: 'chat'
          })],
      }),
      Components({
          resolvers: [TDesignResolver({
              library: 'chat'
          })],
      }),
  ]
})
