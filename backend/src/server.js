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
const statementsRouter = require('./routes/statements');
const billsRouter = require('./routes/bills');
const usersRouter = require('./routes/users');
const transactionsRouter = require('./routes/transactions');
const dashboardRouter = require('./routes/dashboard');
const settingsRouter = require('./routes/settings');
const rolesRouter = require('./routes/roles');
const { guard } = require('./auth/middleware');
const { syncSystemRoles } = require('./roles');
const { startDeliverySweep } = require('./deliverySweep');
const { decimalJson } = require('./jsonDecimal');

const app = express();

// Behind a reverse proxy (Render, nginx) req.ip is the proxy unless Express is
// told how many hops to trust - and the sign-in rate limiter buckets by IP, so
// without this every caller would share one bucket. Left at 0 for local runs;
// set TRUST_PROXY=1 wherever exactly one proxy sits in front. Never set it
// higher than the real hop count: each trusted hop is one more X-Forwarded-For
// entry a client could forge.
app.set('trust proxy', Number(process.env.TRUST_PROXY || 0));

// CORS_ORIGINS = comma-separated list of allowed web origins (Firebase, Render
// static site, etc). Unset / "*" => allow any origin (handy for local dev).
const corsOrigins = (process.env.CORS_ORIGINS || '*')
  .split(',')
  .map((s) => s.trim())
  .filter(Boolean);
app.use(
  cors({
    origin: corsOrigins.includes('*') ? true : corsOrigins,
  }),
);
// The brand and billing routes accept a logo as base64 — up to 2 MB of it
// (see routes/settings.js). Express defaults to 100 kb, which rejected every
// real logo here with a bare 413 before the route's own, friendlier guard
// ever ran. 3 mb leaves room for that logo plus the rest of the payload.
app.use(express.json({ limit: '3mb' }));
// Money is NUMERIC in the database; this renders it as a number rather than
// the string Decimal.toJSON() would produce. See jsonDecimal.js.
app.use(decimalJson);
// Uploaded images, served from this app's own origin. The upload route only
// ever stores raster formats, and these headers are the second lock: nosniff
// stops a browser from re-interpreting a file as HTML, and the tight CSP means
// that even if something scriptable did land here it could not run.
app.use(
  '/uploads',
  (req, res, next) => {
    res.setHeader('X-Content-Type-Options', 'nosniff');
    res.setHeader('Content-Security-Policy', "default-src 'none'; img-src 'self'; sandbox");
    next();
  },
  express.static(path.join(__dirname, '..', process.env.UPLOADS_DIR || 'uploads'), {
    // Never negotiate an extension: ask for exactly what is on disk.
    index: false,
    dotfiles: 'deny',
  }),
);

app.get('/health', (req, res) => res.json({ status: 'ok' }));
app.get('/api/health', (req, res) => res.json({ status: 'ok' }));

// Every /api request past this point needs a signed-in employee with the right
// permission — see src/auth/policy.js for which request needs what.
app.use('/api', guard);

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
app.use('/api/statements', statementsRouter);
app.use('/api/bills', billsRouter);
app.use('/api/users', usersRouter);
app.use('/api/roles', rolesRouter);
app.use('/api/transactions', transactionsRouter);
app.use('/api/dashboard', dashboardRouter);
app.use('/api/settings', settingsRouter);

app.use((err, req, res, next) => {
  console.error(err);
  res.status(err.status || 500).json({ error: err.message || 'Internal server error' });
});

const PORT = process.env.PORT || 4000;
// Bind to 0.0.0.0 so a physical phone on the same Wi-Fi can reach the dev
// backend by the machine's LAN IP — no USB / adb reverse needed.
app.listen(PORT, '0.0.0.0', () => {
  console.log(`SHC Stock backend running on http://localhost:${PORT}`);
  const os = require('os');
  Object.values(os.networkInterfaces())
    .flat()
    .filter((i) => i && i.family === 'IPv4' && !i.internal)
    .forEach((i) => console.log(`  LAN: http://${i.address}:${PORT}`));
  // Ready-made roles follow src/permissions.js, so a new module reaches them
  // on the next start.
  syncSystemRoles().catch((err) => console.error('Role sync failed:', err));
  // Flips orders whose expected delivery date has arrived, booking their stock.
  startDeliverySweep();
});
