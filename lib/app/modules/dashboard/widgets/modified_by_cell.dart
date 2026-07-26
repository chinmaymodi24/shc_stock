import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';

/// Pool of realistic names used to fill in "Modified By" data for seed
/// records that were never given a real modifier (i.e. still carry the
/// generic 'Admin' default). Kept in one place so every list in the app
/// draws from the same set and reads as one consistent team.
const List<String> kDemoModifiers = [
  'Chinmay Modi',
  'Riya Patel',
  'Ravi Sharma',
  'Priya Patel',
  'Amit Verma',
  'Sneha Gupta',
  'Vijay Joshi',
  'Neha Iyer',
  'Kiran Mehta',
  'Suresh Kumar',
];

/// Resolves the (name, date) pair a "Modified By" cell should render.
///
/// Real data (anything where [storedName] isn't the generic 'Admin' seed
/// default, with a non-null [storedDate]) always wins. Otherwise a name and
/// a recent date are derived deterministically from [seedId], so the same
/// row always renders the same way instead of flashing "Admin" everywhere.
({String name, DateTime date}) resolveModifiedBy({
  required String seedId,
  required String storedName,
  DateTime? storedDate,
}) {
  if (storedName != 'Admin' && storedDate != null) {
    return (name: storedName, date: storedDate);
  }
  final h = seedId.hashCode.abs();
  final name = kDemoModifiers[h % kDemoModifiers.length];
  final date = DateTime.now().subtract(
    Duration(days: h % 90, hours: (h ~/ 7) % 24, minutes: (h ~/ 13) % 60),
  );
  return (name: name, date: date);
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
