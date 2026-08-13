const express = require('express');
const prisma = require('../prismaClient');

const router = express.Router();

const productInclude = {
  category: true,
  subCategory: true,
};

function toWriteData(body) {
  const {
    name,
    sku,
    categoryId,
    subCategoryId,
    unit,
    sellingPrice,
    costPrice,
    currentStock,
    minimumStock,
    isActive,
    brand,
    hsnCode,
    description,
    taxPercent,
    stockLocation,
    modifiedBy,
    densityVariants,
    boardVariants,
    thicknessVariants,
    reinforcementTypes,
    otherSpecs,
  } = body;

  return {
    name: name?.trim(),
    sku: sku?.trim(),
    categoryId: Number(categoryId),
    subCategoryId: subCategoryId != null ? Number(subCategoryId) : null,
    unit,
    sellingPrice: Number(sellingPrice),
    costPrice: Number(costPrice),
    currentStock: currentStock != null ? Number(currentStock) : 0,
    minimumStock: minimumStock != null ? Number(minimumStock) : 0,
    isActive: isActive ?? true,
    brand: brand || null,
    hsnCode: hsnCode || null,
    description: description || null,
    taxPercent: taxPercent != null ? Number(taxPercent) : 18.0,
    stockLocation: stockLocation || 'Main Warehouse',
    modifiedBy: modifiedBy || 'Admin',
    modifiedAt: new Date(),
    densityVariants: densityVariants || [],
    boardVariants: boardVariants || [],
    thicknessVariants: thicknessVariants || [],
    reinforcementTypes: reinforcementTypes || [],
    otherSpecs: otherSpecs || null,
  };
}

// GET /api/products
router.get('/', async (req, res, next) => {
  try {
    const products = await prisma.product.findMany({
      orderBy: { createdAt: 'desc' },
      include: productInclude,
    });
    res.json(products);
  } catch (err) {
    next(err);
  }
});

// POST /api/products
router.post('/', async (req, res, next) => {
  try {
    const { name, sku, categoryId, sellingPrice, costPrice, unit } = req.body;
    if (!name || !name.trim()) return res.status(400).json({ error: 'name is required' });
    if (!sku || !sku.trim()) return res.status(400).json({ error: 'sku is required' });
    if (!categoryId) return res.status(400).json({ error: 'categoryId is required' });
    if (sellingPrice == null) return res.status(400).json({ error: 'sellingPrice is required' });
    if (costPrice == null) return res.status(400).json({ error: 'costPrice is required' });
    if (!unit) return res.status(400).json({ error: 'unit is required' });

    const product = await prisma.product.create({
      data: toWriteData(req.body),
      include: productInclude,
    });
    res.status(201).json(product);
  } catch (err) {
    if (err.code === 'P2002') return res.status(409).json({ error: 'SKU already exists' });
    if (err.code === 'P2003') return res.status(404).json({ error: 'Category or sub-category not found' });
    next(err);
  }
});

// PUT /api/products/:id
router.put('/:id', async (req, res, next) => {
  try {
    const id = Number(req.params.id);
    const product = await prisma.product.update({
      where: { id },
      data: toWriteData(req.body),
      include: productInclude,
    });
    res.json(product);
  } catch (err) {
    if (err.code === 'P2025') return res.status(404).json({ error: 'Product not found' });
    if (err.code === 'P2002') return res.status(409).json({ error: 'SKU already exists' });
    next(err);
  }
});

// DELETE /api/products/:id
router.delete('/:id', async (req, res, next) => {
  try {
    const id = Number(req.params.id);
    await prisma.product.delete({ where: { id } });
    res.status(204).send();
  } catch (err) {
    if (err.code === 'P2025') return res.status(404).json({ error: 'Product not found' });
    next(err);
  }
});

module.exports = router;
