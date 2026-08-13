import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:math' as math;
import 'package:shc_stock/app/modules/clients/controllers/clients_controller.dart';
import 'package:shc_stock/app/shared/widgets/app_loading_indicator.dart';
import 'package:shc_stock/app/modules/clients/models/client_model.dart';
import 'package:shc_stock/app/core/theme/app_colors.dart';
import 'package:shc_stock/app/shared/widgets/filter_bar.dart';
import 'package:shc_stock/app/routes/app_routes.dart';
import 'package:shc_stock/app/modules/dashboard/widgets/web_sidebar.dart';
import 'package:shc_stock/app/modules/dashboard/widgets/web_top_bar.dart';
import 'package:shc_stock/app/shared/widgets/stat_cards.dart';
import 'package:shc_stock/app/shared/widgets/table_footer.dart';
import 'package:shc_stock/app/modules/clients/views/client_details_dialog.dart';

// ── Table column constants (header + row MUST match) ──────────────────────
const double _kIdxW = 36.0; // # badge
const double _kGap = 10.0; // column gap
const int _kCodeFlex = 10; // CLT-0001
const int _kNameFlex = 20; // Client Name + badge
const int _kAddrFlex = 22; // Address
const int _kGstFlex = 14; // GSTIN/UIN
const int _kRegFlex = 12; // Registration Type badge
const int _kContactFlex = 18; // Contact person + phone
const int _kActFlex = 16; // Actions — View + Edit + Delete

// ─────────────────────────────────────────────────────────────────────────────
// Main Widget
// ─────────────────────────────────────────────────────────────────────────────
class WebClientsLayout extends GetView<ClientsController> {
  const WebClientsLayout({super.key});

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final colors = context.appColors;

