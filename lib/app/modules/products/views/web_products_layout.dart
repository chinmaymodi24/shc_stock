import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/products_controller.dart';
import '../../../routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../dashboard/widgets/web_sidebar.dart';
import '../models/product_model.dart';
import 'package:intl/intl.dart';

class WebProductsLayout extends StatelessWidget {
  WebProductsLayout({super.key});

  final c = Get.find<ProductsController>();

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: const Color(0xFFF8F7FF),
      body: Row(
        children: [
          const WebSidebar(),
          Expanded(
            child: Column(
              children: [
                _buildTopBar(c),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(),
                        const SizedBox(height: 20),
                        _buildStatCards(c),
                        const SizedBox(height: 20),
                        _buildTableSection(c),
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

  // ── Top Bar ───────────────────────────────────────────────────
  Widget _buildTopBar(ProductsController c) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFF0EFF8))),
      ),
      child: Row(
        children: [
          // Search bar
          Expanded(
            child: Container(
              height: 40,
              constraints: const BoxConstraints(maxWidth: 380),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F7FF),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE0DFF5)),
              ),
              child: TextField(
                onChanged: (v) => c.searchQuery.value = v,
                style: const TextStyle(fontSize: 13, fontFamily: 'Poppins', color: Color(0xFF1A1240)),
                decoration: const InputDecoration(
                  hintText: 'Search anything...',
                  hintStyle: TextStyle(fontSize: 13, color: Color(0xFF9B9BB4), fontFamily: 'Poppins'),
                  prefixIcon: Icon(Icons.search_rounded, color: Color(0xFF9B9BB4), size: 18),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ),
          const Spacer(),
          Stack(children: [
            IconButton(icon: const Icon(Icons.notifications_outlined, color: Color(0xFF1A1240), size: 24), onPressed: () {}),
            Positioned(top: 8, right: 8, child: Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle))),
          ]),
          const SizedBox(width: 4),
          CircleAvatar(radius: 18, backgroundImage: null, backgroundColor: AppColors.primaryOrange.withValues(alpha: 0.15), child: const Icon(Icons.person_rounded, color: AppColors.primaryOrange, size: 20)),
          const SizedBox(width: 8),
          const Text('Admin', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1A1240), fontFamily: 'Poppins')),
          const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF6B6B8A), size: 18),
        ],
      ),
    );
  }

  // ── Page Header ───────────────────────────────────────────────
  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('Products', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Color(0xFF1A1240), fontFamily: 'Poppins')),
            SizedBox(height: 4),
            Text('Manage all your products and inventory details.', style: TextStyle(fontSize: 13, color: Color(0xFF6B6B8A), fontFamily: 'Poppins')),
          ],
        ),
        ElevatedButton.icon(
          onPressed: () => Get.toNamed(AppRoutes.addProduct),
          icon: const Icon(Icons.add_rounded, color: Colors.white, size: 18),
          label: const Text('Add Product', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white, fontFamily: 'Poppins')),
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

  // ── Stat Cards ────────────────────────────────────────────────
  Widget _buildStatCards(ProductsController c) {
    return Obx(() => Row(
      children: [
        _StatCard(label: 'Total Products', value: '${c.totalProducts}', change: '+12% from last month', isPositive: true, icon: Icons.inventory_2_outlined, iconColor: AppColors.primaryOrange, iconBg: const Color(0xFFFFF3E8)),
        const SizedBox(width: 16),
        _StatCard(label: 'Active Products', value: '${c.activeProducts}', change: '+8% from last month', isPositive: true, icon: Icons.check_circle_outline_rounded, iconColor: const Color(0xFF22C55E), iconBg: const Color(0xFFECFDF5)),
        const SizedBox(width: 16),
        _StatCard(label: 'Low Stock Items', value: '${c.lowStockProducts}', change: '-5% from last month', isPositive: false, icon: Icons.warning_amber_rounded, iconColor: const Color(0xFFF59E0B), iconBg: const Color(0xFFFFFBEB)),
        const SizedBox(width: 16),
        _StatCard(label: 'Out of Stock Items', value: '${c.outOfStockProducts}', change: '-3% from last month', isPositive: false, icon: Icons.cancel_outlined, iconColor: const Color(0xFFEF4444), iconBg: const Color(0xFFFEF2F2)),
      ],
    ));
  }

  // ── Table Section ─────────────────────────────────────────────
  Widget _buildTableSection(ProductsController c) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF0EFF8)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          _buildFiltersRow(c),
          const Divider(height: 1, color: Color(0xFFF0EFF8)),
          _buildTableHeader(),
          const Divider(height: 1, color: Color(0xFFF0EFF8)),
          Obx(() {
            final products = c.paginatedProducts;
            if (products.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(48),
                child: Center(child: Text('No products found.', style: TextStyle(color: Color(0xFF6B6B8A), fontFamily: 'Poppins'))),
              );
            }
            return Column(
              children: products.asMap().entries.map((e) {
                return _ProductRow(product: e.value, isEven: e.key.isEven, controller: c);
              }).toList(),
            );
          }),
          const Divider(height: 1, color: Color(0xFFF0EFF8)),
          _buildPagination(c),
        ],
      ),
    );
  }

  // ── Filters Row ───────────────────────────────────────────────
  Widget _buildFiltersRow(ProductsController c) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Obx(() => Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Search — fixed height 40, same as dropdowns
          Expanded(
            child: SizedBox(
              height: 40,
              child: TextField(
                onChanged: (v) => c.searchQuery.value = v,
                style: const TextStyle(fontSize: 13, fontFamily: 'Poppins', color: Color(0xFF1A1240)),
                decoration: InputDecoration(
                  hintText: 'Search products...',
                  hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF9B9BB4), fontFamily: 'Poppins'),
                  prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF9B9BB4), size: 18),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFFE0DFF5)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFFE0DFF5)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.primaryOrange, width: 1.5),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Category filter
          SizedBox(
            width: 160,
            child: _FilterDropdown(
              label: 'Category',
              value: c.selectedCategory.value,
              items: c.categoryNames,
              onChanged: (v) => c.selectedCategory.value = v,
            ),
          ),
          const SizedBox(width: 12),
          // Status filter
          SizedBox(
            width: 120,
            child: _FilterDropdown(
              label: 'Status',
              value: c.selectedStatus.value,
              items: const ['All Status', 'Active', 'Inactive'],
              onChanged: (v) => c.selectedStatus.value = v,
            ),
          ),
          const SizedBox(width: 12),
          // Stock Status filter
          SizedBox(
            width: 130,
            child: _FilterDropdown(
              label: 'Stock Status',
              value: c.selectedStockStatus.value,
              items: const ['All', 'In Stock', 'Low Stock', 'Out of Stock'],
              onChanged: (v) => c.selectedStockStatus.value = v,
            ),
          ),
          const SizedBox(width: 12),
          // Reset
          SizedBox(
            height: 40,
            child: OutlinedButton.icon(
              onPressed: c.resetFilters,
              icon: const Icon(Icons.refresh_rounded, size: 16, color: Color(0xFF6B6B8A)),
              label: const Text('Reset', style: TextStyle(fontSize: 13, color: Color(0xFF6B6B8A), fontFamily: 'Poppins')),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFE0DFF5)),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            height: 40,
            child: ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.filter_list_rounded, size: 16, color: Colors.white),
              label: const Text('Filter', style: TextStyle(fontSize: 13, color: Colors.white, fontFamily: 'Poppins')),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryOrange,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      )),
    );
  }

  // ── Table Header ──────────────────────────────────────────────
  Widget _buildTableHeader() {
    const style = TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF6B6B8A), fontFamily: 'Poppins');
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          const SizedBox(width: 44), // icon space
          Expanded(flex: 5, child: Row(children: [const Text('Product Name', style: style), const SizedBox(width: 4), const Icon(Icons.unfold_more_rounded, size: 14, color: Color(0xFF9B9BB4))])),
          Expanded(flex: 2, child: Row(children: [const Text('SKU', style: style), const SizedBox(width: 4), const Icon(Icons.unfold_more_rounded, size: 14, color: Color(0xFF9B9BB4))])),
          Expanded(flex: 3, child: Row(children: [const Text('Category', style: style), const SizedBox(width: 4), const Icon(Icons.unfold_more_rounded, size: 14, color: Color(0xFF9B9BB4))])),
          Expanded(flex: 2, child: Row(children: [const Text('Unit Price', style: style), const SizedBox(width: 4), const Icon(Icons.unfold_more_rounded, size: 14, color: Color(0xFF9B9BB4))])),
          Expanded(flex: 2, child: Row(children: [const Text('Stock', style: style), const SizedBox(width: 4), const Icon(Icons.unfold_more_rounded, size: 14, color: Color(0xFF9B9BB4))])),
          Expanded(flex: 2, child: Row(children: [const Text('Status', style: style), const SizedBox(width: 4), const Icon(Icons.unfold_more_rounded, size: 14, color: Color(0xFF9B9BB4))])),
          Expanded(flex: 2, child: Row(children: [const Text('Created On', style: style), const SizedBox(width: 4), const Icon(Icons.unfold_more_rounded, size: 14, color: Color(0xFF9B9BB4))])),
          const SizedBox(width: 116, child: Center(child: Text('Actions', style: style))),
        ],
      ),
    );
  }

  // ── Pagination ────────────────────────────────────────────────
  Widget _buildPagination(ProductsController c) {
    return Obx(() => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Text('Showing ${(c.currentPage.value - 1) * c.rowsPerPage.value + 1} to ${((c.currentPage.value) * c.rowsPerPage.value).clamp(0, c.filteredProducts.length)} of ${c.filteredProducts.length} entries',
            style: const TextStyle(fontSize: 12.5, color: Color(0xFF6B6B8A), fontFamily: 'Poppins')),
          const Spacer(),
          // Rows per page
          Row(children: [
            const Text('Rows per page: ', style: TextStyle(fontSize: 12.5, color: Color(0xFF6B6B8A), fontFamily: 'Poppins')),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE0DFF5)), borderRadius: BorderRadius.circular(6)),
              child: DropdownButton<int>(
                value: c.rowsPerPage.value,
                isDense: true,
                underline: const SizedBox(),
                style: const TextStyle(fontSize: 12.5, color: Color(0xFF1A1240), fontFamily: 'Poppins'),
                items: [5, 10, 20, 50].map((e) => DropdownMenuItem(value: e, child: Text('$e'))).toList(),
                onChanged: (v) { if (v != null) { c.rowsPerPage.value = v; c.currentPage.value = 1; } },
              ),
            ),
          ]),
          const SizedBox(width: 16),
          // Page buttons
          _PageButton(icon: Icons.first_page_rounded, onTap: () => c.currentPage.value = 1, enabled: c.currentPage.value > 1),
          _PageButton(icon: Icons.chevron_left_rounded, onTap: () { if (c.currentPage.value > 1) c.currentPage.value--; }, enabled: c.currentPage.value > 1),
          ...List.generate(c.totalPages.clamp(0, 5), (i) {
            final page = i + 1;
            final isActive = c.currentPage.value == page;
            return GestureDetector(
              onTap: () => c.currentPage.value = page,
              child: Container(
                width: 32, height: 32,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: isActive ? AppColors.primaryOrange : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: isActive ? AppColors.primaryOrange : const Color(0xFFE0DFF5)),
                ),
                child: Center(child: Text('$page', style: TextStyle(fontSize: 12.5, fontWeight: isActive ? FontWeight.w600 : FontWeight.w400, color: isActive ? Colors.white : const Color(0xFF1A1240), fontFamily: 'Poppins'))),
              ),
            );
          }),
          if (c.totalPages > 5) ...[
            const Text('...', style: TextStyle(color: Color(0xFF6B6B8A))),
            GestureDetector(
              onTap: () => c.currentPage.value = c.totalPages,
              child: Container(width: 32, height: 32, margin: const EdgeInsets.symmetric(horizontal: 2), decoration: BoxDecoration(borderRadius: BorderRadius.circular(6), border: Border.all(color: const Color(0xFFE0DFF5))), child: Center(child: Text('${c.totalPages}', style: const TextStyle(fontSize: 12.5, color: Color(0xFF1A1240), fontFamily: 'Poppins')))),
            ),
          ],
          _PageButton(icon: Icons.chevron_right_rounded, onTap: () { if (c.currentPage.value < c.totalPages) c.currentPage.value++; }, enabled: c.currentPage.value < c.totalPages),
          _PageButton(icon: Icons.last_page_rounded, onTap: () => c.currentPage.value = c.totalPages, enabled: c.currentPage.value < c.totalPages),
        ],
      ),
    ));
  }
}

