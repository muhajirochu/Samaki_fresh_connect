// Firestore data migration: backfill `fishType`, `sellerLat`, `sellerLng`
// onto every existing `orders` document.
//
// The "Popular Near You" section now ranks fish by the buyer's local
// completed-order volume, weighted by recency. The aggregation lives
// in `lib/providers/buyer_provider.dart` (`_popularDemandProvider`)
// and reads those three denormalized fields off each order so a
// buyer-dashboard render needs only the order stream — no per-order
// join back to the listing collection.
//
// New orders stamp the fields at create time (see
// `OrderService.createOrder` call sites in `lib/screens/buyer/`,
// `lib/screens/common/fish_listing_detail_screen.dart`, and
// `lib/widgets/requests/send_request_sheet.dart`). This script
// backfills the historical orders that were written before that
// change so the demand map is complete on the next dashboard render.
//
// Per write we read the source listing once, extract
// `fishType` / `location.latitude` / `location.longitude`, and write
// them back onto the order. We batch the listing reads using
// `whereIn` (capped at 30 ids per round-trip — Firestore's limit) to
// avoid an N+1 read storm against the `fishListings` collection.
//
// Environment (set by the .sh wrapper):
//   PROJECT_ID    — Firebase project id (required)
//   USE_EMULATOR  — "true" to connect to local emulator at 127.0.0.1:8080
//   DRY_RUN       — "true" to log every change without writing
//   LOG_FILE      — path to write the full log
//
// Idempotence: a document is only mutated if at least one of the
// three target fields is missing. A re-run against an already-
// migrated collection is a no-op.

const fs = require('fs');
const path = require('path');

const admin = require(path.join(process.env.SCRIPT_DIR, 'node_modules', 'firebase-admin'));

const COLLECTION = 'orders';
const LISTINGS_COLLECTION = 'fishListings';
const FIRESTORE_IN_LIMIT = 30; // Firestore `whereIn` upper bound

const DRY_RUN = process.env.DRY_RUN === 'true';
const USE_EMULATOR = process.env.USE_EMULATOR === 'true';
const PROJECT_ID = process.env.PROJECT_ID;
const LOG_FILE = process.env.LOG_FILE;

if (!PROJECT_ID) {
  console.error('PROJECT_ID is required');
  process.exit(1);
}

if (USE_EMULATOR) {
  process.env.FIRESTORE_EMULATOR_HOST = '127.0.0.1:8080';
  process.env.FIREBASE_AUTH_EMULATOR_HOST = '127.0.0.1:9099';
  console.log('  → Connecting to local emulator at 127.0.0.1:8080');
}

admin.initializeApp({ projectId: PROJECT_ID });
const db = admin.firestore();

const logLines = [];
const log = (msg) => {
  const line = `[${new Date().toISOString()}] ${msg}`;
  console.log(line);
  logLines.push(line);
};

/**
 * Build the write payload for a single order given its current data
 * and the resolved source listing. Returns `null` if no fields are
 * missing (idempotent re-run).
 */
function buildPayload(orderData, listingData) {
  const update = {};
  if (!orderData.fishType && listingData && listingData.fishType) {
    update.fishType = listingData.fishType;
  }
  if (orderData.sellerLat == null && listingData) {
    const lat = readLat(listingData);
    if (lat != null) update.sellerLat = lat;
  }
  if (orderData.sellerLng == null && listingData) {
    const lng = readLng(listingData);
    if (lng != null) update.sellerLng = lng;
  }
  return Object.keys(update).length > 0 ? update : null;
}

function readLat(listing) {
  if (typeof listing.latitude === 'number') return listing.latitude;
  if (listing.location && typeof listing.location.latitude === 'number') {
    return listing.location.latitude;
  }
  return null;
}

function readLng(listing) {
  if (typeof listing.longitude === 'number') return listing.longitude;
  if (listing.location && typeof listing.location.longitude === 'number') {
    return listing.location.longitude;
  }
  return null;
}

/**
 * Read a single page of orders, filtering to docs that are missing at
 * least one of the target fields. We rely on client-side filtering
 * because Firestore has no "field missing" predicate, and a missing-
 * field check needs the document contents anyway.
 */
