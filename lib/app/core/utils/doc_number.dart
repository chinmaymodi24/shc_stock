/// Next running document number for the Add Purchase / Add Sale forms.
///
/// [prefix] is the series prefix (e.g. `SO-2024`, `PO-2024`); [existing] is
/// every current number in that series. The trailing digit group of each is
/// read, and the result is `prefix-<max+1>` zero-padded to five digits.
/// With nothing existing yet it starts at `prefix-10001`.
String nextDocNumber({
  required String prefix,
  required Iterable<String> existing,
}) {
  var maxN = 10000;
  final trailing = RegExp(r'(\d+)\s*$');
  for (final s in existing) {
    final m = trailing.firstMatch(s.trim());
    if (m == null) continue;
    final n = int.tryParse(m.group(1)!) ?? 0;
    if (n > maxN) maxN = n;
  }
  return '$prefix-${(maxN + 1).toString().padLeft(5, '0')}';
}