// ── Product Table Row ─────────────────────────────────────────────────────────
class _ProductRow extends StatelessWidget {
  final ProductModel product;
  final bool isEven;
  final ProductsController controller;

  const _ProductRow({required this.product, required this.isEven, required this.controller});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##,##0.00', 'en_IN');
    final dateFmt = DateFormat('d MMM yyyy');

    Color stockColor;
    if (product.currentStock == 0) stockColor = const Color(0xFFEF4444);
    else if (product.currentStock <= product.minimumStock) stockColor = const Color(0xFFF59E0B);
    else stockColor = const Color(0xFF22C55E);

    Color statusBadgeColor;
    Color statusTextColor;
    String statusText = product.stockStatus;
    switch (statusText) {
      case 'In Stock': statusBadgeColor = const Color(0xFFECFDF5); statusTextColor = const Color(0xFF22C55E); break;
      case 'Low Stock': statusBadgeColor = const Color(0xFFFFFBEB); statusTextColor = const Color(0xFFF59E0B); break;
      default: statusBadgeColor = const Color(0xFFFEF2F2); statusTextColor = const Color(0xFFEF4444);
    }

    return Container(
      decoration: BoxDecoration(
        color: isEven ? const Color(0xFFFCFBFF) : Colors.white,
        border: const Border(bottom: BorderSide(color: Color(0xFFF0EFF8))),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: [
            // Product icon placeholder
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFEEECFF),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.inventory_2_outlined, color: AppColors.primaryPurple, size: 18),
            ),
            const SizedBox(width: 8),
            // Name
            Expanded(flex: 5, child: Text(product.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF1A1240), fontFamily: 'Poppins'), overflow: TextOverflow.ellipsis)),
            // SKU
            Expanded(flex: 2, child: Text(product.sku, style: const TextStyle(fontSize: 12.5, color: Color(0xFF6B6B8A), fontFamily: 'Poppins'))),
            // Category
            Expanded(flex: 3, child: Text(product.categoryName.replaceFirst(RegExp(r'^\d+\.\s'), ''), style: const TextStyle(fontSize: 12.5, color: Color(0xFF6B6B8A), fontFamily: 'Poppins'), overflow: TextOverflow.ellipsis)),
            // Price
            Expanded(flex: 2, child: Text('₹ ${fmt.format(product.sellingPrice)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF1A1240), fontFamily: 'Poppins'))),
            // Stock
            Expanded(flex: 2, child: Text('${product.currentStock}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: stockColor, fontFamily: 'Poppins'))),
            // Status badge
            Expanded(
              flex: 2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: statusBadgeColor, borderRadius: BorderRadius.circular(20)),
                child: Text(statusText, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: statusTextColor, fontFamily: 'Poppins'), textAlign: TextAlign.center),
              ),
            ),
            // Created On
            Expanded(flex: 2, child: Text(dateFmt.format(product.createdAt), style: const TextStyle(fontSize: 12.5, color: Color(0xFF6B6B8A), fontFamily: 'Poppins'))),
            // Actions
            SizedBox(
              width: 116,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _ActionBtn(icon: Icons.remove_red_eye_outlined, color: const Color(0xFF6B6B8A), onTap: () {}),
                  const SizedBox(width: 6),
                  _ActionBtn(icon: Icons.edit_outlined, color: AppColors.primaryPurple, onTap: () {}),
                  const SizedBox(width: 6),
                  _ActionBtn(
                    icon: Icons.delete_outline_rounded,
                    color: const Color(0xFFEF4444),
                    onTap: () => Get.dialog(
                      _DeleteConfirmDialog(
                        productName: product.name,
                        onConfirm: () {
                          controller.deleteProduct(product.id);
                          Get.back();
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Helper Widgets ────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String change;
  final bool isPositive;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;

  const _StatCard({required this.label, required this.value, required this.change, required this.isPositive, required this.icon, required this.iconColor, required this.iconBg});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFF0EFF8)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontSize: 12.5, color: Color(0xFF6B6B8A), fontFamily: 'Poppins')),
                  const SizedBox(height: 6),
                  Text(value, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: Color(0xFF1A1240), fontFamily: 'Poppins')),
                  const SizedBox(height: 4),
                  Text(change, style: TextStyle(fontSize: 11.5, color: isPositive ? const Color(0xFF22C55E) : const Color(0xFFEF4444), fontFamily: 'Poppins')),
                ],
              ),
            ),
            Container(
              width: 46, height: 46,
              decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: iconColor, size: 22),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterDropdown extends StatelessWidget {
  final String label;
  final String value;
  final List<String> items;
  final ValueChanged<String> onChanged;

  const _FilterDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: DropdownButtonFormField<String>(
        value: value,
        isDense: true,
        isExpanded: true,
        style: const TextStyle(
          fontSize: 12.5,
          color: Color(0xFF1A1240),
          fontFamily: 'Poppins',
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(
            fontSize: 11,
            color: Color(0xFF9B9BB4),
            fontFamily: 'Poppins',
          ),
          floatingLabelBehavior: FloatingLabelBehavior.always,
          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          isDense: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFE0DFF5)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFE0DFF5)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.primaryOrange, width: 1.5),
          ),
          filled: true,
          fillColor: Colors.white,
        ),
        items: items
            .map((e) => DropdownMenuItem(value: e, child: Text(e, overflow: TextOverflow.ellipsis)))
            .toList(),
        onChanged: (v) {
          if (v != null) onChanged(v);
        },
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _ActionBtn({required this.icon, required this.color, required this.onTap});

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

