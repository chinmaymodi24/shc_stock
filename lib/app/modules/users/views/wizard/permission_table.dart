import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shc_stock/app/core/theme/app_colors.dart';
import 'package:shc_stock/app/modules/users/models/permission_editor.dart';

// ─────────────────────────────────────────────────────────────────────────────
// The permissions table — used by the wizard's Permissions step and by the
// Define Custom Role dialog.
//
//   Modules          Read · Write · Summary
//   Settings tabs    Read · Write
//
// "Summary" is the right to see a page's figures (its stat cards, or the
// Dashboard's KPIs and charts). It is separate from Read so an employee can
// work on a page without seeing how the whole business is doing.
// ─────────────────────────────────────────────────────────────────────────────

class PermissionBulkActions extends StatelessWidget {
  final PermissionEditor editor;
  const PermissionBulkActions({super.key, required this.editor});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _BulkButton(
            label: editor.allRead ? 'Clear All Read' : 'Select All Read',
            selected: editor.allRead,
            onTap: editor.toggleAllRead,
          ),
          _BulkButton(
            label: editor.allWrite ? 'Clear All Write' : 'Select All Write',
            selected: editor.allWrite,
            onTap: editor.toggleAllWrite,
          ),
          _BulkButton(
            label: editor.allSummary ? 'Hide All Summary' : 'Show All Summary',
            selected: editor.allSummary,
            onTap: editor.toggleAllSummary,
          ),
          _BulkButton(label: 'Clear All', onTap: editor.clearAll, muted: true),
        ],
      );
    });
  }
}

class _BulkButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool selected;
  final bool muted;
  const _BulkButton({
    required this.label,
    required this.onTap,
    this.selected = false,
    this.muted = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final color = muted ? c.textSecondary : AppColors.primaryOrange;
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        backgroundColor: selected
            ? AppColors.primaryOrange.withValues(alpha: 0.08)
            : Colors.transparent,
        side: BorderSide(color: muted ? c.border : AppColors.primaryOrange),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12.5,
          color: color,
          fontFamily: brandFontFamily,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class PermissionTable extends StatelessWidget {
  final PermissionEditor editor;
  final bool wide;
  const PermissionTable({super.key, required this.editor, required this.wide});

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Obx(() {
      final modules = editor.modules;
      final settings = editor.settings;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Section(
            title: 'Module',
            rows: modules,
            editor: editor,
            wide: wide,
            colors: c,
          ),
          const SizedBox(height: 16),
          _Section(
            title: 'Settings',
            rows: settings,
            editor: editor,
            wide: wide,
            colors: c,
          ),
        ],
      );
    });
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<WizPerm> rows;
  final PermissionEditor editor;
  final bool wide;
  final AppThemeColors colors;
  const _Section({
    required this.title,
    required this.rows,
    required this.editor,
    required this.wide,
    required this.colors,
  });

  double get _colW => wide ? 120 : 62;

  @override
  Widget build(BuildContext context) {
    final c = colors;
    TextStyle head() => TextStyle(
      fontSize: wide ? 12.5 : 11.5,
      fontWeight: FontWeight.w600,
      color: c.textSecondary,
      fontFamily: brandFontFamily,
    );

    Widget headCell(String wideLabel, String shortLabel) => SizedBox(
      width: _colW,
      child: Center(child: Text(wide ? wideLabel : shortLabel, style: head())),
    );

    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: c.rowEven,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          child: Row(
            children: [
              Expanded(child: Text(title, style: head())),
              headCell('Read Access', 'Read'),
              headCell('Write Access', 'Write'),
              headCell('Summary', 'Summary'),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: c.divider),
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(8),
            ),
          ),
          child: Column(
            children: [
              for (var i = 0; i < rows.length; i++) ...[
                _PermRow(
                  perm: rows[i],
                  editor: editor,
                  colW: _colW,
                  wide: wide,
                  colors: c,
                ),
                if (i < rows.length - 1) Divider(height: 1, color: c.divider),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _PermRow extends StatelessWidget {
  final WizPerm perm;
  final PermissionEditor editor;
  final double colW;
  final bool wide;
  final AppThemeColors colors;
  const _PermRow({
    required this.perm,
    required this.editor,
    required this.colW,
    required this.wide,
    required this.colors,
  });

  Widget _switch(bool value, ValueChanged<bool> onChanged) => SizedBox(
    width: colW,
    child: Center(
      child: Transform.scale(
        scale: wide ? 1 : 0.8,
        child: Switch(
          value: value,
          onChanged: onChanged,
          activeColor: AppColors.primaryOrange,
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final c = colors;
    final p = perm;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: wide ? 8 : 4),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: AppColors.primaryOrange.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(p.icon, color: AppColors.primaryOrange, size: 15),
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    p.label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: wide ? 13.5 : 12.5,
                      color: c.textPrimary,
                      fontFamily: brandFontFamily,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          _switch(p.read, (v) => editor.setRead(p, v)),
          _switch(p.write, (v) => editor.setWrite(p, v)),
          if (p.hasSummary)
            _switch(p.summary, (v) => editor.setSummary(p, v))
          else
            // Settings tabs have no figures to hide.
            SizedBox(
              width: colW,
              child: Center(
                child: Text(
                  '—',
                  style: TextStyle(color: c.textHint, fontSize: 13),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
