// ─────────────────────────────────────────────────────────────────────────────
// GST: which tax applies, and how much.
//
// Every order and bill used to charge a flat 9% CGST + 9% SGST. That is only
// right for a sale inside the seller's own state at 18%:
//   * a party in ANOTHER state is charged IGST at the full rate instead, and
//   * each product carries its own rate (Product.taxPercent: 5, 12, 18, 28…).
// This file is the single place that decides both, for the forms, the order
// details, the exports and the bills alike.
// ─────────────────────────────────────────────────────────────────────────────

/// GST state codes — the first two digits of a GSTIN.
const Map<String, String> kGstStates = {
  '01': 'Jammu and Kashmir',
  '02': 'Himachal Pradesh',
  '03': 'Punjab',
  '04': 'Chandigarh',
  '05': 'Uttarakhand',
  '06': 'Haryana',
  '07': 'Delhi',
  '08': 'Rajasthan',
  '09': 'Uttar Pradesh',
  '10': 'Bihar',
  '11': 'Sikkim',
  '12': 'Arunachal Pradesh',
  '13': 'Nagaland',
  '14': 'Manipur',
  '15': 'Mizoram',
  '16': 'Tripura',
  '17': 'Meghalaya',
  '18': 'Assam',
  '19': 'West Bengal',
  '20': 'Jharkhand',
  '21': 'Odisha',
  '22': 'Chhattisgarh',
  '23': 'Madhya Pradesh',
  '24': 'Gujarat',
  '26': 'Dadra and Nagar Haveli and Daman and Diu',
  '27': 'Maharashtra',
  '29': 'Karnataka',
  '30': 'Goa',
  '31': 'Lakshadweep',
  '32': 'Kerala',
  '33': 'Tamil Nadu',
  '34': 'Puducherry',
  '35': 'Andaman and Nicobar Islands',
  '36': 'Telangana',
  '37': 'Andhra Pradesh',
  '38': 'Ladakh',
};

/// Older or common spellings people type, mapped to their code.
const Map<String, String> _kStateAliases = {
  'orissa': '21',
  'pondicherry': '34',
  'daman and diu': '26',
  'dadra and nagar haveli': '26',
  'j&k': '01',
  'jammu & kashmir': '01',
  'new delhi': '07',
  'nct of delhi': '07',
  'andaman & nicobar': '35',
};

/// Default GST rate for a line not linked to a product.
const double kDefaultGstRate = 18;

String _norm(String s) =>
    s.toLowerCase().replaceAll('&', ' and ').replaceAll(RegExp(r'[^a-z ]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ').trim();

/// The state code a GSTIN starts with, or null when it is not a GSTIN.
String? stateCodeOfGstin(String gstin) {
  final g = gstin.trim().toUpperCase();
  if (g.length < 2) return null;
  final code = g.substring(0, 2);
  return kGstStates.containsKey(code) ? code : null;
}

/// The state named anywhere in [text] — "Gujarat", "Ahmedabad (Gujarat)",
/// "24-Gujarat". Longest names are tried first so "West Bengal" is not read
/// as "Bengal". Null when no state is named.
String? stateCodeOfText(String text) {
  final t = ' ${_norm(text)} ';
  if (t.trim().isEmpty) return null;
  final codeMatch = RegExp(r'^\s*(\d{2})\b').firstMatch(text);
  if (codeMatch != null && kGstStates.containsKey(codeMatch.group(1))) {
    return codeMatch.group(1);
  }
  final names = <String, String>{
    for (final e in kGstStates.entries) _norm(e.value): e.key,
    for (final e in _kStateAliases.entries) _norm(e.key): e.value,
  };
  final ordered = names.keys.toList()..sort((a, b) => b.length - a.length);
  for (final n in ordered) {
    if (t.contains(' $n ')) return names[n];
  }
  return null;
}

/// A party's state: its GSTIN wins, then any state named in [texts]
/// (place of supply, state field, address) in the order given.
String? partyStateCode({String gstin = '', List<String> texts = const []}) {
  final fromGstin = stateCodeOfGstin(gstin);
  if (fromGstin != null) return fromGstin;
  for (final t in texts) {
    final c = stateCodeOfText(t);
    if (c != null) return c;
  }
  return null;
}

/// [partyStateCode] for a form: the GSTIN box and the free-text boxes.
String? gstStateOf(String gstin, List<String> texts) =>
    partyStateCode(gstin: gstin, texts: texts);

/// IGST applies only when both states are known and differ. Unknown on
/// either side keeps CGST + SGST — the seller's home-state default.
bool isInterState(String? sellerState, String? partyState) =>
    sellerState != null && partyState != null && sellerState != partyState;

/// One taxable line: its value before tax and its GST rate (percent).
class GstLine {
  final double taxable;
  final double rate;
  const GstLine(this.taxable, this.rate);
}

double _paise(double v) => double.parse(v.toStringAsFixed(2));

/// The tax on a set of lines.
class GstBreakup {
  final bool interState;
  final double taxable;
  final double cgst;
  final double sgst;
  final double igst;

  /// Every distinct rate on the lines (percent), ascending.
  final List<double> rates;

  const GstBreakup({
    required this.interState,
    required this.taxable,
    required this.cgst,
    required this.sgst,
    required this.igst,
    required this.rates,
  });

  double get totalTax => cgst + sgst + igst;
  double get total => taxable + totalTax;

  /// The one rate on every line, or null when the lines mix rates.
  double? get uniformRate => rates.length == 1 ? rates.first : null;

  /// Labels for the totals block: "CGST (9%)", "SGST (9%)", "IGST (18%)" —
  /// without a percentage when the lines mix rates.
  String get cgstLabel => _label('CGST', uniformRate == null ? null : uniformRate! / 2);
  String get sgstLabel => _label('SGST', uniformRate == null ? null : uniformRate! / 2);
  String get igstLabel => _label('IGST', uniformRate);

  static String _label(String name, double? pct) =>
      pct == null ? name : '$name (${ratePercent(pct)})';
}

/// "9%", "2.5%", "18%".
String ratePercent(double pct) {
  final text = pct == pct.roundToDouble()
      ? pct.toStringAsFixed(0)
      : pct.toStringAsFixed(2).replaceFirst(RegExp(r'0+$'), '');
  return '$text%';
}

/// Works the tax out line by line (each at its own rate) and adds it up.
/// Intra-state: half the rate as CGST and half as SGST. Inter-state: the full
/// rate as IGST.
GstBreakup computeGst(Iterable<GstLine> lines, {required bool interState}) {
  var taxable = 0.0, cgst = 0.0, sgst = 0.0, igst = 0.0;
  final rates = <double>{};
  for (final l in lines) {
    final t = _paise(l.taxable);
    taxable += t;
    rates.add(l.rate);
    if (interState) {
      igst += _paise(t * l.rate / 100);
    } else {
      final half = _paise(t * l.rate / 200);
      cgst += half;
      sgst += half;
    }
  }
  return GstBreakup(
    interState: interState,
    taxable: _paise(taxable),
    cgst: _paise(cgst),
    sgst: _paise(sgst),
    igst: _paise(igst),
    rates: rates.toList()..sort(),
  );
}
