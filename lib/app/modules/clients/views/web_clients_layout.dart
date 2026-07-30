import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:math' as math;
import '../controllers/clients_controller.dart';
import '../models/client_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/filter_bar.dart';
import '../../../routes/app_routes.dart';
import '../../dashboard/widgets/web_sidebar.dart';
import '../../dashboard/widgets/web_top_bar.dart';
import '../../dashboard/widgets/modified_by_cell.dart';
import '../../../shared/widgets/stat_cards.dart';
import '../../../shared/widgets/table_footer.dart';

// ── Table column constants (header + row MUST match) ──────────────────────
const double _kIdxW = 36.0; // # badge
const double _kGap = 10.0; // column gap
const int _kCodeFlex = 10; // CLT-0001
const int _kNameFlex = 22; // Client Name + badge
const int _kAddrFlex = 22; // Address
const int _kStateFlex = 10; // State
const int _kGstFlex = 14; // GSTIN/UIN
const int _kRegFlex = 10; // Registration Type badge
const int _kModFlex = 16; // Modified By
const int _kActFlex = 8; // Actions

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
                    final rowsPerPage = c.rowsPerPage.value;
                    final currentPage = c.currentPage.value;
                    final filtered = searchQuery.isEmpty
                        ? all.toList()
                        : all
                              .where(
                                (cl) =>
                                    cl.name.toLowerCase().contains(
                                      searchQuery.toLowerCase(),
                                    ) ||
                                    cl.code.toLowerCase().contains(
                                      searchQuery.toLowerCase(),
                                    ) ||
                                    cl.address.toLowerCase().contains(
                                      searchQuery.toLowerCase(),
                                    ) ||
                                    cl.gstin.toLowerCase().contains(
                                      searchQuery.toLowerCase(),
                                    ),
                              )
                              .toList();

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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── Page Header ──────────────────────────────────────────
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
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
                                    'Manage your clients and track their business relationship.',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: colors.textSecondary,
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                                ],
                              ),
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
                                  backgroundColor: AppColors.primaryOrange,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // ── Stat Cards ───────────────────────────────────────────
                          IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(
                                  child: AppStatCard(
                                    label: 'Total Clients',
                                    value: '${c.totalClients}',
                                    icon: Icons.people_outline_rounded,
                                    iconColor: AppColors.primaryOrange,
                                    trend: '+18.6%',
                                    trendUp: true,
                                    spark: const [
                                      0.3,
                                      0.5,
                                      0.4,
                                      0.6,
                                      0.55,
                                      0.7,
                                      0.65,
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: AppStatCard(
                                    label: 'Registered (GST) Clients',
                                    value: '${c.registeredClients}',
                                    icon: Icons.verified_outlined,
                                    iconColor: const Color(0xFF4A3AFF),
                                    trend: '+12.3%',
                                    trendUp: true,
                                    spark: const [
                                      0.3,
                                      0.4,
                                      0.5,
                                      0.45,
                                      0.6,
                                      0.55,
                                      0.7,
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: AppStatCard(
                                    label: 'Unregistered Clients',
                                    value: '${c.unregisteredClients}',
                                    icon: Icons.person_off_outlined,
                                    iconColor: const Color(0xFFF59E0B),
                                    trend: '-8.3%',
                                    trendUp: false,
                                    spark: const [
                                      0.7,
                                      0.65,
                                      0.55,
                                      0.5,
                                      0.4,
                                      0.45,
                                      0.35,
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: AppStatCard(
                                    label: 'States Covered',
                                    value: '${c.statesCovered}',
                                    icon: Icons.map_outlined,
                                    iconColor: const Color(0xFF22C55E),
                                    trend: '+15.2%',
                                    trendUp: true,
                                    spark: const [
                                      0.3,
                                      0.35,
                                      0.5,
                                      0.45,
                                      0.6,
                                      0.7,
                                      0.8,
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          // ── Body: Table + Right Panel ────────────────────────────
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // ── LEFT: Table Card ─────────────────────────────────
                              Expanded(
                                child: Container(
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
                                      // Toolbar
                                      _Toolbar(
                                        colors: colors,
                                        onSearch: (v) {
                                          c.searchQuery.value = v;
                                          c.currentPage.value = 1;
                                        },
                                      ),
                                      Divider(height: 1, color: colors.divider),

                                      // Column Header
                                      _ColumnHeader(colors: colors),
                                      Divider(height: 1, color: colors.divider),

                                      // Rows
                                      if (pageItems.isEmpty)
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

                                      // Footer
                                      Divider(height: 1, color: colors.divider),
                                      AppTableFooter(
                                        summaryText:
                                            'Showing ${filtered.isEmpty ? 0 : startIdx + 1} to $endIdx of ${filtered.length} clients',
                                        currentPage: currentPage,
                                        totalPages: totalPages,
                                        rowsPerPage: rowsPerPage,
                                        colors: colors,
                                        onPageChanged: (p) =>
                                            c.currentPage.value = p,
                                        onRowsChanged: (r) {
                                          c.rowsPerPage.value = r;
                                          c.currentPage.value = 1;
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              const SizedBox(width: 16),

                              // ── RIGHT: Panel ─────────────────────────────────────
                              SizedBox(
                                width: 272,
                                child: Column(
                                  children: [
                                    _ClientSummaryCard(colors: colors, c: c),
                                    const SizedBox(height: 14),
                                    _TopClientsCard(colors: colors, c: c),
                                    const SizedBox(height: 14),
                                    _QuickActionsCard(colors: colors),
                                  ],
                                ),
                              ),
                            ],
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: FilterBar(
        search: FilterSearchField(
          controller: c.searchCtrl,
          hint: 'Search clients...',
          width: 250,
          onChanged: onSearch,
        ),
        pills: [
          Obx(
            () => SingleSelectFilterPill(
              value: c.clientType.value,
              items: const [
                'Registration: All',
                'Regular',
                'Unregistered/Consumer',
              ],
              onChanged: (v) => c.clientType.value = v,
            ),
          ),
        ],
        clearAll: Obx(() {
          if (!c.hasActiveFilters) return const SizedBox.shrink();
          return ClearAllButton(onTap: c.resetFilters);
        }),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Export button
            OutlinedButton.icon(
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 9,
                ),
                side: BorderSide(color: colors.border),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Grid icon
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: colors.inputFill,
                border: Border.all(color: colors.border),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.table_chart_outlined,
                size: 17,
                color: colors.textSecondary,
              ),
            ),
          ],
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
            flex: _kStateFlex,
            child: Text('State', style: _s),
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
            flex: _kModFlex,
            child: Text('Modified By', style: _s),
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
                      color: Color(0xFF4A3AFF),
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

                // State
                Expanded(
                  flex: _kStateFlex,
                  child: Text(
                    cl.state.isEmpty ? '—' : cl.state,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: c.textSecondary,
                      fontFamily: 'Poppins',
                    ),
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

                // Modified By
                Expanded(
                  flex: _kModFlex,
                  child: Builder(
                    builder: (_) {
                      final mod = resolveModifiedBy(
                        seedId: cl.id,
                        storedName: cl.modifiedBy,
                        storedDate: cl.modifiedAt,
                      );
                      return ModifiedByCell(
                        name: mod.name,
                        date: mod.date,
                        textPrimary: c.textPrimary,
                        textHint: c.textHint,
                      );
                    },
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
                        onTap: () {},
                      ),
                      const SizedBox(width: 6),
                      _ActBtn(
                        icon: Icons.more_vert_rounded,
                        color: c.textSecondary,
                        tooltip: 'More',
                        onTap: () {},
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
// ─────────────────────────────────────────────────────────────────────────────
// Right Panel — Client Summary Card
// ─────────────────────────────────────────────────────────────────────────────
class _ClientSummaryCard extends StatelessWidget {
  final AppThemeColors colors;
  final ClientsController c;
  const _ClientSummaryCard({required this.colors, required this.c});

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
              'Client Summary',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: colors.textPrimary,
                fontFamily: 'Poppins',
              ),
            ),
          ),
          Divider(height: 1, color: colors.divider),
          _SumRow(
            label: 'Total Clients',
            value: '${c.totalClients}',
            colors: colors,
          ),
          _SumRow(
            label: 'Registered (GST)',
            value: '${c.registeredClients}',
            colors: colors,
            valueColor: const Color(0xFF22C55E),
          ),
          _SumRow(
            label: 'Unregistered',
            value: '${c.unregisteredClients}',
            colors: colors,
            valueColor: const Color(0xFFF59E0B),
          ),
          _SumRow(
            label: 'States Covered',
            value: '${c.statesCovered}',
            colors: colors,
            isLast: true,
          ),
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
            final state = e.value.key;
            final count = e.value.value;
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
  const _QAction({
    required this.icon,
    required this.label,
    required this.iconColor,
    required this.colors,
    this.isLast = false,
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
    );
  }
}
