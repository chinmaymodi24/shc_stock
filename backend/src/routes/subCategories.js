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
    const subCategory = await prisma.subCategory.update({
      where: { id },
      data: { name: name.trim(), description: description.trim() },
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