    return Scaffold(
      backgroundColor: colors.background,
      body: Row(
        children: [
          const WebSidebar(),
          Expanded(
            child: Column(
              children: [
                const WebTopBar(),
                Expanded(
                  child: Obx(() {
                    final all = c.clients;
                    final searchQuery = c.searchQuery.value;
                    final stateFilters = c.stateFilters;
                    final cityFilters = c.cityFilters;
                    final rowsPerPage = c.rowsPerPage.value;
                    final currentPage = c.currentPage.value;
                    final filtered = all.where((cl) {
                      if (searchQuery.isNotEmpty) {
                        final q = searchQuery.toLowerCase();
                        final matches =
                            cl.name.toLowerCase().contains(q) ||
                            cl.code.toLowerCase().contains(q) ||
                            cl.address.toLowerCase().contains(q) ||
                            cl.gstin.toLowerCase().contains(q);
                        if (!matches) return false;
                      }
                      if (stateFilters.isNotEmpty &&
                          !stateFilters.contains(cl.state)) {
                        return false;
                      }
                      if (cityFilters.isNotEmpty &&
                          !cityFilters.contains(cl.city)) {
                        return false;
                      }
                      return true;
                    }).toList();

                    final totalPages = filtered.isEmpty
                        ? 1
                        : (filtered.length / rowsPerPage).ceil();
                    final startIdx = (currentPage - 1) * rowsPerPage;
                    final endIdx = math.min(
                      startIdx + rowsPerPage,
                      filtered.length,
                    );
                    final pageItems = filtered.isEmpty
                        ? <ClientModel>[]
                        : filtered.sublist(startIdx, endIdx);

                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── LEFT COLUMN ──────────────────────────────────────────
                          // Header, summary cards, toolbar, table and footer all
                          // live here so the right panel can run alongside the
                          // whole lot, starting level with the page header rather
                          // than below the summary row.
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // ── Page Header ──────────────────────────────────────────
                                Row(
                                  children: [
                                    // Flexible: the title block and the Add
                                    // button together overflowed the header at
                                    // laptop widths.
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Clients',
                                            style: TextStyle(
                                              fontSize: 22,
                                              fontWeight: FontWeight.w700,
                                              color: colors.textPrimary,
                                              fontFamily: 'Poppins',
                                            ),
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            'Manage your clients and track their business relationship',
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: colors.textSecondary,
                                              fontFamily: 'Poppins',
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    ElevatedButton.icon(
                                      onPressed: () =>
                                          Get.toNamed(AppRoutes.addClient),
                                      icon: const Icon(
                                        Icons.add_rounded,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                      label: const Text(
                                        'Add New Client',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                          fontFamily: 'Poppins',
                                        ),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            AppColors.primaryOrange,
                                        elevation: 0,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 20,
                                          vertical: 14,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),

                                // ── Stat Cards ───────────────────────────────────────────
                                IntrinsicHeight(
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Expanded(
                                        child: AppStatCard(
                                          label: 'Total Clients',
                                          value: '${c.totalClients}',
                                          icon: Icons.groups_rounded,
                                          iconColor: AppColors.primaryOrange,
                                          trend: c.stats.value.trendLabel(
                                            'totalClients',
                                          ),
                                          trendUp: c.stats.value.trendUp(
                                            'totalClients',
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: AppStatCard(
                                          label: 'GST Registered',
                                          value: '${c.registeredClients}',
                                          icon: Icons
                                              .check_circle_outline_rounded,
                                          iconColor: const Color(0xFF4A3AFF),
                                          trend: c.stats.value.trendLabel(
                                            'gstRegistered',
                                          ),
                                          trendUp: c.stats.value.trendUp(
                                            'gstRegistered',
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: AppStatCard(
                                          label: 'Unregistered Clients',
                                          value: '${c.unregisteredClients}',
                                          icon: Icons.block_rounded,
                                          iconColor: const Color(0xFFF59E0B),
                                          trend: c.stats.value.trendLabel(
                                            'unregistered',
                                          ),
                                          trendUp: c.stats.value.trendUp(
                                            'unregistered',
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: AppStatCard(
                                          label: 'States Covered',
                                          value: '${c.statesCovered}',
                                          icon: Icons.map_outlined,
                                          iconColor: const Color(0xFF22C55E),
                                          trend: c.stats.value.trendLabel(
                                            'statesCovered',
                                          ),
                                          trendUp: c.stats.value.trendUp(
                                            'statesCovered',
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 20),

                                // Reference design keeps the toolbar above and
                                // the pagination below the bordered table card,
                                // both sitting on the page background.
                                _Toolbar(
                                  colors: colors,
                                  onSearch: (v) {
                                    c.searchQuery.value = v;
                                    c.currentPage.value = 1;
                                  },
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  decoration: BoxDecoration(
                                    color: colors.surface,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: colors.divider),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.04,
                                        ),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    children: [
                                      // Column Header
                                      _ColumnHeader(colors: colors),
                                      Divider(height: 1, color: colors.divider),

                                      // Rows
                                      if (c.isLoading.value)
                                        const AppLoadingIndicator(
                                          label: 'Loading clients...',
                                          padding: 40,
                                        )
                                      else if (pageItems.isEmpty)
                                        Padding(
                                          padding: const EdgeInsets.all(48),
                                          child: Center(
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.person_search_rounded,
                                                  size: 40,
                                                  color: colors.textHint,
                                                ),
                                                const SizedBox(height: 10),
                                                Text(
                                                  'No clients found',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    color: colors.textHint,
                                                    fontFamily: 'Poppins',
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        )
                                      else
                                        ...pageItems.asMap().entries.map(
                                          (e) => _ClientRow(
                                            client: e.value,
                                            displayIndex: startIdx + e.key + 1,
                                            colors: colors,
                                            isLast:
                                                e.key == pageItems.length - 1,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 6),
                                AppTableFooter(
                                  currentPage: currentPage,
                                  totalPages: totalPages,
                                  rowsPerPage: rowsPerPage,
                                  colors: colors,
                                  onPageChanged: (p) => c.currentPage.value = p,
                                  onRowsChanged: (r) {
                                    c.rowsPerPage.value = r;
                                    c.currentPage.value = 1;
                                  },
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(width: 16),

                          // ── RIGHT: Panel ─────────────────────────────────────────
                          // Starts at the top of the page, level with the header
                          // and summary cards.
                          SizedBox(
                            width: 272,
                            child: Column(
                              children: [
                                _TopClientsCard(colors: colors, c: c),
                                const SizedBox(height: 14),
                                _QuickStatsCard(c: c),
                                const SizedBox(height: 14),
                                _NewThisMonthCard(colors: colors, c: c),
                                const SizedBox(height: 14),
                                _QuickActionsCard(colors: colors),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Table Toolbar
// ─────────────────────────────────────────────────────────────────────────────
class _Toolbar extends StatelessWidget {
  final AppThemeColors colors;
  final ValueChanged<String> onSearch;
  const _Toolbar({required this.colors, required this.onSearch});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<ClientsController>();
    // Sits on the page background above the table card, so it carries no
    // inner card padding — it lines up with the table's left/right edges.
    return FilterBar(
      search: FilterSearchField(
        controller: c.searchCtrl,
        hint: 'Search clients...',
        width: 250,
        onChanged: onSearch,
      ),
      pills: [
        Obx(
          () => MultiSelectFilterPill(
            label: 'State',
            selected: c.stateFilters,
            items: c.stateOptions,
            onToggle: (v) {
              if (c.stateFilters.contains(v)) {
                c.stateFilters.remove(v);
              } else {
                c.stateFilters.add(v);
              }
              // Selected cities may no longer belong to the narrowed
              // state set — matches the design's cascading behaviour.
              c.cityFilters.removeWhere(
                (city) => !c.cityOptions.contains(city),
              );
              c.currentPage.value = 1;
            },
          ),
        ),
      ],
      clearAll: Obx(() {
        if (!c.hasActiveFilters) return const SizedBox.shrink();
        return ClearAllButton(onTap: c.resetFilters);
      }),
      trailing: OutlinedButton.icon(
        onPressed: () {},
        icon: Icon(
          Icons.upload_outlined,
          size: 15,
          color: colors.textSecondary,
        ),
        label: Text(
          'Export',
          style: TextStyle(
            fontSize: 13,
            fontFamily: 'Poppins',
            color: colors.textSecondary,
          ),
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          side: BorderSide(color: colors.border),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Table Column Header
// ─────────────────────────────────────────────────────────────────────────────
class _ColumnHeader extends StatelessWidget {
  final AppThemeColors colors;
  const _ColumnHeader({required this.colors});

  TextStyle get _s => TextStyle(
    fontSize: 12.5,
    fontWeight: FontWeight.w600,
    color: colors.textSecondary,
    fontFamily: 'Poppins',
    letterSpacing: 0.1,
  );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      child: Row(
        children: [
          SizedBox(
            width: _kIdxW,
            child: Text('#', style: _s),
          ),
          const SizedBox(width: _kGap),
          Expanded(
            flex: _kCodeFlex,
            child: Text('Client Code', style: _s),
          ),
          Expanded(
            flex: _kNameFlex,
            child: Text('Client Name', style: _s),
          ),
          Expanded(
            flex: _kAddrFlex,
            child: Text('Address', style: _s),
          ),
          Expanded(
            flex: _kGstFlex,
            child: Text('GSTIN/UIN', style: _s),
          ),
          Expanded(
            flex: _kRegFlex,
            child: Center(child: Text('Reg. Type', style: _s)),
          ),
          Expanded(
            flex: _kContactFlex,
            child: Text('Contact', style: _s),
          ),
          Expanded(
            flex: _kActFlex,
            child: Center(child: Text('Actions', style: _s)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Client Table Row
// ─────────────────────────────────────────────────────────────────────────────
class _ClientRow extends StatefulWidget {
  final ClientModel client;
  final int displayIndex;
  final AppThemeColors colors;
  final bool isLast;
  const _ClientRow({
    required this.client,
    required this.displayIndex,
    required this.colors,
    required this.isLast,
  });
  @override
  State<_ClientRow> createState() => _ClientRowState();
}

class _ClientRowState extends State<_ClientRow> {
  // Local, widget-scoped hover flag — kept as an Rx on the persistent State
  // object (not setState) so only the row's background repaints on hover.
  final _hovered = false.obs;

  @override
  void dispose() {
    _hovered.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cl = widget.client;
    final c = widget.colors;
    final isRegistered = cl.registrationType == 'Regular';

    return MouseRegion(
      onEnter: (_) => _hovered.value = true,
      onExit: (_) => _hovered.value = false,
      child: Obx(
        () => AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          decoration: BoxDecoration(
            color: _hovered.value ? c.rowEven : c.surface,
            border: widget.isLast
                ? null
                : Border(bottom: BorderSide(color: c.divider, width: 0.8)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // # badge
                Container(
                  width: _kIdxW,
                  height: _kIdxW,
                  decoration: BoxDecoration(
                    color: AppColors.primaryOrange.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Center(
                    child: Text(
                      '${widget.displayIndex}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryOrange,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: _kGap),

                // Client Code
                Expanded(
                  flex: _kCodeFlex,
                  child: Text(
                    cl.code,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryOrange,
                      fontFamily: 'Poppins',
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                // Client Name + initials badge
                Expanded(
                  flex: _kNameFlex,
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: cl.badgeColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            cl.initials,
                            style: TextStyle(
                              fontSize: cl.initials.length > 2 ? 9.5 : 11,
                              fontWeight: FontWeight.w700,
                              color: cl.badgeColor,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          cl.name,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w500,
                            color: c.textPrimary,
                            fontFamily: 'Poppins',
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),

                // Address
                Expanded(
                  flex: _kAddrFlex,
                  child: Text(
                    cl.address.isEmpty ? '—' : cl.address,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: c.textSecondary,
                      fontFamily: 'Poppins',
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                // GSTIN/UIN
                Expanded(
                  flex: _kGstFlex,
                  child: Text(
                    cl.gstin.isEmpty ? '—' : cl.gstin,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: c.textSecondary,
                      fontFamily: 'Poppins',
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                // Registration Type badge
                Expanded(
                  flex: _kRegFlex,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: isRegistered
                            ? const Color(0xFF22C55E).withValues(alpha: 0.10)
                            : c.comingSoonBadge,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        cl.registrationType,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: isRegistered
                              ? const Color(0xFF22C55E)
                              : c.textSecondary,
                          fontFamily: 'Poppins',
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),

                // Contact
                Expanded(
                  flex: _kContactFlex,
                  child: cl.contactPerson.isEmpty
                      ? Row(
                          children: [
                            Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color: c.textHint.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.remove_rounded,
                                size: 12,
                                color: c.textHint,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '—',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: c.textHint,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ],
                        )
                      : Row(
                          children: [
                            Container(
                              width: 20,
                              height: 20,
                              decoration: const BoxDecoration(
                                color: AppColors.primaryPurple,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  cl.contactInitials,
                                  style: const TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    cl.contactPerson,
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      color: c.textPrimary,
                                      fontFamily: 'Poppins',
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (cl.contactPhone.isNotEmpty)
                                    Text(
                                      cl.contactPhone,
                                      style: TextStyle(
                                        fontSize: 9.5,
                                        color: c.textHint,
                                        fontFamily: 'Poppins',
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                ),

                // Actions
                Expanded(
                  flex: _kActFlex,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _ActBtn(
                        icon: Icons.remove_red_eye_outlined,
                        color: const Color(0xFF4A3AFF),
                        tooltip: 'View',
                        onTap: () => Get.dialog(
                          ClientDetailsDialog(
                            client: cl,
                            onDelete: () {
                              Get.back();
                              Get.find<ClientsController>().deleteClient(cl.id);
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 5),
                      _ActBtn(
                        icon: Icons.edit_outlined,
                        color: const Color(0xFFF59E0B),
                        tooltip: 'Edit',
                        onTap: () {},
                      ),
                      const SizedBox(width: 5),
                      _ActBtn(
                        icon: Icons.delete_outline_rounded,
                        color: const Color(0xFFEF4444),
                        tooltip: 'Delete',
                        onTap: () =>
                            Get.find<ClientsController>().deleteClient(cl.id),
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

class _ActBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;
  const _ActBtn({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(7),
        child: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: colors.iconBgPurple,
            borderRadius: BorderRadius.circular(7),
          ),
          child: Icon(icon, color: color, size: 15),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Right Panel — Quick Stats Card (Avg. Order Value / Repeat Clients)
// ─────────────────────────────────────────────────────────────────────────────
class _QuickStatsCard extends StatelessWidget {
  final ClientsController c;
  const _QuickStatsCard({required this.c});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Text(
              'Quick Stats',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: colors.textPrimary,
                fontFamily: 'Poppins',
              ),
            ),
          ),
          Divider(height: 1, color: colors.divider),
          Obx(
            () => _SumRow(
              label: 'Avg. Order Value',
              value: '₹${c.avgOrderValue.value.round()}',
              colors: colors,
            ),
          ),
          _SumRow(
            label: 'Repeat Clients',
            value: '${c.repeatClientsPct.value}%',
            colors: colors,
            isLast: true,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Right Panel — New This Month Card
// ─────────────────────────────────────────────────────────────────────────────
class _NewThisMonthCard extends StatelessWidget {
  final AppThemeColors colors;
  final ClientsController c;
  const _NewThisMonthCard({required this.colors, required this.c});

  @override
  Widget build(BuildContext context) {
    final recent = c.newThisMonth;
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Text(
              'New This Month',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: colors.textPrimary,
                fontFamily: 'Poppins',
              ),
            ),
          ),
          Divider(height: 1, color: colors.divider),
          if (recent.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'No new clients yet this month.',
                style: TextStyle(
                  fontSize: 12,
                  color: colors.textHint,
                  fontFamily: 'Poppins',
                ),
              ),
            )
          else
            ...recent.asMap().entries.map((e) {
              final cl = e.value;
              return InkWell(
                onTap: () {
                  // The panel row is a lightweight summary; pull the full
                  // client out of the loaded list to show its details.
                  final full = c.clients.firstWhereOrNull((x) => x.id == cl.id);
                  if (full == null) return;
                  Get.dialog(
                    ClientDetailsDialog(
                      client: full,
                      onDelete: () {
                        Get.back();
                        c.deleteClient(full.id);
                      },
                    ),
                  );
                },
                child: Container(
                  decoration: e.key == recent.length - 1
                      ? null
                      : BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: colors.divider,
                              width: 0.5,
                            ),
                          ),
                        ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: cl.badgeColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            cl.initials,
                            style: TextStyle(
                              fontSize: cl.initials.length > 2 ? 9 : 10.5,
                              fontWeight: FontWeight.w700,
                              color: cl.badgeColor,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          cl.name,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: colors.textPrimary,
                            fontFamily: 'Poppins',
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _SumRow extends StatelessWidget {
  final String label, value;
  final AppThemeColors colors;
  final Color? valueColor;
  final bool isLast;
  const _SumRow({
    required this.label,
    required this.value,
    required this.colors,
    this.valueColor,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: isLast
          ? null
          : BoxDecoration(
              border: Border(
                bottom: BorderSide(color: colors.divider, width: 0.5),
              ),
            ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                color: colors.textSecondary,
                fontFamily: 'Poppins',
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: valueColor ?? colors.textPrimary,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Right Panel — Top States Card
// ─────────────────────────────────────────────────────────────────────────────
class _TopClientsCard extends StatelessWidget {
  final AppThemeColors colors;
  final ClientsController c;
  const _TopClientsCard({required this.colors, required this.c});

  @override
  Widget build(BuildContext context) {
    final top = c.topStates;
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Top States',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                    fontFamily: 'Poppins',
                  ),
                ),
                Text(
                  'By Client Count',
                  style: TextStyle(
                    fontSize: 11,
                    color: colors.textHint,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: colors.divider),
          ...top.asMap().entries.map((e) {
            final state = e.value.state;
            final count = e.value.count;
            return Container(
              decoration: e.key == top.length - 1
                  ? null
                  : BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: colors.divider, width: 0.5),
                      ),
                    ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.primaryOrange.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.location_on_outlined,
                      size: 16,
                      color: AppColors.primaryOrange,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      state,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: colors.textPrimary,
                        fontFamily: 'Poppins',
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '$count',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Right Panel — Quick Actions Card
// ─────────────────────────────────────────────────────────────────────────────
class _QuickActionsCard extends StatelessWidget {
  final AppThemeColors colors;
  const _QuickActionsCard({required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: colors.textPrimary,
                fontFamily: 'Poppins',
              ),
            ),
          ),
          Divider(height: 1, color: colors.divider),
          _QAction(
            icon: Icons.person_add_outlined,
            label: 'Add New Client',
            iconColor: AppColors.primaryOrange,
            colors: colors,
            onTap: () => Get.toNamed(AppRoutes.addClient),
          ),
          Divider(height: 1, color: colors.divider),
          _QAction(
            icon: Icons.receipt_long_outlined,
            label: 'Client Ledger Report',
            iconColor: const Color(0xFF4A3AFF),
            colors: colors,
          ),
          Divider(height: 1, color: colors.divider),
          _QAction(
            icon: Icons.history_rounded,
            label: 'All Transactions History',
            iconColor: const Color(0xFF2D1B8C),
            colors: colors,
            onTap: () => Get.toNamed(AppRoutes.transactions),
          ),
          Divider(height: 1, color: colors.divider),
          _QAction(
            icon: Icons.warning_amber_rounded,
            label: 'Outstanding Report',
            iconColor: const Color(0xFFF59E0B),
            colors: colors,
            isLast: true,
          ),
        ],
      ),
    );
  }
}

class _QAction extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color iconColor;
  final AppThemeColors colors;
  final bool isLast;
  final VoidCallback? onTap;
  const _QAction({
    required this.icon,
    required this.label,
    required this.iconColor,
    required this.colors,
    this.isLast = false,
    this.onTap,
  });
  @override
  State<_QAction> createState() => _QActionState();
}

class _QActionState extends State<_QAction> {
  // Local, widget-scoped hover flag — kept as an Rx on the persistent State
  // object (not setState) so only the background repaints on hover.
  final _hovered = false.obs;

  @override
  void dispose() {
    _hovered.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.colors;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => _hovered.value = true,
      onExit: (_) => _hovered.value = false,
      child: GestureDetector(
        onTap: widget.onTap,
        child: Obx(
          () => AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            decoration: BoxDecoration(
              color: _hovered.value ? c.rowEven : Colors.transparent,
              borderRadius: widget.isLast
                  ? const BorderRadius.only(
                      bottomLeft: Radius.circular(14),
                      bottomRight: Radius.circular(14),
                    )
                  : BorderRadius.zero,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Icon(widget.icon, color: widget.iconColor, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: c.textPrimary,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: c.textHint, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
