import { Queue } from 'bullmq';
import Redis from 'ioredis';

/*
 * BullMQ queues. Anything async — notifications, payout processing, webhook
 * retries — goes through here rather than running in the request path.
 *
 * The worker that drains this queue runs as a SEPARATE process
 * (`pnpm worker`), matching the Render Background Worker split.
 */

export const NOTIFICATIONS_QUEUE = 'notifications';

/**
 * Build a Redis connection for BullMQ. Same pattern as the socket.io adapter:
 * log errors rather than letting ioredis throw and take the process down.
 *
 * `maxRetriesPerRequest: null` is required by BullMQ for blocking commands.
 */
export function createQueueConnection(label: string): Redis {
  const url = process.env.REDIS_URL;
  if (!url) {
    throw new Error('REDIS_URL is not set — BullMQ needs Redis');
  }
  const conn = new Redis(url, { maxRetriesPerRequest: null });
  conn.on('error', (err) => console.error(`[queue:${label}] redis error:`, err.message));
  return conn;
}

export interface NotificationJob {
  userId: string;
  title: string;
  body: string;
  data?: Record<string, string>;
}

export const notificationsQueue = new Queue<NotificationJob>(NOTIFICATIONS_QUEUE, {
  connection: createQueueConnection('notifications'),
  defaultJobOptions: {
    attempts: 3,
    backoff: { type: 'exponential', delay: 2000 },
    removeOnComplete: 1000,
    // TODO (Phase 4): full dead-letter handling. Jobs that exhaust all 3 attempts
    // currently just sit in the failed set — they need to be drained to a DLQ and
    // surfaced for inspection/replay.
    removeOnFail: false,
  },
});