async function fetchOrdersNeedingBackfill(pageSize, offset) {
  const snap = await db
    .collection(COLLECTION)
    .orderBy(admin.firestore.FieldPath.documentId())
    .offset(offset)
    .limit(pageSize)
    .get();

  const needs = [];
  for (const doc of snap.docs) {
    const data = doc.data();
    if (
      !data.fishType ||
      data.sellerLat == null ||
      data.sellerLng == null
    ) {
      needs.push(doc);
    }
  }
  return { docs: snap.docs, needs };
}

/**
 * Batch-fetch listings for the given order docs using `whereIn`,
 * returning a Map<listingId, listingData> for the ones that still
 * exist. We chunk into FIRESTORE_IN_LIMIT-sized slices because
 * Firestore rejects wider `whereIn` queries.
 */
async function fetchListingsForOrders(orders) {
  const ids = [...new Set(orders.map((o) => o.data().listingId).filter(Boolean))];
  const out = new Map();
  for (let i = 0; i < ids.length; i += FIRESTORE_IN_LIMIT) {
    const chunk = ids.slice(i, i + FIRESTORE_IN_LIMIT);
    const snap = await db
      .collection(LISTINGS_COLLECTION)
      .where(admin.firestore.FieldPath.documentId(), 'in', chunk)
      .get();
    for (const d of snap.docs) {
      out.set(d.id, d.data());
    }
  }
  return out;
}

async function migrate() {
  log(`Backfill start. Project=${PROJECT_ID} emulator=${USE_EMULATOR} dry-run=${DRY_RUN}`);
  log(`Collection: ${COLLECTION}`);
  log('');

  const totals = { scanned: 0, needs: 0, migrated: 0, skipped: 0, missingListing: 0, errors: 0 };

  let offset = 0;
  const pageSize = 500;
  let pageCount = 0;

  while (true) {
    const { docs, needs } = await fetchOrdersNeedingBackfill(pageSize, offset);
    if (docs.length === 0) break;
    pageCount++;
    totals.scanned += docs.length;
    totals.needs += needs.length;

    // Skip the listing fetch entirely if nothing on this page needs
    // backfill — saves the cross-collection round-trip on already-
    // migrated pages.
    if (needs.length > 0) {
      const listingsById = await fetchListingsForOrders(needs);
      for (const doc of needs) {
        try {
          const orderData = doc.data();
          const listingData = listingsById.get(orderData.listingId);
          if (!listingData) {
            totals.missingListing++;
            log(`  no listing for ${COLLECTION}/${doc.id} (listingId=${orderData.listingId}) — skipping`);
            continue;
          }
          const payload = buildPayload(orderData, listingData);
          if (!payload) {
            totals.skipped++;
            continue;
          }
          if (DRY_RUN) {
            log(`  [dry-run] ${COLLECTION}/${doc.id} would be backfilled: ${Object.keys(payload).join(', ')}`);
            totals.migrated++;
          } else {
            await doc.ref.update(payload);
            log(`  backfilled ${COLLECTION}/${doc.id}: ${Object.keys(payload).join(', ')}`);
            totals.migrated++;
          }
        } catch (err) {
          totals.errors++;
          log(`  ERROR ${COLLECTION}/${doc.id}: ${err.message}`);
        }
      }
    }

    if (docs.length < pageSize) break;
    offset += pageSize;
  }

  log('');
  log('========================================');
  log('Backfill summary');
  log('========================================');
  log(`  Pages processed:      ${pageCount}`);
  log(`  Documents scanned:    ${totals.scanned}`);
  log(`  Needing backfill:     ${totals.needs}`);
  log(`  Documents backfilled: ${totals.migrated}`);
  log(`  Skipped (already ok): ${totals.skipped}`);
  log(`  Missing listing:      ${totals.missingListing}`);
  log(`  Errors:               ${totals.errors}`);
  log(`  Mode:                 ${DRY_RUN ? 'DRY RUN' : 'LIVE'}`);

  if (LOG_FILE) {
    fs.writeFileSync(LOG_FILE, logLines.join('\n') + '\n');
    log(`Log written to ${LOG_FILE}`);
  }

  if (totals.errors > 0) {
    process.exit(2);
  }
}

migrate().catch((err) => {
  console.error('Backfill failed:', err);
  process.exit(1);
});
