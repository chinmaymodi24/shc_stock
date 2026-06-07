import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/categories_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../dashboard/widgets/web_sidebar.dart';
import '../../products/models/product_model.dart';

class WebCategoriesLayout extends StatelessWidget {
  const WebCategoriesLayout({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<CategoriesController>();
    final colors = appColors;
    return Scaffold(
      backgroundColor: colors.background,
      body: Row(
        children: [
          const WebSidebar(),
          Expanded(
            child: Column(
              children: [
                _TopBar(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(c),
                        const SizedBox(height: 20),
                        _buildStatCards(c),
                        const SizedBox(height: 20),
                        _buildCategoryList(c),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(CategoriesController c) {
    final colors = appColors;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Categories', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: colors.textPrimary, fontFamily: 'Poppins')),
          const SizedBox(height: 4),
          Text('Manage product categories and sub-categories.', style: TextStyle(fontSize: 13, color: colors.textSecondary, fontFamily: 'Poppins')),
        ]),
        ElevatedButton.icon(
          onPressed: () => _showAddCategoryDialog(c),
          icon: const Icon(Icons.add_rounded, color: Colors.white, size: 18),
          label: const Text('Add Category', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white, fontFamily: 'Poppins')),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryOrange,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCards(CategoriesController c) {
    return Obx(() => Row(children: [
      Expanded(child: _StatCard(label: 'Total Categories', value: '${c.totalCategories}', icon: Icons.category_outlined, iconColor: AppColors.primaryOrange, iconBg: const Color(0xFFFFF3E8))),
      const SizedBox(width: 16),
      Expanded(child: _StatCard(label: 'Total Sub-Categories', value: '${c.totalSubCategories}', icon: Icons.list_alt_rounded, iconColor: AppColors.primaryPurple, iconBg: const Color(0xFFEEECFF))),
      const Expanded(child: SizedBox()),
      const Expanded(child: SizedBox()),
    ]));
  }

  Widget _buildCategoryList(CategoriesController c) {
    return Obx(() => Column(
      children: c.categories.asMap().entries.map((entry) {
        return _CategoryCard(cat: entry.value, index: entry.key, controller: c);
      }).toList(),
    ));
  }

  void _showAddCategoryDialog(CategoriesController c) {
    final ctrl = TextEditingController();
    Get.dialog(
      _FormDialog(
        title: 'Add New Category',
        hint: 'e.g. Ceramic Fiber Products',
        controller: ctrl,
        onSave: () { c.addCategory(ctrl.text); Get.back(); },
      ),
    );
  }
}

// ── Top Bar ───────────────────────────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = appColors;
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(color: colors.topBarBg, border: Border(bottom: BorderSide(color: colors.divider))),
      child: Row(children: [
        const Spacer(),
        CircleAvatar(radius: 18, backgroundColor: AppColors.primaryOrange.withValues(alpha: 0.15), child: const Icon(Icons.person_rounded, color: AppColors.primaryOrange, size: 20)),
        const SizedBox(width: 8),
        Text('Admin', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: colors.textPrimary, fontFamily: 'Poppins')),
        Icon(Icons.keyboard_arrow_down_rounded, color: colors.textSecondary, size: 18),
      ]),
    );
  }
}

// ── Category Card ─────────────────────────────────────────────────────────────
class _CategoryCard extends StatefulWidget {
  final ProductCategory cat;
  final int index;
  final CategoriesController controller;
  const _CategoryCard({required this.cat, required this.index, required this.controller});

  @override
  State<_CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<_CategoryCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final cat = widget.cat;
    final c = widget.controller;
    final colors = appColors;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.divider),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          // ── Category Header Row ──
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(color: AppColors.primaryOrange.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Center(child: Text('${widget.index + 1}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primaryOrange, fontFamily: 'Poppins'))),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(color: colors.iconBgPurple, borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.category_outlined, color: AppColors.primaryPurple, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(cat.name, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: colors.textPrimary, fontFamily: 'Poppins')),
                      const SizedBox(height: 2),
                      Text('${cat.subProducts.length} sub-categories', style: TextStyle(fontSize: 12.5, color: colors.textSecondary, fontFamily: 'Poppins')),
                    ],
                  ),
                ),
                _ActionBtn(icon: Icons.add_rounded, color: const Color(0xFF22C55E), tooltip: 'Add Sub-Category',
                  onTap: () => _showAddSubDialog(c, cat.id)),
                const SizedBox(width: 6),
                _ActionBtn(icon: Icons.edit_outlined, color: AppColors.primaryPurple, tooltip: 'Edit Category',
                  onTap: () => _showEditCategoryDialog(c, cat)),
                const SizedBox(width: 6),
                _ActionBtn(icon: Icons.delete_outline_rounded, color: const Color(0xFFEF4444), tooltip: 'Delete Category',
                  onTap: () => _confirmDeleteCategory(c, cat)),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => setState(() => _expanded = !_expanded),
                  child: AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(Icons.keyboard_arrow_down_rounded, color: colors.textSecondary, size: 22),
                  ),
                ),
              ],
            ),
          ),

          // ── Sub-categories (expandable) ──
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            child: _expanded
                ? Container(
                    decoration: BoxDecoration(
                      border: Border(top: BorderSide(color: colors.divider)),
                    ),
                    child: cat.subProducts.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.all(20),
                            child: Center(
                              child: Column(children: [
                                Icon(Icons.inbox_outlined, color: colors.textHint, size: 36),
                                const SizedBox(height: 8),
                                Text('No sub-categories yet. Tap + to add.', style: TextStyle(fontSize: 13, color: colors.textHint, fontFamily: 'Poppins')),
                              ]),
                            ),
                          )
                        : Column(
                            children: cat.subProducts.asMap().entries.map((e) {
                              return _SubCategoryRow(
                                name: e.value,
                                index: e.key,
                                categoryId: cat.id,
                                controller: c,
                                isLast: e.key == cat.subProducts.length - 1,
                              );
                            }).toList(),
                          ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  void _showAddSubDialog(CategoriesController c, String catId) {
    final ctrl = TextEditingController();
    Get.dialog(_FormDialog(
      title: 'Add Sub-Category',
      hint: 'e.g. Ceramic Fiber Rope',
      controller: ctrl,
      onSave: () { c.addSubCategory(catId, ctrl.text); Get.back(); setState(() => _expanded = true); },
    ));
  }

  void _showEditCategoryDialog(CategoriesController c, ProductCategory cat) {
    final ctrl = TextEditingController(text: cat.name);
    Get.dialog(_FormDialog(
      title: 'Edit Category',
      hint: cat.name,
      controller: ctrl,
      onSave: () { c.updateCategory(cat.id, ctrl.text); Get.back(); },
    ));
  }

  void _confirmDeleteCategory(CategoriesController c, ProductCategory cat) {
    final colors = appColors;
    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440, minWidth: 360),
            child: Container(
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.20), blurRadius: 32, offset: const Offset(0, 8))],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                    child: Row(
                      children: [
                        Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(10)),
                          child: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Text('Delete Category?', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: colors.textPrimary, fontFamily: 'Poppins'))),
                        GestureDetector(
                          onTap: Get.back,
                          child: Container(width: 32, height: 32, decoration: BoxDecoration(color: colors.comingSoonBadge, borderRadius: BorderRadius.circular(8)), child: Icon(Icons.close_rounded, size: 18, color: colors.textSecondary)),
                        ),
                      ],
                    ),
                  ),
                  Padding(padding: const EdgeInsets.only(top: 16), child: Divider(height: 1, color: colors.divider)),
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Are you sure you want to permanently delete "${cat.name}"? This will also delete all ${cat.subProducts.length} sub-categories inside it. This action cannot be undone.',
                      style: TextStyle(fontSize: 13.5, color: colors.textSecondary, fontFamily: 'Poppins', height: 1.5),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                      OutlinedButton(onPressed: Get.back, style: OutlinedButton.styleFrom(side: BorderSide(color: colors.border), padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))), child: Text('Cancel', style: TextStyle(fontFamily: 'Poppins', color: colors.textSecondary, fontSize: 14))),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: () { c.deleteCategory(cat.id); Get.back(); },
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444), elevation: 0, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                        child: const Text('Delete', style: TextStyle(fontFamily: 'Poppins', color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                      ),
                    ]),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Sub-category Row ──────────────────────────────────────────────────────────
