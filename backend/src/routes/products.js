const express = require('express');
const prisma = require('../prismaClient');
const { stockStatus, committedByProduct, applyStock } = require('../stockService');
const { getAppSettings } = require('../appSettings');
const { actorName } = require('../auth/middleware');
const { listResponse } = require('../pagination');
const V = require('../validate');
const { unitAllowsFraction } = require('../units');

const router = express.Router();
router.param('id', require('../validate').idParam);

/// 'inStock' | 'lowStock' | 'outOfStock' | 'inactive' — same derivation the
/// inventory list uses, so the products list's stock badge honours the global
/// low-stock threshold instead of only the per-product minimum.
function withStockStatus(product, lowStockThreshold) {
  return { ...product, stockStatus: stockStatus(product, lowStockThreshold) };
}

const productInclude = {
  category: true,
  subCategory: true,
};

/// Adds what the apps need to judge "can I sell this?": the units other open
/// sales have already claimed, and what is genuinely free.
function withAvailability(product, committed) {
  const held = committed.get(product.id) || 0;
  return {
    ...product,
    committedStock: held,
    availableStock: Math.max(product.currentStock - held, 0),
  };
}

/// The validated fields of a product body. Only fields that were actually sent
/// come back, so a PUT changes just what it was given — it used to rewrite
/// every column, zeroing anything the caller left out.
///
/// currentStock is deliberately NOT here. Stock is owned by the movement
/// ledger (purchases, sales, adjustments); letting a product edit set it
/// overwrote live stock with whatever the edit form had loaded earlier, and
/// left the ledger disagreeing with the number.
function productFields(body, actor, { creating }) {
  const has = (k) => body[k] !== undefined;
  const data = { modifiedBy: actor, modifiedAt: new Date() };

  if (creating || has('name')) data.name = V.text(body.name, 'name', { required: true, max: 200 });
  if (creating || has('sku')) data.sku = V.text(body.sku, 'sku', { required: true, max: 100 });
  if (creating || has('categoryId')) data.categoryId = V.id(body.categoryId, 'categoryId');
  if (has('subCategoryId')) data.subCategoryId = V.optionalId(body.subCategoryId, 'subCategoryId');
  if (creating || has('unit')) data.unit = V.text(body.unit, 'unit', { required: true, max: 40 });
  if (has('imageUrl')) data.imageUrl = V.text(body.imageUrl, 'imageUrl', { max: 500 }) || null;
  if (creating || has('sellingPrice')) {
    data.sellingPrice = V.money(body.sellingPrice, 'sellingPrice', { required: true });
  }
  if (creating || has('costPrice')) {
    data.costPrice = V.money(body.costPrice, 'costPrice', { required: true });
  }
  if (has('minimumStock')) data.minimumStock = V.stockQty(body.minimumStock, 'minimumStock');
  if (has('isActive')) data.isActive = body.isActive === true;
  if (has('brand')) data.brand = V.text(body.brand, 'brand', { max: 100 }) || null;
  if (has('hsnCode')) data.hsnCode = V.text(body.hsnCode, 'hsnCode', { max: 20 }) || null;
  if (has('description')) data.description = V.text(body.description, 'description', { max: 2000 }) || null;
  if (has('taxPercent')) data.taxPercent = V.number(body.taxPercent, 'taxPercent', { min: 0, max: 100 });
  if (has('stockLocation')) {
    data.stockLocation = V.text(body.stockLocation, 'stockLocation', { max: 100 }) || 'Main Warehouse';
  }
  for (const k of ['densityVariants', 'boardVariants', 'thicknessVariants', 'reinforcementTypes']) {
    if (has(k)) {
      if (!Array.isArray(body[k])) V.fail(`${k} must be a list`);
      data[k] = body[k].map((v) => V.text(v, k, { max: 100 })).filter(Boolean);
    }
  }
  if (has('otherSpecs')) data.otherSpecs = V.text(body.otherSpecs, 'otherSpecs', { max: 2000 }) || null;

  if (creating) {
    data.minimumStock ??= 0;
    data.taxPercent ??= 18;
  }
  return data;
}

/// A second product with the same name under the same category and
/// sub-category is almost always a double entry, and it makes the product
/// pickers on Add Sale / Add Purchase ambiguous.
async function assertNameFree(name, categoryId, subCategoryId, exceptId) {
  const clash = await prisma.product.findFirst({
    where: {
      name: { equals: name, mode: 'insensitive' },
      categoryId,
      subCategoryId: subCategoryId ?? null,
      ...(exceptId ? { id: { not: exceptId } } : {}),
    },
    select: { sku: true },
  });
  if (clash) {
    const e = new Error(`A product named "${name}" already exists in this category (${clash.sku})`);
    e.status = 409;
    throw e;
  }
}

/// A sub-category must belong to the category the product is filed under.
async function assertSubCategoryMatches(categoryId, subCategoryId) {
  if (subCategoryId == null) return;
  const sub = await prisma.subCategory.findUnique({
    where: { id: subCategoryId },
    select: { categoryId: true },
  });
  if (!sub) V.fail('subCategoryId does not exist');
  if (categoryId != null && sub.categoryId !== categoryId) {
    V.fail('That sub-category does not belong to the selected category');
  }
}

