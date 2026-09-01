# EaszyGoo

Hyperlocal vegetable/grocery delivery platform — Customer, Vendor, and Rider apps, an Admin panel, and a shared Fastify backend, in one Turborepo monorepo.

## Structure
- apps/backend — Fastify + TypeScript API
- apps/admin — Next.js 15 admin panel
- apps/customer, apps/vendor, apps/rider — Expo/React Native apps
- packages/api-client — shared typed API client

## Getting started
1. Copy `.env.example` to `.env` and fill in credentials
2. `pnpm install`
3. `pnpm dev` — runs all apps in parallel via Turborepo

See CLAUDE.md for architecture, build phases, and working conventions.
