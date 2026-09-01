import type { FastifyInstance } from 'fastify';
import { prisma } from '../lib/prisma';

const EARTH_RADIUS_KM = 6371;
const KM_PER_DEG_LAT = 111.045; // good enough for a bounding box
const DEFAULT_MAX_RADIUS_KM = 10;

/** Great-circle distance in km between two lat/lng points. */
function haversineKm(lat1: number, lng1: number, lat2: number, lng2: number): number {
  const toRad = (d: number) => (d * Math.PI) / 180;
  const dLat = toRad(lat2 - lat1);
  const dLng = toRad(lng2 - lng1);
  const a =
    Math.sin(dLat / 2) ** 2 +
    Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) * Math.sin(dLng / 2) ** 2;
  return EARTH_RADIUS_KM * 2 * Math.asin(Math.sqrt(a));
}

interface NearbyQuery {
  lat?: string;
  lng?: string;
  maxRadiusKm?: string;
}

export default async function discoveryRoutes(app: FastifyInstance) {
  // GET /v1/vendors/nearby — public
  //
  // NOTE: bounding-box prefilter + in-memory Haversine is fine at low vendor
  // counts. If the vendor table grows large this should move to a PostGIS
  // `ST_DWithin` query or a geospatial index rather than scanning the box.
  app.get<{ Querystring: NearbyQuery }>('/vendors/nearby', async (request, reply) => {
    const lat = Number(request.query.lat);
    const lng = Number(request.query.lng);
    if (
      request.query.lat === undefined ||
      request.query.lng === undefined ||
      !Number.isFinite(lat) ||
      !Number.isFinite(lng) ||
      lat < -90 ||
      lat > 90 ||
      lng < -180 ||
      lng > 180
    ) {
      return reply
        .code(400)
        .send({ error: 'lat and lng are required and must be valid coordinates' });
    }

    let maxRadiusKm = DEFAULT_MAX_RADIUS_KM;
    if (request.query.maxRadiusKm !== undefined) {
      maxRadiusKm = Number(request.query.maxRadiusKm);
      if (!Number.isFinite(maxRadiusKm) || maxRadiusKm <= 0) {
        return reply.code(400).send({ error: 'maxRadiusKm must be a positive number' });
      }
    }

    // Rough bounding box around (lat, lng) sized to maxRadiusKm so we don't scan
    // every vendor row. Longitude degrees shrink with latitude; clamp cos near the poles.
    const latDelta = maxRadiusKm / KM_PER_DEG_LAT;
    const lngDelta =
      maxRadiusKm / (KM_PER_DEG_LAT * Math.max(Math.cos((lat * Math.PI) / 180), 0.01));

    const candidates = await prisma.vendor.findMany({
      where: {
        status: 'APPROVED',
        isOpen: true,
        latitude: { gte: lat - latDelta, lte: lat + latDelta },
        longitude: { gte: lng - lngDelta, lte: lng + lngDelta },
      },
      select: {
        id: true,
        storeName: true,
        latitude: true,
        longitude: true,
        deliveryRadiusKm: true,
      },
    });

    const results = candidates
      .map((v) => ({
        id: v.id,
        storeName: v.storeName,
        latitude: v.latitude,
        longitude: v.longitude,
        deliveryRadiusKm: v.deliveryRadiusKm,
        distanceKm: haversineKm(lat, lng, v.latitude, v.longitude),
      }))
      // must be inside both the vendor's own delivery radius and the search cap
      .filter((v) => v.distanceKm <= Math.min(v.deliveryRadiusKm, maxRadiusKm))
      .sort((a, b) => a.distanceKm - b.distanceKm)
      .map((v) => ({ ...v, distanceKm: Math.round(v.distanceKm * 100) / 100 }));

    return results;
  });
}
