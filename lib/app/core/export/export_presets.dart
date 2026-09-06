import 'dart:convert';

import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shc_stock/app/core/export/export_source.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Column presets the user saved themselves.
//
// Kept per entity and on disk, because the point of naming a column set is
// that it is there next month too. The entity's own built-in presets live in
// its config and are never touched by this.
// ─────────────────────────────────────────────────────────────────────────────
class ExportPresetStore extends GetxService {
  static ExportPresetStore get to => Get.find<ExportPresetStore>();

  static const _key = 'export_column_presets';

  /// entityKey -> presets, newest last.
  final RxMap<String, List<ExportColumnPreset>> presets =
      <String, List<ExportColumnPreset>>{}.obs;

  @override
  void onInit() {
    super.onInit();
    restore();
  }

  List<ExportColumnPreset> forEntity(String entityKey) =>
      presets[entityKey] ?? const [];

  /// Saves (or replaces) a named column set. Returns false for a blank name.
  Future<bool> save(
    String entityKey,
    String name,
    List<String> columnKeys,
  ) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty || columnKeys.isEmpty) return false;

    final existing = [...forEntity(entityKey)]
      ..removeWhere((p) => p.name.toLowerCase() == trimmed.toLowerCase());
    existing.add(ExportColumnPreset(trimmed, List.of(columnKeys)));
    presets[entityKey] = existing;
    presets.refresh();
    await _persist();
    return true;
  }

  Future<void> remove(String entityKey, String name) async {
    final existing = [...forEntity(entityKey)]
      ..removeWhere((p) => p.name == name);
    presets[entityKey] = existing;
    presets.refresh();
    await _persist();
  }

  Future<void> restore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null || raw.isEmpty) return;
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      presets.assignAll(
        decoded.map(
          (entity, value) => MapEntry(entity, [
            for (final item in value as List<dynamic>)
              ExportColumnPreset(
                (item as Map<String, dynamic>)['name'] as String? ?? '',
                [
                  for (final key in (item['columns'] as List<dynamic>? ?? []))
                    key as String,
                ],
              ),
          ]),
        ),
      );
    } catch (e) {
      // A corrupt blob should cost the user their saved presets, not the
      // ability to export at all.
      presets.clear();
    }
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _key,
        jsonEncode(
          presets.map(
            (entity, list) => MapEntry(entity, [
              for (final preset in list)
                {'name': preset.name, 'columns': preset.columnKeys},
            ]),
          ),
        ),
      );
    } catch (e) {
      // Non-fatal: the preset still applies for this session.
    }
  }
}