class _SubCategoryRow extends StatelessWidget {
  final String name;
  final int index;
  final String categoryId;
  final CategoriesController controller;
  final bool isLast;

  const _SubCategoryRow({required this.name, required this.index, required this.categoryId, required this.controller, required this.isLast});

  @override
  Widget build(BuildContext context) {
    final colors = appColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: index.isEven ? colors.rowEven : colors.surface,
        border: isLast ? null : Border(bottom: BorderSide(color: colors.divider)),
      ),
      child: Row(
        children: [
          const SizedBox(width: 52),
          Container(
            width: 6, height: 6,
            decoration: BoxDecoration(color: AppColors.primaryOrange.withValues(alpha: 0.5), shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(name, style: TextStyle(fontSize: 13.5, color: colors.textPrimary, fontFamily: 'Poppins'))),
          _ActionBtn(icon: Icons.edit_outlined, color: AppColors.primaryPurple, tooltip: 'Edit',
            onTap: () {
              final ctrl = TextEditingController(text: name);
              Get.dialog(_FormDialog(
                title: 'Edit Sub-Category',
                hint: name,
                controller: ctrl,
                onSave: () { controller.updateSubCategory(categoryId, index, ctrl.text); Get.back(); },
              ));
            }),
          const SizedBox(width: 6),
          _ActionBtn(icon: Icons.delete_outline_rounded, color: const Color(0xFFEF4444), tooltip: 'Delete',
            onTap: () => Get.dialog(
              Dialog(
                backgroundColor: Colors.transparent,
                insetPadding: EdgeInsets.zero,
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440, minWidth: 360),
                    child: Container(
                      decoration: BoxDecoration(color: colors.surface, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.20), blurRadius: 32, offset: const Offset(0, 8))]),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                            child: Row(children: [
                              Container(width: 40, height: 40, decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 22)),
                              const SizedBox(width: 12),
                              Expanded(child: Text('Delete Sub-Category?', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: colors.textPrimary, fontFamily: 'Poppins'))),
                              GestureDetector(onTap: Get.back, child: Container(width: 32, height: 32, decoration: BoxDecoration(color: colors.comingSoonBadge, borderRadius: BorderRadius.circular(8)), child: Icon(Icons.close_rounded, size: 18, color: colors.textSecondary))),
                            ]),
                          ),
                          Padding(padding: const EdgeInsets.only(top: 16), child: Divider(height: 1, color: colors.divider)),
                          Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text('Are you sure you want to permanently delete "$name"? This action cannot be undone.', style: TextStyle(fontSize: 13.5, color: colors.textSecondary, fontFamily: 'Poppins', height: 1.5)),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                            child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                              OutlinedButton(onPressed: Get.back, style: OutlinedButton.styleFrom(side: BorderSide(color: colors.border), padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))), child: Text('Cancel', style: TextStyle(fontFamily: 'Poppins', color: colors.textSecondary, fontSize: 14))),
                              const SizedBox(width: 10),
                              ElevatedButton(onPressed: () { controller.deleteSubCategory(categoryId, index); Get.back(); }, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444), elevation: 0, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))), child: const Text('Delete', style: TextStyle(fontFamily: 'Poppins', color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14))),
                            ]),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared Helper Widgets ─────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  const _StatCard({required this.label, required this.value, required this.icon, required this.iconColor, required this.iconBg});

  @override
  Widget build(BuildContext context) {
    final colors = appColors;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.surface, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.divider),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(fontSize: 12.5, color: colors.textSecondary, fontFamily: 'Poppins')),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: colors.textPrimary, fontFamily: 'Poppins')),
        ])),
        Container(width: 46, height: 46, decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: iconColor, size: 22)),
      ]),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;
  const _ActionBtn({required this.icon, required this.color, required this.tooltip, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 32, height: 32,
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: color, size: 17),
        ),
      ),
    );
  }
}

