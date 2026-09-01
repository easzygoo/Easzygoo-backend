import * as Sentry from '@sentry/node';

/*
 * Crash reporting. The API server and the notification worker are separate Node
 * processes (Render web service + Background Worker), so each one calls
 * initSentry() for itself — one process's init does nothing for the other.
 *
 * Requires lib/env to have loaded first, since the DSN comes from the root .env.
 */

let initialised = false;

export function initSentry(): void {
  if (initialised) return;

  const dsn = process.env.SENTRY_DSN;
  if (!dsn) {
    // Local dev without Sentry configured must still boot.
    console.warn('[sentry] SENTRY_DSN not set — crash reporting disabled');
    return;
  }

  Sentry.init({
    dsn,
    environment: process.env.NODE_ENV || 'development',
    tracesSampleRate: 0.1,
  });

  initialised = true;
  console.log(`[sentry] initialised (env: ${process.env.NODE_ENV || 'development'})`);
}
