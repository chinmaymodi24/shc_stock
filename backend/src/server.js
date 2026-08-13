require('dotenv').config();
const path = require('path');
const express = require('express');
const cors = require('cors');

const categoriesRouter = require('./routes/categories');
const subCategoriesRouter = require('./routes/subCategories');
const uploadRouter = require('./routes/upload');
const productsRouter = require('./routes/products');
const authRouter = require('./routes/auth');
const purchaseOrdersRouter = require('./routes/purchaseOrders');
const salesOrdersRouter = require('./routes/salesOrders');
const clientsRouter = require('./routes/clients');
const inventoryRouter = require('./routes/inventory');
const statsRouter = require('./routes/stats');
const usersRouter = require('./routes/users');
const transactionsRouter = require('./routes/transactions');
const dashboardRouter = require('./routes/dashboard');
const settingsRouter = require('./routes/settings');

const app = express();

app.use(cors());
app.use(express.json());
app.use('/uploads', express.static(path.join(__dirname, '..', process.env.UPLOADS_DIR || 'uploads')));

app.get('/health', (req, res) => res.json({ status: 'ok' }));

app.use('/api/categories', categoriesRouter);
app.use('/api/sub-categories', subCategoriesRouter);
app.use('/api/upload', uploadRouter);
app.use('/api/products', productsRouter);
app.use('/api/auth', authRouter);
app.use('/api/purchase-orders', purchaseOrdersRouter);
app.use('/api/sales-orders', salesOrdersRouter);
app.use('/api/clients', clientsRouter);
app.use('/api/inventory', inventoryRouter);
app.use('/api/stats', statsRouter);
app.use('/api/users', usersRouter);
app.use('/api/transactions', transactionsRouter);
app.use('/api/dashboard', dashboardRouter);
app.use('/api/settings', settingsRouter);

app.use((err, req, res, next) => {
  console.error(err);
  res.status(err.status || 500).json({ error: err.message || 'Internal server error' });
});

const PORT = process.env.PORT || 4000;
app.listen(PORT, () => {
  console.log(`SHC Stock backend running on http://localhost:${PORT}`);
});
