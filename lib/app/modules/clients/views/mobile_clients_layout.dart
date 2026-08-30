import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shc_stock/app/core/theme/app_colors.dart';
import 'package:shc_stock/app/routes/app_routes.dart';
import 'package:shc_stock/app/modules/dashboard/widgets/app_drawer.dart';
import 'package:shc_stock/app/modules/clients/controllers/clients_controller.dart';
import 'package:shc_stock/app/modules/clients/models/client_model.dart';
import 'package:shc_stock/app/modules/clients/views/client_actions.dart';
import 'package:shc_stock/app/shared/widgets/mobile_row_actions.dart';
import 'package:shc_stock/app/shared/widgets/app_loading_indicator.dart';
import 'package:shc_stock/app/shared/widgets/stat_cards.dart';
import 'package:shc_stock/app/shared/widgets/mobile_list_scaffold.dart';
import 'package:shc_stock/app/shared/widgets/filter_bar.dart';
import 'package:shc_stock/app/shared/widgets/mobile_filter_sheet.dart';
import 'package:shc_stock/app/shared/widgets/mobile_appbar_avatar.dart';

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
      body: _buildList(context, c),
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
      centerTitle: true,
      actions: [
        Obx(
          () => MobileFilterButton(
            filters: _buildFilters(c),
            onClear: c.resetFilters,
            activeCount: c.stateFilters.length + c.cityFilters.length,
          ),
        ),
        const MobileAppBarAvatar(),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Divider(height: 1, color: colors.divider),
      ),
    );
  }

  Widget _searchField(ClientsController c) => FilterSearchField(
    controller: c.searchCtrl,
    hint: 'Search clients...',
    width: double.infinity,
    onChanged: (v) {
      c.searchQuery.value = v;
      c.currentPage.value = 1;
    },
  );

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

  List<MobileStatCardData> _statCards(BuildContext context, ClientsController c) {
    return [
      MobileStatCardData(
        label: 'Total Clients',
        value: '${c.totalClients}',
        icon: Icons.groups_rounded,
        color: AppColors.primaryOrange,
      ),
      MobileStatCardData(
        label: 'GST Registered',
        value: '${c.registeredClients}',
        icon: Icons.check_circle_outline_rounded,
        color: context.appColors.accent,
      ),
      MobileStatCardData(
        label: 'Unregistered',
        value: '${c.unregisteredClients}',
        icon: Icons.block_rounded,
        color: const Color(0xFFF59E0B),
      ),
      MobileStatCardData(
        label: 'States Covered',
        value: '${c.statesCovered}',
        icon: Icons.map_outlined,
        color: const Color(0xFF22C55E),
      ),
    ];
  }

  Widget _buildList(BuildContext context, ClientsController c) {
    return Obx(() {
      final loading = c.isLoading.value && c.clients.isEmpty;

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

      return MobileListScaffold(
        statCards: _statCards(context, c),
        search: _searchField(c),
        countLabel: loading ? null : 'Showing ${filtered.length} clients',
        sliver: loading
            ? const SliverFillRemaining(
                hasScrollBody: false,
                child: AppLoadingIndicator(label: 'Loading clients...'),
              )
            : filtered.isEmpty
            ? const MobileListEmpty(
                icon: Icons.person_search_rounded,
                label: 'No clients found',
              )
            : SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 88),
                sliver: SliverList.builder(
                  itemCount: filtered.length,
                  itemBuilder: (_, i) =>
                      _MobileClientCard(client: filtered[i]),
                ),
              ),
      );
    });
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
          // Same four actions the web table offers.
          MobileActionRow(
            actions: [
              MobileActionButton.view(
                context: context,
                onTap: () => ClientActions.view(context, cl),
              ),
              MobileActionButton.edit(
                context: context,
                onTap: () => ClientActions.edit(cl),
              ),
              MobileActionButton.duplicate(
                onTap: () => ClientActions.duplicate(cl),
              ),
              MobileActionButton.delete(
                onTap: () => ClientActions.delete(context, cl),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
