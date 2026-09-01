import { registerRootComponent } from 'expo';

import App from './App';

// Explicit entry point. The default "node_modules/expo/AppEntry.js" resolves
// its `../../App` import relative to pnpm's content-addressed store, not this
// app folder, so it never finds App.tsx in a pnpm workspace.
registerRootComponent(App);
