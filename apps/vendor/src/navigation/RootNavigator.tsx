import { NavigationContainer } from '@react-navigation/native';
import { createNativeStackNavigator } from '@react-navigation/native-stack';

import AuthStack from './AuthStack';
import OnboardingStack from './OnboardingStack';
import MainTabs from './MainTabs';
import PendingApprovalScreen from '../screens/PendingApprovalScreen';
import type { RootStackParamList, VendorAppState } from './types';

const Root = createNativeStackNavigator<RootStackParamList>();

type Props = {
  /** Temporary: hardcoded in App.tsx until real auth + vendor status exist. */
  state: VendorAppState;
};

/**
 * Switches between the four top-level flows:
 *
 *   loggedOut       -> AuthStack          phone + OTP
 *   onboarding      -> OnboardingStack    store details, then bank details
 *   pendingApproval -> PendingApprovalScreen   waiting on an admin decision
 *   active          -> MainTabs           the approved vendor's app
 *
 * Exactly one branch is mounted at a time, so there is no back-navigation
 * between flows.
 */
export default function RootNavigator({ state }: Props) {
  return (
    <NavigationContainer>
      <Root.Navigator screenOptions={{ headerShown: false }}>
        {state === 'loggedOut' && <Root.Screen name="Auth" component={AuthStack} />}
        {state === 'onboarding' && <Root.Screen name="Onboarding" component={OnboardingStack} />}
        {state === 'pendingApproval' && (
          <Root.Screen name="PendingApproval" component={PendingApprovalScreen} />
        )}
        {state === 'active' && <Root.Screen name="Main" component={MainTabs} />}
      </Root.Navigator>
    </NavigationContainer>
  );
}
