import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants.dart';
import '../models/item.dart';
import '../providers/item_provider.dart';
import '../providers/user_provider.dart';
import '../widgets/item_card.dart';
import '../widgets/empty_state.dart';
import '../widgets/loading_indicator.dart';
import '../l10n/app_localizations.dart';
import 'add_edit_item_screen.dart';
import 'item_detail_screen.dart';
import 'family_screen.dart';
import 'scan_screen.dart';
import 'settings_screen.dart';

class ItemListScreen extends StatefulWidget {
  const ItemListScreen({super.key});

  @override
  State<ItemListScreen> createState() => _ItemListScreenState();
}

class _ItemListScreenState extends State<ItemListScreen> {
  final _searchController = TextEditingController();
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ItemProvider>().loadItems();
      context.read<UserProvider>().loadUser();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgMain,
      appBar: AppBar(
        centerTitle: false,
        title: Text(context.tr('app_name'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: () async {
              final result = await Navigator.push<ScanResult>(context, MaterialPageRoute(builder: (_) => const ScanScreen()));
              if (result != null && mounted) {
                Navigator.push(context, MaterialPageRoute(
                  builder: (_) => AddEditItemScreen(
                    initialName: result.barcode,
                    barcodeResult: result.lookup,
                  ),
                ));
              }
            },
          ),
          Consumer<ItemProvider>(
            builder: (context, provider, _) => PopupMenuButton<String>(
              icon: const Icon(Icons.sort_outlined),
              tooltip: context.tr('sort'),
              onSelected: (v) {
                switch (v) {
                  case 'expiry_asc':
                    provider.setSortBy(ItemSortBy.expiryDate);
                    provider.setSortAsc(true);
                  case 'expiry_desc':
                    provider.setSortBy(ItemSortBy.expiryDate);
                    provider.setSortAsc(false);
                  case 'name_asc':
                    provider.setSortBy(ItemSortBy.name);
                    provider.setSortAsc(true);
                  case 'name_desc':
                    provider.setSortBy(ItemSortBy.name);
                    provider.setSortAsc(false);
                  case 'created_desc':
                    provider.setSortBy(ItemSortBy.createdAt);
                    provider.setSortAsc(false);
                }
              },
              itemBuilder: (ctx) => [
                CheckedPopupMenuItem(
                  value: 'expiry_asc',
                  checked: provider.sortBy == ItemSortBy.expiryDate && provider.sortAsc,
                  child: Text(ctx.tr('sort_expiry_asc')),
                ),
                CheckedPopupMenuItem(
                  value: 'expiry_desc',
                  checked: provider.sortBy == ItemSortBy.expiryDate && !provider.sortAsc,
                  child: Text(ctx.tr('sort_expiry_desc')),
                ),
                CheckedPopupMenuItem(
                  value: 'name_asc',
                  checked: provider.sortBy == ItemSortBy.name && provider.sortAsc,
                  child: Text(ctx.tr('sort_name_asc')),
                ),
                CheckedPopupMenuItem(
                  value: 'name_desc',
                  checked: provider.sortBy == ItemSortBy.name && !provider.sortAsc,
                  child: Text(ctx.tr('sort_name_desc')),
                ),
                CheckedPopupMenuItem(
                  value: 'created_desc',
                  checked: provider.sortBy == ItemSortBy.createdAt,
                  child: Text(ctx.tr('sort_created_desc')),
                ),
              ],
            ),
          ),
          IconButton(icon: const Icon(Icons.wifi_tethering), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FamilyScreen()))),
          IconButton(icon: const Icon(Icons.settings_outlined), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()))),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildSummaryCard(),
            _buildSearchBar(),
            _buildTabBar(),
            Expanded(child: _buildItemList()),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddEditItemScreen())),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Consumer<ItemProvider>(
      builder: (context, provider, _) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Card(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.cardRadius)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  _statItem(context.tr('total_count'), provider.totalCount, Theme.of(context).colorScheme.primary),
                  _statDivider(),
                  _statItem(context.tr('drug_status_valid'), provider.validCount, AppColors.statusSuccess),
                  _statDivider(),
                  _statItem(context.tr('drug_status_warning'), provider.warningCount, AppColors.statusWarning),
                  _statDivider(),
                  _statItem(context.tr('drug_status_expired'), provider.expiredCount, AppColors.statusError),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _statItem(String label, int count, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(count.toString(), style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _statDivider() {
    return Container(width: 1, height: 32, color: AppColors.divider);
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: TextField(
        controller: _searchController,
        onChanged: (v) => context.read<ItemProvider>().setSearchQuery(v),
        decoration: InputDecoration(
          hintText: context.tr('search_hint'),
          hintStyle: const TextStyle(color: AppColors.textDisabled, fontSize: 14),
          prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.textSecondary),
          suffixIcon: ListenableBuilder(
            listenable: _searchController,
            builder: (context, _) => _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: () {
                      _searchController.clear();
                      context.read<ItemProvider>().setSearchQuery('');
                    },
                  )
                : const SizedBox.shrink(),
          ),
          filled: true,
          fillColor: AppColors.bgSurface,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSizes.inputRadius), borderSide: BorderSide.none),
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Consumer<ItemProvider>(
      builder: (context, provider, _) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              _buildTab(0, context.tr('tab_all'), provider.showArchived ? _totalWithArchived(provider) : provider.activeItems.length),
              const SizedBox(width: 8),
              _buildTab(1, context.tr('tab_valid'), provider.validCount),
              const SizedBox(width: 8),
              _buildTab(2, context.tr('tab_warning'), provider.warningCount),
              const SizedBox(width: 8),
              _buildTab(3, context.tr('tab_expired'), provider.expiredCount),
              GestureDetector(
                onTap: () => context.read<ItemProvider>().toggleShowArchived(),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: provider.showArchived ? Theme.of(context).colorScheme.primary : Colors.transparent, width: 2),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.archive_outlined,
                        size: 16,
                        color: provider.showArchived ? Theme.of(context).colorScheme.primary : AppColors.textSecondary,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        context.tr('tab_archived'),
                        style: TextStyle(
                          fontSize: 11,
                          color: provider.showArchived ? Theme.of(context).colorScheme.primary : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  int _totalWithArchived(ItemProvider provider) {
    return provider.items.length;
  }

  Widget _buildTab(int index, String label, int count) {
    final selected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: selected ? Theme.of(context).colorScheme.primary : Colors.transparent, width: 2),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  color: selected ? Theme.of(context).colorScheme.primary : AppColors.textSecondary,
                ),
              ),
              Text(
                count.toString(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: selected ? Theme.of(context).colorScheme.primary : AppColors.textDisabled,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildItemList() {
    return Consumer<ItemProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) return LoadingIndicator(message: context.tr('loading'));

        var list = provider.filteredItems;
        if (_selectedTab == 1) list = list.where((d) => d.status == ItemStatus.valid).toList();
        if (_selectedTab == 2) list = list.where((d) => d.status == ItemStatus.warning).toList();
        if (_selectedTab == 3) list = list.where((d) => d.status == ItemStatus.expired).toList();

        if (list.isEmpty) {
          return RefreshIndicator(
            color: Theme.of(context).colorScheme.primary,
            onRefresh: provider.loadItems,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.5,
                child: EmptyState(
                  icon: Icons.inventory_2_outlined,
                  title: _selectedTab == 0 ? context.tr('empty_title') : context.tr('empty_title_filtered'),
                  subtitle: context.tr('empty_subtitle'),
                  actionLabel: context.tr('add_drug'),
                  onAction: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddEditItemScreen())),
                ),
              ),
            ),
          );
        }

        return RefreshIndicator(
          color: Theme.of(context).colorScheme.primary,
          onRefresh: provider.loadItems,
          child: ListView.builder(
            padding: const EdgeInsets.only(top: 4, bottom: 80),
            itemCount: list.length,
            itemBuilder: (context, index) {
              final item = list[index];
              return ItemCard(
                item: item,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ItemDetailScreen(itemId: item.id!)),
                ),
                onDelete: () => _confirmDelete(item.id!),
              );
            },
          ),
        );
      },
    );
  }

  void _confirmDelete(int id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.tr('confirm_delete_title')),
        content: Text(context.tr('confirm_delete_body')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(context.tr('cancel'))),
          TextButton(
            onPressed: () {
              context.read<ItemProvider>().deleteItem(id);
              Navigator.pop(ctx);
            },
            child: Text(context.tr('delete'), style: const TextStyle(color: AppColors.statusError)),
          ),
        ],
      ),
    );
  }
}
