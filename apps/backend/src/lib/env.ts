import path from 'node:path';
import { config } from 'dotenv';

// Side-effect module: import this FIRST (before any module that reads process.env)
// so the monorepo-root .env is loaded before prisma.ts / firebase.ts initialise.
config({ path: path.resolve(__dirname, '../../../../.env') });

// Variables read from the loaded .env:
//   Runtime (app):
//     DATABASE_URL, DIRECT_URL, REDIS_URL, JWT_SECRET
//     FIREBASE_PROJECT_ID, FIREBASE_CLIENT_EMAIL, FIREBASE_PRIVATE_KEY
//     CLOUDINARY_*, RAZORPAY_*, CASHFREE_*, MAPS_API_KEY
//   Dev-only (scripts/get-test-token.ts — Firebase client SDK, not the app):
//     FIREBASE_WEB_API_KEY, FIREBASE_WEB_AUTH_DOMAIN
