import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shc_stock/app/core/session/app_modules.dart';
import 'package:shc_stock/app/core/session/session_controller.dart';

/// One row of a permissions table: a module (read / write / summary) or a
/// Settings tab (read / write). Mutable on purpose — the table edits these in
/// place and refreshes the RxList that holds them.
class WizPerm {
  /// Stored in `users.permissions` — a module name, or "Settings: Billing" for a tab.
  final String key;
  final String label;
  final IconData icon;
  final bool isSettings;
  bool read;
  bool write;
  bool summary;

  WizPerm({
    required this.key,
    required this.label,
    required this.icon,
    this.isSettings = false,
    this.read = false,
    this.write = false,
    this.summary = false,
  });

  bool get hasSummary => !isSettings;
  bool get noAccess => !read && !write && !summary;

  /// Copies [access]; write and summary still imply read.
  void apply(ModuleAccess access) {
    write = access.write;
    summary = hasSummary && access.summary;
    read = access.read || write || summary;
  }

  Map<String, dynamic> toJson() => isSettings
      ? {'read': read, 'write': write}
      : {'read': read, 'write': write, 'summary': summary};
}

/// Editable permission rows plus the rules for changing them — shared by the
/// Add Employee wizard's Permissions step and the Define Custom Role dialog,
/// so both behave identically.
///
/// Rows come straight off the shared catalog in app_modules.dart (every gated
/// module, then every gated Settings tab), so a key ticked here is the same
/// key the backend, the sidebar and the route guard check.
class PermissionEditor {
  final RxList<WizPerm> perms = <WizPerm>[
    for (final m in kGatedModules)
      WizPerm(key: m.name, label: m.name, icon: m.icon),
    for (final s in kSettingsSections)
      WizPerm(key: s.key, label: s.name, icon: s.icon, isSettings: true),
  ].obs;

  List<WizPerm> get modules => perms.where((p) => !p.isSettings).toList();
  List<WizPerm> get settings => perms.where((p) => p.isSettings).toList();

  // ── Counts ────────────────────────────────────────────────────────────
  int get readCnt => modules.where((p) => p.read).length;
  int get writeCnt => modules.where((p) => p.write).length;
  int get summaryCnt => modules.where((p) => p.summary).length;
  int get noCnt => modules.where((p) => p.noAccess).length;
  int get moduleCnt => modules.length;
  int get settingsReadCnt => settings.where((p) => p.read).length;
  int get settingsWriteCnt => settings.where((p) => p.write).length;
  int get settingsCnt => settings.length;

  /// Loads a saved map — a role's defaults or an employee's own access.
  void load(Map<String, ModuleAccess> map, {bool everything = false}) {
    for (final p in perms) {
      p.apply(everything ? ModuleAccess.full : map[p.key] ?? ModuleAccess.none);
    }
    perms.refresh();
  }

  /// The map the API stores.
  Map<String, dynamic> toJson() => {for (final p in perms) p.key: p.toJson()};

  // ── Single toggles ────────────────────────────────────────────────────
  // Write and summary both need read: switching either on switches read on,
  // and switching read off takes the other two with it.

  void setRead(WizPerm p, bool v) {
    p.read = v;
    if (!v) {
      p.write = false;
      p.summary = false;
    }
    perms.refresh();
  }

  void setWrite(WizPerm p, bool v) {
    p.write = v;
    if (v) p.read = true;
    perms.refresh();
  }

  void setSummary(WizPerm p, bool v) {
    if (!p.hasSummary) return;
    p.summary = v;
    if (v) p.read = true;
    perms.refresh();
  }

  // ── Select all / clear ────────────────────────────────────────────────
  bool get allRead => perms.every((p) => p.read);
  bool get allWrite => perms.every((p) => p.write);
  bool get allSummary => modules.every((p) => p.summary);

  /// "Select All" buttons toggle: when every row is already on they clear it.
  void toggleAllRead() {
    final on = !allRead;
    for (final p in perms) {
      p.read = on;
      if (!on) {
        p.write = false;
        p.summary = false;
      }
    }
    perms.refresh();
  }

  void toggleAllWrite() {
    final on = !allWrite;
    for (final p in perms) {
      p.write = on;
      if (on) p.read = true;
    }
    perms.refresh();
  }

  void toggleAllSummary() {
    final on = !allSummary;
    for (final p in modules) {
      p.summary = on;
      if (on) p.read = true;
    }
    perms.refresh();
  }

  void clearAll() {
    for (final p in perms) {
      p.read = false;
      p.write = false;
      p.summary = false;
    }
    perms.refresh();
  }
}
