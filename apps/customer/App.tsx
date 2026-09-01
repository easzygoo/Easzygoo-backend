import { SafeAreaProvider } from 'react-native-safe-area-context';

import RootNavigator from './src/navigation/RootNavigator';

// Temporary: flip this by hand to preview either flow. Real auth-state-driven
// switching arrives with the Firebase phone-auth step.
const isLoggedIn = false;

export default function App() {
  return (
    <SafeAreaProvider>
      <RootNavigator isLoggedIn={isLoggedIn} />
    </SafeAreaProvider>
  );
}
