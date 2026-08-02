// Firestore data migration: rename `fishermanId` → `streetSellerId`
// across every configured collection.
//
// Wave 3 of the cleanup removed the legacy role from client code and
// Firestore rules. This script completes the migration on the data
// layer.
//
// Environment (set by the .sh wrapper):
//   PROJECT_ID    — Firebase project id (required)
//   USE_EMULATOR  — "true" to connect to local emulator at 127.0.0.1:8080
//   DRY_RUN       — "true" to log every change without writing
//   LOG_FILE      — path to write the full log

const fs = require('fs');
const path = require('path');

// Resolve firebase-admin from the temp install dir.
const admin = require(path.join(process.env.SCRIPT_DIR, 'node_modules', 'firebase-admin'));

const COLLECTIONS = [
  'users',
  'streetSellers',
  'fishListings',
  'fishRequests',
  'orders',
  'notifications',
  'fishCategories',
  'activityLogs',
];

const DRY_RUN = process.env.DRY_RUN === 'true';
const USE_EMULATOR = process.env.USE_EMULATOR === 'true';
const PROJECT_ID = process.env.PROJECT_ID;
const LOG_FILE = process.env.LOG_FILE;

if (!PROJECT_ID) {
  console.error('PROJECT_ID is required');
  process.exit(1);
}

if (USE_EMULATOR) {
  // Emulator override — Firebase Admin lets us poke the emulator by
  // shimming the FIRESTORE_EMULATOR_HOST env var before init.
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
 * Decide whether a doc needs migration.
 *
 * Returns the write payload (object) or null if the doc is already
 * consistent. The payload is the field-level update to apply via
 * `firestore.FieldValue`.
 */
function migrationPayload(data) {
  const hasFisher = Object.prototype.hasOwnProperty.call(data, 'fishermanId');
  if (!hasFisher) return null;

  const fisherValue = data.fishermanId;
  const hasStreet = Object.prototype.hasOwnProperty.call(data, 'streetSellerId');
  const streetValue = hasStreet ? data.streetSellerId : null;

  // Skip if streetSellerId already matches fishermanId.
  if (hasStreet && fisherValue === streetValue) return null;

  // Build the write: copy fishermanId over streetSellerId, delete
  // fishermanId.
  const update = {
    streetSellerId: fisherValue,
    fishermanId: admin.firestore.FieldValue.delete(),
  };
  return update;
}

async function migrate() {
  log(`Migration start. Project=${PROJECT_ID} emulator=${USE_EMULATOR} dry-run=${DRY_RUN}`);
  log(`Collections: ${COLLECTIONS.join(', ')}`);
  log('');

  const totals = { scanned: 0, migrated: 0, skipped: 0, errors: 0 };

  for (const collectionName of COLLECTIONS) {
    log(`--- Collection: ${collectionName} ---`);
    const collectionRef = db.collection(collectionName);

    // List in pages of 500 (Firestore max page size).
    let offset = 0;
    const pageSize = 500;
    let pageCount = 0;

    while (true) {
      const snapshot = await collectionRef
        .orderBy(admin.firestore.FieldPath.documentId())
        .offset(offset)
        .limit(pageSize)
        .get();

      if (snapshot.empty) break;
      pageCount++;

      for (const doc of snapshot.docs) {
        totals.scanned++;
        try {
          const payload = migrationPayload(doc.data());
          if (!payload) {
            totals.skipped++;
            continue;
          }

          if (DRY_RUN) {
            log(`  [dry-run] ${collectionName}/${doc.id} would be migrated`);
            totals.migrated++; // count what we *would* have migrated
          } else {
            await doc.ref.update(payload);
            log(`  migrated ${collectionName}/${doc.id}`);
            totals.migrated++;
          }
        } catch (err) {
          totals.errors++;
          log(`  ERROR ${collectionName}/${doc.id}: ${err.message}`);
        }
      }

      if (snapshot.size < pageSize) break;
      offset += pageSize;
    }

    log(`  ${collectionName}: ${pageCount} page(s) processed`);
  }

  log('');
  log('========================================');
  log('Migration summary');
  log('========================================');
  log(`  Documents scanned:   ${totals.scanned}`);
  log(`  Documents migrated:  ${totals.migrated}`);
  log(`  Documents skipped:   ${totals.skipped}`);
  log(`  Errors:              ${totals.errors}`);
  log(`  Mode:                ${DRY_RUN ? 'DRY RUN' : 'LIVE'}`);

  if (LOG_FILE) {
    fs.writeFileSync(LOG_FILE, logLines.join('\n') + '\n');
    log(`Log written to ${LOG_FILE}`);
  }

  if (totals.errors > 0) {
    process.exit(2);
  }
}

migrate().catch((err) => {
  console.error('Migration failed:', err);
  process.exit(1);
});
