import { Button, StyleSheet, Text, View } from 'react-native';
import type { NativeStackScreenProps } from '@react-navigation/native-stack';

import type { OnboardingStackParamList } from '../navigation/types';

type Props = NativeStackScreenProps<OnboardingStackParamList, 'StoreDetails'>;

export default function StoreDetailsScreen({ navigation }: Props) {
  return (
    <View style={styles.container}>
      <Text style={styles.title}>Store details</Text>
      {/* TODO: storeName, address, pincode, latitude, longitude, openTime,
          closeTime — these become the body of POST /v1/vendors/onboard. */}
      <Text style={styles.hint}>Store name, address, pincode, location, hours</Text>
      <Button title="Continue" onPress={() => navigation.navigate('BankDetails')} />
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, alignItems: 'center', justifyContent: 'center', gap: 16, padding: 24 },
  title: { fontSize: 18, fontWeight: '600' },
  hint: { fontSize: 13, opacity: 0.6, textAlign: 'center' },
});
