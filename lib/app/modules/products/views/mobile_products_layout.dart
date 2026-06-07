import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_colors.dart';
import '../../../routes/app_routes.dart';
import '../../dashboard/widgets/app_drawer.dart';
import '../controllers/products_controller.dart';
import '../models/product_model.dart';

class MobileProductsLayout extends StatelessWidget {
  const MobileProductsLayout({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<ProductsController>();
    return Scaffold(
      backgroundColor: const Color(0xFFF8F7FF),
      drawer: const AppDrawer(activeRoute: AppRoutes.products),
      appBar: _buildAppBar(context, c),
      body: Column(
        children: [
          _buildSearchBar(c),
          _buildFilterChips(c),
          Expanded(child: _buildProductList(c)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Get.toNamed(AppRoutes.addProduct),
        backgroundColor: AppColors.primaryOrange,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Add Product', style: TextStyle(color: Colors.white, fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
      ),
    );
  }

  // ── AppBar ───────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar(BuildContext context, ProductsController c) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: Builder(
        builder: (ctx) => IconButton(
          icon: const Icon(Icons.menu_rounded, color: Color(0xFF1A1240), size: 24),
          onPressed: () => Scaffold.of(ctx).openDrawer(),
        ),
      ),
      title: const Text('Products', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF1A1240), fontFamily: 'Poppins')),
      actions: [
        Stack(children: [
          IconButton(icon: const Icon(Icons.notifications_outlined, color: Color(0xFF1A1240), size: 24), onPressed: () {}),
          Positioned(top: 10, right: 10, child: Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle))),
        ]),
      ],
      bottom: const PreferredSize(preferredSize: Size.fromHeight(1), child: Divider(height: 1, color: Color(0xFFF0EFF8))),
    );
  }

  // ── Search Bar ───────────────────────────────────────────────
  Widget _buildSearchBar(ProductsController c) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: TextField(
        onChanged: (v) => c.searchQuery.value = v,
        style: const TextStyle(fontSize: 14, fontFamily: 'Poppins', color: Color(0xFF1A1240)),
        decoration: InputDecoration(
          hintText: 'Search products...',
          hintStyle: const TextStyle(fontSize: 14, color: Color(0xFF9B9BB4), fontFamily: 'Poppins'),
          prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF9B9BB4), size: 20),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE0DFF5))),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE0DFF5))),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primaryOrange, width: 1.5)),
        ),
      ),
    );
  }

  // ── Category Filter Chips ────────────────────────────────────
  Widget _buildFilterChips(ProductsController c) {
    return Obx(() {
      RxList<String> cats = ['All', ...ProductsController.allCategories.map((cat) => cat.name)].obs;
      return SizedBox(
        height: 44,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: cats.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (_, i) {
            final isSelected = c.selectedCategory.value == (i == 0 ? 'All' : cats[i]);
            return GestureDetector(
              onTap: () => c.selectedCategory.value = i == 0 ? 'All' : cats[i],
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primaryOrange : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isSelected ? AppColors.primaryOrange : const Color(0xFFE0DFF5)),
                ),
                child: Text(
                  cats[i],
                  style: TextStyle(
                    fontSize: 12.5,
                    fontFamily: 'Poppins',
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected ? Colors.white : const Color(0xFF6B6B8A),
                  ),
                ),
              ),
            );
          },
        ),
      );
    });
  }

  // ── Product List ─────────────────────────────────────────────
  Widget _buildProductList(ProductsController c) {
    return Obx(() {
      final products = c.filteredProducts;
      if (products.isEmpty) {
        return Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.inventory_2_outlined, size: 56, color: Colors.grey[300]),
            const SizedBox(height: 12),
            const Text('No products found.', style: TextStyle(fontSize: 15, color: Color(0xFF9B9BB4), fontFamily: 'Poppins')),
          ]),
        );
      }
      return ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        itemCount: products.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) => _ProductCard(product: products[i], controller: c),
      );
    });
  }
}

// ── Product Card ──────────────────────────────────────────────
class _ProductCard extends StatelessWidget {
  final ProductModel product;
  final ProductsController controller;
  const _ProductCard({required this.product, required this.controller});

