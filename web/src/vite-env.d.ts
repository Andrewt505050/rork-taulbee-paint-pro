/// <reference types="vite/client" />

interface ImportMetaEnv {
  readonly EXPO_PUBLIC_TOOLKIT_URL?: string;
  readonly EXPO_PUBLIC_RORK_FUNCTIONS_URL?: string;
}

interface ImportMeta {
  readonly env: ImportMetaEnv;
}
