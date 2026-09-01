import { SafeAreaProvider } from 'react-native-safe-area-context';

import RootNavigator from './src/navigation/RootNavigator';
import type { VendorAppState } from './src/navigation/types';

// Temporary: flip this by hand to preview any flow. Real switching comes from
// stored auth + the Vendor row's status (PENDING / APPROVED) once the API is
// wired up. The type lives in src/navigation/types.ts so RootNavigator can
// share it without importing from App.tsx.
const vendorAppState: VendorAppState = 'loggedOut';

export default function App() {
  return (
    <SafeAreaProvider>
      <RootNavigator state={vendorAppState} />
    </SafeAreaProvider>
  );
}
