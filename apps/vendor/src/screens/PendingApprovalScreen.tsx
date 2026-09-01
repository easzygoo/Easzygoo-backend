import { StyleSheet, Text, View } from 'react-native';

/** Shown between submitting onboarding and an admin approving the Vendor row. */
export default function PendingApprovalScreen() {
  return (
    <View style={styles.container}>
      <Text style={styles.title}>Your store is under review</Text>
      <Text style={styles.body}>
        We are verifying your store and bank details. You will be able to start
        taking orders as soon as it is approved.
      </Text>
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, alignItems: 'center', justifyContent: 'center', gap: 12, padding: 32 },
  title: { fontSize: 18, fontWeight: '600', textAlign: 'center' },
  body: { fontSize: 14, opacity: 0.7, textAlign: 'center' },
});
