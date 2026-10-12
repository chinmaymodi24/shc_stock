// ─────────────────────────────────────────────────────────────────────────────
// Which units can be split. Measured units (kg, m, sqm, litre…) take decimal
// quantities; counted units (pieces, rolls, bags, boxes, sets) stay whole.
// Mirrors lib/app/core/utils/units.dart — keep the two in step.
// ─────────────────────────────────────────────────────────────────────────────

const COUNTED = new Set([
  'pcs', 'pc', 'piece', 'pieces', 'nos', 'no', 'number', 'numbers', 'each',
  'ea', 'unit', 'units', 'roll', 'rolls', 'bag', 'bags', 'box', 'boxes',
  'set', 'sets', 'pair', 'pairs', 'packet', 'packets', 'pkt', 'bundle',
  'bundles', 'carton', 'cartons', 'ctn', 'drum', 'drums', 'sheet', 'sheets',
  'bottle', 'bottles', 'can', 'cans', 'dozen',
]);

/// False for a counted unit ("Piece (pcs)", "Roll"), true otherwise.
function unitAllowsFraction(unit) {
  const words = String(unit || '').toLowerCase().match(/[a-z]+/g) || [];
  return !words.some((w) => COUNTED.has(w));
}

module.exports = { unitAllowsFraction };
