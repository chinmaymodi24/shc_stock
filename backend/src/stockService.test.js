/* eslint-disable no-console */
// Stock can never go negative. Run with:
//   node src/stockService.test.js
// (No test runner in this project — plain asserts, non-zero exit on failure.)
//
// A real -2 reached a customer dashboard: a manual "+2" adjustment was
// deleted after those units had already left, and the undo subtracted them a
// second time. Two paths could do that, because neither has the shortfall
// check a sale does — reversing a purchase, and deleting an adjustment. Both
// now go through shiftStock, which floors at zero.

const assert = require('assert');
const { shiftStock, reverseStockFor } = require('./stockService');

/// A stand-in for Prisma's transaction client, holding products and movements
/// in memory. Only the handful of calls these two paths make are implemented.
function fakeTx({ products = {}, movements = [] } = {}) {
  return {
    products,
    movements,
    product: {
      findUnique: async ({ where }) =>
        products[where.id] ? { ...products[where.id] } : null,
      update: async ({ where, data }) => {
        Object.assign(products[where.id], data);
        return products[where.id];
      },
    },
    stockMovement: {
      findMany: async ({ where }) =>
        movements.filter(
          (m) => m.refType === where.refType && m.refId === where.refId
        ),
      deleteMany: async ({ where }) => {
        const before = movements.length;
        for (let i = movements.length - 1; i >= 0; i--) {
          if (
            movements[i].refType === where.refType &&
            movements[i].refId === where.refId
          ) {
            movements.splice(i, 1);
          }
        }
        return { count: before - movements.length };
      },
    },
  };
}

const tests = [
  {
    why: 'a normal decrement just decrements',
    run: async () => {
      const tx = fakeTx({ products: { 1: { id: 1, currentStock: 10 } } });
      await shiftStock(tx, 1, -4);
      assert.strictEqual(tx.products[1].currentStock, 6);
    },
  },
  {
    why: 'an increment adds',
    run: async () => {
      const tx = fakeTx({ products: { 1: { id: 1, currentStock: 3 } } });
      await shiftStock(tx, 1, 5);
      assert.strictEqual(tx.products[1].currentStock, 8);
    },
  },
  {
    why: 'a decrement past zero stops AT zero, never below',
    run: async () => {
      const tx = fakeTx({ products: { 1: { id: 1, currentStock: 0 } } });
      await shiftStock(tx, 1, -2); // the exact shape of the reported bug
      assert.strictEqual(tx.products[1].currentStock, 0);
    },
  },
  {
    why: 'a partial shortfall still lands on zero',
    run: async () => {
      const tx = fakeTx({ products: { 1: { id: 1, currentStock: 3 } } });
      await shiftStock(tx, 1, -10);
      assert.strictEqual(tx.products[1].currentStock, 0);
    },
  },
  {
    why: 'a product deleted since the movement was written is skipped',
    run: async () => {
      const tx = fakeTx({ products: {} });
      await shiftStock(tx, 99, -5); // must not throw
    },
  },
  {
    why: 'reversing a received purchase whose goods are gone floors at zero',
    run: async () => {
      const tx = fakeTx({
        products: { 1: { id: 1, currentStock: 0 } },
        movements: [
          { id: 1, productId: 1, type: 'IN', qty: 5, refType: 'purchase', refId: 7 },
        ],
      });
      const undone = await reverseStockFor(tx, 'purchase', 7);
      assert.strictEqual(undone, 1);
      assert.strictEqual(tx.products[1].currentStock, 0);
      assert.strictEqual(tx.movements.length, 0, 'log rows removed too');
    },
  },
  {
    why: 'reversing a sale puts the stock back',
    run: async () => {
      const tx = fakeTx({
        products: { 1: { id: 1, currentStock: 2 } },
        movements: [
          { id: 1, productId: 1, type: 'OUT', qty: 3, refType: 'sale', refId: 9 },
        ],
      });
      await reverseStockFor(tx, 'sale', 9);
      assert.strictEqual(tx.products[1].currentStock, 5);
    },
  },
  {
    why: 'reversing an order with several lines floors each one separately',
    run: async () => {
      const tx = fakeTx({
        products: {
          1: { id: 1, currentStock: 10 },
          2: { id: 2, currentStock: 1 },
        },
        movements: [
          { id: 1, productId: 1, type: 'IN', qty: 4, refType: 'purchase', refId: 3 },
          { id: 2, productId: 2, type: 'IN', qty: 6, refType: 'purchase', refId: 3 },
        ],
      });
      await reverseStockFor(tx, 'purchase', 3);
      assert.strictEqual(tx.products[1].currentStock, 6, 'had the stock');
      assert.strictEqual(tx.products[2].currentStock, 0, 'did not, so floors');
    },
  },
];

(async () => {
  let failed = 0;
  for (const t of tests) {
    try {
      await t.run();
      console.log(`  ok   ${t.why}`);
    } catch (err) {
      failed++;
      console.error(`  FAIL ${t.why}\n       ${err.message}`);
    }
  }
  console.log(`\n${tests.length - failed}/${tests.length} passed`);
  process.exit(failed ? 1 : 0);
})();
