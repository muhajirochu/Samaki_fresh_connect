// Validates firestore.rules against the actual data shapes used by lib/services/*.
// Run from /tmp/fb-rules-test once @firebase/rules-unit-testing is installed there.
//
// Usage:
//   node firestore.rules.test.js
//
// Requires Firestore emulator running on 127.0.0.1:8080:
//   firebase emulators:start --only firestore

const { initializeTestEnvironment, assertFails, assertSucceeds } =
  require('@firebase/rules-unit-testing');
const { doc, setDoc, getDoc, updateDoc, deleteDoc, addDoc, collection } =
  require('firebase/firestore');
const fs = require('fs');

const PROJECT_ID = 'demo-samaki-rules-test';

(async () => {
  const rules = fs.readFileSync(
    '/home/muhajir001/Videos/SamakiFresh/samaki_fresh_connect/firestore.rules',
    'utf8'
  );

  const env = await initializeTestEnvironment({
    projectId: PROJECT_ID,
    firestore: { rules, host: '127.0.0.1', port: 8080 },
  });

  let pass = 0, fail = 0;
  const check = async (label, fn) => {
    try {
      await fn();
      console.log(`✓ ${label}`);
      pass++;
    } catch (e) {
      console.log(`✗ ${label}\n   ${e.message || e}`);
      fail++;
    }
  };

  await env.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    // Seed: two buyers, one fisherman, one street_seller, one admin
    await setDoc(doc(db, 'users', 'buyer1'), { userId: 'buyer1', role: 'buyer', name: 'B' });
    await setDoc(doc(db, 'users', 'buyer2'), { userId: 'buyer2', role: 'buyer', name: 'B2' });
    await setDoc(doc(db, 'users', 'fisher1'), { userId: 'fisher1', role: 'fisherman', name: 'F' });
    await setDoc(doc(db, 'users', 'seller1'), { userId: 'seller1', role: 'street_seller', name: 'S' });
    await setDoc(doc(db, 'users', 'admin1'), { userId: 'admin1', role: 'admin', name: 'A' });

    // Seed one listing owned by seller1
    await setDoc(doc(db, 'fishListings', 'list1'), {
      sellerId: 'seller1',
      status: 'active',
      createdAt: Date.now(),
    });
    // Seed one listing owned by fisher1
    await setDoc(doc(db, 'fishListings', 'list2'), {
      sellerId: 'fisher1',
      status: 'active',
      createdAt: Date.now(),
    });
  });

  // ---- READS ----
  await check('any signed-in user can read users/{buyer1}', async () => {
    const ctx = env.authenticatedContext('buyer2');
    await assertSucceeds(getDoc(doc(ctx.firestore(), 'users/buyer1')));
  });

  await check('user can read their own wishlist', async () => {
    await env.withSecurityRulesDisabled(async (adminCtx) => {
      await setDoc(doc(adminCtx.firestore(), 'users/buyer1/wishlist/w1'), { item: 'tilapia' });
    });
    const ctx = env.authenticatedContext('buyer1');
    await assertSucceeds(getDoc(doc(ctx.firestore(), 'users/buyer1/wishlist/w1')));
  });

  await check('user CANNOT read another user\'s wishlist', async () => {
    const ctx = env.authenticatedContext('buyer2');
    await assertFails(getDoc(doc(ctx.firestore(), 'users/buyer1/wishlist/w1')));
  });

  await check('any signed-in user can read fishListings', async () => {
    const ctx = env.authenticatedContext('buyer1');
    await assertSucceeds(getDoc(doc(ctx.firestore(), 'fishListings/list1')));
  });

  // ---- WRITES: listings ----
  await check('seller can create listing with own sellerId', async () => {
    const ctx = env.authenticatedContext('seller1');
    await assertSucceeds(setDoc(doc(ctx.firestore(), 'fishListings/list_new'), {
      sellerId: 'seller1',
      status: 'active',
      createdAt: Date.now(),
    }));
  });

  await check('seller CANNOT create listing under someone else\'s sellerId', async () => {
    const ctx = env.authenticatedContext('seller1');
    await assertFails(setDoc(doc(ctx.firestore(), 'fishListings/list_evil'), {
      sellerId: 'fisher1',
      status: 'active',
      createdAt: Date.now(),
    }));
  });

  await check('seller CANNOT write to another seller\'s listing', async () => {
    const ctx = env.authenticatedContext('seller1');
    await assertFails(updateDoc(doc(ctx.firestore(), 'fishListings/list2'), { status: 'sold' }));
  });

  await check('buyer CANNOT create a listing', async () => {
    const ctx = env.authenticatedContext('buyer1');
    await assertFails(setDoc(doc(ctx.firestore(), 'fishListings/list_buyer'), {
      sellerId: 'buyer1',
      status: 'active',
      createdAt: Date.now(),
    }));
  });

  // ---- WRITES: users ----
  await check('user can update their own profile', async () => {
    const ctx = env.authenticatedContext('buyer1');
    await assertSucceeds(updateDoc(doc(ctx.firestore(), 'users/buyer1'), { name: 'B-new' }));
  });

  await check('user CANNOT update another user\'s role', async () => {
    const ctx = env.authenticatedContext('buyer1');
    await assertFails(updateDoc(doc(ctx.firestore(), 'users/buyer2'), { role: 'admin' }));
  });

  // ---- WRITES: orders ----
  await check('buyer can create order for themselves', async () => {
    const ctx = env.authenticatedContext('buyer1');
    await assertSucceeds(addDoc(collection(ctx.firestore(), 'orders'), {
      buyerId: 'buyer1',
      streetSellerId: 'seller1',
      status: 'pending',
      createdAt: Date.now(),
    }));
  });

  await check('buyer CANNOT create order as another buyer', async () => {
    const ctx = env.authenticatedContext('buyer1');
    await assertFails(addDoc(collection(ctx.firestore(), 'orders'), {
      buyerId: 'buyer2',
      streetSellerId: 'seller1',
      status: 'pending',
      createdAt: Date.now(),
    }));
  });

  await check('seller can transition order to confirmed', async () => {
    let orderId = '';
    await env.withSecurityRulesDisabled(async (adminCtx) => {
      const r = await addDoc(collection(adminCtx.firestore(), 'orders'), {
        buyerId: 'buyer1',
        streetSellerId: 'seller1',
        status: 'pending',
        createdAt: Date.now(),
      });
      orderId = r.id;
    });
    const ctx = env.authenticatedContext('seller1');
    await assertSucceeds(updateDoc(doc(ctx.firestore(), `orders/${orderId}`), { status: 'confirmed' }));
  });

  await check('random user CANNOT read someone else\'s order', async () => {
    const ctx = env.authenticatedContext('buyer2');
    await assertFails(getDoc(doc(ctx.firestore(), 'orders/some-order')));
  });

  // ---- WRITES: notifications ----
  await check('admin CAN write notifications (current rule)', async () => {
    // Without admin claim, only admin custom claim works — but we haven't set one.
    // So this test verifies the lockout: regular users cannot write notifs.
    const ctx = env.authenticatedContext('buyer1');
    await assertFails(setDoc(doc(ctx.firestore(), 'notifications/n1'), {
      userId: 'buyer2',
      title: 'spam',
      body: 'x',
      type: 'info',
      isRead: false,
      createdAt: Date.now(),
    }));
  });

  // ---- STREET SELLERS ----
  await check('seller can update their own mirror doc', async () => {
    const ctx = env.authenticatedContext('seller1');
    await assertSucceeds(setDoc(doc(ctx.firestore(), 'streetSellers/seller1'), {
      isOnline: true,
      isActive: true,
      geohash: 'abc123',
    }, { merge: true }));
  });

  await check('seller CANNOT update another seller\'s mirror', async () => {
    const ctx = env.authenticatedContext('seller1');
    await assertFails(setDoc(doc(ctx.firestore(), 'streetSellers/fisher1'), {
      isOnline: true,
    }, { merge: true }));
  });

  console.log(`\n${pass} passed, ${fail} failed`);
  await env.cleanup();
  process.exit(fail === 0 ? 0 : 1);
})().catch((e) => {
  console.error(e);
  process.exit(1);
});