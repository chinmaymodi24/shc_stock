import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_colors.dart';
import '../../../routes/app_routes.dart';
import '../../dashboard/widgets/app_drawer.dart';
import '../controllers/categories_controller.dart';
import '../../products/models/product_model.dart';

class MobileCategoriesLayout extends StatelessWidget {
  const MobileCategoriesLayout({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<CategoriesController>();
    return Scaffold(
      backgroundColor: const Color(0xFFF8F7FF),
      drawer: const AppDrawer(activeRoute: AppRoutes.categories),
      appBar: _buildAppBar(context),
      body: Obx(() => ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        itemCount: c.categories.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) => _MobileCategoryCard(
          cat: c.categories[i],
          index: i,
          controller: c,
        ),
      )),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDialog(c),
        backgroundColor: AppColors.primaryOrange,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Add Category', style: TextStyle(color: Colors.white, fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: Builder(
        builder: (ctx) => IconButton(
          icon: const Icon(Icons.menu_rounded, color: Color(0xFF1A1240), size: 24),
          onPressed: () => Scaffold.of(ctx).openDrawer(),
        ),
      ),
      title: const Text('Categories', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF1A1240), fontFamily: 'Poppins')),
      bottom: const PreferredSize(preferredSize: Size.fromHeight(1), child: Divider(height: 1, color: Color(0xFFF0EFF8))),
    );
  }

  void _showAddDialog(CategoriesController c) {
    final ctrl = TextEditingController();
    Get.dialog(_MobileFormDialog(
      title: 'Add New Category',
      hint: 'e.g. Ceramic Fiber Products',
      controller: ctrl,
      onSave: () { c.addCategory(ctrl.text); Get.back(); },
    ));
  }
}

// ── Category Card ─────────────────────────────────────────────
class _MobileCategoryCard extends StatefulWidget {
  final ProductCategory cat;
  final int index;
  final CategoriesController controller;
  const _MobileCategoryCard({required this.cat, required this.index, required this.controller});

  @override
  State<_MobileCategoryCard> createState() => _MobileCategoryCardState();
}

class _MobileCategoryCardState extends State<_MobileCategoryCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final cat = widget.cat;
    final c = widget.controller;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF0EFF8)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          // ── Header ──
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(color: AppColors.primaryOrange.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Center(child: Text('${widget.index + 1}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primaryOrange, fontFamily: 'Poppins'))),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(cat.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1A1240), fontFamily: 'Poppins')),
                  Text('${cat.subProducts.length} sub-categories', style: const TextStyle(fontSize: 12, color: Color(0xFF9B9BB4), fontFamily: 'Poppins')),
                ])),
                // Action buttons
                _MiniBtn(icon: Icons.add_rounded, color: const Color(0xFF22C55E),
                  onTap: () { _showAddSubDialog(c, cat.id); setState(() => _expanded = true); }),
                const SizedBox(width: 6),
                _MiniBtn(icon: Icons.edit_outlined, color: AppColors.primaryPurple,
                  onTap: () => _showEditDialog(c, cat)),
                const SizedBox(width: 6),
                _MiniBtn(icon: Icons.delete_outline_rounded, color: const Color(0xFFEF4444),
                  onTap: () => _confirmDelete(c, cat)),
                const SizedBox(width: 6),
                AnimatedRotation(
                  turns: _expanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF6B6B8A), size: 20),
                ),
              ]),
            ),
          ),

          // ── Sub-categories ──
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            child: _expanded
                ? Container(
                    decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0xFFF0EFF8)))),
                    child: cat.subProducts.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(child: Text('No sub-categories yet.', style: TextStyle(fontSize: 13, color: Color(0xFF9B9BB4), fontFamily: 'Poppins'))),
                          )
                        : Column(
                            children: cat.subProducts.asMap().entries.map((e) {
                              return _SubRow(
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
    Get.dialog(_MobileFormDialog(
      title: 'Add Sub-Category',
      hint: 'e.g. Ceramic Fiber Rope',
      controller: ctrl,
      onSave: () { c.addSubCategory(catId, ctrl.text); Get.back(); },
    ));
  }

  void _showEditDialog(CategoriesController c, ProductCategory cat) {
    final ctrl = TextEditingController(text: cat.name);
    Get.dialog(_MobileFormDialog(
      title: 'Edit Category',
      hint: cat.name,
      controller: ctrl,
      onSave: () { c.updateCategory(cat.id, ctrl.text); Get.back(); },
    ));
  }

  void _confirmDelete(CategoriesController c, ProductCategory cat) {
    Get.dialog(AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Delete Category?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, fontFamily: 'Poppins')),
      content: Text('Are you sure you want to delete "${cat.name}"? This will also delete all ${cat.subProducts.length} sub-categories.', style: const TextStyle(fontSize: 13.5, color: Color(0xFF6B6B8A), fontFamily: 'Poppins')),
      actions: [
        TextButton(onPressed: Get.back, child: const Text('Cancel', style: TextStyle(fontFamily: 'Poppins', color: Color(0xFF6B6B8A)))),
        ElevatedButton(
          onPressed: () { c.deleteCategory(cat.id); Get.back(); },
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
          child: const Text('Delete', style: TextStyle(fontFamily: 'Poppins', color: Colors.white)),
        ),
      ],
    ));
  }
}

