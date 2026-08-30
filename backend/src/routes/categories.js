const express = require('express');
const prisma = require('../prismaClient');

const router = express.Router();

const categoryInclude = {
  subCategories: { orderBy: { sortOrder: 'asc' } },
};

// GET /api/categories
router.get('/', async (req, res, next) => {
  try {
    const categories = await prisma.category.findMany({
      orderBy: { sortOrder: 'asc' },
      include: categoryInclude,
    });
    res.json(categories);
  } catch (err) {
    next(err);
  }
});

// POST /api/categories
router.post('/', async (req, res, next) => {
  try {
    const { name, description = '' } = req.body;
    if (!name || !name.trim()) {
      return res.status(400).json({ error: 'name is required' });
    }
    // Last added first: take the slot above the current top. The list is still
    // ordered by sortOrder, so drag-to-reorder keeps working.
    const minOrder = await prisma.category.aggregate({ _min: { sortOrder: true } });
    const category = await prisma.category.create({
      data: {
        name: name.trim(),
        description: description.trim(),
        sortOrder: (minOrder._min.sortOrder ?? 0) - 1,
      },
      include: categoryInclude,
    });
    res.status(201).json(category);
  } catch (err) {
    next(err);
  }
});

// PUT /api/categories/:id
router.put('/:id', async (req, res, next) => {
  try {
    const id = Number(req.params.id);
    const { name, description = '' } = req.body;
    if (!name || !name.trim()) {
      return res.status(400).json({ error: 'name is required' });
    }
    // Last modified first: an edited category moves back to the top.
    const minOrder = await prisma.category.aggregate({ _min: { sortOrder: true } });
    const data = {
      name: name.trim(),
      description: description.trim(),
      sortOrder: (minOrder._min.sortOrder ?? 0) - 1,
    };
    const category = await prisma.category.update({
      where: { id },
      data,
      include: categoryInclude,
    });
    res.json(category);
  } catch (err) {
    if (err.code === 'P2025') return res.status(404).json({ error: 'Category not found' });
    next(err);
  }
});

// DELETE /api/categories/:id
router.delete('/:id', async (req, res, next) => {
  try {
    const id = Number(req.params.id);
    // Block the delete while products still point at this category — hard
    // delete would either be refused by the FK or orphan transaction history.
    const productCount = await prisma.product.count({ where: { categoryId: id } });
    if (productCount > 0) {
      return res.status(409).json({
        error:
          `This category has ${productCount} product${productCount === 1 ? '' : 's'} linked to it. ` +
          'Move or delete those products first, then try again.',
      });
    }
    await prisma.category.delete({ where: { id } });
    res.status(204).send();
  } catch (err) {
    if (err.code === 'P2025') return res.status(404).json({ error: 'Category not found' });
    next(err);
  }
});

// PATCH /api/categories/reorder  { orderedIds: [3,1,2] }
router.patch('/reorder', async (req, res, next) => {
  try {
    const { orderedIds } = req.body;
    if (!Array.isArray(orderedIds)) {
      return res.status(400).json({ error: 'orderedIds must be an array' });
    }
    await prisma.$transaction(
      orderedIds.map((id, index) =>
        prisma.category.update({ where: { id: Number(id) }, data: { sortOrder: index } })
      )
    );
    const categories = await prisma.category.findMany({
      orderBy: { sortOrder: 'asc' },
      include: categoryInclude,
    });
    res.json(categories);
  } catch (err) {
    next(err);
  }
});

// POST /api/categories/:id/sub-categories
router.post('/:id/sub-categories', async (req, res, next) => {
  try {
    const categoryId = Number(req.params.id);
    const { name, description = '' } = req.body;
    if (!name || !name.trim()) {
      return res.status(400).json({ error: 'name is required' });
    }
    // Last added first, same rule as categories.
    const minOrder = await prisma.subCategory.aggregate({
      where: { categoryId },
      _min: { sortOrder: true },
    });
    const subCategory = await prisma.subCategory.create({
      data: {
        categoryId,
        name: name.trim(),
        description: description.trim(),
        sortOrder: (minOrder._min.sortOrder ?? 0) - 1,
      },
    });
    res.status(201).json(subCategory);
  } catch (err) {
    if (err.code === 'P2003') return res.status(404).json({ error: 'Category not found' });
    next(err);
  }
});

module.exports = router;
