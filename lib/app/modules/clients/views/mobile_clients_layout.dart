import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shc_stock/app/core/theme/app_colors.dart';
import 'package:shc_stock/app/routes/app_routes.dart';
import 'package:shc_stock/app/modules/dashboard/widgets/app_drawer.dart';
import 'package:shc_stock/app/modules/clients/controllers/clients_controller.dart';
import 'package:shc_stock/app/modules/clients/models/client_model.dart';
import 'package:shc_stock/app/modules/clients/views/client_details_dialog.dart';
import 'package:shc_stock/app/shared/widgets/app_loading_indicator.dart';
import 'package:shc_stock/app/shared/widgets/confirm_delete_dialog.dart';
import 'package:shc_stock/app/shared/widgets/row_action_button.dart';
import 'package:shc_stock/app/shared/widgets/stat_cards.dart';
import 'package:shc_stock/app/shared/widgets/filter_bar.dart';
import 'package:shc_stock/app/shared/widgets/mobile_filter_sheet.dart';

/// Mobile counterpart of WebClientsLayout — same data, same actions
/// (view/edit/duplicate/delete via the same ClientDetailsDialog and
/// confirmDelete used on web), laid out as a scrolling card list instead of
/// a table.
class MobileClientsLayout extends StatelessWidget {
  const MobileClientsLayout({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<ClientsController>();
    final colors = context.appColors;

    return Scaffold(
      backgroundColor: colors.background,
      drawer: const AppDrawer(activeRoute: AppRoutes.clients),
      appBar: _buildAppBar(context, c),
      body: Column(
        children: [
          _buildSearchBar(context, c),
          Expanded(child: _buildList(context, c)),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Get.toNamed(AppRoutes.addClient),
        backgroundColor: AppColors.primaryOrange,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, ClientsController c) {
    final colors = context.appColors;
    return AppBar(
      backgroundColor: colors.topBarBg,
      elevation: 0,
      leading: Builder(
        builder: (ctx) => IconButton(
          icon: Icon(Icons.menu_rounded, color: colors.textPrimary, size: 24),
          onPressed: () => Scaffold.of(ctx).openDrawer(),
        ),
      ),
      title: Text(
        'Clients',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: colors.textPrimary,
          fontFamily: 'Poppins',
        ),
      ),
      actions: [
        MobileFilterButton(filters: _buildFilters(c), onClear: c.resetFilters),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Divider(height: 1, color: colors.divider),
      ),
    );
  }

  // Same FilterSearchField the web filter row uses, and the same searchCtrl
  // so a Clear-all tap in the filter sheet also clears the visible text.
  Widget _buildSearchBar(BuildContext context, ClientsController c) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      child: FilterSearchField(
        controller: c.searchCtrl,
        hint: 'Search clients...',
        width: double.infinity,
        onChanged: (v) {
          c.searchQuery.value = v;
          c.currentPage.value = 1;
        },
      ),
    );
  }

  // Same data/controller binding as WebClientsLayout's FilterBar — State —
  // shown as a flat chip group instead of a dropdown pill (see
  // mobile_filter_sheet.dart for why).
  List<Widget> _buildFilters(ClientsController c) {
    return [
      Obx(
        () => MobileFilterChipGroup(
          label: 'State',
          selected: c.stateFilters,
          items: c.stateOptions,
          onToggle: (v) {
            if (c.stateFilters.contains(v)) {
              c.stateFilters.remove(v);
            } else {
              c.stateFilters.add(v);
            }
            c.cityFilters.removeWhere((city) => !c.cityOptions.contains(city));
            c.currentPage.value = 1;
          },
        ),
      ),
    ];
  }

  Widget _buildList(BuildContext context, ClientsController c) {
    final colors = context.appColors;
    return Obx(() {
      if (c.isLoading.value && c.clients.isEmpty) {
        return const AppLoadingIndicator(label: 'Loading clients...');
      }
      // Same filter logic as WebClientsLayout — search, state, city.
      final query = c.searchQuery.value.toLowerCase();
      final stateFilters = c.stateFilters;
      final cityFilters = c.cityFilters;
      final filtered = c.clients.where((cl) {
        if (query.isNotEmpty) {
          final matches =
              cl.name.toLowerCase().contains(query) ||
              cl.code.toLowerCase().contains(query) ||
              cl.address.toLowerCase().contains(query) ||
              cl.gstin.toLowerCase().contains(query);
          if (!matches) return false;
        }
        if (stateFilters.isNotEmpty && !stateFilters.contains(cl.state)) {
          return false;
        }
        if (cityFilters.isNotEmpty && !cityFilters.contains(cl.city)) {
          return false;
        }
        return true;
      }).toList();

      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 88),
        children: [
          // Stat cards strip — IntrinsicHeight, not a fixed SizedBox, so a
          // 2-line label ("GST Registered", "States Covered") sizes the
          // strip instead of overflowing a guessed fixed height.
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: IntrinsicHeight(
              child: Row(
                children: [
                  _MobileStatCard(
                    label: 'Total Clients',
                    value: '${c.totalClients}',
                    icon: Icons.groups_rounded,
                    color: AppColors.primaryOrange,
                  ),
                  const SizedBox(width: 10),
                  _MobileStatCard(
                    label: 'GST Registered',
                    value: '${c.registeredClients}',
                    icon: Icons.check_circle_outline_rounded,
                    color: context.appColors.accent,
                  ),
                  const SizedBox(width: 10),
                  _MobileStatCard(
                    label: 'Unregistered',
                    value: '${c.unregisteredClients}',
                    icon: Icons.block_rounded,
                    color: const Color(0xFFF59E0B),
                  ),
                  const SizedBox(width: 10),
                  _MobileStatCard(
                    label: 'States Covered',
                    value: '${c.statesCovered}',
                    icon: Icons.map_outlined,
                    color: const Color(0xFF22C55E),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Showing ${filtered.length} clients',
            style: TextStyle(
              fontSize: 12.5,
              color: colors.textSecondary,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 8),
          if (filtered.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 48),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.person_search_rounded,
                      size: 44,
                      color: colors.textHint,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'No clients found',
                      style: TextStyle(
                        color: colors.textHint,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ...filtered.map((cl) => _MobileClientCard(client: cl)),
        ],
      );
    });
  }
}

class _MobileStatCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _MobileStatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 150,
      child: AppStatCard(
        label: label,
        value: value,
        icon: icon,
        iconColor: color,
        smallValue: true,
        showCaption: false,
      ),
    );
  }
}

class _MobileClientCard extends StatelessWidget {
  final ClientModel client;
  const _MobileClientCard({required this.client});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final cl = client;
    final isRegistered = cl.registrationType == 'Regular';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: cl.badgeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Center(
                  child: Text(
                    cl.initials,
                    style: TextStyle(
                      fontSize: cl.initials.length > 2 ? 9.5 : 11.5,
                      fontWeight: FontWeight.w700,
                      color: cl.badgeColor,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cl.name,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                        fontFamily: 'Poppins',
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      cl.code,
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryOrange,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: isRegistered
                      ? const Color(0xFF22C55E).withValues(alpha: 0.10)
                      : colors.comingSoonBadge,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  cl.registrationType,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: isRegistered
                        ? const Color(0xFF22C55E)
                        : colors.textSecondary,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            ],
          ),
          if (cl.address.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              cl.address,
              style: TextStyle(
                fontSize: 12,
                color: colors.textSecondary,
                fontFamily: 'Poppins',
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (cl.gstin.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'GSTIN: ${cl.gstin}',
              style: TextStyle(
                fontSize: 11.5,
                color: colors.textHint,
                fontFamily: 'Poppins',
              ),
            ),
          ],
          const SizedBox(height: 10),
          Divider(height: 1, color: colors.divider),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              RowActionButton(
                icon: Icons.remove_red_eye_outlined,
                color: context.appColors.success,
                bg: context.appColors.success.withValues(alpha: 0.10),
                tooltip: 'View',
                onTap: () => Get.dialog(
                  ClientDetailsDialog(
                    client: cl,
                    onDelete: () {
                      Get.back();
                      confirmDelete(
                        context,
                        itemName: cl.name,
                        itemLabel: 'Client',
                        onConfirm: () =>
                            Get.find<ClientsController>().deleteClient(cl.id),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(width: 6),
              RowActionButton(
                icon: Icons.copy_outlined,
                color: const Color(0xFF3B82F6),
                bg: const Color(0xFF3B82F6).withValues(alpha: 0.10),
                tooltip: 'Duplicate',
                onTap: () => Get.toNamed(AppRoutes.addClient, arguments: cl),
              ),
              const SizedBox(width: 6),
              RowActionButton(
                icon: Icons.delete_outline_rounded,
                color: context.appColors.error,
                bg: context.appColors.tagBg,
                tooltip: 'Delete',
                onTap: () => confirmDelete(
                  context,
                  itemName: cl.name,
                  itemLabel: 'Client',
                  onConfirm: () =>
                      Get.find<ClientsController>().deleteClient(cl.id),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
