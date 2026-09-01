import type { FastifyInstance } from 'fastify';
import { Prisma } from '@prisma/client';
import { prisma } from '../lib/prisma';
import { requireAuth, requireRole } from '../lib/auth-middleware';
import { notifyUser } from '../lib/notify';

// TODO: replace with a ServiceZone.baseDeliveryFee lookup by the address's pincode
// once service zones are wired up.
const FLAT_DELIVERY_FEE = new Prisma.Decimal(25);

interface OrderItemInput {
  productId: string;
  quantity: number;
}

/** Thrown inside the transaction when a guarded stock decrement finds nothing to update. */
class OutOfStockError extends Error {
  constructor(public readonly productIds: string[]) {
    super('insufficient stock');
    this.name = 'OutOfStockError';
  }
}

/** Thrown inside the transaction when the guarded coupon claim finds nothing to update. */
class CouponUnavailableError extends Error {
  constructor() {
    super('coupon usage limit reached');
    this.name = 'CouponUnavailableError';
  }
}

export default async function orderRoutes(app: FastifyInstance) {
  // POST /v1/orders — customer only
  app.post(
    '/orders',
    { preHandler: [requireAuth, requireRole('CUSTOMER')] },
    async (request, reply) => {
      const customerId = request.authUser!.userId;
      const body = (request.body ?? {}) as Record<string, unknown>;

      const vendorId = typeof body.vendorId === 'string' ? body.vendorId.trim() : '';
      if (!vendorId) {
        return reply.code(400).send({ error: 'vendorId is required' });
      }

      const addressId = typeof body.addressId === 'string' ? body.addressId.trim() : '';
      if (!addressId) {
        return reply.code(400).send({ error: 'addressId is required' });
      }

      // ---- items ----
      if (!Array.isArray(body.items) || body.items.length === 0) {
        return reply.code(400).send({ error: 'items must be a non-empty array' });
      }

      const items: OrderItemInput[] = [];
      for (const raw of body.items) {
        const it = (raw ?? {}) as Record<string, unknown>;
        const productId = typeof it.productId === 'string' ? it.productId.trim() : '';
        if (!productId) {
          return reply.code(400).send({ error: 'each item requires a productId' });
        }
        if (
          typeof it.quantity !== 'number' ||
          !Number.isInteger(it.quantity) ||
          it.quantity <= 0
        ) {
          return reply
            .code(400)
            .send({ error: 'each item quantity must be a positive integer' });
        }
        items.push({ productId, quantity: it.quantity });
      }

      // Duplicates would be validated once but decremented twice — reject rather than oversell.
      if (new Set(items.map((i) => i.productId)).size !== items.length) {
        return reply
          .code(400)
          .send({ error: 'duplicate productId in items; merge quantities before sending' });
      }

      // ---- address must belong to this customer ----
      const address = await prisma.address.findUnique({ where: { id: addressId } });
      if (!address) {
        return reply.code(404).send({ error: 'Address not found' });
      }
      if (address.userId !== customerId) {
        return reply.code(403).send({ error: 'This address belongs to another account' });
      }

      // ---- vendor must exist and be accepting orders ----
      const vendor = await prisma.vendor.findUnique({ where: { id: vendorId } });
      if (!vendor) {
        return reply.code(404).send({ error: 'Vendor not found' });
      }
      if (vendor.status !== 'APPROVED') {
        return reply.code(400).send({ error: 'Vendor is not approved to take orders' });
      }

      // ---- products: one query for the whole cart ----
      const productIds = items.map((i) => i.productId);
      const products = await prisma.product.findMany({ where: { id: { in: productIds } } });

      const byId = new Map(products.map((p) => [p.id, p]));
      const missing = productIds.filter((id) => !byId.has(id));
      if (missing.length > 0) {
        return reply.code(404).send({ error: 'Product not found', productIds: missing });
      }

      // single-vendor cart: every product must belong to the vendorId in the body
      const foreign = products.filter((p) => p.vendorId !== vendorId).map((p) => p.id);
      if (foreign.length > 0) {
        return reply.code(400).send({
          error: 'single-vendor cart: all products must belong to the same vendor',
          productIds: foreign,
        });
      }

      // ---- availability ----
      const unavailable = items
        .map((it) => {
          const p = byId.get(it.productId)!;
          if (!p.isActive) return { productId: p.id, name: p.name, reason: 'inactive' };
          if (p.stockQty < it.quantity) {
            return {
              productId: p.id,
              name: p.name,
              reason: 'insufficient stock',
              requested: it.quantity,
              available: p.stockQty,
            };
          }
          return null;
        })
        .filter((x): x is NonNullable<typeof x> => x !== null);

      if (unavailable.length > 0) {
        return reply.code(409).send({ error: 'insufficient stock', products: unavailable });
      }

      // ---- totals (Decimal maths, never floats, for money) ----
      const orderItems = items.map((it) => {
        const unitPrice = byId.get(it.productId)!.price;
        return {
          productId: it.productId,
          quantity: it.quantity,
          unitPrice, // snapshot of the price at order time
          lineTotal: unitPrice.mul(it.quantity),
        };
      });

      const subtotal = orderItems.reduce(
        (sum, i) => sum.add(i.lineTotal),
        new Prisma.Decimal(0),
      );
      const deliveryFee = FLAT_DELIVERY_FEE;

      const couponCode =
        typeof body.couponCode === 'string' && body.couponCode.trim()
          ? body.couponCode.trim()
          : null;

      // ---- coupon ----
      // Validated here, but only *claimed* inside the transaction below, so a
      // coupon on its last use can't be handed to two concurrent orders.
      let discount = new Prisma.Decimal(0);
      let coupon: { id: string; maxUses: number | null } | null = null;

      if (couponCode) {
        const found = await prisma.coupon.findUnique({ where: { code: couponCode } });
        if (!found || !found.isActive) {
          return reply.code(400).send({ error: 'invalid coupon code' });
        }

        const now = new Date();
        if (now < found.validFrom) {
          return reply.code(400).send({ error: 'coupon not yet valid' });
        }
        if (now > found.validUntil) {
          return reply.code(400).send({ error: 'coupon has expired' });
        }
        if (found.minOrderValue !== null && subtotal.lessThan(found.minOrderValue)) {
          return reply
            .code(400)
            .send({ error: 'order total below minimum for this coupon' });
        }
        if (found.maxUses !== null && found.usedCount >= found.maxUses) {
          return reply.code(400).send({ error: 'coupon usage limit reached' });
        }

        const raw =
          found.discountType === 'PERCENT'
            ? subtotal.mul(found.discountValue).div(100).toDecimalPlaces(2)
            : found.discountValue;
        // Never discount more than the goods are worth — delivery fee is still payable.
        discount = raw.greaterThan(subtotal) ? subtotal : raw;
        coupon = { id: found.id, maxUses: found.maxUses };
      }

      const total = subtotal.add(deliveryFee).sub(discount);

      try {
        const order = await prisma.$transaction(async (tx) => {
          // Guarded decrement: the `stockQty >= quantity` condition lives in the WHERE
          // clause, so a concurrent order cannot drive stock negative. count === 0
          // means someone else took the stock between our check and this write.
          for (const it of items) {
            const res = await tx.product.updateMany({
              where: { id: it.productId, isActive: true, stockQty: { gte: it.quantity } },
              data: { stockQty: { decrement: it.quantity } },
            });
            if (res.count === 0) {
              throw new OutOfStockError([it.productId]);
            }
          }

          // Guarded coupon claim, same shape as the stock decrement: the
          // usedCount ceiling lives in the WHERE clause. count === 0 means a
          // concurrent order took the last use, so the whole transaction rolls
          // back — no order is created against a coupon we did not get.
          if (coupon) {
            const claim = await tx.coupon.updateMany({
              where:
                coupon.maxUses === null
                  ? { id: coupon.id }
                  : { id: coupon.id, usedCount: { lt: coupon.maxUses } },
              data: { usedCount: { increment: 1 } },
            });
            if (claim.count === 0) {
              throw new CouponUnavailableError();
            }
          }

          // Orders go straight to PLACED for now. Once Razorpay is integrated this
          // should gate on a successful payment intent before reaching PLACED —
          // there is no payment provider connected yet.
          return tx.order.create({
            data: {
              customerId,
              vendorId,
              addressId,
              status: 'PLACED',
              subtotal,
              deliveryFee,
              discount,
              total,
              couponCode,
              items: { create: orderItems },
            },
            include: { items: true },
          });
        });

        // Vendor needs to know even with the app backgrounded. Queued, never
        // sent inline — see lib/notify.ts.
        await notifyUser(
          vendor.userId,
          'New order received',
          `${orderItems.length} item(s), total Rs ${total.toString()}`,
          { orderId: order.id, type: 'NEW_ORDER' },
        );

        return reply.code(201).send(order);
      } catch (err) {
        if (err instanceof CouponUnavailableError) {
          return reply.code(409).send({ error: 'coupon usage limit reached' });
        }
        if (err instanceof OutOfStockError) {
          return reply.code(409).send({
            error: 'insufficient stock',
            products: err.productIds.map((id) => ({
              productId: id,
              name: byId.get(id)?.name,
              reason: 'stock changed while the order was being placed',
            })),
          });
        }
        throw err;
      }
    },
  );

  // GET /v1/orders/mine — customer only, light list view.
  // Registered before /orders/:id so the static segment is unambiguous.
  app.get(
    '/orders/mine',
    { preHandler: [requireAuth, requireRole('CUSTOMER')] },
    async (request) => {
      const orders = await prisma.order.findMany({
        where: { customerId: request.authUser!.userId },
        orderBy: { placedAt: 'desc' },
        select: {
          id: true,
          vendorId: true,
          status: true,
          total: true,
          placedAt: true,
          _count: { select: { items: true } },
        },
      });

      return orders.map(({ _count, ...o }) => ({ ...o, itemCount: _count.items }));
    },
  );

  // GET /v1/orders/:id — the order's customer, its vendor, or an admin
  app.get<{ Params: { id: string } }>(
    '/orders/:id',
    { preHandler: [requireAuth] },
    async (request, reply) => {
      const order = await prisma.order.findUnique({
        where: { id: request.params.id },
        include: {
          items: { include: { product: { select: { id: true, name: true } } } },
        },
      });
      if (!order) {
        return reply.code(404).send({ error: 'Order not found' });
      }

      const { userId, role } = request.authUser!;

      let allowed = role === 'ADMIN' || order.customerId === userId;
      if (!allowed && role === 'VENDOR') {
        const vendor = await prisma.vendor.findUnique({
          where: { userId },
          select: { id: true },
        });
        allowed = vendor?.id === order.vendorId;
      }

      if (!allowed) {
        return reply.code(403).send({ error: 'Not allowed to view this order' });
      }

      return order;
    },
  );
}
