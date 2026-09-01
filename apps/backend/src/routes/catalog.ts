import type { FastifyInstance, FastifyReply, FastifyRequest } from 'fastify';
import { ProductUnit } from '@prisma/client';
import { prisma } from '../lib/prisma';
import { requireAuth, requireRole } from '../lib/auth-middleware';

const PRODUCT_UNITS = Object.values(ProductUnit);

/** Resolve the Vendor row for the authenticated vendor, or send 403. */
async function getOwnVendor(request: FastifyRequest, reply: FastifyReply) {
  const vendor = await prisma.vendor.findUnique({
    where: { userId: request.authUser!.userId },
  });
  if (!vendor) {
    reply.code(403).send({ error: 'No vendor profile linked to this account' });
    return null;
  }
  return vendor;
}

export default async function catalogRoutes(app: FastifyInstance) {
  // ---------- Categories ----------

  // 1. GET /v1/categories — public
  app.get('/categories', async () => {
    return prisma.category.findMany({ orderBy: { sortOrder: 'asc' } });
  });

  // 2. POST /v1/categories — admin only
  app.post(
    '/categories',
    { preHandler: [requireAuth, requireRole('ADMIN')] },
    async (request, reply) => {
      const body = (request.body ?? {}) as Record<string, unknown>;
      const name = typeof body.name === 'string' ? body.name.trim() : '';
      if (!name) {
        return reply.code(400).send({ error: 'name is required' });
      }

      const imageUrl = typeof body.imageUrl === 'string' ? body.imageUrl : null;
      let sortOrder = 0;
      if (body.sortOrder !== undefined) {
        if (typeof body.sortOrder !== 'number' || !Number.isInteger(body.sortOrder)) {
          return reply.code(400).send({ error: 'sortOrder must be an integer' });
        }
        sortOrder = body.sortOrder;
      }

      const existing = await prisma.category.findUnique({ where: { name } });
      if (existing) {
        return reply.code(400).send({ error: 'A category with this name already exists' });
      }

      const category = await prisma.category.create({
        data: { name, imageUrl, sortOrder },
      });
      return reply.code(201).send(category);
    },
  );

  // ---------- Products ----------

  // 3. GET /v1/vendors/:vendorId/products — public, active products only
  app.get<{ Params: { vendorId: string } }>(
    '/vendors/:vendorId/products',
    async (request, reply) => {
      const { vendorId } = request.params;

      const vendor = await prisma.vendor.findUnique({ where: { id: vendorId } });
      if (!vendor) {
        return reply.code(404).send({ error: 'Vendor not found' });
      }

      return prisma.product.findMany({
        where: { vendorId, isActive: true },
        orderBy: { createdAt: 'desc' },
      });
    },
  );

  // 4. POST /v1/products — vendor only; vendorId comes from the auth user, never the body
  app.post(
    '/products',
    { preHandler: [requireAuth, requireRole('VENDOR')] },
    async (request, reply) => {
      const vendor = await getOwnVendor(request, reply);
      if (!vendor) return;

      const body = (request.body ?? {}) as Record<string, unknown>;

      const name = typeof body.name === 'string' ? body.name.trim() : '';
      if (!name) {
        return reply.code(400).send({ error: 'name is required' });
      }

      const categoryId = typeof body.categoryId === 'string' ? body.categoryId : '';
      if (!categoryId) {
        return reply.code(400).send({ error: 'categoryId is required' });
      }

      if (typeof body.unit !== 'string' || !PRODUCT_UNITS.includes(body.unit as ProductUnit)) {
        return reply
          .code(400)
          .send({ error: `unit must be one of ${PRODUCT_UNITS.join(', ')}` });
      }
      const unit = body.unit as ProductUnit;

      if (typeof body.unitValue !== 'number' || body.unitValue <= 0) {
        return reply.code(400).send({ error: 'unitValue must be a positive number' });
      }

      if (typeof body.price !== 'number' || body.price < 0) {
        return reply.code(400).send({ error: 'price must be a non-negative number' });
      }

      let stockQty = 0;
      if (body.stockQty !== undefined) {
        if (typeof body.stockQty !== 'number' || !Number.isInteger(body.stockQty) || body.stockQty < 0) {
          return reply.code(400).send({ error: 'stockQty must be a non-negative integer' });
        }
        stockQty = body.stockQty;
      }

      const category = await prisma.category.findUnique({ where: { id: categoryId } });
      if (!category) {
        return reply.code(400).send({ error: 'Invalid categoryId' });
      }

      const product = await prisma.product.create({
        data: {
          vendorId: vendor.id,
          categoryId,
          name,
          description: typeof body.description === 'string' ? body.description : null,
          imageUrl: typeof body.imageUrl === 'string' ? body.imageUrl : null,
          unit,
          unitValue: body.unitValue,
          price: body.price,
          stockQty,
        },
      });
      return reply.code(201).send(product);
    },
  );

  // 5. PUT /v1/products/:id — vendor only; must own the product
  app.put<{ Params: { id: string } }>(
    '/products/:id',
    { preHandler: [requireAuth, requireRole('VENDOR')] },
    async (request, reply) => {
      const vendor = await getOwnVendor(request, reply);
      if (!vendor) return;

      const product = await prisma.product.findUnique({ where: { id: request.params.id } });
      if (!product) {
        return reply.code(404).send({ error: 'Product not found' });
      }
      if (product.vendorId !== vendor.id) {
        return reply.code(403).send({ error: 'This product belongs to another vendor' });
      }

      const body = (request.body ?? {}) as Record<string, unknown>;
      const data: Record<string, unknown> = {};

      if (body.name !== undefined) {
        if (typeof body.name !== 'string' || !body.name.trim()) {
          return reply.code(400).send({ error: 'name must be a non-empty string' });
        }
        data.name = body.name.trim();
      }

      if (body.description !== undefined) {
        data.description = typeof body.description === 'string' ? body.description : null;
      }

      if (body.imageUrl !== undefined) {
        data.imageUrl = typeof body.imageUrl === 'string' ? body.imageUrl : null;
      }

      if (body.unit !== undefined) {
        if (typeof body.unit !== 'string' || !PRODUCT_UNITS.includes(body.unit as ProductUnit)) {
          return reply
            .code(400)
            .send({ error: `unit must be one of ${PRODUCT_UNITS.join(', ')}` });
        }
        data.unit = body.unit as ProductUnit;
      }

      if (body.unitValue !== undefined) {
        if (typeof body.unitValue !== 'number' || body.unitValue <= 0) {
          return reply.code(400).send({ error: 'unitValue must be a positive number' });
        }
        data.unitValue = body.unitValue;
      }

      if (body.price !== undefined) {
        if (typeof body.price !== 'number' || body.price < 0) {
          return reply.code(400).send({ error: 'price must be a non-negative number' });
        }
        data.price = body.price;
      }

      if (body.stockQty !== undefined) {
        if (typeof body.stockQty !== 'number' || !Number.isInteger(body.stockQty) || body.stockQty < 0) {
          return reply.code(400).send({ error: 'stockQty must be a non-negative integer' });
        }
        data.stockQty = body.stockQty;
      }

      if (body.isActive !== undefined) {
        if (typeof body.isActive !== 'boolean') {
          return reply.code(400).send({ error: 'isActive must be a boolean' });
        }
        data.isActive = body.isActive;
      }

      if (body.categoryId !== undefined) {
        if (typeof body.categoryId !== 'string' || !body.categoryId) {
          return reply.code(400).send({ error: 'categoryId must be a string' });
        }
        const category = await prisma.category.findUnique({ where: { id: body.categoryId } });
        if (!category) {
          return reply.code(400).send({ error: 'Invalid categoryId' });
        }
        data.categoryId = body.categoryId;
      }

      if (Object.keys(data).length === 0) {
        return reply.code(400).send({ error: 'No updatable fields provided' });
      }

      const updated = await prisma.product.update({
        where: { id: product.id },
        data,
      });
      return updated;
    },
  );

  // 6. PATCH /v1/products/:id/stock — vendor only; minimal stock-only update
  app.patch<{ Params: { id: string } }>(
    '/products/:id/stock',
    { preHandler: [requireAuth, requireRole('VENDOR')] },
    async (request, reply) => {
      const body = (request.body ?? {}) as Record<string, unknown>;
      if (
        typeof body.stockQty !== 'number' ||
        !Number.isInteger(body.stockQty) ||
        body.stockQty < 0
      ) {
        return reply.code(400).send({ error: 'stockQty must be a non-negative integer' });
      }

      const vendor = await getOwnVendor(request, reply);
      if (!vendor) return;

      const product = await prisma.product.findUnique({
        where: { id: request.params.id },
        select: { id: true, vendorId: true },
      });
      if (!product) {
        return reply.code(404).send({ error: 'Product not found' });
      }
      if (product.vendorId !== vendor.id) {
        return reply.code(403).send({ error: 'This product belongs to another vendor' });
      }

      const updated = await prisma.product.update({
        where: { id: product.id },
        data: { stockQty: body.stockQty },
        select: { id: true, stockQty: true },
      });
      return updated;
    },
  );

  // 7. DELETE /v1/products/:id — vendor only; soft-delete (isActive = false)
  app.delete<{ Params: { id: string } }>(
    '/products/:id',
    { preHandler: [requireAuth, requireRole('VENDOR')] },
    async (request, reply) => {
      const vendor = await getOwnVendor(request, reply);
      if (!vendor) return;

      const product = await prisma.product.findUnique({
        where: { id: request.params.id },
        select: { id: true, vendorId: true },
      });
      if (!product) {
        return reply.code(404).send({ error: 'Product not found' });
      }
      if (product.vendorId !== vendor.id) {
        return reply.code(403).send({ error: 'This product belongs to another vendor' });
      }

      await prisma.product.update({
        where: { id: product.id },
        data: { isActive: false },
      });
      return { id: product.id, isActive: false };
    },
  );
}
