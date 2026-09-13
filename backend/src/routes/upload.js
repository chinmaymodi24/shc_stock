const express = require('express');
const multer = require('multer');
const path = require('path');
const fs = require('fs');

const router = express.Router();

const uploadsDir = path.join(__dirname, '..', '..', process.env.UPLOADS_DIR || 'uploads');
fs.mkdirSync(uploadsDir, { recursive: true });

// Raster formats only, matched on BOTH the declared type and the extension.
//
// The filter used to accept anything whose mimetype began with "image/", and
// the stored name kept whatever extension the client sent. An SVG satisfies
// that check honestly — "image/svg+xml" is an image type — but SVG is a
// document: it can carry <script>, and /uploads is served from this app's own
// origin, so opening such a file ran script with the signed-in user's session.
// Nothing here needs vector art, so the format is simply not accepted.
const ALLOWED = new Map([
  ['image/png', '.png'],
  ['image/jpeg', '.jpg'],
  ['image/webp', '.webp'],
  ['image/gif', '.gif'],
]);
const ALLOWED_EXT = new Set(['.png', '.jpg', '.jpeg', '.webp', '.gif']);

const storage = multer.diskStorage({
  destination: (req, file, cb) => cb(null, uploadsDir),
  // The extension comes from the type we accepted, never from the client's
  // filename, so "payload.html" cannot survive as an .html file on disk.
  filename: (req, file, cb) => {
    const ext = ALLOWED.get(file.mimetype) || '.bin';
    cb(null, `${Date.now()}-${Math.round(Math.random() * 1e9)}${ext}`);
  },
});

const upload = multer({
  storage,
  limits: { fileSize: 5 * 1024 * 1024, files: 1 },
  fileFilter: (req, file, cb) => {
    const ext = path.extname(file.originalname || '').toLowerCase();
    if (!ALLOWED.has(file.mimetype) || (ext && !ALLOWED_EXT.has(ext))) {
      return cb(new Error('Only PNG, JPEG, WebP or GIF images are allowed'));
    }
    cb(null, true);
  },
});

// POST /api/upload  (multipart/form-data, field name "image")
router.post('/', (req, res, next) => {
  upload.single('image')(req, res, (err) => {
    if (err) return res.status(400).json({ error: err.message });
    if (!req.file) return res.status(400).json({ error: 'No file uploaded' });
    res.status(201).json({ url: `/uploads/${req.file.filename}` });
  });
});

module.exports = router;
