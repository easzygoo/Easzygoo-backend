/**
 * Dev-only utility — NOT part of the app runtime.
 *
 * Mints a real Firebase ID token for a fixed test phone number so authenticated
 * routes can be exercised locally before the phone-auth UI exists.
 *
 *   pnpm get-test-token
 *
 * Copy the printed token into `Authorization: Bearer <token>` for requests to
 * /v1/auth/verify, /v1/products, etc.
 *
 * Needs FIREBASE_WEB_API_KEY + FIREBASE_WEB_AUTH_DOMAIN in the root .env
 * (plus the FIREBASE_* admin creds the app already uses).
 */
import '../src/lib/env';
import { firebaseAuth } from '../src/lib/firebase';
import { initializeApp } from 'firebase/app';
import { getAuth, signInWithCustomToken } from 'firebase/auth';

const TEST_PHONE = '+911234567890';

async function main() {
  // 1. Find or create the test user on the Firebase Auth side (admin SDK).
  let user;
  try {
    user = await firebaseAuth.getUserByPhoneNumber(TEST_PHONE);
    console.log(`Using existing Firebase user for ${TEST_PHONE}`);
  } catch (err) {
    if ((err as { code?: string }).code !== 'auth/user-not-found') throw err;
    user = await firebaseAuth.createUser({ phoneNumber: TEST_PHONE });
    console.log(`Created Firebase user for ${TEST_PHONE}`);
  }

  // 2. Mint a custom token for that uid.
  const customToken = await firebaseAuth.createCustomToken(user.uid);

  // 3. Init the Firebase *client* SDK.
  const clientApp = initializeApp({
    apiKey: process.env.FIREBASE_WEB_API_KEY,
    authDomain: process.env.FIREBASE_WEB_AUTH_DOMAIN,
    projectId: process.env.FIREBASE_PROJECT_ID,
  });
  const clientAuth = getAuth(clientApp);

  // 4. Exchange the custom token for a real ID token.
  const credential = await signInWithCustomToken(clientAuth, customToken);
  const idToken = await credential.user.getIdToken();

  // 5. Print, clearly labelled.
  console.log('\n──────────────────────────────────────────────');
  console.log('  test uid   :', user.uid);
  console.log('  test phone :', user.phoneNumber);
  console.log('──────────────────────────────────────────────');
  console.log('\nAuthorization: Bearer ' + idToken);
  console.log('\nID token:\n' + idToken + '\n');

  process.exit(0);
}

main().catch((err) => {
  console.error(err);
  process.exitCode = 1;
});