// GET /api/products
router.get('/', async (req, res, next) => {
  try {
    // Last added / modified first (updatedAt covers both).
    const { lowStockThreshold } = await getAppSettings();
    const committed = await committedByProduct(prisma);
    res.json(await listResponse({
      query: req.query,
      findMany: (page) => prisma.product.findMany({
        orderBy: [{ updatedAt: 'desc' }, { id: 'desc' }],
        include: productInclude,
        ...page,
      }),
      count: () => prisma.product.count(),
      transform: (rows) =>
        rows.map((p) => withStockStatus(withAvailability(p, committed), lowStockThreshold)),
    }));
  } catch (err) {
    next(err);
  }
});

// POST /api/products
//
// A product starts at zero. If the caller supplies an opening stock it is
// booked as a real "Opening stock" ledger entry, so the number and the ledger
// agree from the first day.
router.post('/', async (req, res, next) => {
  try {
    const actor = actorName(req);
    const data = productFields(req.body, actor, { creating: true });
    const opening = V.stockQty(req.body.currentStock, 'currentStock', { fallback: 0 });
    // Opening stock follows the same rule as any movement: decimals only for
    // a measured unit.
    if (opening !== Math.round(opening) && !unitAllowsFraction(data.unit)) {
      return res.status(400).json({
        error: `Opening stock must be a whole number — ${data.unit} is counted, not measured`,
      });
    }
    await assertSubCategoryMatches(data.categoryId, data.subCategoryId);
    await assertNameFree(data.name, data.categoryId, data.subCategoryId, null);

    const product = await prisma.$transaction(async (tx) => {
      const created = await tx.product.create({ data: { ...data, currentStock: 0 } });
      if (opening > 0) {
        await applyStock(tx, {
          lines: [{ productId: created.id, qty: opening }],
          direction: +1,
          type: 'IN',
          refType: 'manual',
          refId: null,
          reference: 'Opening stock',
          note: 'Entered when the product was created',
          createdBy: actor,
        });
      }
      return tx.product.findUnique({ where: { id: created.id }, include: productInclude });
    });
    const { lowStockThreshold } = await getAppSettings();
    res.status(201).json(
      withStockStatus(withAvailability(product, await committedByProduct(prisma)), lowStockThreshold),
    );
  } catch (err) {
    if (err.code === 'P2002') return res.status(409).json({ error: 'SKU already exists' });
    if (err.code === 'P2003') return res.status(404).json({ error: 'Category or sub-category not found' });
    next(err);
  }
});

// PUT /api/products/:id — changes the fields it is sent, never the stock.
router.put('/:id', async (req, res, next) => {
  try {
    const id = Number(req.params.id);
    const data = productFields(req.body, actorName(req), { creating: false });
    if (
      data.categoryId !== undefined ||
      data.subCategoryId !== undefined ||
      data.name !== undefined
    ) {
      const current = await prisma.product.findUnique({
        where: { id },
        select: { categoryId: true, subCategoryId: true, name: true },
      });
      if (!current) return res.status(404).json({ error: 'Product not found' });
      const categoryId = data.categoryId ?? current.categoryId;
      const subCategoryId =
        data.subCategoryId !== undefined ? data.subCategoryId : current.subCategoryId;
      await assertSubCategoryMatches(categoryId, subCategoryId);
      await assertNameFree(data.name ?? current.name, categoryId, subCategoryId, id);
    }
    const product = await prisma.product.update({
      where: { id },
      data,
      include: productInclude,
    });
    const { lowStockThreshold } = await getAppSettings();
    res.json(
      withStockStatus(withAvailability(product, await committedByProduct(prisma)), lowStockThreshold),
    );
  } catch (err) {
    if (err.code === 'P2025') return res.status(404).json({ error: 'Product not found' });
    if (err.code === 'P2002') return res.status(409).json({ error: 'SKU already exists' });
    if (err.code === 'P2003') return res.status(404).json({ error: 'Category or sub-category not found' });
    next(err);
  }
});

// DELETE /api/products/:id
router.delete('/:id', async (req, res, next) => {
  try {
    const id = Number(req.params.id);
    // The stock ledger and the order lines are the business's record of what
    // came in and went out. Deleting the product used to take its ledger with
    // it (cascade) and blank the product link on every order line, so the
    // history quietly stopped adding up. A product with any history is kept;
    // switch it to Inactive instead.
    const [movements, saleLines, purchaseLines] = await Promise.all([
      prisma.stockMovement.count({ where: { productId: id } }),
      prisma.saleItem.count({ where: { productId: id } }),
      prisma.purchaseItem.count({ where: { productId: id } }),
    ]);
    if (movements + saleLines + purchaseLines > 0) {
      const parts = [];
      if (movements) parts.push(`${movements} stock movement${movements === 1 ? '' : 's'}`);
      if (saleLines) parts.push(`${saleLines} sale line${saleLines === 1 ? '' : 's'}`);
      if (purchaseLines) parts.push(`${purchaseLines} purchase line${purchaseLines === 1 ? '' : 's'}`);
      return res.status(409).json({
        error:
          `This product has history (${parts.join(', ')}), so it cannot be deleted. ` +
          'Mark it Inactive instead.',
      });
    }
    await prisma.product.delete({ where: { id } });
    res.status(204).send();
  } catch (err) {
    if (err.code === 'P2025') return res.status(404).json({ error: 'Product not found' });
    next(err);
  }
});

module.exports = router;
