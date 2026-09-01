import { createNativeStackNavigator } from '@react-navigation/native-stack';

import StoreDetailsScreen from '../screens/StoreDetailsScreen';
import BankDetailsScreen from '../screens/BankDetailsScreen';
import type { OnboardingStackParamList } from './types';

const Stack = createNativeStackNavigator<OnboardingStackParamList>();

/**
 * One-time vendor profile creation, shown after sign-in when the account has
 * no Vendor row yet. Together these two screens collect the body of
 * POST /v1/vendors/onboard.
 */
export default function OnboardingStack() {
  return (
    <Stack.Navigator initialRouteName="StoreDetails">
      <Stack.Screen
        name="StoreDetails"
        component={StoreDetailsScreen}
        options={{ title: 'Store details' }}
      />
      <Stack.Screen
        name="BankDetails"
        component={BankDetailsScreen}
        options={{ title: 'Bank details' }}
      />
    </Stack.Navigator>
  );
}
