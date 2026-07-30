require('dotenv').config();
const path = require('path');
const express = require('express');
const cors = require('cors');

const categoriesRouter = require('./routes/categories');
const subCategoriesRouter = require('./routes/subCategories');
const uploadRouter = require('./routes/upload');

const app = express();

app.use(cors());
app.use(express.json());
app.use('/uploads', express.static(path.join(__dirname, '..', process.env.UPLOADS_DIR || 'uploads')));

app.get('/health', (req, res) => res.json({ status: 'ok' }));

app.use('/api/categories', categoriesRouter);
app.use('/api/sub-categories', subCategoriesRouter);
app.use('/api/upload', uploadRouter);

app.use((err, req, res, next) => {
  console.error(err);
  res.status(err.status || 500).json({ error: err.message || 'Internal server error' });
});

const PORT = process.env.PORT || 4000;
app.listen(PORT, () => {
  console.log(`SHC Stock backend running on http://localhost:${PORT}`);
});
