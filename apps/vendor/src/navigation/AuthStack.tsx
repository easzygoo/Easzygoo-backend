import { createNativeStackNavigator } from '@react-navigation/native-stack';

import PhoneEntryScreen from '../screens/PhoneEntryScreen';
import OtpVerifyScreen from '../screens/OtpVerifyScreen';
import type { AuthStackParamList } from './types';

const Stack = createNativeStackNavigator<AuthStackParamList>();

/** Phone + OTP sign-in. Shown while there is no stored token. */
export default function AuthStack() {
  return (
    <Stack.Navigator initialRouteName="PhoneEntry">
      <Stack.Screen name="PhoneEntry" component={PhoneEntryScreen} options={{ title: 'Sign in' }} />
      <Stack.Screen name="OtpVerify" component={OtpVerifyScreen} options={{ title: 'Verify OTP' }} />
    </Stack.Navigator>
  );
}