  @override
  Widget build(BuildContext context) {
    final isLow = product.currentStock <= product.minimumStock;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF0EFF8)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Top Row: icon + name + stock badge ──
          Row(
            children: [
              Container(
                width: 42, height: 42,
                decoration: BoxDecoration(color: AppColors.primaryOrange.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.inventory_2_outlined, color: AppColors.primaryOrange, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product.name, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: Color(0xFF1A1240), fontFamily: 'Poppins'), maxLines: 2, overflow: TextOverflow.ellipsis),
                    Text(product.categoryName, style: const TextStyle(fontSize: 11.5, color: Color(0xFF9B9BB4), fontFamily: 'Poppins')),
                  ],
                ),
              ),
              // Stock status badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isLow ? const Color(0xFFFEF2F2) : const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isLow ? 'Low Stock' : 'In Stock',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isLow ? const Color(0xFFEF4444) : const Color(0xFF22C55E), fontFamily: 'Poppins'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFF0EFF8)),
          const SizedBox(height: 10),
          // ── Bottom Row: price | stock | sub-cat + actions ──
          Row(children: [
            _InfoChip(label: 'Price', value: '\u20b9${product.sellingPrice.toStringAsFixed(0)}'),
            const SizedBox(width: 8),
            _InfoChip(label: 'Stock', value: '${product.currentStock} ${product.unit}'),
            const SizedBox(width: 8),
            _InfoChip(label: 'Sub-Cat', value: product.subCategory, flex: 2),
          ]),
          const SizedBox(height: 12),
          // ── Action Row ──
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _MobileActionBtn(
                icon: Icons.edit_outlined,
                color: AppColors.primaryPurple,
                onTap: () {},
              ),
              const SizedBox(width: 8),
              _MobileActionBtn(
                icon: Icons.delete_outline_rounded,
                color: const Color(0xFFEF4444),
                onTap: () => Get.dialog(
                  _MobileDeleteConfirmDialog(
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
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final String value;
  final int flex;
  const _InfoChip({required this.label, required this.value, this.flex = 1});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(color: const Color(0xFFF8F7FF), borderRadius: BorderRadius.circular(8)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 10.5, color: Color(0xFF9B9BB4), fontFamily: 'Poppins')),
            const SizedBox(height: 2),
            Text(value, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF1A1240), fontFamily: 'Poppins'), maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}

// ── Mobile Action Button ───────────────────────────────────────────────────────
class _MobileActionBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _MobileActionBtn({required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34, height: 34,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Icon(icon, color: color, size: 17),
      ),
    );
  }
}

// ── Mobile Delete Confirm Dialog ───────────────────────────────────────────────
class _MobileDeleteConfirmDialog extends StatelessWidget {
  final String productName;
  final VoidCallback onConfirm;
  const _MobileDeleteConfirmDialog({required this.productName, required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 32, offset: const Offset(0, 10))],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Header ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Row(
                children: [
                  Container(
                    width: 42, height: 42,
                    decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text('Delete Product?',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF1A1240), fontFamily: 'Poppins')),
                  ),
                  GestureDetector(
                    onTap: Get.back,
                    child: Container(
                      width: 30, height: 30,
                      decoration: BoxDecoration(color: const Color(0xFFF5F4FF), borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.close_rounded, size: 17, color: Color(0xFF6B6B8A)),
                    ),
                  ),
                ],
              ),
            ),
            const Padding(padding: EdgeInsets.only(top: 14), child: Divider(height: 1, color: Color(0xFFF0EFF8))),
            // ── Body ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(fontSize: 13.5, color: Color(0xFF6B6B8A), fontFamily: 'Poppins', height: 1.5),
                      children: [
                        const TextSpan(text: 'Are you sure you want to permanently delete '),
                        TextSpan(
                          text: '"$productName"',
                          style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1A1240)),
                        ),
                        const TextSpan(text: '? This cannot be undone.'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: Get.back,
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFE0DFF5)),
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text('Cancel', style: TextStyle(fontSize: 14, fontFamily: 'Poppins', color: Color(0xFF6B6B8A))),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: onConfirm,
                          icon: const Icon(Icons.delete_rounded, color: Colors.white, size: 16),
                          label: const Text('Delete', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, fontFamily: 'Poppins', color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFEF4444),
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
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
    );
  }
}

