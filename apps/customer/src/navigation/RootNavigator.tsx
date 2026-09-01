import { NavigationContainer } from '@react-navigation/native';
import { createNativeStackNavigator } from '@react-navigation/native-stack';

import AuthStack from './AuthStack';
import MainTabs from './MainTabs';
import type { RootStackParamList } from './types';

const Root = createNativeStackNavigator<RootStackParamList>();

type Props = {
  /** Temporary: a hardcoded flag from App.tsx. Replaced by real auth state
   *  once Firebase phone auth is wired up. */
  isLoggedIn: boolean;
};

/**
 * Swaps between the auth flow and the signed-in app. Only one branch is
 * mounted at a time, so there is no back-navigation from Main into Auth.
 */
export default function RootNavigator({ isLoggedIn }: Props) {
  return (
    <NavigationContainer>
      <Root.Navigator screenOptions={{ headerShown: false }}>
        {isLoggedIn ? (
          <Root.Screen name="Main" component={MainTabs} />
        ) : (
          <Root.Screen name="Auth" component={AuthStack} />
        )}
      </Root.Navigator>
    </NavigationContainer>
  );
}
