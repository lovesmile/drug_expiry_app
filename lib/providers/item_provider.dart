import 'package:flutter/foundation.dart';
import '../models/item.dart';
import '../services/database_service.dart';

enum ItemSortBy { expiryDate, name, createdAt }

class ItemProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();
  List<Item> _items = [];
  bool _isLoading = false;
  String _searchQuery = '';
  ItemSortBy _sortBy = ItemSortBy.expiryDate;
  bool _sortAsc = true;
  bool _showArchived = false;

  List<Item> get items => _items;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  ItemSortBy get sortBy => _sortBy;
  bool get sortAsc => _sortAsc;
  bool get showArchived => _showArchived;

  int get totalCount => _items.length;
  int get validCount =>
      activeItems.where((d) => d.status == ItemStatus.valid).length;
  int get warningCount =>
      activeItems.where((d) => d.status == ItemStatus.warning).length;
  int get expiredCount =>
      activeItems.where((d) => d.status == ItemStatus.expired).length;

  List<Item> get activeItems =>
      _items.where((d) => d.usageStatus == UsageStatus.active).toList();

  List<Item> get filteredItems {
    var list = _showArchived ? _items : activeItems;
    final noDeadlineDate = DateTime(9999, 12, 31);

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list
          .where((d) =>
              d.name.toLowerCase().contains(q) ||
              (d.subtitle?.toLowerCase().contains(q) ?? false) ||
              (d.manufacturer?.toLowerCase().contains(q) ?? false))
          .toList();
    }

    // Apply sorting
    switch (_sortBy) {
      case ItemSortBy.expiryDate:
        list.sort((a, b) => _sortAsc
            ? (a.deadlineDate ?? noDeadlineDate)
                .compareTo(b.deadlineDate ?? noDeadlineDate)
            : (b.deadlineDate ?? noDeadlineDate)
                .compareTo(a.deadlineDate ?? noDeadlineDate));
        break;
      case ItemSortBy.name:
        list.sort((a, b) =>
            _sortAsc ? a.name.compareTo(b.name) : b.name.compareTo(a.name));
        break;
      case ItemSortBy.createdAt:
        list.sort((a, b) => _sortAsc
            ? a.createdAt.compareTo(b.createdAt)
            : b.createdAt.compareTo(a.createdAt));
        break;
    }

    return list;
  }

  Future<void> loadItems() async {
    _isLoading = true;
    notifyListeners();
    _items = await _db.getAllItems();
    _isLoading = false;
    notifyListeners();
  }

  Future<int> addItem(Item item) async {
    final id = await _db.insertItem(item);
    await loadItems();
    return id;
  }

  Future<void> updateItem(Item item) async {
    await _db.updateItem(item);
    await loadItems();
  }

  Future<void> deleteItem(int id) async {
    await _db.deleteItem(id);
    await loadItems();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setSortBy(ItemSortBy by) {
    _sortBy = by;
    notifyListeners();
  }

  void setSortAsc(bool asc) {
    _sortAsc = asc;
    notifyListeners();
  }

  void toggleSortOrder() {
    _sortAsc = !_sortAsc;
    notifyListeners();
  }

  void toggleShowArchived() {
    _showArchived = !_showArchived;
    notifyListeners();
  }
}
