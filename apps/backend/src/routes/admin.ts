import type { FastifyInstance } from 'fastify';
import { Prisma } from '@prisma/client';
import { prisma } from '../lib/prisma';
import { requireAuth, requireRole } from '../lib/auth-middleware';

/*
 * Admin approval routes. Every route here is ADMIN-only.
 *
 * Note: no route anywhere in the API creates an ADMIN user — phone OTP signup
 * can only ever produce CUSTOMER / VENDOR / RIDER (see routes/auth.ts). Admins
 * are promoted by hand in the database.
 *
 * Vendor and Rider both start at PENDING after onboarding; approve/reject only
 * act on PENDING rows, so an already-decided profile can't be flipped here.
 */

const ADMIN_ONLY = { preHandler: [requireAuth, requireRole('ADMIN')] };

const DISCOUNT_TYPES = ['FLAT', 'PERCENT'] as const;

const DECISIONS = [
  ['approve', 'APPROVED'],
  ['reject', 'REJECTED'],
] as const;

export default async function adminRoutes(app: FastifyInstance) {
  // 1. GET /v1/admin/vendors/pending
  app.get('/admin/vendors/pending', ADMIN_ONLY, async () => {
    const vendors = await prisma.vendor.findMany({
      where: { status: 'PENDING' },
      orderBy: { createdAt: 'desc' },
      include: { user: { select: { phone: true } } },
    });
    return vendors.map(({ user, ...v }) => ({ ...v, phone: user.phone }));
  });

  // 4. GET /v1/admin/riders/pending
  app.get('/admin/riders/pending', ADMIN_ONLY, async () => {
    const riders = await prisma.rider.findMany({
      where: { status: 'PENDING' },
      orderBy: { createdAt: 'desc' },
      include: { user: { select: { phone: true } } },
    });
    return riders.map(({ user, ...r }) => ({ ...r, phone: user.phone }));
  });

  // POST /v1/admin/coupons — minimal creation endpoint so coupons can be
  // exercised end to end. No listing/editing yet.
  app.post('/admin/coupons', ADMIN_ONLY, async (request, reply) => {
    const body = (request.body ?? {}) as Record<string, unknown>;

    const code = typeof body.code === 'string' ? body.code.trim() : '';
    if (!code) {
      return reply.code(400).send({ error: 'code is required' });
    }

    const discountType = typeof body.discountType === 'string' ? body.discountType : '';
    if (!DISCOUNT_TYPES.includes(discountType as (typeof DISCOUNT_TYPES)[number])) {
      return reply
        .code(400)
        .send({ error: `discountType must be one of ${DISCOUNT_TYPES.join(', ')}` });
    }

    if (typeof body.discountValue !== 'number' || body.discountValue <= 0) {
      return reply.code(400).send({ error: 'discountValue must be a positive number' });
    }

    let minOrderValue: number | null = null;
    if (body.minOrderValue !== undefined && body.minOrderValue !== null) {
      if (typeof body.minOrderValue !== 'number' || body.minOrderValue < 0) {
        return reply.code(400).send({ error: 'minOrderValue must be a non-negative number' });
      }
      minOrderValue = body.minOrderValue;
    }

    let maxUses: number | null = null;
    if (body.maxUses !== undefined && body.maxUses !== null) {
      if (typeof body.maxUses !== 'number' || !Number.isInteger(body.maxUses) || body.maxUses <= 0) {
        return reply.code(400).send({ error: 'maxUses must be a positive integer' });
      }
      maxUses = body.maxUses;
    }

    const validFrom = new Date(String(body.validFrom));
    const validUntil = new Date(String(body.validUntil));
    if (Number.isNaN(validFrom.getTime()) || Number.isNaN(validUntil.getTime())) {
      return reply
        .code(400)
        .send({ error: 'validFrom and validUntil are required ISO date strings' });
    }
    if (validUntil <= validFrom) {
      return reply.code(400).send({ error: 'validUntil must be after validFrom' });
    }

    const existing = await prisma.coupon.findUnique({ where: { code } });
    if (existing) {
      return reply.code(400).send({ error: 'A coupon with this code already exists' });
    }

    try {
      const coupon = await prisma.coupon.create({
        data: {
          code,
          discountType,
          discountValue: body.discountValue,
          minOrderValue,
          maxUses,
          validFrom,
          validUntil,
        },
      });
      return reply.code(201).send(coupon);
    } catch (err) {
      // Concurrent create with the same code raced past the pre-check.
      if (err instanceof Prisma.PrismaClientKnownRequestError && err.code === 'P2002') {
        return reply.code(400).send({ error: 'A coupon with this code already exists' });
      }
      throw err;
    }
  });

  for (const [action, next] of DECISIONS) {
    // 2 & 3. PATCH /v1/admin/vendors/:id/approve | /reject
    app.patch<{ Params: { id: string } }>(
      `/admin/vendors/:id/${action}`,
      ADMIN_ONLY,
      async (request, reply) => {
        const vendor = await prisma.vendor.findUnique({
          where: { id: request.params.id },
          select: { id: true, status: true },
        });
        if (!vendor) {
          return reply.code(404).send({ error: 'Vendor not found' });
        }
        if (vendor.status !== 'PENDING') {
          return reply.code(400).send({
            error: `Vendor is not pending review (current status: ${vendor.status})`,
            currentStatus: vendor.status,
          });
        }

        // Guarded update so two admins deciding at once can't both win.
        const done = await prisma.vendor.updateMany({
          where: { id: vendor.id, status: 'PENDING' },
          data: { status: next },
        });
        if (done.count === 0) {
          return reply
            .code(409)
            .send({ error: 'Vendor status changed before the decision was applied' });
        }

        return prisma.vendor.findUnique({ where: { id: vendor.id } });
      },
    );

    // 5 & 6. PATCH /v1/admin/riders/:id/approve | /reject
    app.patch<{ Params: { id: string } }>(
      `/admin/riders/:id/${action}`,
      ADMIN_ONLY,
      async (request, reply) => {
        const rider = await prisma.rider.findUnique({
          where: { id: request.params.id },
          select: { id: true, status: true },
        });
        if (!rider) {
          return reply.code(404).send({ error: 'Rider not found' });
        }
        if (rider.status !== 'PENDING') {
          return reply.code(400).send({
            error: `Rider is not pending review (current status: ${rider.status})`,
            currentStatus: rider.status,
          });
        }

        const done = await prisma.rider.updateMany({
          where: { id: rider.id, status: 'PENDING' },
          data: { status: next },
        });
        if (done.count === 0) {
          return reply
            .code(409)
            .send({ error: 'Rider status changed before the decision was applied' });
        }

        return prisma.rider.findUnique({ where: { id: rider.id } });
      },
    );
  }
}
