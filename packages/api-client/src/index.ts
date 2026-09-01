// Shared typed API client — used by Customer, Vendor, and Rider apps
// so all three hit the same typed endpoints and never drift apart.

const BASE_URL = process.env.EXPO_PUBLIC_API_URL ?? 'http://localhost:4000';

export async function apiGet<T>(path: string): Promise<T> {
  const res = await fetch(`${BASE_URL}${path}`);
  if (!res.ok) throw new Error(`API error: ${res.status}`);
  return res.json();
}

// Add typed request/response types and POST/PUT/DELETE helpers here
// as Phase 1 endpoints (auth, catalog) come online.
