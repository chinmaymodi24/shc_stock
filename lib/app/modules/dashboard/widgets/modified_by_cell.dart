import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shc_stock/app/core/theme/app_colors.dart';

/// Resolves the (name, date) pair a "Modified By" cell should render.
///
/// Returns null when the row has no real modifier yet — the caller then shows
/// a dash. This used to invent a name from a pool of ten fake employees and a
/// random-looking recent date, which made every list look busier than the data
/// actually was; now the column only ever shows what the API stored.
({String name, DateTime date})? resolveModifiedBy({
  required String storedName,
  DateTime? storedDate,
}) {
  final name = storedName.trim();
  if (name.isEmpty || storedDate == null) return null;
  return (name: name, date: storedDate);
}

/// Placeholder for a row that has never been modified.
class ModifiedByEmpty extends StatelessWidget {
  final Color textHint;
  const ModifiedByEmpty({super.key, required this.textHint});

  @override
  Widget build(BuildContext context) => Text(
    '—',
    style: TextStyle(fontSize: 12.5, color: textHint, fontFamily: 'Poppins'),
  );
}

/// Shared "Modified By" table-cell UI: a solid brand-purple avatar with the
/// modifier's initials, the name in bold, and the date below in a muted
/// tone. Used identically across every module's list table.
class ModifiedByCell extends StatelessWidget {
  final String name;
  final DateTime date;
  final Color textPrimary;
  final Color textHint;

  const ModifiedByCell({
    super.key,
    required this.name,
    required this.date,
    required this.textPrimary,
    required this.textHint,
  });

  @override
  Widget build(BuildContext context) {
    final initials = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .take(2)
        .map((w) => w[0].toUpperCase())
        .join();
    final dateFmt = DateFormat('MMM d, yyyy, h:mm a');

    return Row(
      children: [
        CircleAvatar(
          radius: 13,
          backgroundColor: AppColors.accentPurple,
          child: Text(
            initials,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              fontFamily: 'Poppins',
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                  fontFamily: 'Poppins',
                ),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                dateFmt.format(date),
                style: TextStyle(
                  fontSize: 11,
                  color: textHint,
                  fontFamily: 'Poppins',
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
