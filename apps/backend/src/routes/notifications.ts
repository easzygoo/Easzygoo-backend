import type { FastifyInstance } from 'fastify';
import { prisma } from '../lib/prisma';
import { requireAuth } from '../lib/auth-middleware';

export default async function notificationRoutes(app: FastifyInstance) {
  /**
   * POST /v1/notifications/register-token — any signed-in user.
   *
   * Upserts on the token itself, not on (userId, token): the same physical
   * device can be handed to a different account, and FCM will hand back the
   * same token. Re-pointing the row at the new user is the correct outcome,
   * otherwise the previous account keeps receiving that device's pushes.
   */
  app.post('/notifications/register-token', { preHandler: [requireAuth] }, async (request, reply) => {
    const body = (request.body ?? {}) as Record<string, unknown>;

    const token = typeof body.token === 'string' ? body.token.trim() : '';
    if (!token) {
      return reply.code(400).send({ error: 'token is required' });
    }

    const platform =
      typeof body.platform === 'string' && body.platform.trim() ? body.platform.trim() : null;

    const userId = request.authUser!.userId;
    return prisma.pushToken.upsert({
      where: { token },
      update: { userId, platform },
      create: { userId, token, platform },
    });
  });
}
