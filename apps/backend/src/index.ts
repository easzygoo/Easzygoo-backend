import './lib/env'; // must be first — loads the root .env before anything reads process.env
import * as Sentry from '@sentry/node';
import { initSentry } from './lib/sentry';

// Start crash reporting before anything else runs. NOTE: TypeScript hoists the
// `import` statements below above this call, so modules are required first —
// error capture is unaffected, only deep auto-instrumentation would be.
initSentry();

import Fastify from 'fastify';
import adminRoutes from './routes/admin';
import authRoutes from './routes/auth';
import catalogRoutes from './routes/catalog';
import discoveryRoutes from './routes/discovery';
import notificationRoutes from './routes/notifications';
import onboardingRoutes from './routes/onboarding';
import orderLifecycleRoutes from './routes/order-lifecycle';
import orderRoutes from './routes/orders';
import { initSocket } from './lib/socket';

const app = Fastify({ logger: true });

// Captures unhandled route errors with full request context.
Sentry.setupFastifyErrorHandler(app);

app.get('/health', async () => {
  return { status: 'ok', service: 'easzygoo-backend' };
});

// Phase 1: register auth, catalog, and order routes here.
// Keep versioned under /v1 per CLAUDE.md conventions.
app.register(authRoutes, { prefix: '/v1' });
app.register(adminRoutes, { prefix: '/v1' });
app.register(onboardingRoutes, { prefix: '/v1' });
app.register(notificationRoutes, { prefix: '/v1' });
app.register(discoveryRoutes, { prefix: '/v1' });
app.register(catalogRoutes, { prefix: '/v1' });
app.register(orderRoutes, { prefix: '/v1' });
app.register(orderLifecycleRoutes, { prefix: '/v1' });

const start = async () => {
  try {
    const port = Number(process.env.PORT) || 4000;
    await app.listen({ port, host: '0.0.0.0' });
    // Fastify exposes the underlying Node http.Server; Socket.io rides on it.
    initSocket(app.server);
    app.log.info('Socket.io attached');
  } catch (err) {
    app.log.error(err);
    process.exit(1);
  }
};

start();
