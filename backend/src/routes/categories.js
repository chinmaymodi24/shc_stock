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
    const maxOrder = await prisma.category.aggregate({ _max: { sortOrder: true } });
    const category = await prisma.category.create({
      data: {
        name: name.trim(),
        description: description.trim(),
        sortOrder: (maxOrder._max.sortOrder ?? -1) + 1,
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
    const data = { name: name.trim(), description: description.trim() };
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
    const maxOrder = await prisma.subCategory.aggregate({
      where: { categoryId },
      _max: { sortOrder: true },
    });
    const subCategory = await prisma.subCategory.create({
      data: {
        categoryId,
        name: name.trim(),
        description: description.trim(),
        sortOrder: (maxOrder._max.sortOrder ?? -1) + 1,
      },
    });
    res.status(201).json(subCategory);
  } catch (err) {
    if (err.code === 'P2003') return res.status(404).json({ error: 'Category not found' });
    next(err);
  }
});

module.exports = router;
