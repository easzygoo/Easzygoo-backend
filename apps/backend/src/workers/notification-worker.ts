import '../lib/env'; // must be first — loads the root .env before anything reads process.env
import * as Sentry from '@sentry/node';
import { initSentry } from '../lib/sentry';

// Separate process from the API server, so it needs its own Sentry init.
initSentry();

import { Worker, type Job } from 'bullmq';
import { getMessaging } from 'firebase-admin/messaging';
import '../lib/firebase'; // initialises the Admin SDK
import { prisma } from '../lib/prisma';
import { NOTIFICATIONS_QUEUE, createQueueConnection, type NotificationJob } from '../lib/queue';

/*
 * Notification worker — runs as its own process (`pnpm worker`), separate from
 * the API server, matching the Render Background Worker split in CLAUDE.md.
 *
 * Drains the "notifications" queue: looks up the user's device tokens and sends
 * one multicast via FCM. Tokens FCM reports as dead are deleted; anything else
 * is logged and left to BullMQ's retry/backoff.
 */

// FCM error codes that mean "this device is gone" — deleting is correct, retrying is not.
const DEAD_TOKEN_CODES = new Set([
  'messaging/registration-token-not-registered',
  'messaging/invalid-registration-token',
]);

async function handle(job: Job<NotificationJob>) {
  const { userId, title, body, data } = job.data;

  const tokens = await prisma.pushToken.findMany({
    where: { userId },
    select: { id: true, token: true },
  });

  if (tokens.length === 0) {
    // Not a failure — the user simply has no registered device.
    console.log(`[worker] job ${job.id}: no push tokens for user ${userId}, skipping`);
    return { sent: 0, skipped: true };
  }

  const response = await getMessaging().sendEachForMulticast({
    tokens: tokens.map((t) => t.token),
    notification: { title, body },
    data,
  });

  const deadTokenIds: string[] = [];
  response.responses.forEach((res, i) => {
    if (res.success) return;
    const code = (res.error as { code?: string } | undefined)?.code ?? '';
    if (DEAD_TOKEN_CODES.has(code)) {
      deadTokenIds.push(tokens[i].id);
    } else {
      console.error(`[worker] job ${job.id}: send failed for token ${tokens[i].id}:`, code || res.error?.message);
    }
  });

  if (deadTokenIds.length > 0) {
    await prisma.pushToken.deleteMany({ where: { id: { in: deadTokenIds } } });
    console.log(`[worker] job ${job.id}: pruned ${deadTokenIds.length} dead token(s)`);
  }

  console.log(
    `[worker] job ${job.id}: sent ${response.successCount}/${tokens.length} (failed ${response.failureCount})`,
  );
  return { sent: response.successCount, failed: response.failureCount };
}

const worker = new Worker<NotificationJob>(NOTIFICATIONS_QUEUE, handle, {
  connection: createQueueConnection('worker'),
});

worker.on('failed', (job, err) => {
  console.error(`[worker] job ${job?.id} failed (attempt ${job?.attemptsMade}):`, err.message);
  Sentry.captureException(err, {
    extra: {
      jobId: job?.id,
      userId: job?.data?.userId,
      attemptsMade: job?.attemptsMade,
      queue: NOTIFICATIONS_QUEUE,
    },
  });
});
worker.on('ready', () => console.log('[worker] notification worker ready'));

const shutdown = async () => {
  console.log('[worker] shutting down, draining in-flight jobs...');
  await worker.close();
  await prisma.$disconnect();
  process.exit(0);
};
process.on('SIGTERM', shutdown);
process.on('SIGINT', shutdown);