class _PageButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool enabled;
  const _PageButton({required this.icon, required this.onTap, required this.enabled});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 32, height: 32,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFFE0DFF5)),
          color: enabled ? Colors.white : const Color(0xFFF8F7FF),
        ),
        child: Icon(icon, size: 18, color: enabled ? const Color(0xFF1A1240) : const Color(0xFFB0B0C4)),
      ),
    );
  }
}

// ── Delete Confirm Dialog ─────────────────────────────────────────────────────
class _DeleteConfirmDialog extends StatelessWidget {
  final String productName;
  final VoidCallback onConfirm;

  const _DeleteConfirmDialog({
    required this.productName,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460, minWidth: 360),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 36,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Header ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                  child: Row(
                    children: [
                      Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.delete_outline_rounded,
                            color: Color(0xFFEF4444), size: 24),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Text(
                          'Delete Product?',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1A1240),
                              fontFamily: 'Poppins'),
                        ),
                      ),
                      GestureDetector(
                        onTap: Get.back,
                        child: Container(
                          width: 32, height: 32,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F4FF),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.close_rounded,
                              size: 18, color: Color(0xFF6B6B8A)),
                        ),
                      ),
                    ],
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(top: 16),
                  child: Divider(height: 1, color: Color(0xFFF0EFF8)),
                ),
                // ── Body ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RichText(
                        text: TextSpan(
                          style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF6B6B8A),
                              fontFamily: 'Poppins',
                              height: 1.55),
                          children: [
                            const TextSpan(
                                text:
                                    'Are you sure you want to permanently delete '),
                            TextSpan(
                              text: '"$productName"',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1A1240)),
                            ),
                            const TextSpan(
                                text:
                                    '? This action cannot be undone.'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton(
                            onPressed: Get.back,
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(
                                  color: Color(0xFFE0DFF5)),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 22, vertical: 12),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                            child: const Text('Cancel',
                                style: TextStyle(
                                    fontSize: 14,
                                    fontFamily: 'Poppins',
                                    color: Color(0xFF6B6B8A))),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            onPressed: onConfirm,
                            icon: const Icon(Icons.delete_rounded,
                                color: Colors.white, size: 16),
                            label: const Text('Yes, Delete',
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: 'Poppins',
                                    color: Colors.white)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFEF4444),
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 22, vertical: 12),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ],
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
