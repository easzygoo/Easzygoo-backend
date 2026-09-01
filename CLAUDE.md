# EaszyGoo

Hyper-local on-demand vegetable/grocery delivery platform for the Indian market (Swiggy Instamart / Blinkit model). Four actor types — customers, vendors, riders, admins — across five applications in one Turborepo monorepo.

**Status: Pre-development.** Architecture, tech stack, and PRD are finalized (see below), but no code has been written yet. This is a from-scratch build — don't assume any existing implementation.

## Monorepo layout (target structure — to be created)

- `apps/customer` — Customer mobile app (React Native)
- `apps/vendor` — Vendor mobile app (React Native)
- `apps/rider` — Rider/delivery mobile app (React Native)
- `apps/admin` — Admin panel (Next.js 15)
- `apps/backend` — Fastify + TypeScript API
- `packages/api-client` — shared typed API client used across all apps
- `packages/*` — shared types/utils

## Tech stack (decided)

| Layer | Technology |
|---|---|
| Backend | Fastify + TypeScript + Prisma ORM |
| Database | PostgreSQL, with a read replica for admin/analytics traffic |
| Cache/Queue | Redis (keep cache, queue, and rate-limit traffic logically separated — see Known Pitfalls), BullMQ |
| Real-time | Socket.io with Redis adapter |
| Auth | Firebase Admin SDK (OTP-based) |
| Storage | Cloudinary |
| Payments | Razorpay |
| Payouts | Cashfree |
| Admin panel | Next.js 15 |
| Mobile apps | React Native |
| Monorepo tooling | Turborepo |

## Build order (phases)

1. **Foundations** — env/secrets setup (Firebase creds, Maps API key, JWT secret, Redis provider), Prisma schema + core catalog CRUD, auth flows for all 3 roles
2. **Payments** — Razorpay/Cashfree integration + merchant KYC onboarding. Start merchant onboarding immediately in parallel — it takes several business days and shouldn't block other work
3. **Core commerce** — cart, coupons, nearby vendor discovery/search, push notifications (FCM), crash reporting (Sentry)
4. **Hardening** — integration tests, webhook dead-letter queue via BullMQ, graceful shutdown with job draining, E2E smoke tests, load testing before public launch

## Known pitfalls to avoid from day 1

- **Redis provider choice**: many free tiers (Upstash included) expose only a single logical DB, which breaks setups that expect separate DBs for caching, queues, and rate-limiting. Pick Redis Cloud from the start, or design `redisConn` around key-prefix separation instead of DB indices — don't discover this after queues are already built.
- **Connection pooling**: with 4 apps hitting Postgres, use a provider with built-in pooling (Supabase, or RDS + PgBouncer) from the first migration, not as an afterthought.

## Infrastructure

- Backend as a PM2 cluster behind Nginx, Cloudflare CDN in front. Target ~1,000–2,000 concurrent users at launch.
- Recommended hosting: Render (backend — Standard tier + a dedicated Background Worker for BullMQ), Supabase (PostgreSQL with built-in PgBouncer), Redis Cloud, Vercel (admin panel), Expo EAS Build (mobile apps).

## Working conventions

- Anything async (notifications, payout processing, webhook retries, order-state transitions) goes through a BullMQ queue — never synchronous in the request path.
- Admin/analytics queries go through the read replica, not the primary, from the first reporting query written.
- All 3 mobile apps call the API only through the shared `api-client` package — no ad-hoc fetch/axios calls in app code.
- API versioned under `/v1/` from the start.

## Commands

> Set these up as part of Phase 1 and update once the actual `package.json` scripts exist.

```bash
pnpm install          # install all workspace deps
turbo dev             # run all apps in dev mode
turbo build           # build all apps
turbo test            # run test suites
```

## When starting a session

1. Confirm which phase the current task belongs to before proposing an approach — don't jump ahead to Phase 3/4 work while Phase 1 foundations are incomplete.
2. If a task touches payments, check whether merchant KYC/API keys have arrived yet.
3. Build the backend contract (schema + API shape) before starting any of the 3 mobile apps, so they're not built against a moving target.
