import { Button, StyleSheet, Text, View } from 'react-native';
import type { NativeStackScreenProps } from '@react-navigation/native-stack';

import type { OnboardingStackParamList } from '../navigation/types';

type Props = NativeStackScreenProps<OnboardingStackParamList, 'BankDetails'>;

export default function BankDetailsScreen(_props: Props) {
  return (
    <View style={styles.container}>
      <Text style={styles.title}>Bank details</Text>
      {/* TODO: bankAccountNumber, bankIfsc. Submitting posts the whole
          onboarding payload and moves the app state to 'pendingApproval'. */}
      <Text style={styles.hint}>Account number, IFSC</Text>
      <Button title="Submit" onPress={() => {}} />
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, alignItems: 'center', justifyContent: 'center', gap: 16, padding: 24 },
  title: { fontSize: 18, fontWeight: '600' },
  hint: { fontSize: 13, opacity: 0.6, textAlign: 'center' },
});
