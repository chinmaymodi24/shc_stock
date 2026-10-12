// ─────────────────────────────────────────────────────────────────────────────
// Which units can be split.
//
// Stock used to be whole numbers only, so 12.5 kg of bulk fibre or 7.5 m of
// rope could not be bought or sold. Now quantities may carry decimals — but
// only for units that are measured (kg, m, sqm, litre…). Units that are
// counted (pieces, rolls, bags, boxes, sets) stay whole: half a bag is a typo.
//
// Mirrors backend/src/units.js — keep the two in step.
// ─────────────────────────────────────────────────────────────────────────────

const _counted = {
  'pcs', 'pc', 'piece', 'pieces', 'nos', 'no', 'number', 'numbers', 'each',
  'ea', 'unit', 'units', 'roll', 'rolls', 'bag', 'bags', 'box', 'boxes',
  'set', 'sets', 'pair', 'pairs', 'packet', 'packets', 'pkt', 'bundle',
  'bundles', 'carton', 'cartons', 'ctn', 'drum', 'drums', 'sheet', 'sheets',
  'bottle', 'bottles', 'can', 'cans', 'dozen',
};

/// False for a counted unit ("Piece (pcs)", "Roll", "Bag"), true otherwise.
/// An empty unit is treated as measurable — it says nothing to the contrary.
bool unitAllowsFraction(String unit) {
  final u = unit.toLowerCase();
  final words = RegExp(r'[a-z]+').allMatches(u).map((m) => m.group(0)!);
  return !words.any(_counted.contains);
}