// ── Sub-category Row ──────────────────────────────────────────
class _SubRow extends StatelessWidget {
  final String name;
  final int index;
  final String categoryId;
  final CategoriesController controller;
  final bool isLast;
  const _SubRow({required this.name, required this.index, required this.categoryId, required this.controller, required this.isLast});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: index.isEven ? const Color(0xFFFCFBFF) : Colors.white,
        border: isLast ? null : const Border(bottom: BorderSide(color: Color(0xFFF0EFF8))),
      ),
      child: Row(children: [
        const SizedBox(width: 16),
        Container(width: 5, height: 5, decoration: BoxDecoration(color: AppColors.primaryOrange.withValues(alpha: 0.5), shape: BoxShape.circle)),
        const SizedBox(width: 10),
        Expanded(child: Text(name, style: const TextStyle(fontSize: 13, color: Color(0xFF1A1240), fontFamily: 'Poppins'))),
        _MiniBtn(icon: Icons.edit_outlined, color: AppColors.primaryPurple,
          onTap: () {
            final ctrl = TextEditingController(text: name);
            Get.dialog(_MobileFormDialog(
              title: 'Edit Sub-Category',
              hint: name,
              controller: ctrl,
              onSave: () { controller.updateSubCategory(categoryId, index, ctrl.text); Get.back(); },
            ));
          }),
        const SizedBox(width: 6),
        _MiniBtn(icon: Icons.delete_outline_rounded, color: const Color(0xFFEF4444),
          onTap: () => Get.dialog(AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Delete?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, fontFamily: 'Poppins')),
            content: Text('Are you sure you want to delete "$name"?', style: const TextStyle(fontSize: 13.5, color: Color(0xFF6B6B8A), fontFamily: 'Poppins')),
            actions: [
              TextButton(onPressed: Get.back, child: const Text('Cancel', style: TextStyle(fontFamily: 'Poppins', color: Color(0xFF6B6B8A)))),
              ElevatedButton(
                onPressed: () { controller.deleteSubCategory(categoryId, index); Get.back(); },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                child: const Text('Delete', style: TextStyle(fontFamily: 'Poppins', color: Colors.white)),
              ),
            ],
          )),
        ),
      ]),
    );
  }
}

// ── Shared helpers ────────────────────────────────────────────
class _MiniBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _MiniBtn({required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30, height: 30,
        decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(7)),
        child: Icon(icon, color: color, size: 16),
      ),
    );
  }
}

class _MobileFormDialog extends StatelessWidget {
  final String title;
  final String hint;
  final TextEditingController controller;
  final VoidCallback onSave;
  const _MobileFormDialog({required this.title, required this.hint, required this.controller, required this.onSave});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1A1240), fontFamily: 'Poppins')),
            const SizedBox(height: 14),
            TextField(
              controller: controller,
              autofocus: true,
              style: const TextStyle(fontSize: 14, color: Color(0xFF1A1240), fontFamily: 'Poppins'),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: const TextStyle(color: Color(0xFF9B9BB4), fontFamily: 'Poppins'),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE0DFF5))),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE0DFF5))),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primaryOrange, width: 1.5)),
              ),
              onSubmitted: (_) => onSave(),
            ),
            const SizedBox(height: 16),
            Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              TextButton(onPressed: Get.back, child: const Text('Cancel', style: TextStyle(fontFamily: 'Poppins', color: Color(0xFF6B6B8A)))),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: onSave,
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryOrange, elevation: 0, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                child: const Text('Save', style: TextStyle(fontFamily: 'Poppins', color: Colors.white, fontWeight: FontWeight.w600)),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}
