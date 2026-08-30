const express = require('express');
const prisma = require('../prismaClient');

const router = express.Router();

// PUT /api/sub-categories/:id
router.put('/:id', async (req, res, next) => {
  try {
    const id = Number(req.params.id);
    const { name, description = '' } = req.body;
    if (!name || !name.trim()) {
      return res.status(400).json({ error: 'name is required' });
    }
    // Last modified first: an edited sub-category moves to the top of its
    // category. Ordering is still by sortOrder, so drag-to-reorder still works.
    const existing = await prisma.subCategory.findUnique({ where: { id } });
    if (!existing) return res.status(404).json({ error: 'Sub-category not found' });
    const minOrder = await prisma.subCategory.aggregate({
      where: { categoryId: existing.categoryId },
      _min: { sortOrder: true },
    });
    const subCategory = await prisma.subCategory.update({
      where: { id },
      data: {
        name: name.trim(),
        description: description.trim(),
        sortOrder: (minOrder._min.sortOrder ?? 0) - 1,
      },
    });
    res.json(subCategory);
  } catch (err) {
    if (err.code === 'P2025') return res.status(404).json({ error: 'Sub-category not found' });
    next(err);
  }
});

// DELETE /api/sub-categories/:id
router.delete('/:id', async (req, res, next) => {
  try {
    const id = Number(req.params.id);
    // Block the delete while products still sit under this sub-category —
    // otherwise their sub-category link would be silently nulled.
    const productCount = await prisma.product.count({ where: { subCategoryId: id } });
    if (productCount > 0) {
      return res.status(409).json({
        error:
          `This sub-category has ${productCount} product${productCount === 1 ? '' : 's'} under it. ` +
          'Reassign them to another sub-category first.',
      });
    }
    await prisma.subCategory.delete({ where: { id } });
    res.status(204).send();
  } catch (err) {
    if (err.code === 'P2025') return res.status(404).json({ error: 'Sub-category not found' });
    next(err);
  }
});

// PATCH /api/sub-categories/reorder  { categoryId, orderedIds: [5,4,6] }
router.patch('/reorder', async (req, res, next) => {
  try {
    const { categoryId, orderedIds } = req.body;
    if (!Array.isArray(orderedIds)) {
      return res.status(400).json({ error: 'orderedIds must be an array' });
    }
    await prisma.$transaction(
      orderedIds.map((id, index) =>
        prisma.subCategory.update({ where: { id: Number(id) }, data: { sortOrder: index } })
      )
    );
    const subCategories = await prisma.subCategory.findMany({
      where: { categoryId: Number(categoryId) },
      orderBy: { sortOrder: 'asc' },
    });
    res.json(subCategories);
  } catch (err) {
    next(err);
  }
});

module.exports = router;
