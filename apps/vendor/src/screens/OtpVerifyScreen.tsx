import { Button, StyleSheet, Text, View } from 'react-native';
import type { NativeStackScreenProps } from '@react-navigation/native-stack';

import type { AuthStackParamList } from '../navigation/types';

type Props = NativeStackScreenProps<AuthStackParamList, 'OtpVerify'>;

export default function OtpVerifyScreen(_props: Props) {
  return (
    <View style={styles.container}>
      <Text style={styles.title}>Enter the OTP</Text>
      {/* Last screen of the auth flow — nothing to navigate to. Confirming the
          OTP will move the app state on to 'onboarding' or 'active', which
          swaps the root navigator. Wired up with Firebase next. */}
      <Button title="Continue" onPress={() => {}} />
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, alignItems: 'center', justifyContent: 'center', gap: 16 },
  title: { fontSize: 18, fontWeight: '600' },
});