// ── Form Dialog ───────────────────────────────────────────────────────────────
class _FormDialog extends StatelessWidget {
  final String title;
  final String hint;
  final TextEditingController controller;
  final VoidCallback onSave;
  const _FormDialog({required this.title, required this.hint, required this.controller, required this.onSave});

  @override
  Widget build(BuildContext context) {
    final colors = appColors;
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480, minWidth: 380),
          child: Container(
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.20),
                  blurRadius: 32,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                  child: Row(
                    children: [
                      Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.primaryOrange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.edit_note_rounded, color: AppColors.primaryOrange, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: colors.textPrimary,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: Get.back,
                        child: Container(
                          width: 32, height: 32,
                          decoration: BoxDecoration(
                            color: colors.comingSoonBadge,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.close_rounded, size: 18, color: colors.textSecondary),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Divider(height: 1, color: colors.divider),
                ),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Name',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: colors.textPrimary,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: controller,
                        autofocus: true,
                        style: TextStyle(fontSize: 14, color: colors.textPrimary, fontFamily: 'Poppins'),
                        decoration: InputDecoration(
                          hintText: hint,
                          hintStyle: TextStyle(color: colors.textHint, fontFamily: 'Poppins'),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: colors.border),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: colors.border),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: AppColors.primaryOrange, width: 1.5),
                          ),
                          filled: true,
                          fillColor: colors.inputFill,
                        ),
                        onSubmitted: (_) => onSave(),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: Get.back,
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: colors.border),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: Text('Cancel', style: TextStyle(fontFamily: 'Poppins', color: colors.textSecondary, fontSize: 14)),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: onSave,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryOrange,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('Save', style: TextStyle(fontFamily: 'Poppins', color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
