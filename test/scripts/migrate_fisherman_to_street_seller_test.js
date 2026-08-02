// Unit tests for the migration script's payload decision logic.
//
// The script runs against a real Firestore project (or emulator) —
// these tests verify the branching rules that decide whether a doc
// needs migration and what the write payload looks like.
//
// Run with: node test/scripts/migrate_fisherman_to_street_seller_test.js
// (or via mocha if you install it; the script is plain Node and the
// asserts are self-explanatory).

const assert = require('node:assert/strict');

// Mirror the function from migrate_fisherman_to_street_seller.js so
// the tests can be run without bootstrapping the script's full module
// (which requires firebase-admin installed). If the script's logic
// changes, mirror the change here.
function migrationPayload(data, FieldValue) {
  const hasFisher = Object.prototype.hasOwnProperty.call(data, 'fishermanId');
  if (!hasFisher) return null;

  const fisherValue = data.fishermanId;
  const hasStreet = Object.prototype.hasOwnProperty.call(data, 'streetSellerId');
  const streetValue = hasStreet ? data.streetSellerId : null;

  if (hasStreet && fisherValue === streetValue) return null;

  return {
    streetSellerId: fisherValue,
    fishermanId: FieldValue.delete(),
  };
}

const sentinel = {
  delete() {
    return { __delete: true };
  },
};

const cases = [
  {
    name: 'no fishermanId → unchanged',
    data: { streetSellerId: 'seller1' },
    expected: null,
  },
  {
    name: 'fishermanId matches existing streetSellerId → unchanged',
    data: { fishermanId: 'seller1', streetSellerId: 'seller1' },
    expected: null,
  },
  {
    name: 'fishermanId + missing streetSellerId → copy + delete',
    data: { fishermanId: 'seller1' },
    expected: {
      streetSellerId: 'seller1',
      fishermanId: { __delete: true },
    },
  },
  {
    name: 'fishermanId + differing streetSellerId → overwrite + delete',
    data: { fishermanId: 'seller1', streetSellerId: 'seller2' },
    expected: {
      streetSellerId: 'seller1',
      fishermanId: { __delete: true },
    },
  },
  {
    name: 'fishermanId + empty streetSellerId → fill + delete',
    data: { fishermanId: 'seller1', streetSellerId: '' },
    expected: {
      streetSellerId: 'seller1',
      fishermanId: { __delete: true },
    },
  },
  {
    name: 'fishermanId + null streetSellerId → fill + delete',
    data: { fishermanId: 'seller1', streetSellerId: null },
    expected: {
      streetSellerId: 'seller1',
      fishermanId: { __delete: true },
    },
  },
];

let failed = 0;
for (const c of cases) {
  const got = migrationPayload(c.data, sentinel);
  try {
    assert.deepStrictEqual(got, c.expected);
    console.log(`  ✓ ${c.name}`);
  } catch (err) {
    console.log(`  ✗ ${c.name}`);
    console.log(`    expected: ${JSON.stringify(c.expected)}`);
    console.log(`    actual:   ${JSON.stringify(got)}`);
    failed++;
  }
}

console.log('');
console.log(`${cases.length - failed} passed, ${failed} failed`);
process.exit(failed === 0 ? 0 : 1);
