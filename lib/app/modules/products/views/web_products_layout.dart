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
    final colors = context.appColors;
    return Scaffold(
      backgroundColor: colors.background,
      body: Row(
        children: [
          const WebSidebar(),
          Expanded(
            child: Column(
              children: [
                _buildTopBar(context, c),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(context),
                        const SizedBox(height: 20),
                        _buildStatCards(c),
                        const SizedBox(height: 20),
                        _buildTableSection(context, c),
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
  Widget _buildTopBar(BuildContext context, ProductsController c) {
    final colors = context.appColors;
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: colors.topBarBg,
        border: Border(bottom: BorderSide(color: colors.divider)),
      ),
      child: Row(
        children: [
          // Search bar
          Expanded(
            child: Container(
              height: 40,
              constraints: const BoxConstraints(maxWidth: 380),
              decoration: BoxDecoration(
                color: colors.inputFill,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: colors.border),
              ),
              child: TextField(
                onChanged: (v) => c.searchQuery.value = v,
                style: TextStyle(fontSize: 13, fontFamily: 'Poppins', color: colors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Search anything...',
                  hintStyle: TextStyle(fontSize: 13, color: colors.textHint, fontFamily: 'Poppins'),
                  prefixIcon: Icon(Icons.search_rounded, color: colors.textHint, size: 18),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ),
          const Spacer(),
          Stack(children: [
            IconButton(icon: Icon(Icons.notifications_outlined, color: colors.textPrimary, size: 24), onPressed: () {}),
            Positioned(top: 8, right: 8, child: Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle))),
          ]),
          const SizedBox(width: 4),
          CircleAvatar(radius: 18, backgroundColor: AppColors.primaryOrange.withValues(alpha: 0.15), child: const Icon(Icons.person_rounded, color: AppColors.primaryOrange, size: 20)),
          const SizedBox(width: 8),
          Text('Admin', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: colors.textPrimary, fontFamily: 'Poppins')),
          Icon(Icons.keyboard_arrow_down_rounded, color: colors.textSecondary, size: 18),
        ],
      ),
    );
  }

  // ── Page Header ───────────────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    final colors = context.appColors;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Products', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: colors.textPrimary, fontFamily: 'Poppins')),
            const SizedBox(height: 4),
            Text('Manage all your products and inventory details.', style: TextStyle(fontSize: 13, color: colors.textSecondary, fontFamily: 'Poppins')),
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
        _StatCard(label: 'Total Products', value: '${c.totalProducts}', change: '+12% from last month', isPositive: true, icon: Icons.inventory_2_outlined, iconColor: AppColors.primaryOrange),
        const SizedBox(width: 16),
        _StatCard(label: 'Active Products', value: '${c.activeProducts}', change: '+8% from last month', isPositive: true, icon: Icons.check_circle_outline_rounded, iconColor: appColors.success),
        const SizedBox(width: 16),
        _StatCard(label: 'Low Stock Items', value: '${c.lowStockProducts}', change: '-5% from last month', isPositive: false, icon: Icons.warning_amber_rounded, iconColor: appColors.warning),
        const SizedBox(width: 16),
        _StatCard(label: 'Out of Stock Items', value: '${c.outOfStockProducts}', change: '-3% from last month', isPositive: false, icon: Icons.cancel_outlined, iconColor: appColors.error),
      ],
    ));
  }

  // ── Table Section ─────────────────────────────────────────────
  Widget _buildTableSection(BuildContext context, ProductsController c) {
    final colors = context.appColors;
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.divider),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 3, offset: const Offset(0, 1))],
      ),
      child: Column(
        children: [
          _buildFiltersRow(context, c),
          Divider(height: 1, color: colors.divider),
          _buildTableHeader(context),
          Divider(height: 1, color: colors.divider),
          Obx(() {
            final products = c.paginatedProducts;
            if (products.isEmpty) {
              return Padding(
                padding: const EdgeInsets.all(48),
                child: Center(child: Text('No products found.', style: TextStyle(color: colors.textSecondary, fontFamily: 'Poppins'))),
              );
            }
            return Column(
              children: products.asMap().entries.map((e) {
                return _ProductRow(product: e.value, isEven: e.key.isEven, controller: c);
              }).toList(),
            );
          }),
          Divider(height: 1, color: colors.divider),
          _buildPagination(context, c),
        ],
      ),
    );
  }

  // ── Filters Row ───────────────────────────────────────────────
  Widget _buildFiltersRow(BuildContext context, ProductsController c) {
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Obx(() => Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Search
          Expanded(
            child: SizedBox(
              height: 40,
              child: TextField(
                onChanged: (v) => c.searchQuery.value = v,
                style: TextStyle(fontSize: 13, fontFamily: 'Poppins', color: colors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Search products...',
                  hintStyle: TextStyle(fontSize: 13, color: colors.textHint, fontFamily: 'Poppins'),
                  prefixIcon: Icon(Icons.search_rounded, color: colors.textHint, size: 18),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: colors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: colors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.primaryOrange, width: 1.5),
                  ),
                  filled: true,
                  fillColor: colors.inputFill,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
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
          SizedBox(
            height: 40,
            child: OutlinedButton.icon(
              onPressed: c.resetFilters,
              icon: Icon(Icons.refresh_rounded, size: 16, color: colors.textSecondary),
              label: Text('Reset', style: TextStyle(fontSize: 13, color: colors.textSecondary, fontFamily: 'Poppins')),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: colors.border),
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
  Widget _buildTableHeader(BuildContext context) {
    final style = TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: context.appColors.textSecondary, fontFamily: 'Poppins');
    final sortIcon = Icon(Icons.unfold_more_rounded, size: 14, color: context.appColors.textHint);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          const SizedBox(width: 44),
          Expanded(flex: 5, child: Row(children: [Text('Product Name', style: style), const SizedBox(width: 4), sortIcon])),
          Expanded(flex: 2, child: Row(children: [Text('SKU', style: style), const SizedBox(width: 4), sortIcon])),
          Expanded(flex: 3, child: Row(children: [Text('Category', style: style), const SizedBox(width: 4), sortIcon])),
          Expanded(flex: 2, child: Row(children: [Text('Unit Price', style: style), const SizedBox(width: 4), sortIcon])),
          Expanded(flex: 2, child: Row(children: [Text('Stock', style: style), const SizedBox(width: 4), sortIcon])),
          Expanded(flex: 2, child: Row(children: [Text('Status', style: style), const SizedBox(width: 4), sortIcon])),
          Expanded(flex: 2, child: Row(children: [Text('Created On', style: style), const SizedBox(width: 4), sortIcon])),
          SizedBox(width: 116, child: Center(child: Text('Actions', style: style))),
        ],
      ),
    );
  }

  // ── Pagination ────────────────────────────────────────────────
  Widget _buildPagination(BuildContext context, ProductsController c) {
    final colors = context.appColors;
    return Obx(() => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Text('Showing ${(c.currentPage.value - 1) * c.rowsPerPage.value + 1} to ${((c.currentPage.value) * c.rowsPerPage.value).clamp(0, c.filteredProducts.length)} of ${c.filteredProducts.length} entries',
            style: TextStyle(fontSize: 12.5, color: colors.textSecondary, fontFamily: 'Poppins')),
          const Spacer(),
          Row(children: [
            Text('Rows per page: ', style: TextStyle(fontSize: 12.5, color: colors.textSecondary, fontFamily: 'Poppins')),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(border: Border.all(color: colors.border), borderRadius: BorderRadius.circular(6)),
              child: DropdownButton<int>(
                value: c.rowsPerPage.value,
                isDense: true,
                underline: const SizedBox(),
                dropdownColor: colors.surface,
                style: TextStyle(fontSize: 12.5, color: colors.textPrimary, fontFamily: 'Poppins'),
                items: [5, 10, 20, 50].map((e) => DropdownMenuItem(value: e, child: Text('$e'))).toList(),
                onChanged: (v) { if (v != null) { c.rowsPerPage.value = v; c.currentPage.value = 1; } },
              ),
            ),
          ]),
          const SizedBox(width: 16),
          _PageButton(icon: Icons.first_page_rounded, onTap: () => c.currentPage.value = 1, enabled: c.currentPage.value > 1),
          _PageButton(icon: Icons.chevron_left_rounded, onTap: () { if (c.currentPage.value > 1) c.currentPage.value--; }, enabled: c.currentPage.value > 1),
          ...List.generate(c.totalPages.clamp(0, 5), (i) {
            final page = i + 1;
            final isActive = c.currentPage.value == page;
            return InkWell(
              onTap: () => c.currentPage.value = page,
              borderRadius: BorderRadius.circular(6),
              child: Container(
                width: 32, height: 32,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: isActive ? AppColors.primaryOrange : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: isActive ? AppColors.primaryOrange : colors.border),
                ),
                child: Center(child: Text('$page', style: TextStyle(fontSize: 12.5, fontWeight: isActive ? FontWeight.w600 : FontWeight.w400, color: isActive ? Colors.white : colors.textPrimary, fontFamily: 'Poppins'))),
              ),
            );
          }),
          if (c.totalPages > 5) ...[
            Text('...', style: TextStyle(color: colors.textSecondary)),
            InkWell(
              onTap: () => c.currentPage.value = c.totalPages,
              borderRadius: BorderRadius.circular(6),
              child: Container(width: 32, height: 32, margin: const EdgeInsets.symmetric(horizontal: 2), decoration: BoxDecoration(borderRadius: BorderRadius.circular(6), border: Border.all(color: colors.border)), child: Center(child: Text('${c.totalPages}', style: TextStyle(fontSize: 12.5, color: colors.textPrimary, fontFamily: 'Poppins')))),
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
    final colors = context.appColors;

    Color stockColor;
    if (product.currentStock == 0) stockColor = colors.error;
    else if (product.currentStock <= product.minimumStock) stockColor = colors.warning;
    else stockColor = colors.success;

    Color statusBadgeColor;
    Color statusTextColor;
    String statusText = product.stockStatus;
    switch (statusText) {
      case 'In Stock': 
        statusTextColor = colors.success; 
        statusBadgeColor = statusTextColor.withValues(alpha: 0.1); 
        break;
      case 'Low Stock': 
        statusTextColor = colors.warning; 
        statusBadgeColor = statusTextColor.withValues(alpha: 0.1); 
        break;
      default: 
        statusTextColor = colors.error; 
        statusBadgeColor = statusTextColor.withValues(alpha: 0.1);
    }

    return Container(
      decoration: BoxDecoration(
        color: isEven ? colors.rowEven : colors.surface,
        border: Border(bottom: BorderSide(color: colors.divider)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: colors.iconBgPurple,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.inventory_2_outlined, color: colors.purple, size: 18),
            ),
            const SizedBox(width: 8),
            Expanded(flex: 5, child: Text(product.name, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: colors.textPrimary, fontFamily: 'Poppins'), overflow: TextOverflow.ellipsis)),
            Expanded(flex: 2, child: Text(product.sku, style: TextStyle(fontSize: 12.5, color: colors.textSecondary, fontFamily: 'Poppins'))),
            Expanded(flex: 3, child: Text(product.categoryName.replaceFirst(RegExp(r'^\d+\.\s'), ''), style: TextStyle(fontSize: 12.5, color: colors.textSecondary, fontFamily: 'Poppins'), overflow: TextOverflow.ellipsis)),
            Expanded(flex: 2, child: Text('₹ ${fmt.format(product.sellingPrice)}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: colors.textPrimary, fontFamily: 'Poppins'))),
            Expanded(flex: 2, child: Text('${product.currentStock}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: stockColor, fontFamily: 'Poppins'))),
            Expanded(
              flex: 2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: statusBadgeColor, borderRadius: BorderRadius.circular(20)),
                child: Text(statusText, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: statusTextColor, fontFamily: 'Poppins'), textAlign: TextAlign.center),
              ),
            ),
            Expanded(flex: 2, child: Text(dateFmt.format(product.createdAt), style: TextStyle(fontSize: 12.5, color: colors.textSecondary, fontFamily: 'Poppins'))),
            SizedBox(
              width: 116,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _ActionBtn(icon: Icons.remove_red_eye_outlined, color: colors.textSecondary, onTap: () {}),
                  const SizedBox(width: 6),
                  _ActionBtn(icon: Icons.edit_outlined, color: colors.purple, onTap: () {}),
                  const SizedBox(width: 6),
                  _ActionBtn(
                    icon: Icons.delete_outline_rounded,
                    color: colors.error,
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

  const _StatCard({required this.label, required this.value, required this.change, required this.isPositive, required this.icon, required this.iconColor});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colors.divider),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 3, offset: const Offset(0, 1))],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(fontSize: 12.5, color: colors.textSecondary, fontFamily: 'Poppins')),
                  const SizedBox(height: 6),
                  Text(value, style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: colors.textPrimary, fontFamily: 'Poppins')),
                  const SizedBox(height: 4),
                  Text(change, style: TextStyle(fontSize: 11.5, color: isPositive ? colors.success : colors.error, fontFamily: 'Poppins')),
                ],
              ),
            ),
            Container(
              width: 46, height: 46,
              decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
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
    final colors = context.appColors;
    return SizedBox(
      height: 40,
      child: DropdownButtonFormField<String>(
        value: value,
        isDense: true,
        isExpanded: true,
        dropdownColor: colors.surface,
        style: TextStyle(
          fontSize: 12.5,
          color: colors.textPrimary,
          fontFamily: 'Poppins',
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            fontSize: 11,
            color: colors.textHint,
            fontFamily: 'Poppins',
          ),
          floatingLabelBehavior: FloatingLabelBehavior.always,
          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          isDense: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: colors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: colors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.primaryOrange, width: 1.5),
          ),
          filled: true,
          fillColor: colors.inputFill,
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(7),
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
    final colors = appColors;
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: 32, height: 32,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: colors.border),
          color: enabled ? colors.surface : colors.background,
        ),
        child: Icon(icon, size: 18, color: enabled ? colors.textPrimary : colors.textHint),
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
    final colors = context.appColors;
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460, minWidth: 360),
          child: Container(
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.20),
                  blurRadius: 36,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                  child: Row(
                    children: [
                      Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(
                          color: colors.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.delete_outline_rounded,
                            color: colors.error, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          'Delete Product?',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: colors.textPrimary,
                              fontFamily: 'Poppins'),
                        ),
                      ),
                      InkWell(
                        onTap: Get.back,
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          width: 32, height: 32,
                          decoration: BoxDecoration(
                            color: colors.comingSoonBadge,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.close_rounded,
                              size: 18, color: colors.textSecondary),
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
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RichText(
                        text: TextSpan(
                          style: TextStyle(
                              fontSize: 14,
                              color: colors.textSecondary,
                              fontFamily: 'Poppins',
                              height: 1.55),
                          children: [
                            const TextSpan(
                                text:
                                    'Are you sure you want to permanently delete '),
                            TextSpan(
                              text: '"$productName"',
                              style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: colors.textPrimary),
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
                              side: BorderSide(color: colors.border),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 22, vertical: 12),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                            child: Text('Cancel',
                                style: TextStyle(
                                    fontSize: 14,
                                    fontFamily: 'Poppins',
                                    color: colors.textSecondary)),
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
                              backgroundColor: colors.error,
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
