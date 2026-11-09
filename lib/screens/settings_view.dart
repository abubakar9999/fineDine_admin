import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart' as xl;
import '../services/supabase_service.dart';
import '../utils/file_saver.dart';

class SettingsView extends StatefulWidget {
  final Map<String, dynamic> settingsData;
  final String restId;
  final Future<void> Function(Map<String, dynamic> updatedSettings) onSaveSettings;

  const SettingsView({
    super.key,
    required this.settingsData,
    required this.restId,
    required this.onSaveSettings,
  });

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Map<String, dynamic> _localSettings;
  bool _isSaving = false;

  // Search & Filter Query Controllers
  String _itemSearchQuery = '';
  String _selectedCategoryFilter = 'All';

  int _catCuisineTagSubTab = 0; // 0: Categories, 1: Cuisines, 2: Tags
  String _catCuisineTagSearch = '';

  int _tablesSubTab = 0; // 0: Tables, 1: Areas
  String _tableSearchQuery = '';

  int _stockSubTab = 0; // 0: Stock Levels, 1: Movement Logs, 2: Ingredients
  String _stockSearchQuery = '';
  String _stockStatusFilter = 'All';

  int _expenseSubTab = 0; // 0: Expense History, 1: Groups & Heads
  String _expenseSearchQuery = '';
  String _selectedExpenseGroupFilter = 'All';

  int _systemSettingsSubTab = 0; // 0: Restaurant Profile & VAT, 1: Payment Methods, 2: Print Setup
  bool _manageTable = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 8, vsync: this);
    _localSettings = Map<String, dynamic>.from(widget.settingsData);
    _normalizeSettingsKeys();
  }

  @override
  void didUpdateWidget(covariant SettingsView oldWidget) {
    super.didUpdateWidget(oldWidget);
    _localSettings = Map<String, dynamic>.from(widget.settingsData);
    _normalizeSettingsKeys();
  }

  void _normalizeSettingsKeys() {
    _localSettings = SupabaseService.sanitizeSettingsData(widget.restId, _localSettings);
    if (_localSettings.containsKey('manage_table')) {
      _manageTable = _localSettings['manage_table'] == true;
    }

    final items = _getItems();
    final categories = _getCategories();
    final cuisines = _getCuisines();
    final tags = _getTags();
    final tables = _getTables();
    final areas = _getAreas();
    final staff = _getStaff();
    final promotions = _getPromotions();
    final tills = _getTills();
    final kitchens = _getKitchens();
    final bars = _getBars();
    final paymentMethods = _getPaymentMethods();
    final customers = _getCustomers();
    final expenseGroups = _getExpenseGroups();
    final expenseHeads = _getExpenseHeads();
    final expenseItems = _getExpenseItems();
    final stocks = _getStocks();
    final stockLogs = _getStockLogs();
    final ingredients = _getIngredients();
    final recipes = _getRecipes();

    _localSettings['items'] = items;
    _localSettings['foodSettingData'] = items;
    _localSettings['foodItems'] = items;

    _localSettings['categories'] = categories;
    _localSettings['categoryData'] = categories;
    _localSettings['foodCategories'] = categories;

    _localSettings['cuisines'] = cuisines;
    _localSettings['cuisineData'] = cuisines;

    _localSettings['tags'] = tags;
    _localSettings['tagData'] = tags;

    _localSettings['tables'] = tables;
    _localSettings['tableData'] = tables;

    _localSettings['areas'] = areas;
    _localSettings['areaData'] = areas;

    _localSettings['staff'] = staff;
    _localSettings['staffData'] = staff;

    _localSettings['promotions'] = promotions;
    _localSettings['promotionData'] = promotions;

    _localSettings['tills'] = tills;
    _localSettings['tillData'] = tills;

    _localSettings['kitchens'] = kitchens;
    _localSettings['kitchenData'] = kitchens;

    _localSettings['bars'] = bars;
    _localSettings['barData'] = bars;

    _localSettings['paymentMethods'] = paymentMethods;
    _localSettings['paymentMethodSettingData'] = paymentMethods;

    _localSettings['customers'] = customers;
    _localSettings['customerData'] = customers;
    _localSettings['expenseGroups'] = expenseGroups;
    _localSettings['expenseGroupData'] = expenseGroups;
    _localSettings['expenseHeads'] = expenseHeads;
    _localSettings['expenseHeadData'] = expenseHeads;
    _localSettings['expenseItems'] = expenseItems;
    _localSettings['expenseItemData'] = expenseItems;
    _localSettings['stocks'] = stocks;
    _localSettings['stockData'] = stocks;
    _localSettings['stockLogs'] = stockLogs;
    _localSettings['stockLogData'] = stockLogs;
    _localSettings['ingredients'] = ingredients;
    _localSettings['ingredientData'] = ingredients;
    _localSettings['recipes'] = recipes;
    _localSettings['recipeData'] = recipes;
  }

  List<Map<String, dynamic>> _extractArray(List<String> keys) {
    if (_localSettings['total_data_table'] is List) {
      final List totalList = _localSettings['total_data_table'] as List;
      for (var obj in totalList) {
        if (obj is Map<String, dynamic>) {
          for (var key in keys) {
            if (obj.containsKey(key) && obj[key] is List) {
              return List<Map<String, dynamic>>.from((obj[key] as List).map((e) => Map<String, dynamic>.from(e)));
            }
          }
        }
      }
    }
    for (var key in keys) {
      if (_localSettings[key] is List) {
        return List<Map<String, dynamic>>.from((_localSettings[key] as List).map((e) => Map<String, dynamic>.from(e)));
      }
    }
    return [];
  }

  List<Map<String, dynamic>> _getItems() => _extractArray(['foodSettingData', 'items', 'foodItems']);
  List<Map<String, dynamic>> _getCategories() => _extractArray(['categoryData', 'categories', 'foodCategories']);
  List<Map<String, dynamic>> _getCuisines() => _extractArray(['cuisineData', 'cuisines']);
  List<Map<String, dynamic>> _getTags() => _extractArray(['tagData', 'tags']);
  List<Map<String, dynamic>> _getTables() => _extractArray(['tableData', 'tables', 'table_list']);
  List<Map<String, dynamic>> _getAreas() => _extractArray(['areaData', 'areas', 'area_list']);
  List<Map<String, dynamic>> _getStaff() => _extractArray(['staffData', 'staff']);
  List<Map<String, dynamic>> _getPromotions() => _extractArray(['promotionData', 'promotions']);
  List<Map<String, dynamic>> _getTills() => _extractArray(['tillData', 'tills']);
  List<Map<String, dynamic>> _getKitchens() => _extractArray(['kitchenData', 'kitchens']);
  List<Map<String, dynamic>> _getBars() => _extractArray(['barData', 'bars']);
  List<Map<String, dynamic>> _getPaymentMethods() => _extractArray(['paymentMethodSettingData', 'paymentMethods']);
  List<Map<String, dynamic>> _getCustomers() => _extractArray(['customerData', 'customers']);
  List<Map<String, dynamic>> _getExpenseGroups() => _extractArray(['expenseGroupData', 'expenseGroups']);
  List<Map<String, dynamic>> _getExpenseHeads() => _extractArray(['expenseHeadData', 'expenseHeads']);
  List<Map<String, dynamic>> _getExpenseItems() => _extractArray(['expenseItemData', 'expenseItems']);
  List<Map<String, dynamic>> _getStocks() => _extractArray(['stockData', 'stocks']);
  List<Map<String, dynamic>> _getStockLogs() => _extractArray(['stockLogData', 'stockLogs']);
  List<Map<String, dynamic>> _getIngredients() => _extractArray(['ingredientData', 'ingredients']);
  List<Map<String, dynamic>> _getRecipes() => _extractArray(['recipeData', 'recipes']);

  void _updateListForKey(List<String> keys, List<Map<String, dynamic>> newList) {
    for (var key in keys) {
      _localSettings[key] = newList;
    }

    if (_localSettings['total_data_table'] is List) {
      final List totalList = List<dynamic>.from(_localSettings['total_data_table']);
      for (int i = 0; i < totalList.length; i++) {
        final obj = totalList[i];
        if (obj is Map<String, dynamic>) {
          final Map<String, dynamic> mutableObj = Map<String, dynamic>.from(obj);
          for (var key in keys) {
            if (mutableObj.containsKey(key)) {
              mutableObj[key] = newList;
              totalList[i] = mutableObj;
              break;
            }
          }
        }
      }
      _localSettings['total_data_table'] = totalList;
    }
  }

  void _saveItems(List<Map<String, dynamic>> items) => _updateListForKey(['foodSettingData', 'items', 'foodItems'], items);
  void _saveCategories(List<Map<String, dynamic>> categories) => _updateListForKey(['categoryData', 'categories', 'foodCategories'], categories);
  void _saveCuisines(List<Map<String, dynamic>> cuisines) => _updateListForKey(['cuisineData', 'cuisines'], cuisines);
  void _saveTags(List<Map<String, dynamic>> tags) => _updateListForKey(['tagData', 'tags'], tags);
  void _saveTables(List<Map<String, dynamic>> tables) => _updateListForKey(['tableData', 'tables', 'table_list'], tables);
  void _saveAreas(List<Map<String, dynamic>> areas) => _updateListForKey(['areaData', 'areas', 'area_list'], areas);
  void _saveStaff(List<Map<String, dynamic>> staff) => _updateListForKey(['staffData', 'staff'], staff);
  void _savePromotions(List<Map<String, dynamic>> promotions) => _updateListForKey(['promotionData', 'promotions'], promotions);
  void _saveTills(List<Map<String, dynamic>> tills) => _updateListForKey(['tillData', 'tills'], tills);
  void _saveKitchens(List<Map<String, dynamic>> kitchens) => _updateListForKey(['kitchenData', 'kitchens'], kitchens);
  void _saveBars(List<Map<String, dynamic>> bars) => _updateListForKey(['barData', 'bars'], bars);
  void _saveExpenseGroups(List<Map<String, dynamic>> groups) => _updateListForKey(['expenseGroupData', 'expenseGroups'], groups);
  void _saveExpenseHeads(List<Map<String, dynamic>> heads) => _updateListForKey(['expenseHeadData', 'expenseHeads'], heads);
  void _saveExpenseItems(List<Map<String, dynamic>> items) => _updateListForKey(['expenseItemData', 'expenseItems'], items);
  void _saveStocks(List<Map<String, dynamic>> stocks) => _updateListForKey(['stockData', 'stocks'], stocks);
  void _saveStockLogs(List<Map<String, dynamic>> logs) => _updateListForKey(['stockLogData', 'stockLogs'], logs);
  void _saveIngredients(List<Map<String, dynamic>> ingredients) => _updateListForKey(['ingredientData', 'ingredients'], ingredients);
  void _savePaymentMethods(List<Map<String, dynamic>> methods) => _updateListForKey(['paymentMethodSettingData', 'paymentMethods'], methods);

  Map<String, dynamic> _getBasicSetting() {
    final list = _extractArray(['basicSettingData', 'basicSettings']);
    if (list.isNotEmpty) return Map<String, dynamic>.from(list.first);
    if (_localSettings['basicSettingData'] is Map) return Map<String, dynamic>.from(_localSettings['basicSettingData']);
    return {
      '_id': 'setting_${widget.restId}',
      'restName': '',
      'vat': '20.00',
      'currSym': '£',
      'openingHour': '10:00',
      'closingHour': '23:00',
      'addrLn1': '',
      'addrLn2': '',
      'addrLn3': '',
      'txtLn1': 'Thank you for dining with us!',
      'txtLn2': 'Please visit again.',
      'txtLn3': '',
      'setMealDuration': 0,
      'tillId': '',
      'androidId': '',
      'logo': [],
      'restId': widget.restId,
      'deliveryAndBag': {'delivery': [], 'bag': []},
    };
  }

  void _saveBasicSetting(Map<String, dynamic> setting) {
    _localSettings['basicSettingData'] = [setting];
    _localSettings['basicSettings'] = [setting];
    _updateListForKey(['basicSettingData', 'basicSettings'], [setting]);
  }

  Map<String, dynamic> _getPrintCopyData() {
    if (_localSettings['printCopyData'] is Map) {
      return Map<String, dynamic>.from(_localSettings['printCopyData']);
    }
    return {
      "kitchenPrint_all": 1,
      "kitchenPrint_new": 1,
      "kitchenPrint_barOnly": 1,
      "kitchenPrint_kitchenOnly": 1,
      "guestPrint": 1,
      "releasePrint": 1,
    };
  }

  void _savePrintCopyData(Map<String, dynamic> printData) {
    _localSettings['printCopyData'] = printData;
  }

  Future<void> _persistChanges() async {
    setState(() => _isSaving = true);
    _normalizeSettingsKeys();
    try {
      await widget.onSaveSettings(_localSettings);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Settings updated and saved successfully!'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save settings: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<bool?> _showDeleteConfirmation(String title, String content) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.red),
            const SizedBox(width: 8),
            Text(title),
          ],
        ),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentedTab({
    required IconData icon,
    required String title,
    String? count,
  }) {
    return Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 8),
          Text(title),
          if (count != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                count,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF475569),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaWidth = MediaQuery.of(context).size.width;
    final isMobile = mediaWidth < 650;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 14.0 : 26.0,
        vertical: isMobile ? 14.0 : 20.0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Settings & Menu Management',
                      style: TextStyle(
                        fontSize: isMobile ? 20 : 24,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F172A),
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Configure food menu items, portions, seating tables, staff and store parameters',
                      style: TextStyle(color: Colors.blueGrey.shade600, fontSize: isMobile ? 12 : 13),
                    ),
                  ],
                ),
              ),
              if (_isSaving) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFC7D2FE)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF4F46E5)),
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Syncing Cloud...',
                        style: TextStyle(color: Color(0xFF4F46E5), fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),

          // Modern Pill Segmented TabBar
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: const Color(0xFF4F46E5),
              unselectedLabelColor: const Color(0xFF64748B),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              indicator: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              tabs: [
                _buildSegmentedTab(
                  icon: Icons.restaurant_menu_rounded,
                  title: 'Food Items',
                  count: '${_getItems().length}',
                ),
                _buildSegmentedTab(
                  icon: Icons.category_rounded,
                  title: 'Categories & Cuisines',
                  count: '${_getCategories().length + _getCuisines().length + _getTags().length}',
                ),
                _buildSegmentedTab(
                  icon: Icons.table_restaurant_rounded,
                  title: 'Tables & Areas',
                  count: '${_getTables().length + _getAreas().length}',
                ),
                _buildSegmentedTab(
                  icon: Icons.groups_rounded,
                  title: 'Staff & Tills',
                  count: '${_getStaff().length + _getTills().length}',
                ),
                _buildSegmentedTab(
                  icon: Icons.local_offer_rounded,
                  title: 'Promotions',
                  count: '${_getPromotions().length}',
                ),
                _buildSegmentedTab(
                  icon: Icons.inventory_2_rounded,
                  title: 'Stock Levels',
                  count: '${_getStocks().length}',
                ),
                _buildSegmentedTab(
                  icon: Icons.account_balance_wallet_rounded,
                  title: 'Expenses',
                  count: '${_getExpenseItems().length}',
                ),
                _buildSegmentedTab(
                  icon: Icons.tune_rounded,
                  title: 'Restaurant Profile',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildFoodItemsTab(),
                _buildCategoriesCuisinesTagsTab(),
                _buildTablesAndAreasTab(),
                _buildStaffAndTillsTab(),
                _buildPromotionsTab(),
                _buildStockManagementTab(),
                _buildExpenseManagementTab(),
                _buildRestaurantSystemSettingsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // --- 1. FOOD ITEMS TAB (CRUD & TAGGING) ---
  // ==========================================
  Widget _buildFoodItemsTab() {
    final allItems = _getItems();
    final categories = _getCategories();

    final filteredItems = allItems.where((item) {
      final name = (item['name'] ?? '').toString().toLowerCase();

      final matchesSearch = name.contains(_itemSearchQuery.toLowerCase());
      final matchesCategory = _selectedCategoryFilter == 'All' ||
          _getItemCategoryNames(item).contains(_selectedCategoryFilter);

      return matchesSearch && matchesCategory;
    }).toList();

    final categoryNames = ['All', ...categories.map((c) => c['name']?.toString() ?? '').where((name) => name.isNotEmpty)];

    return Column(
      children: [
        // Modern Toolbar Container
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F172A).withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search food items by name...',
                    prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF94A3B8), size: 20),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 1.5),
                    ),
                  ),
                  onChanged: (val) => setState(() => _itemSearchQuery = val),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  border: Border.all(color: const Color(0xFFCBD5E1)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: categoryNames.contains(_selectedCategoryFilter) ? _selectedCategoryFilter : 'All',
                    icon: const Icon(Icons.filter_list_rounded, size: 18, color: Color(0xFF64748B)),
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF1E293B)),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedCategoryFilter = val);
                    },
                    items: categoryNames.map((c) {
                      return DropdownMenuItem<String>(
                        value: c,
                        child: Text(c == 'All' ? 'All Categories' : c),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF0F766E),
                  side: const BorderSide(color: Color(0xFF99F6E4)),
                  backgroundColor: const Color(0xFFF0FDFA),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _downloadExcelTemplate,
                icon: const Icon(Icons.download_rounded, size: 16),
                label: const Text('Template', style: TextStyle(fontSize: 13)),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF0369A1),
                  side: const BorderSide(color: Color(0xFFBAE6FD)),
                  backgroundColor: const Color(0xFFF0F9FF),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _exportFoodItemsToCsv,
                icon: const Icon(Icons.file_download_outlined, size: 16),
                label: const Text('Export CSV', style: TextStyle(fontSize: 13)),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF059669),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                onPressed: _importFoodItemsFromExcel,
                icon: const Icon(Icons.upload_file_rounded, size: 17),
                label: const Text('Import CSV', style: TextStyle(fontSize: 13)),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4F46E5),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                onPressed: () => _showFoodItemDialog(),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: Text('Create Item (${allItems.length})', style: const TextStyle(fontSize: 13)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: filteredItems.isEmpty
              ? Center(
                  child: Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.restaurant_rounded, size: 36, color: Color(0xFF94A3B8)),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _itemSearchQuery.isNotEmpty || _selectedCategoryFilter != 'All'
                              ? 'No food items match your filter.'
                              : 'No food items added yet.',
                          style: const TextStyle(color: Color(0xFF475569), fontWeight: FontWeight.w600, fontSize: 15),
                        ),
                        const SizedBox(height: 16),
                        if (_itemSearchQuery.isEmpty && _selectedCategoryFilter == 'All')
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4F46E5),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () => _showFoodItemDialog(),
                            icon: const Icon(Icons.add_rounded),
                            label: const Text('Add First Food Item'),
                          ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  itemCount: filteredItems.length,
                  itemBuilder: (context, index) {
                    final item = filteredItems[index];
                    final String id = item['_id'] ?? item['id'] ?? '';
                    final String name = item['name'] ?? 'Unnamed';

                    final List catNames = _getItemCategoryNames(item);
                    final List cuisineNames = _getItemCuisineNames(item);
                    final List tagNames = _getItemTagNames(item);
                    final List portions = item['portions'] is List ? item['portions'] : [];
                    final String readyFor = (item['ready_for'] ?? item['readyFor'] ?? 'kitchen').toString().toLowerCase();
                    final bool stickerEnabled = (item['sticker_enable'] ?? item['stickerEnable'] ?? false) == true;

                    final originalIndex = allItems.indexWhere((element) => (element['_id'] ?? element['id']) == id);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0F172A).withValues(alpha: 0.02),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFFEEF2FF), Color(0xFFE0E7FF)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: const Color(0xFFC7D2FE)),
                                  ),
                                  child: const Center(
                                    child: Icon(Icons.restaurant_rounded, color: Color(0xFF4F46E5), size: 20),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            name,
                                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Color(0xFF0F172A)),
                                          ),
                                          if (item['shortName'] != null && item['shortName'].toString().isNotEmpty) ...[
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFF1F5F9),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                '#${item['shortName']}',
                                                style: const TextStyle(color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit_rounded, color: Color(0xFF4F46E5), size: 20),
                                  tooltip: 'Edit Item',
                                  onPressed: () => _showFoodItemDialog(item: item, index: originalIndex >= 0 ? originalIndex : index),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 20),
                                  tooltip: 'Delete Item',
                                  onPressed: () async {
                                    final confirm = await _showDeleteConfirmation(
                                      'Delete Food Item',
                                      'Are you sure you want to delete "$name"?',
                                    );
                                    if (confirm == true) {
                                      final items = _getItems();
                                      if (originalIndex >= 0 && originalIndex < items.length) {
                                        items.removeAt(originalIndex);
                                      } else {
                                        items.removeWhere((i) => (i['_id'] ?? i['id']) == id);
                                      }
                                      setState(() {
                                        _saveItems(items);
                                      });
                                      _persistChanges();
                                    }
                                  },
                                ),
                              ],
                            ),
                            if (catNames.isNotEmpty || cuisineNames.isNotEmpty || tagNames.isNotEmpty || readyFor.isNotEmpty || stickerEnabled) ...[
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: [
                                  _buildStationBadge(readyFor),
                                  if (stickerEnabled)
                                    _buildBadge('Sticker Enabled', const Color(0xFF059669), icon: Icons.loyalty_rounded),
                                  ...catNames.map((c) => _buildBadge(c, const Color(0xFF4F46E5))),
                                  ...cuisineNames.map((c) => _buildBadge(c, const Color(0xFF059669))),
                                  ...tagNames.map((t) => _buildBadge(t, const Color(0xFFD97706))),
                                ],
                              ),
                            ],
                            if (portions.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 8,
                                runSpacing: 6,
                                children: portions.map<Widget>((p) {
                                  final pName = (p['portionName'] ?? 'Regular').toString();
                                  final pPrice = p['portionPriceDineIn'] ?? p['portionPrice'] ?? 0;
                                  return Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF8FAFC),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: const Color(0xFFE2E8F0)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          pName,
                                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          '৳$pPrice',
                                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildBadge(String label, Color color, {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _buildStationBadge(String readyFor) {
    Color color;
    IconData icon;
    String label;
    switch (readyFor.toLowerCase().trim()) {
      case 'bar':
        color = const Color(0xFF7C3AED);
        icon = Icons.local_bar_rounded;
        label = 'Bar Station';
        break;
      case 'hot_kitchen':
      case 'hot kitchen':
        color = const Color(0xFFDC2626);
        icon = Icons.local_fire_department_rounded;
        label = 'Hot Kitchen';
        break;
      case 'readymade':
      case 'ready made':
        color = const Color(0xFF0D9488);
        icon = Icons.takeout_dining_rounded;
        label = 'Readymade';
        break;
      case 'kitchen':
      default:
        color = const Color(0xFFEA580C);
        icon = Icons.restaurant_rounded;
        label = 'Kitchen';
        break;
    }
    return _buildBadge(label, color, icon: icon);
  }

  Widget _buildStationChip(String key, String label, IconData icon, Color color, String currentSelected, ValueChanged<String> onSelected) {
    final isSelected = currentSelected == key;
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => onSelected(key),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.12) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? color : const Color(0xFFCBD5E1),
            width: isSelected ? 1.6 : 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: isSelected ? color : const Color(0xFF64748B)),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? color : const Color(0xFF334155),
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 4),
              Icon(Icons.check_circle_rounded, size: 14, color: color),
            ],
          ],
        ),
      ),
    );
  }

  List<String> _getItemCategoryNames(Map<String, dynamic> item) {
    List<String> names = [];
    if (item['categories'] is List) {
      for (var c in item['categories']) {
        if (c is Map<String, dynamic> && c['name'] != null) {
          names.add(c['name'].toString());
        }
      }
    }
    if (names.isEmpty && item['categoryName'] != null && item['categoryName'].toString().isNotEmpty) {
      names.add(item['categoryName'].toString());
    }
    return names;
  }

  List<String> _getItemCuisineNames(Map<String, dynamic> item) {
    List<String> names = [];
    if (item['cuisines'] is List) {
      for (var c in item['cuisines']) {
        if (c is Map<String, dynamic> && c['name'] != null) {
          names.add(c['name'].toString());
        }
      }
    }
    return names;
  }

  List<String> _getItemTagNames(Map<String, dynamic> item) {
    List<String> names = [];
    if (item['tags'] is List) {
      for (var t in item['tags']) {
        if (t is Map<String, dynamic> && t['name'] != null) {
          names.add(t['name'].toString());
        }
      }
    }
    return names;
  }

  void _showFoodItemDialog({Map<String, dynamic>? item, int? index}) {
    final nameCtrl = TextEditingController(text: item?['name'] ?? '');
    final shortNameCtrl = TextEditingController(text: item?['shortName'] ?? '');
    final descCtrl = TextEditingController(text: item?['description'] ?? '');

    final categories = _getCategories();
    final cuisines = _getCuisines();
    final tags = _getTags();

    // Currently tagged items
    List<Map<String, dynamic>> selectedCategories = item?['categories'] is List
        ? List<Map<String, dynamic>>.from((item!['categories'] as List).map((c) => Map<String, dynamic>.from(c)))
        : [];
    List<Map<String, dynamic>> selectedCuisines = item?['cuisines'] is List
        ? List<Map<String, dynamic>>.from((item!['cuisines'] as List).map((c) => Map<String, dynamic>.from(c)))
        : [];
    List<Map<String, dynamic>> selectedTags = item?['tags'] is List
        ? List<Map<String, dynamic>>.from((item!['tags'] as List).map((t) => Map<String, dynamic>.from(t)))
        : [];

    List<Map<String, dynamic>> portions = item?['portions'] is List
        ? List<Map<String, dynamic>>.from((item!['portions'] as List).map((p) => Map<String, dynamic>.from(p)))
        : [];

    final portionNameCtrl = TextEditingController();
    final portionPriceCtrl = TextEditingController();

    // Days availability (CRITICAL for rest_pos so items are displayed on the order screen)
    final rawDays = item?['days'];
    Map<String, bool> days = (rawDays is Map)
        ? {
            'sat': rawDays['sat'] == true,
            'sun': rawDays['sun'] == true,
            'mon': rawDays['mon'] == true,
            'tue': rawDays['tue'] == true,
            'wed': rawDays['wed'] == true,
            'thu': rawDays['thu'] == true,
            'fri': rawDays['fri'] == true,
          }
        : {
            'sat': true,
            'sun': true,
            'mon': true,
            'tue': true,
            'wed': true,
            'thu': true,
            'fri': true,
          };

    bool vatAble = item?['vatAble'] is bool ? item!['vatAble'] : false;
    bool stickerEnable = (item?['sticker_enable'] ?? item?['stickerEnable'] ?? false) == true;
    String readyFor = (item?['ready_for'] ?? item?['readyFor'] ?? 'kitchen').toString().toLowerCase().trim();
    if (!['kitchen', 'bar', 'readymade', 'hot_kitchen'].contains(readyFor)) {
      readyFor = 'kitchen';
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(item == null ? 'Create Food Item' : 'Edit Food Item'),
          content: SizedBox(
            width: 600,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: TextField(
                          controller: nameCtrl,
                          decoration: const InputDecoration(labelText: 'Item Name', prefixIcon: Icon(Icons.fastfood), border: OutlineInputBorder()),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 1,
                        child: TextField(
                          controller: shortNameCtrl,
                          decoration: const InputDecoration(labelText: 'Code / Short', border: OutlineInputBorder()),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descCtrl,
                    decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 16),

                  // Days of the week availability
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Available Days (POS Ordering)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      TextButton(
                        onPressed: () {
                          setDialogState(() {
                            final allActive = days.values.every((v) => v);
                            days.updateAll((key, value) => !allActive);
                          });
                        },
                        child: Text(days.values.every((v) => v) ? 'Uncheck All' : 'Select All Days', style: const TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: ['sat', 'sun', 'mon', 'tue', 'wed', 'thu', 'fri'].map((dayKey) {
                      final dayLabels = {
                        'sat': 'Saturday',
                        'sun': 'Sunday',
                        'mon': 'Monday',
                        'tue': 'Tuesday',
                        'wed': 'Wednesday',
                        'thu': 'Thursday',
                        'fri': 'Friday',
                      };
                      final isSelected = days[dayKey] ?? true;
                      return FilterChip(
                        label: Text(dayLabels[dayKey] ?? dayKey),
                        selected: isSelected,
                        selectedColor: Colors.green.shade100,
                        checkmarkColor: Colors.green.shade800,
                        onSelected: (val) {
                          setDialogState(() {
                            days[dayKey] = val;
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),

                  // VAT Applicable toggle
                  SwitchListTile(
                    title: const Text('VAT / Tax Applicable', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    subtitle: const Text('Check if standard restaurant VAT applies to this item', style: TextStyle(fontSize: 12)),
                    value: vatAble,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (val) => setDialogState(() => vatAble = val),
                  ),
                  const SizedBox(height: 12),

                  // Station Pre-Printer & Sticker Setup
                  Container(
                    padding: const EdgeInsets.all(14),
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.print_rounded, size: 18, color: Color(0xFF4F46E5)),
                            SizedBox(width: 8),
                            Text(
                              'Printer Station & Sticker Setup',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        SwitchListTile(
                          title: const Text('Sticker / Label Printing', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          subtitle: const Text('Enable adhesive sticker printing for cup/box labels', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                          secondary: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: stickerEnable ? const Color(0xFFECFDF5) : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.loyalty_rounded,
                              size: 18,
                              color: stickerEnable ? const Color(0xFF059669) : const Color(0xFF94A3B8),
                            ),
                          ),
                          value: stickerEnable,
                          contentPadding: EdgeInsets.zero,
                          activeColor: const Color(0xFF059669),
                          onChanged: (val) => setDialogState(() => stickerEnable = val),
                        ),
                        const Divider(height: 20),
                        const Text(
                          'Pre-Printer Routing Station (ready_for)',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF334155)),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Select which prep station printer receives orders for this item',
                          style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _buildStationChip('kitchen', 'Kitchen', Icons.restaurant_rounded, const Color(0xFFEA580C), readyFor, (val) {
                              setDialogState(() => readyFor = val);
                            }),
                            _buildStationChip('bar', 'Bar', Icons.local_bar_rounded, const Color(0xFF7C3AED), readyFor, (val) {
                              setDialogState(() => readyFor = val);
                            }),
                            _buildStationChip('readymade', 'Readymade', Icons.takeout_dining_rounded, const Color(0xFF0D9488), readyFor, (val) {
                              setDialogState(() => readyFor = val);
                            }),
                            _buildStationChip('hot_kitchen', 'Hot Kitchen', Icons.local_fire_department_rounded, const Color(0xFFDC2626), readyFor, (val) {
                              setDialogState(() => readyFor = val);
                            }),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Tagging Section: Categories
                  const Text('Categories Tagging', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: categories.map((cat) {
                      final cId = cat['_id'] ?? cat['id'] ?? '';
                      final isSelected = selectedCategories.any((c) => (c['_id'] ?? c['id']) == cId);
                      return FilterChip(
                        label: Text(cat['name'] ?? ''),
                        selected: isSelected,
                        selectedColor: Colors.indigo.shade100,
                        onSelected: (val) {
                          setDialogState(() {
                            if (val) {
                              selectedCategories.add(cat);
                            } else {
                              selectedCategories.removeWhere((c) => (c['_id'] ?? c['id']) == cId);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),

                  // Tagging Section: Cuisines
                  const Text('Cuisines Tagging', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: cuisines.map((cuis) {
                      final cId = cuis['_id'] ?? cuis['id'] ?? '';
                      final isSelected = selectedCuisines.any((c) => (c['_id'] ?? c['id']) == cId);
                      return FilterChip(
                        label: Text(cuis['name'] ?? ''),
                        selected: isSelected,
                        selectedColor: Colors.teal.shade100,
                        onSelected: (val) {
                          setDialogState(() {
                            if (val) {
                              selectedCuisines.add(cuis);
                            } else {
                              selectedCuisines.removeWhere((c) => (c['_id'] ?? c['id']) == cId);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),

                  // Tagging Section: Tags
                  const Text('Tags Tagging', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: tags.map((t) {
                      final tId = t['_id'] ?? t['id'] ?? '';
                      final isSelected = selectedTags.any((tg) => (tg['_id'] ?? tg['id']) == tId);
                      return FilterChip(
                        label: Text(t['name'] ?? ''),
                        selected: isSelected,
                        selectedColor: Colors.deepOrange.shade100,
                        onSelected: (val) {
                          setDialogState(() {
                            if (val) {
                              selectedTags.add(t);
                            } else {
                              selectedTags.removeWhere((tg) => (tg['_id'] ?? tg['id']) == tId);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // Portions Section
                  const Text('Portions / Pricing', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const Divider(),
                  ...portions.asMap().entries.map((entry) {
                    final pIdx = entry.key;
                    final p = entry.value;
                    final priceVal = p['portionPriceDineIn'] ?? p['portionPrice'] ?? 0.0;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              initialValue: p['portionName'] ?? '',
                              decoration: const InputDecoration(labelText: 'Portion Name', isDense: true, border: InputBorder.none),
                              onChanged: (val) => p['portionName'] = val.trim(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 1,
                            child: TextFormField(
                              initialValue: priceVal.toString(),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(labelText: 'Price (৳)', isDense: true, border: InputBorder.none),
                              onChanged: (val) {
                                final parsedPrice = double.tryParse(val.trim()) ?? 0.0;
                                p['portionPriceDineIn'] = parsedPrice;
                                p['portionPriceCollection'] = parsedPrice;
                                p['portionPriceDelivery'] = parsedPrice;
                                p['portionPriceWaiting'] = parsedPrice;
                                p['portionPrice'] = parsedPrice;
                              },
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.remove_circle, color: Colors.red, size: 20),
                            onPressed: () => setDialogState(() => portions.removeAt(pIdx)),
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: portionNameCtrl,
                          decoration: const InputDecoration(labelText: 'Add Portion (e.g. Regular, Large)', isDense: true),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 1,
                        child: TextField(
                          controller: portionPriceCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(labelText: 'Price (৳)', isDense: true),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle, color: Colors.indigo, size: 28),
                        onPressed: () {
                          if (portionNameCtrl.text.trim().isNotEmpty) {
                            final pr = double.tryParse(portionPriceCtrl.text.trim()) ?? 0.0;
                            setDialogState(() {
                              portions.add({
                                '_id': 'p_${DateTime.now().millisecondsSinceEpoch}',
                                'portionName': portionNameCtrl.text.trim(),
                                'portionPriceDineIn': pr,
                                'portionPriceCollection': pr,
                                'portionPriceDelivery': pr,
                                'portionPriceWaiting': pr,
                                'portionPrice': pr,
                              });
                              portionNameCtrl.clear();
                              portionPriceCtrl.clear();
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
              onPressed: () {
                if (nameCtrl.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter food item name')),
                  );
                  return;
                }

                // If no portions were explicitly added via the list, check if user filled out portion name/price text fields
                if (portions.isEmpty) {
                  final pName = portionNameCtrl.text.trim().isNotEmpty ? portionNameCtrl.text.trim() : 'Standard';
                  final pPrice = double.tryParse(portionPriceCtrl.text.trim()) ?? 0.0;
                  portions.add({
                    '_id': 'p_${DateTime.now().millisecondsSinceEpoch}',
                    'portionName': pName,
                    'portionPriceDineIn': pPrice,
                    'portionPriceCollection': pPrice,
                    'portionPriceDelivery': pPrice,
                    'portionPriceWaiting': pPrice,
                    'portionPrice': pPrice,
                  });
                }

                final newItem = {
                  '_id': item?['_id'] ?? item?['id'] ?? 'item_${DateTime.now().millisecondsSinceEpoch}',
                  'name': nameCtrl.text.trim(),
                  'shortName': shortNameCtrl.text.trim(),
                  'description': descCtrl.text.trim(),
                  'restId': widget.restId,
                  'categories': selectedCategories,
                  'cuisines': selectedCuisines,
                  'tags': selectedTags,
                  'portions': portions,
                  'status': true,
                  'vatAble': vatAble,
                  'days': days,
                  'foodTypeList': ['DineIn', 'Collection', 'Delivery', 'Waiting'],
                  'cookingTime': (item?['cookingTime'] as num?)?.toInt() ?? 0,
                  'startTime': item?['startTime'] ?? DateTime.now().toIso8601String(),
                  'endTime': item?['endTime'] ?? DateTime.now().add(const Duration(hours: 14)).toIso8601String(),
                  'makedByKitchen': item?['makedByKitchen'] is List ? item!['makedByKitchen'] : [],
                  'makedByBar': item?['makedByBar'] is List ? item!['makedByBar'] : [],
                  'sticker_enable': stickerEnable,
                  'stickerEnable': stickerEnable,
                  'ready_for': readyFor,
                  'readyFor': readyFor,
                  'options': item?['options'] is List ? item!['options'] : [],
                  'extras': item?['extras'] is List ? item!['extras'] : [],
                  'relatedItems': item?['relatedItems'] is List ? item!['relatedItems'] : [],
                  'createdBy': (item?['createdBy'] ?? 'Admin').toString(),
                  'updatedBy': 'Admin',
                  'createdAt': item?['createdAt'] ?? DateTime.now().toIso8601String(),
                  'updatedAt': DateTime.now().toIso8601String(),
                  '__v': (item?['__v'] as num?)?.toInt() ?? 0,
                };

                final items = _getItems();
                setState(() {
                  if (index != null && index >= 0 && index < items.length) {
                    items[index] = newItem;
                  } else {
                    items.add(newItem);
                  }
                  _saveItems(items);
                });
                _persistChanges();
                Navigator.pop(context);
              },
              child: const Text('Save Food Item'),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // --- EXCEL & CSV IMPORT / EXPORT FOR FOOD ITEMS ---
  // ==========================================

  String _escapeCsvCell(dynamic value) {
    if (value == null) return '';
    final str = value.toString().trim();
    if (str.contains(',') || str.contains('"') || str.contains('\n') || str.contains('\r') || str.contains(';')) {
      return '"${str.replaceAll('"', '""')}"';
    }
    return str;
  }

  String _formatPortionsForCsv(dynamic portionsRaw) {
    if (portionsRaw is! List || portionsRaw.isEmpty) return 'Standard: 0.00';
    List<String> list = [];
    for (var p in portionsRaw) {
      if (p is Map) {
        final name = (p['portionName'] ?? 'Standard').toString().trim();
        final price = (p['portionPriceDineIn'] ?? p['portionPrice'] ?? 0.0);
        list.add('$name: $price');
      }
    }
    return list.isNotEmpty ? list.join(' | ') : 'Standard: 0.00';
  }

  String _formatOptionsForCsv(dynamic optionsRaw) {
    if (optionsRaw is! List || optionsRaw.isEmpty) return '';
    List<String> list = [];
    for (var opt in optionsRaw) {
      if (opt is Map) {
        final optName = (opt['optionName'] ?? opt['name'] ?? '').toString().trim();
        if (optName.isEmpty) continue;
        List<String> varList = [];
        if (opt['optionVariant'] is List) {
          for (var v in opt['optionVariant']) {
            if (v is Map) {
              final vName = (v['variantName'] ?? v['name'] ?? '').toString().trim();
              final num vPrice = (v['variantPrice'] ?? v['price'] ?? 0.0);
              if (vName.isNotEmpty) {
                if (vPrice > 0) {
                  varList.add('$vName (+$vPrice)');
                } else {
                  varList.add(vName);
                }
              }
            }
          }
        }
        if (varList.isNotEmpty) {
          list.add('$optName: ${varList.join(', ')}');
        } else {
          list.add(optName);
        }
      }
    }
    return list.join(' | ');
  }

  String _formatExtrasForCsv(dynamic extrasRaw) {
    if (extrasRaw is! List || extrasRaw.isEmpty) return '';
    List<String> list = [];
    for (var ext in extrasRaw) {
      if (ext is Map) {
        final eName = (ext['extraName'] ?? ext['name'] ?? '').toString().trim();
        final num ePrice = (ext['extraPrice'] ?? ext['price'] ?? 0.0);
        if (eName.isNotEmpty) {
          list.add('$eName: $ePrice');
        }
      }
    }
    return list.join(' | ');
  }

  void _exportFoodItemsToCsv() {
    try {
      final items = _getItems();
      if (items.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No food items available to export.'), backgroundColor: Colors.orange),
        );
        return;
      }

      final buffer = StringBuffer();
      // CSV Header
      buffer.writeln('name,shortName,description,category,cuisine,tags,portions,options,extras,sticker_enable,ready_for,vatAble,status');

      for (var item in items) {
        final name = item['name'] ?? '';
        final shortName = item['shortName'] ?? '';
        final desc = item['description'] ?? '';
        final cats = _getItemCategoryNames(item).join('; ');
        final cuis = _getItemCuisineNames(item).join('; ');
        final tags = _getItemTagNames(item).join('; ');
        final portions = _formatPortionsForCsv(item['portions']);
        final options = _formatOptionsForCsv(item['options']);
        final extras = _formatExtrasForCsv(item['extras']);
        final stickerEnable = (item['sticker_enable'] ?? item['stickerEnable'] ?? false) == true ? 'true' : 'false';
        final readyFor = (item['ready_for'] ?? item['readyFor'] ?? 'kitchen').toString();
        final vatAble = item['vatAble'] == true ? 'true' : 'false';
        final status = item['status'] == false ? 'false' : 'true';

        buffer.writeln([
          _escapeCsvCell(name),
          _escapeCsvCell(shortName),
          _escapeCsvCell(desc),
          _escapeCsvCell(cats),
          _escapeCsvCell(cuis),
          _escapeCsvCell(tags),
          _escapeCsvCell(portions),
          _escapeCsvCell(options),
          _escapeCsvCell(extras),
          _escapeCsvCell(stickerEnable),
          _escapeCsvCell(readyFor),
          _escapeCsvCell(vatAble),
          _escapeCsvCell(status),
        ].join(','));
      }

      final bytes = Uint8List.fromList(utf8.encode(buffer.toString()));
      final fileName = 'food_items_export_${DateTime.now().millisecondsSinceEpoch}.csv';
      _downloadViaAnchor(bytes, fileName, 'text/csv', successMsg: 'Exported ${items.length} items with sticker setup & printer routing stations!');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to export CSV: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _downloadExcelTemplate() {
    try {
      final categories = _getCategories().map((c) => (c['name'] ?? '').toString().trim()).where((s) => s.isNotEmpty).toList();
      final cuisines = _getCuisines().map((c) => (c['name'] ?? '').toString().trim()).where((s) => s.isNotEmpty).toList();
      final tags = _getTags().map((t) => (t['name'] ?? '').toString().trim()).where((s) => s.isNotEmpty).toList();

      final cat1 = categories.isNotEmpty ? categories[0] : 'Main Course';
      final cat2 = categories.length > 1 ? categories[1] : (categories.isNotEmpty ? categories[0] : 'Starters');
      final cat3 = categories.length > 2 ? categories[2] : (categories.isNotEmpty ? categories[0] : 'Drinks');

      final cuis1 = cuisines.isNotEmpty ? cuisines[0] : 'Indian';
      final cuis2 = cuisines.length > 1 ? cuisines[1] : cuis1;

      final tag1 = tags.isNotEmpty ? tags[0] : 'Halal';
      final tag2 = tags.length > 1 ? '${tags[0]}; ${tags[1]}' : 'Spicy; Chef Special';

      final buffer = StringBuffer();
      // CSV Header
      buffer.writeln('name,shortName,description,category,cuisine,tags,portions,options,extras,sticker_enable,ready_for,vatAble,status');

      // Sample Row 1: Kitchen item with sticker printing enabled
      buffer.writeln([
        _escapeCsvCell('Chicken Biryani'),
        _escapeCsvCell('CB01'),
        _escapeCsvCell('Aromatic basmati rice cooked with spiced chicken and herbs'),
        _escapeCsvCell(cat1),
        _escapeCsvCell(cuis1),
        _escapeCsvCell(tag1),
        _escapeCsvCell('Regular: 11.95 | Large: 14.50'),
        _escapeCsvCell('Spice Level: Mild, Medium, Hot | Rice Choice: Basmati, Pilau (+1.00)'),
        _escapeCsvCell('Extra Raita: 1.50 | Boiled Egg: 1.00'),
        'true',
        'kitchen',
        'false',
        'true',
      ].join(','));

      // Sample Row 2: Hot Kitchen item with sticker printing disabled
      buffer.writeln([
        _escapeCsvCell('Garlic Naan Bread'),
        _escapeCsvCell('GNB01'),
        _escapeCsvCell('Clay oven baked flatbread brushed with garlic butter and fresh coriander'),
        _escapeCsvCell(cat2),
        _escapeCsvCell(cuis2),
        _escapeCsvCell(tag2),
        _escapeCsvCell('Standard: 3.50'),
        _escapeCsvCell('Preparation: Crispy, Soft'),
        _escapeCsvCell('Extra Garlic Butter: 0.80 | Cheese Stuffed: 1.50'),
        'false',
        'hot_kitchen',
        'false',
        'true',
      ].join(','));

      // Sample Row 3: Bar drink with sticker printing enabled
      buffer.writeln([
        _escapeCsvCell('Mango Lassi Drink'),
        _escapeCsvCell('ML01'),
        _escapeCsvCell('Chilled yogurt smoothie blended with sweet mango pulp'),
        _escapeCsvCell(cat3),
        _escapeCsvCell(cuis1),
        _escapeCsvCell('Popular'),
        _escapeCsvCell('Regular: 4.25 | Large: 5.50'),
        _escapeCsvCell('Sweetness: Normal Sweet, Less Sweet'),
        _escapeCsvCell('Extra Mint: 0.50'),
        'true',
        'bar',
        'true',
        'true',
      ].join(','));

      final bytes = Uint8List.fromList(utf8.encode(buffer.toString()));
      _downloadViaAnchor(bytes, 'food_items_template.csv', 'text/csv', successMsg: 'Template downloaded with sticker_enable & ready_for printer routing stations!');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create template: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _downloadViaAnchor(Uint8List bytes, String fileName, String mimeType, {String successMsg = 'Downloaded successfully!'}) async {
    try {
      final success = await FileSaver.saveFile(
        dialogTitle: 'Save File',
        fileName: fileName,
        bytes: bytes,
        mimeType: mimeType,
      );
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(successMsg), backgroundColor: const Color(0xFF10B981)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Download failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  List<List<String>> _parseCsv(String content) {
    final List<List<String>> rows = [];
    List<String> currentRow = [];
    final StringBuffer currentCell = StringBuffer();
    bool inQuotes = false;

    // Standardize newlines
    final cleanContent = content.replaceAll('\r\n', '\n').replaceAll('\r', '\n');

    for (int i = 0; i < cleanContent.length; i++) {
      final char = cleanContent[i];

      if (char == '"') {
        if (inQuotes && i + 1 < cleanContent.length && cleanContent[i + 1] == '"') {
          currentCell.write('"');
          i++; // Skip escaped quote
        } else {
          inQuotes = !inQuotes;
        }
      } else if (char == ',' && !inQuotes) {
        currentRow.add(currentCell.toString().trim());
        currentCell.clear();
      } else if (char == '\n' && !inQuotes) {
        currentRow.add(currentCell.toString().trim());
        currentCell.clear();
        if (currentRow.any((cell) => cell.isNotEmpty)) {
          rows.add(List.from(currentRow));
        }
        currentRow.clear();
      } else {
        currentCell.write(char);
      }
    }

    if (currentCell.isNotEmpty || currentRow.isNotEmpty) {
      currentRow.add(currentCell.toString().trim());
      if (currentRow.any((cell) => cell.isNotEmpty)) {
        rows.add(currentRow);
      }
    }

    return rows;
  }

  Future<void> _importFoodItemsFromExcel() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'csv'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      if (file.bytes == null || file.bytes!.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not read file data'), backgroundColor: Colors.red),
          );
        }
        return;
      }

      // Show loading indicator
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                SizedBox(width: 12),
                Text('Parsing file...'),
              ],
            ),
            backgroundColor: Colors.indigo,
            duration: Duration(seconds: 10),
          ),
        );
      }

      await Future.delayed(const Duration(milliseconds: 100));

      final isCsv = file.name.toLowerCase().endsWith('.csv');
      List<List<String>> rows = [];

      if (isCsv) {
        final content = utf8.decode(file.bytes!);
        rows = _parseCsv(content);
      } else {
        // XLSX handling
        final List<int> bytesList = List<int>.from(file.bytes!);
        try {
          final excel = xl.Excel.decodeBytes(bytesList);
          if (excel.tables.isNotEmpty) {
            final sheetName = excel.tables.keys.first;
            final sheet = excel.tables[sheetName];
            if (sheet != null && sheet.rows.isNotEmpty) {
              for (var row in sheet.rows) {
                final rowValues = row.map((cell) => cell?.value?.toString().trim() ?? '').toList();
                rows.add(rowValues);
              }
            }
          }
        } catch (e) {
          // If XLSX decode fails, attempt CSV fallback in case user renamed .csv to .xlsx
          try {
            final content = utf8.decode(file.bytes!);
            rows = _parseCsv(content);
          } catch (_) {
            if (mounted) {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Failed to read Excel file format. Please upload a .csv file or valid .xlsx template.'),
                  backgroundColor: Colors.red,
                  duration: Duration(seconds: 5),
                ),
              );
            }
            return;
          }
        }
      }

      // Hide loading snackbar
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
      }

      if (rows.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Uploaded file is empty'), backgroundColor: Colors.red),
          );
        }
        return;
      }

      // Parse header row
      final headerRow = rows.first;
      final Map<String, int> columnMap = {};
      for (int i = 0; i < headerRow.length; i++) {
        final cellValue = headerRow[i].trim().toLowerCase();
        if (cellValue.isNotEmpty) {
          columnMap[cellValue] = i;
        }
      }

      // Resolve column indices with flexible header names
      int? nameCol = columnMap['name'];
      int? shortNameCol = columnMap['shortname'] ?? columnMap['short_name'] ?? columnMap['code'];
      int? descCol = columnMap['description'] ?? columnMap['desc'];
      int? categoryCol = columnMap['category'] ?? columnMap['categories'];
      int? cuisineCol = columnMap['cuisine'] ?? columnMap['cuisines'];
      int? tagCol = columnMap['tags'] ?? columnMap['tag'];
      int? portionsCol = columnMap['portions'] ?? columnMap['portion'] ?? columnMap['portionname'] ?? columnMap['portion_name'];
      int? priceCol = columnMap['price'] ?? columnMap['portionprice'] ?? columnMap['portion_price'];
      int? optionsCol = columnMap['options'] ?? columnMap['option'];
      int? extrasCol = columnMap['extras'] ?? columnMap['extra'];
      int? stickerCol = columnMap['sticker_enable'] ?? columnMap['stickerenable'] ?? columnMap['sticker'] ?? columnMap['is_label_enabled'] ?? columnMap['label_enable'];
      int? readyForCol = columnMap['ready_for'] ?? columnMap['readyfor'] ?? columnMap['station'] ?? columnMap['pre_printer'] ?? columnMap['printer'];
      int? vatCol = columnMap['vatable'] ?? columnMap['vat_able'] ?? columnMap['vat'];
      int? statusCol = columnMap['status'] ?? columnMap['isactive'] ?? columnMap['active'];

      if (nameCol == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('File must have a "name" column header in the first row'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 4),
            ),
          );
        }
        return;
      }

      // Parse data rows
      final categories = _getCategories();
      final cuisines = _getCuisines();
      final tags = _getTags();

      final List<Map<String, dynamic>> newCategoriesToSave = [];
      final List<Map<String, dynamic>> newCuisinesToSave = [];
      final List<Map<String, dynamic>> newTagsToSave = [];

      final List<Map<String, dynamic>> parsedItems = [];
      final List<String> warnings = [];

      for (int rowIdx = 1; rowIdx < rows.length; rowIdx++) {
        final row = rows[rowIdx];

        String getCellStr(int? colIdx) {
          if (colIdx == null || colIdx >= row.length) return '';
          return row[colIdx].trim();
        }

        final name = getCellStr(nameCol);
        if (name.isEmpty) {
          warnings.add('Row ${rowIdx + 1}: Skipped (empty name)');
          continue;
        }

        final shortName = getCellStr(shortNameCol);
        final description = getCellStr(descCol);
        final categoryRaw = getCellStr(categoryCol);
        final cuisineRaw = getCellStr(cuisineCol);
        final tagRaw = getCellStr(tagCol);
        final portionsRaw = getCellStr(portionsCol);
        final priceRaw = getCellStr(priceCol);
        final optionsRaw = getCellStr(optionsCol);
        final extrasRaw = getCellStr(extrasCol);
        final stickerRaw = getCellStr(stickerCol).toLowerCase();
        final readyForRaw = getCellStr(readyForCol).toLowerCase().replaceAll(' ', '_');
        final vatRaw = getCellStr(vatCol).toLowerCase();
        final statusRaw = getCellStr(statusCol).toLowerCase();

        // 1. Match or auto-create categories
        List<Map<String, dynamic>> matchedCategories = [];
        if (categoryRaw.isNotEmpty) {
          final catTokens = categoryRaw.split(RegExp(r'[;,|]')).map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
          for (var token in catTokens) {
            final existing = categories.firstWhere(
              (c) => (c['name'] ?? '').toString().toLowerCase() == token.toLowerCase(),
              orElse: () => {},
            );
            if (existing.isNotEmpty) {
              if (!matchedCategories.any((c) => c['_id'] == existing['_id'])) {
                matchedCategories.add(existing);
              }
            } else {
              // Auto-create category so item is never unassigned
              final newCat = {
                '_id': 'cat_${DateTime.now().millisecondsSinceEpoch}_${categories.length}',
                'name': token,
                'restId': widget.restId,
                'sl': categories.length,
                'createdBy': 'Admin (Import)',
                'updatedBy': 'Admin (Import)',
                'createdAt': DateTime.now().toIso8601String(),
                'updatedAt': DateTime.now().toIso8601String(),
                '__v': 0,
              };
              categories.add(newCat);
              newCategoriesToSave.add(newCat);
              matchedCategories.add(newCat);
            }
          }
        }

        // 2. Match or auto-create cuisines
        List<Map<String, dynamic>> matchedCuisines = [];
        if (cuisineRaw.isNotEmpty) {
          final cuisTokens = cuisineRaw.split(RegExp(r'[;,|]')).map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
          for (var token in cuisTokens) {
            final existing = cuisines.firstWhere(
              (c) => (c['name'] ?? '').toString().toLowerCase() == token.toLowerCase(),
              orElse: () => {},
            );
            if (existing.isNotEmpty) {
              if (!matchedCuisines.any((c) => c['_id'] == existing['_id'])) {
                matchedCuisines.add(existing);
              }
            } else {
              final newCuis = {
                '_id': 'cuis_${DateTime.now().millisecondsSinceEpoch}_${cuisines.length}',
                'name': token,
                'restId': widget.restId,
                'sl': cuisines.length,
                'createdBy': 'Admin (Import)',
                'updatedBy': 'Admin (Import)',
                'createdAt': DateTime.now().toIso8601String(),
                'updatedAt': DateTime.now().toIso8601String(),
                '__v': 0,
              };
              cuisines.add(newCuis);
              newCuisinesToSave.add(newCuis);
              matchedCuisines.add(newCuis);
            }
          }
        }

        // 3. Match or auto-create tags
        List<Map<String, dynamic>> matchedTags = [];
        if (tagRaw.isNotEmpty) {
          final tagTokens = tagRaw.split(RegExp(r'[;,|]')).map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
          for (var token in tagTokens) {
            final existing = tags.firstWhere(
              (t) => (t['name'] ?? '').toString().toLowerCase() == token.toLowerCase(),
              orElse: () => {},
            );
            if (existing.isNotEmpty) {
              if (!matchedTags.any((t) => t['_id'] == existing['_id'])) {
                matchedTags.add(existing);
              }
            } else {
              final newTag = {
                '_id': 'tag_${DateTime.now().millisecondsSinceEpoch}_${tags.length}',
                'name': token,
                'restId': widget.restId,
                'createdBy': 'Admin (Import)',
                'updatedBy': 'Admin (Import)',
                'createdAt': DateTime.now().toIso8601String(),
                'updatedAt': DateTime.now().toIso8601String(),
                '__v': 0,
              };
              tags.add(newTag);
              newTagsToSave.add(newTag);
              matchedTags.add(newTag);
            }
          }
        }

        // 4. Parse Portions (supports "Regular: 11.95 | Large: 14.50" or simple price)
        List<Map<String, dynamic>> portions = [];
        if (portionsRaw.isNotEmpty && portionsRaw.contains(':')) {
          final pSegments = portionsRaw.split(RegExp(r'[|;]'));
          int pIdx = 0;
          for (var seg in pSegments) {
            final parts = seg.split(':');
            if (parts.isNotEmpty) {
              final pName = parts[0].trim();
              final pPriceStr = parts.length > 1 ? parts[1].replaceAll(RegExp(r'[^\d.]'), '').trim() : '0.0';
              final pPrice = double.tryParse(pPriceStr) ?? 0.0;
              if (pName.isNotEmpty) {
                portions.add({
                  '_id': 'p_${DateTime.now().millisecondsSinceEpoch}_${rowIdx}_$pIdx',
                  'portionName': pName,
                  'portionPriceDineIn': pPrice,
                  'portionPriceCollection': pPrice,
                  'portionPriceDelivery': pPrice,
                  'portionPriceWaiting': pPrice,
                  'portionPrice': pPrice,
                });
                pIdx++;
              }
            }
          }
        }

        if (portions.isEmpty) {
          final fallbackName = portionsRaw.isNotEmpty && !portionsRaw.contains(':') ? portionsRaw : 'Standard';
          final fallbackPrice = double.tryParse(priceRaw) ?? double.tryParse(portionsRaw.replaceAll(RegExp(r'[^\d.]'), '')) ?? 0.0;
          portions.add({
            '_id': 'p_${DateTime.now().millisecondsSinceEpoch}_$rowIdx',
            'portionName': fallbackName,
            'portionPriceDineIn': fallbackPrice,
            'portionPriceCollection': fallbackPrice,
            'portionPriceDelivery': fallbackPrice,
            'portionPriceWaiting': fallbackPrice,
            'portionPrice': fallbackPrice,
          });
        }

        // 5. Parse Options & Variants (e.g. "Spice Level: Mild, Medium, Hot | Meat: Chicken, Lamb (+2.00)")
        List<Map<String, dynamic>> options = [];
        if (optionsRaw.isNotEmpty) {
          final optBlocks = optionsRaw.split(RegExp(r'[|]'));
          int optIdx = 0;
          for (var block in optBlocks) {
            final parts = block.split(':');
            if (parts.isNotEmpty) {
              final optName = parts[0].trim();
              if (optName.isEmpty) continue;

              List<Map<String, dynamic>> variants = [];
              if (parts.length > 1) {
                final vTokens = parts[1].split(RegExp(r'[,;]'));
                int vIdx = 0;
                for (var token in vTokens) {
                  final t = token.trim();
                  if (t.isEmpty) continue;

                  String vName = t;
                  double vPrice = 0.0;

                  final priceMatch = RegExp(r'\(\+?([\d.]+)\)').firstMatch(t);
                  if (priceMatch != null) {
                    vPrice = double.tryParse(priceMatch.group(1) ?? '0.0') ?? 0.0;
                    vName = t.replaceAll(RegExp(r'\(\+?[\d.]+\)'), '').trim();
                  } else if (t.contains(':')) {
                    final subParts = t.split(':');
                    vName = subParts[0].trim();
                    vPrice = double.tryParse(subParts[1].replaceAll(RegExp(r'[^\d.]'), '')) ?? 0.0;
                  }

                  variants.add({
                    '_id': 'var_${DateTime.now().millisecondsSinceEpoch}_${rowIdx}_${optIdx}_$vIdx',
                    'variantName': vName,
                    'variantPrice': vPrice,
                  });
                  vIdx++;
                }
              }

              options.add({
                '_id': 'opt_${DateTime.now().millisecondsSinceEpoch}_${rowIdx}_$optIdx',
                'optionName': optName,
                'optionVariant': variants,
              });
              optIdx++;
            }
          }
        }

        // 6. Parse Extras (e.g. "Extra Cheese: 1.50 | Garlic Sauce: 0.80")
        List<Map<String, dynamic>> extras = [];
        if (extrasRaw.isNotEmpty) {
          final extBlocks = extrasRaw.split(RegExp(r'[|;]'));
          int extIdx = 0;
          for (var block in extBlocks) {
            final b = block.trim();
            if (b.isEmpty) continue;

            String eName = b;
            double ePrice = 0.0;
            if (b.contains(':')) {
              final sub = b.split(':');
              eName = sub[0].trim();
              ePrice = double.tryParse(sub[1].replaceAll(RegExp(r'[^\d.]'), '')) ?? 0.0;
            } else {
              final pMatch = RegExp(r'\(\+?([\d.]+)\)').firstMatch(b);
              if (pMatch != null) {
                ePrice = double.tryParse(pMatch.group(1) ?? '0.0') ?? 0.0;
                eName = b.replaceAll(RegExp(r'\(\+?[\d.]+\)'), '').trim();
              }
            }

            if (eName.isNotEmpty) {
              extras.add({
                '_id': 'ext_${DateTime.now().millisecondsSinceEpoch}_${rowIdx}_$extIdx',
                'extraName': eName,
                'extraPrice': ePrice,
                'extraQuantity': 1,
              });
              extIdx++;
            }
          }
        }

        // 7. Parse VAT, Status, Sticker & Station
        final bool vatAble = vatRaw == 'true' || vatRaw == 'yes' || vatRaw == '1';
        final bool status = statusRaw.isEmpty || statusRaw == 'true' || statusRaw == 'yes' || statusRaw == 'active' || statusRaw == '1';
        final bool stickerEnable = stickerRaw == 'true' || stickerRaw == 'yes' || stickerRaw == '1';
        final String readyFor = ['bar', 'hot_kitchen', 'readymade'].contains(readyForRaw) ? readyForRaw : 'kitchen';

        final newItem = {
          '_id': 'import_${DateTime.now().millisecondsSinceEpoch}_$rowIdx',
          'name': name,
          'shortName': shortName,
          'description': description,
          'restId': widget.restId,
          'categories': matchedCategories,
          'cuisines': matchedCuisines,
          'tags': matchedTags,
          'portions': portions,
          'options': options,
          'extras': extras,
          'sticker_enable': stickerEnable,
          'stickerEnable': stickerEnable,
          'ready_for': readyFor,
          'readyFor': readyFor,
          'status': status,
          'vatAble': vatAble,
          'foodTypeList': ['DineIn', 'Collection', 'Delivery', 'Waiting'],
          'days': {'sat': true, 'sun': true, 'mon': true, 'tue': true, 'wed': true, 'thu': true, 'fri': true},
          'makedByKitchen': [],
          'makedByBar': [],
          'relatedItems': [],
          'cookingTime': 0,
          'startTime': DateTime.now().toIso8601String(),
          'endTime': DateTime.now().toIso8601String(),
          'createdAt': DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
          '__v': 0,
        };

        parsedItems.add(newItem);
      }

      if (parsedItems.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('No valid food items found in the Excel file. ${warnings.isNotEmpty ? warnings.first : ''}'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 4),
            ),
          );
        }
        return;
      }

      // Show preview dialog
      if (mounted) {
        _showImportPreviewDialog(
          parsedItems,
          warnings,
          file.name,
          newCategories: newCategoriesToSave,
          newCuisines: newCuisinesToSave,
          newTags: newTagsToSave,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        String errorMsg = e.toString();
        if (errorMsg.contains('LateInitialization')) {
          errorMsg = 'File format error. Please use the "Template" button to download a valid template, fill it in, and try again.';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error importing file: $errorMsg'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  void _showImportPreviewDialog(
    List<Map<String, dynamic>> parsedItems,
    List<String> warnings,
    String fileName, {
    List<Map<String, dynamic>>? newCategories,
    List<Map<String, dynamic>>? newCuisines,
    List<Map<String, dynamic>>? newTags,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.upload_file, color: Colors.green.shade700),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Import Preview', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(
                    '$fileName — ${parsedItems.length} item${parsedItems.length == 1 ? '' : 's'} ready to import',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.normal),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 850,
          height: 500,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Warnings section
              if (warnings.isNotEmpty) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber.shade300),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.warning_amber_rounded, size: 18, color: Colors.amber.shade800),
                          const SizedBox(width: 6),
                          Text(
                            '${warnings.length} Warning${warnings.length == 1 ? '' : 's'}',
                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber.shade900, fontSize: 13),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      ...warnings.take(3).map((w) => Padding(
                            padding: const EdgeInsets.only(left: 24, top: 2),
                            child: Text(w, style: TextStyle(fontSize: 12, color: Colors.amber.shade900)),
                          )),
                      if (warnings.length > 3)
                        Padding(
                          padding: const EdgeInsets.only(left: 24, top: 4),
                          child: Text(
                            '...and ${warnings.length - 3} more',
                            style: TextStyle(fontSize: 12, color: Colors.amber.shade700, fontStyle: FontStyle.italic),
                          ),
                        ),
                    ],
                  ),
                ),
              ],

              // Summary chips
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  _importChip(Icons.fastfood, '${parsedItems.length} Items', Colors.indigo),
                  _importChip(
                    Icons.category,
                    '${parsedItems.where((i) => (i['categories'] as List?)?.isNotEmpty == true).length} w/ Category',
                    Colors.teal,
                  ),
                  _importChip(
                    Icons.restaurant,
                    '${parsedItems.where((i) => (i['cuisines'] as List?)?.isNotEmpty == true).length} w/ Cuisine',
                    Colors.orange,
                  ),
                  _importChip(
                    Icons.local_offer,
                    '${parsedItems.where((i) => (i['tags'] as List?)?.isNotEmpty == true).length} w/ Tags',
                    Colors.purple,
                  ),
                  _importChip(
                    Icons.tune,
                    '${parsedItems.where((i) => (i['options'] as List?)?.isNotEmpty == true).length} w/ Options',
                    Colors.blue,
                  ),
                  _importChip(
                    Icons.add_circle_outline,
                    '${parsedItems.where((i) => (i['extras'] as List?)?.isNotEmpty == true).length} w/ Extras',
                    Colors.amber,
                  ),
                  if (newCategories != null && newCategories.isNotEmpty)
                    _importChip(Icons.add, '+${newCategories.length} New Categories Created', Colors.green),
                  if (newCuisines != null && newCuisines.isNotEmpty)
                    _importChip(Icons.add, '+${newCuisines.length} New Cuisines Created', Colors.green),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 4),

              // Items data table
              Expanded(
                child: SingleChildScrollView(
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(Colors.indigo.shade50),
                    columnSpacing: 12,
                    dataRowMinHeight: 40,
                    dataRowMaxHeight: 56,
                    columns: const [
                      DataColumn(label: Text('#', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Name', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Category', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Cuisine', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Portions & Prices', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Options & Extras', style: TextStyle(fontWeight: FontWeight.bold))),
                    ],
                    rows: parsedItems.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final item = entry.value;

                      final cats = (item['categories'] as List? ?? []).map((c) => (c['name'] ?? '').toString()).where((s) => s.isNotEmpty).join(', ');
                      final cuis = (item['cuisines'] as List? ?? []).map((c) => (c['name'] ?? '').toString()).where((s) => s.isNotEmpty).join(', ');
                      final portions = (item['portions'] as List? ?? []).map((p) => '${p['portionName']}: ৳${p['portionPriceDineIn'] ?? 0}').join(' | ');

                      final optionsCount = (item['options'] as List? ?? []).length;
                      final extrasCount = (item['extras'] as List? ?? []).length;
                      String optExtText = 'None';
                      if (optionsCount > 0 && extrasCount > 0) {
                        optExtText = '$optionsCount opts, $extrasCount extras';
                      } else if (optionsCount > 0) {
                        optExtText = '$optionsCount option(s)';
                      } else if (extrasCount > 0) {
                        optExtText = '$extrasCount extra(s)';
                      }

                      return DataRow(cells: [
                        DataCell(Text('${idx + 1}')),
                        DataCell(
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(item['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
                              if ((item['shortName'] ?? '').toString().isNotEmpty)
                                Text('Code: ${item['shortName']}', style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
                            ],
                          ),
                        ),
                        DataCell(Text(cats.isNotEmpty ? cats : 'Unassigned', style: TextStyle(color: cats.isNotEmpty ? Colors.teal.shade700 : Colors.grey, fontSize: 12))),
                        DataCell(Text(cuis.isNotEmpty ? cuis : 'N/A', style: TextStyle(color: Colors.orange.shade800, fontSize: 12))),
                        DataCell(Text(portions, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12))),
                        DataCell(Text(optExtText, style: TextStyle(color: optionsCount > 0 || extrasCount > 0 ? Colors.indigo.shade700 : Colors.grey, fontSize: 12))),
                      ]);
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700, foregroundColor: Colors.white),
            onPressed: () {
              final items = _getItems();
              setState(() {
                if (newCategories != null && newCategories.isNotEmpty) {
                  _saveCategories(_getCategories());
                }
                if (newCuisines != null && newCuisines.isNotEmpty) {
                  _saveCuisines(_getCuisines());
                }
                if (newTags != null && newTags.isNotEmpty) {
                  _saveTags(_getTags());
                }
                items.addAll(parsedItems);
                _saveItems(items);
              });
              _persistChanges();
              Navigator.pop(context);

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.white),
                        const SizedBox(width: 8),
                        Text('Successfully imported ${parsedItems.length} food item${parsedItems.length == 1 ? '' : 's'}!'),
                      ],
                    ),
                    backgroundColor: Colors.green.shade700,
                    duration: const Duration(seconds: 3),
                  ),
                );
              }
            },
            icon: const Icon(Icons.check),
            label: Text('Import ${parsedItems.length} Item${parsedItems.length == 1 ? '' : 's'}'),
          ),
        ],
      ),
    );
  }

  Widget _importChip(IconData icon, String label, MaterialColor color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color.shade700),
          const SizedBox(width: 5),
          Text(label, style: TextStyle(fontSize: 12, color: color.shade800, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  // ==========================================
  // --- 2. CATEGORIES, CUISINES & TAGS TAB ---
  // ==========================================
  Widget _buildCategoriesCuisinesTagsTab() {
    return Column(
      children: [
        Row(
          children: [
            ChoiceChip(
              label: Text('Categories (${_getCategories().length})'),
              selected: _catCuisineTagSubTab == 0,
              selectedColor: Colors.indigo.shade100,
              onSelected: (val) {
                if (val) setState(() => _catCuisineTagSubTab = 0);
              },
            ),
            const SizedBox(width: 12),
            ChoiceChip(
              label: Text('Cuisines (${_getCuisines().length})'),
              selected: _catCuisineTagSubTab == 1,
              selectedColor: Colors.teal.shade100,
              onSelected: (val) {
                if (val) setState(() => _catCuisineTagSubTab = 1);
              },
            ),
            const SizedBox(width: 12),
            ChoiceChip(
              label: Text('Tags (${_getTags().length})'),
              selected: _catCuisineTagSubTab == 2,
              selectedColor: Colors.deepOrange.shade100,
              onSelected: (val) {
                if (val) setState(() => _catCuisineTagSubTab = 2);
              },
            ),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: _catCuisineTagSubTab == 0
              ? _buildGenericMetadataSubView('Category', _getCategories(), _saveCategories)
              : _catCuisineTagSubTab == 1
                  ? _buildGenericMetadataSubView('Cuisine', _getCuisines(), _saveCuisines)
                  : _buildGenericMetadataSubView('Tag', _getTags(), _saveTags),
        ),
      ],
    );
  }

  Widget _buildGenericMetadataSubView(
    String typeName,
    List<Map<String, dynamic>> dataList,
    Function(List<Map<String, dynamic>>) onUpdateList,
  ) {
    final filtered = dataList.where((item) {
      final name = (item['name'] ?? '').toString().toLowerCase();
      return name.contains(_catCuisineTagSearch.toLowerCase());
    }).toList();

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search $typeName...',
                  prefixIcon: const Icon(Icons.search),
                  isDense: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onChanged: (val) => setState(() => _catCuisineTagSearch = val),
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              onPressed: () => _showMetadataDialog(typeName, dataList, onUpdateList),
              icon: const Icon(Icons.add),
              label: Text('Add $typeName'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('No $typeName added yet.', style: TextStyle(color: Colors.grey.shade600)),
                      const SizedBox(height: 16),
                      if (_catCuisineTagSearch.isEmpty)
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
                          onPressed: () => _showMetadataDialog(typeName, dataList, onUpdateList),
                          icon: const Icon(Icons.add),
                          label: Text('Add $typeName'),
                        ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final item = filtered[index];
                    final String id = item['_id'] ?? item['id'] ?? '';
                    final String name = item['name'] ?? 'Unnamed';
                    final originalIndex = dataList.indexWhere((element) => (element['_id'] ?? element['id']) == id);

                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.indigo.shade50,
                          child: Icon(Icons.label, color: Colors.indigo.shade800),
                        ),
                        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _showMetadataDialog(typeName, dataList, onUpdateList, item: item, index: originalIndex >= 0 ? originalIndex : index),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () async {
                                final confirm = await _showDeleteConfirmation('Delete $typeName', 'Are you sure you want to delete "$name"?');
                                if (confirm == true) {
                                  if (originalIndex >= 0 && originalIndex < dataList.length) {
                                    dataList.removeAt(originalIndex);
                                  } else {
                                    dataList.removeWhere((element) => (element['_id'] ?? element['id']) == id);
                                  }
                                  setState(() {
                                    onUpdateList(dataList);
                                  });
                                  _persistChanges();
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _showMetadataDialog(
    String typeName,
    List<Map<String, dynamic>> list,
    Function(List<Map<String, dynamic>>) onUpdateList, {
    Map<String, dynamic>? item,
    int? index,
  }) {
    final nameCtrl = TextEditingController(text: item?['name'] ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(item == null ? 'Add $typeName' : 'Edit $typeName'),
        content: TextField(
          controller: nameCtrl,
          decoration: InputDecoration(labelText: '$typeName Name', prefixIcon: const Icon(Icons.label)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
            onPressed: () {
              if (nameCtrl.text.trim().isNotEmpty) {
                final newItem = {
                  '_id': item?['_id'] ?? item?['id'] ?? '${typeName.toLowerCase()}_${DateTime.now().millisecondsSinceEpoch}',
                  'name': nameCtrl.text.trim(),
                  'restId': widget.restId,
                  'sl': (item?['sl'] as num?)?.toInt() ?? 0,
                  'notes': (item?['notes'] ?? '').toString(),
                  'createdBy': (item?['createdBy'] ?? 'Admin').toString(),
                  'updatedBy': 'Admin',
                  'createdAt': item?['createdAt'] ?? DateTime.now().toIso8601String(),
                  'updatedAt': DateTime.now().toIso8601String(),
                  '__v': (item?['__v'] as num?)?.toInt() ?? 0,
                };
                setState(() {
                  if (index != null && index >= 0 && index < list.length) {
                    list[index] = newItem;
                  } else {
                    list.add(newItem);
                  }
                  onUpdateList(list);
                });
                _persistChanges();
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // --- 3. TABLES & AREAS TAB (CRUD) ---
  // ==========================================
  Widget _buildTablesAndAreasTab() {
    return Column(
      children: [
        Row(
          children: [
            ChoiceChip(
              label: Text('Tables (${_getTables().length})'),
              selected: _tablesSubTab == 0,
              selectedColor: Colors.indigo.shade100,
              onSelected: (val) {
                if (val) setState(() => _tablesSubTab = 0);
              },
            ),
            const SizedBox(width: 12),
            ChoiceChip(
              label: Text('Areas (${_getAreas().length})'),
              selected: _tablesSubTab == 1,
              selectedColor: Colors.indigo.shade100,
              onSelected: (val) {
                if (val) setState(() => _tablesSubTab = 1);
              },
            ),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: _tablesSubTab == 0 ? _buildTablesSubView() : _buildAreasSubView(),
        ),
      ],
    );
  }

  Widget _buildTablesSubView() {
    final allTables = _getTables();

    final filteredTables = allTables.where((t) {
      final name = (t['name'] ?? t['tableName'] ?? '').toString().toLowerCase();
      return name.contains(_tableSearchQuery.toLowerCase());
    }).toList();

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search tables...',
                  prefixIcon: const Icon(Icons.search),
                  isDense: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onChanged: (val) => setState(() => _tableSearchQuery = val),
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              onPressed: () => _showTableDialog(),
              icon: const Icon(Icons.add),
              label: Text('Add Table (${allTables.length})'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: filteredTables.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('No tables added yet.', style: TextStyle(color: Colors.grey.shade600)),
                      const SizedBox(height: 16),
                      if (_tableSearchQuery.isEmpty)
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
                          onPressed: () => _showTableDialog(),
                          icon: const Icon(Icons.add),
                          label: const Text('Add Table'),
                        ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: filteredTables.length,
                  itemBuilder: (context, index) {
                    final t = filteredTables[index];
                    final String tId = t['_id'] ?? t['id'] ?? '';
                    final String name = t['name'] ?? t['tableName'] ?? 'Table';
                    final int capacity = (t['capacity'] as num?)?.toInt() ?? 4;
                    final originalIndex = allTables.indexWhere((tbl) => (tbl['_id'] ?? tbl['id']) == tId);

                    final String areaId = t['area'] ?? '';
                    final String createdByStaffId = t['createdBy'] ?? '';

                    final areas = _getAreas();
                    final staffList = _getStaff();

                    final areaName = areas.firstWhere((a) => (a['_id'] ?? a['id']) == areaId, orElse: () => {})['name'] ?? 'No Area';
                    final staffName = staffList.firstWhere((s) => (s['id'] ?? s['_id'] ?? s['staffId']) == createdByStaffId, orElse: () => {})['name'] ?? 'N/A';

                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.purple.shade100,
                          child: Icon(Icons.table_restaurant, color: Colors.purple.shade800),
                        ),
                        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('Capacity: $capacity guests | Area: $areaName | Created By: $staffName'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _showTableDialog(table: t, index: originalIndex >= 0 ? originalIndex : index),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () async {
                                final confirm = await _showDeleteConfirmation('Delete Table', 'Are you sure you want to delete "$name"?');
                                if (confirm == true) {
                                  final tables = _getTables();
                                  if (originalIndex >= 0 && originalIndex < tables.length) {
                                    tables.removeAt(originalIndex);
                                  } else {
                                    tables.removeWhere((tbl) => (tbl['_id'] ?? tbl['id']) == tId);
                                  }
                                  setState(() {
                                    _saveTables(tables);
                                  });
                                  _persistChanges();
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _showTableDialog({Map<String, dynamic>? table, int? index}) {
    final nameCtrl = TextEditingController(text: table?['name'] ?? table?['tableName'] ?? '');
    final capCtrl = TextEditingController(text: (table?['capacity'] ?? 4).toString());
    
    final areas = _getAreas();
    final staffList = _getStaff();

    String selectedAreaId = table?['area'] ?? (areas.isNotEmpty ? (areas.first['_id'] ?? areas.first['id'] ?? '') : '');
    String selectedCreatedBy = table?['createdBy'] ?? (staffList.isNotEmpty ? (staffList.first['id'] ?? staffList.first['_id'] ?? '') : '');

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(table == null ? 'Add Table' : 'Edit Table'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Table Name / Number', prefixIcon: Icon(Icons.table_restaurant), border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: capCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Seating Capacity', prefixIcon: Icon(Icons.event_seat), border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: areas.any((a) => (a['_id'] ?? a['id']) == selectedAreaId) ? selectedAreaId : (areas.isNotEmpty ? (areas.first['_id'] ?? areas.first['id']) : null),
                decoration: const InputDecoration(labelText: 'Dining Area', prefixIcon: Icon(Icons.place), border: OutlineInputBorder()),
                items: areas.map((a) {
                  final id = a['_id'] ?? a['id'] ?? '';
                  final name = a['name'] ?? 'Area';
                  return DropdownMenuItem<String>(value: id, child: Text(name));
                }).toList(),
                onChanged: (val) {
                  if (val != null) setDialogState(() => selectedAreaId = val);
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: staffList.any((s) => (s['id'] ?? s['_id'] ?? s['staffId']) == selectedCreatedBy) ? selectedCreatedBy : (staffList.isNotEmpty ? (staffList.first['id'] ?? staffList.first['_id']) : null),
                decoration: const InputDecoration(labelText: 'Assigned / Created By Staff', prefixIcon: Icon(Icons.person), border: OutlineInputBorder()),
                items: staffList.map((s) {
                  final id = s['id'] ?? s['_id'] ?? s['staffId'] ?? '';
                  final name = s['name'] ?? 'Staff';
                  final role = s['role'] ?? '';
                  return DropdownMenuItem<String>(value: id, child: Text('$name ($role)'));
                }).toList(),
                onChanged: (val) {
                  if (val != null) setDialogState(() => selectedCreatedBy = val);
                },
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
              onPressed: () {
                if (nameCtrl.text.trim().isNotEmpty) {
                  final newTable = {
                    '_id': table?['_id'] ?? table?['id'] ?? 't_${DateTime.now().millisecondsSinceEpoch}',
                    'name': nameCtrl.text.trim(),
                    'capacity': int.tryParse(capCtrl.text.trim()) ?? 4,
                    'status': 1,
                    'area': selectedAreaId,
                    'createdBy': selectedCreatedBy.isNotEmpty ? selectedCreatedBy : (table?['createdBy'] ?? 'Admin'),
                    'updatedBy': 'Admin',
                    'restId': widget.restId,
                    'createdAt': table?['createdAt'] ?? DateTime.now().toIso8601String(),
                    'updatedAt': DateTime.now().toIso8601String(),
                    '__v': (table?['__v'] as num?)?.toInt() ?? 0,
                  };

                  final tables = _getTables();
                  setState(() {
                    if (index != null && index >= 0 && index < tables.length) {
                      tables[index] = newTable;
                    } else {
                      tables.add(newTable);
                    }
                    _saveTables(tables);
                  });
                  _persistChanges();
                  Navigator.pop(context);
                }
              },
              child: const Text('Save Table'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAreasSubView() {
    final areas = _getAreas();

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Dining Areas (${areas.length})', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
              onPressed: () => _showAreaDialog(),
              icon: const Icon(Icons.add),
              label: const Text('Add Area'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: areas.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('No dining areas added yet.', style: TextStyle(color: Colors.grey.shade600)),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
                        onPressed: () => _showAreaDialog(),
                        icon: const Icon(Icons.add),
                        label: const Text('Add Area'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: areas.length,
                  itemBuilder: (context, index) {
                    final a = areas[index];
                    final String aName = a['name'] ?? 'Unnamed Area';

                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.teal.shade100,
                          child: Icon(Icons.place, color: Colors.teal.shade800),
                        ),
                        title: Text(aName, style: const TextStyle(fontWeight: FontWeight.bold)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _showAreaDialog(area: a, index: index),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () async {
                                final confirm = await _showDeleteConfirmation('Delete Area', 'Are you sure you want to delete "$aName"?');
                                if (confirm == true) {
                                  final areaList = _getAreas();
                                  areaList.removeAt(index);
                                  setState(() {
                                    _saveAreas(areaList);
                                  });
                                  _persistChanges();
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _showAreaDialog({Map<String, dynamic>? area, int? index}) {
    final nameCtrl = TextEditingController(text: area?['name'] ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(area == null ? 'Add Area' : 'Edit Area'),
        content: TextField(
          controller: nameCtrl,
          decoration: const InputDecoration(labelText: 'Area Name', prefixIcon: Icon(Icons.place)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
            onPressed: () {
              if (nameCtrl.text.trim().isNotEmpty) {
                final newArea = {
                  '_id': area?['_id'] ?? area?['id'] ?? 'area_${DateTime.now().millisecondsSinceEpoch}',
                  'name': nameCtrl.text.trim(),
                  'restId': widget.restId,
                  'status': area?['status'] is bool ? area!['status'] : true,
                  'createdBy': (area?['createdBy'] ?? 'Admin').toString(),
                  'updatedBy': 'Admin',
                  'createdAt': area?['createdAt'] ?? DateTime.now().toIso8601String(),
                  'updatedAt': DateTime.now().toIso8601String(),
                  '__v': (area?['__v'] as num?)?.toInt() ?? 0,
                };

                final areas = _getAreas();
                setState(() {
                  if (index != null && index >= 0 && index < areas.length) {
                    areas[index] = newArea;
                  } else {
                    areas.add(newArea);
                  }
                  _saveAreas(areas);
                });
                _persistChanges();
                Navigator.pop(context);
              }
            },
            child: const Text('Save Area'),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // --- 4. STAFF, TILLS, KITCHENS & BARS MANAGEMENT TAB ---
  // ==========================================
  int _staffSubTab = 0; // 0: Staff, 1: Tills, 2: Kitchens, 3: Bars

  Widget _buildStaffAndTillsTab() {
    return Column(
      children: [
        Row(
          children: [
            ChoiceChip(
              label: Text('Staff (${_getStaff().length})'),
              selected: _staffSubTab == 0,
              selectedColor: Colors.indigo.shade100,
              onSelected: (val) {
                if (val) setState(() => _staffSubTab = 0);
              },
            ),
            const SizedBox(width: 12),
            ChoiceChip(
              label: Text('Tills (${_getTills().length})'),
              selected: _staffSubTab == 1,
              selectedColor: Colors.amber.shade100,
              onSelected: (val) {
                if (val) setState(() => _staffSubTab = 1);
              },
            ),
            const SizedBox(width: 12),
            ChoiceChip(
              label: Text('Kitchens (${_getKitchens().length})'),
              selected: _staffSubTab == 2,
              selectedColor: Colors.orange.shade100,
              onSelected: (val) {
                if (val) setState(() => _staffSubTab = 2);
              },
            ),
            const SizedBox(width: 12),
            ChoiceChip(
              label: Text('Bars (${_getBars().length})'),
              selected: _staffSubTab == 3,
              selectedColor: Colors.purple.shade100,
              onSelected: (val) {
                if (val) setState(() => _staffSubTab = 3);
              },
            ),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: _staffSubTab == 0
              ? _buildStaffSubView()
              : _staffSubTab == 1
                  ? _buildTillsSubView()
                  : _staffSubTab == 2
                      ? _buildKitchensSubView()
                      : _buildBarsSubView(),
        ),
      ],
    );
  }

  Widget _buildStaffSubView() {
    final staffList = _getStaff();

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Staff & Employee Accounts',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.indigo),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
              icon: const Icon(Icons.person_add),
              label: const Text('Add Staff Member'),
              onPressed: () => _showStaffDialog(),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: staffList.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('No staff members registered yet.', style: TextStyle(color: Colors.grey.shade600)),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
                        onPressed: () => _showStaffDialog(),
                        icon: const Icon(Icons.add),
                        label: const Text('Add Staff Member'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: staffList.length,
                  itemBuilder: (context, index) {
                    final s = staffList[index];
                    final name = s['name'] ?? 'Unknown Staff';
                    final role = s['role'] ?? 'Staff';
                    final email = s['email'] ?? 'N/A';
                    final mobile = s['mobile'] ?? s['empContact'] ?? 'N/A';

                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: role.toString().toLowerCase() == 'owner' ? Colors.amber.shade100 : Colors.indigo.shade100,
                          child: Icon(
                            role.toString().toLowerCase() == 'owner' ? Icons.star : Icons.person,
                            color: role.toString().toLowerCase() == 'owner' ? Colors.amber.shade900 : Colors.indigo.shade900,
                          ),
                        ),
                        title: Text('$name ($role)', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('Email: $email | Mobile: $mobile'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _showStaffDialog(staff: s, index: index),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () async {
                                final confirm = await _showDeleteConfirmation('Delete Staff', 'Are you sure you want to remove "$name"?');
                                if (confirm == true) {
                                  final list = _getStaff();
                                  list.removeAt(index);
                                  setState(() {
                                    _saveStaff(list);
                                  });
                                  _persistChanges();
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // --- Tills Sub View ---
  Widget _buildTillsSubView() {
    final tills = _getTills();

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Cash Tills', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.indigo)),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
              icon: const Icon(Icons.point_of_sale),
              label: const Text('Add Till'),
              onPressed: () => _showTillDialog(),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: tills.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('No cash tills added yet.', style: TextStyle(color: Colors.grey.shade600)),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
                        onPressed: () => _showTillDialog(),
                        icon: const Icon(Icons.add),
                        label: const Text('Add Till'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: tills.length,
                  itemBuilder: (context, index) {
                    final t = tills[index];
                    final name = t['tillName'] ?? t['name'] ?? 'Till';
                    final tillId = t['tillId'] ?? '';
                    final total = t['totalAmount'] ?? 0;

                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.amber.shade100,
                          child: Icon(Icons.point_of_sale, color: Colors.amber.shade900),
                        ),
                        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('Till ID: $tillId | Total: ৳$total'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _showTillDialog(till: t, index: index),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () async {
                                final confirm = await _showDeleteConfirmation('Delete Till', 'Delete till "$name"?');
                                if (confirm == true) {
                                  final list = _getTills();
                                  list.removeAt(index);
                                  setState(() {
                                    _saveTills(list);
                                  });
                                  _persistChanges();
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _showTillDialog({Map<String, dynamic>? till, int? index}) {
    final nameCtrl = TextEditingController(text: till?['tillName'] ?? till?['name'] ?? '');
    final idCtrl = TextEditingController(text: till?['tillId'] ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(till == null ? 'Add Till' : 'Edit Till'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Till Name', prefixIcon: Icon(Icons.point_of_sale)),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: idCtrl,
              decoration: const InputDecoration(labelText: 'Till ID / Code', prefixIcon: Icon(Icons.qr_code)),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
            onPressed: () {
              if (nameCtrl.text.trim().isNotEmpty) {
                final newTill = {
                  '_id': till?['_id'] ?? till?['id'] ?? 'till_${DateTime.now().millisecondsSinceEpoch}',
                  'tillName': nameCtrl.text.trim(),
                  'tillId': idCtrl.text.trim().isNotEmpty ? idCtrl.text.trim() : 'T-${DateTime.now().millisecondsSinceEpoch % 1000}',
                  'tillStatus': till?['tillStatus'] is bool ? till!['tillStatus'] : false,
                  'openingBalance': (till?['openingBalance'] as num?)?.toDouble() ?? 0.0,
                  'depositAmount': (till?['depositAmount'] as num?)?.toDouble() ?? 0.0,
                  'withdrawAmount': (till?['withdrawAmount'] as num?)?.toDouble() ?? 0.0,
                  'totalAmount': (till?['totalAmount'] as num?)?.toDouble() ?? 0.0,
                  'restId': widget.restId,
                  'createdAt': till?['createdAt'] ?? DateTime.now().toIso8601String(),
                  'updatedAt': DateTime.now().toIso8601String(),
                  '__v': (till?['__v'] as num?)?.toInt() ?? 0,
                };
                final list = _getTills();
                setState(() {
                  if (index != null && index >= 0 && index < list.length) {
                    list[index] = newTill;
                  } else {
                    list.add(newTill);
                  }
                  _saveTills(list);
                });
                _persistChanges();
                Navigator.pop(context);
              }
            },
            child: const Text('Save Till'),
          ),
        ],
      ),
    );
  }

  // --- Kitchens Sub View ---
  Widget _buildKitchensSubView() {
    return _buildGenericMetadataSubView('Kitchen', _getKitchens(), _saveKitchens);
  }

  // --- Bars Sub View ---
  Widget _buildBarsSubView() {
    return _buildGenericMetadataSubView('Bar', _getBars(), _saveBars);
  }

  void _showStaffDialog({Map<String, dynamic>? staff, int? index}) {
    final nameCtrl = TextEditingController(text: staff?['name'] ?? '');
    final emailCtrl = TextEditingController(text: staff?['email'] ?? '');
    final mobileCtrl = TextEditingController(text: staff?['mobile'] ?? '');
    final passCtrl = TextEditingController(text: staff?['password'] ?? '');
    String selectedRole = staff?['role'] ?? 'Staff';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(staff == null ? 'Add Staff Member' : 'Edit Staff Member'),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 450,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Full Name', prefixIcon: Icon(Icons.person)),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: emailCtrl,
                    decoration: const InputDecoration(labelText: 'Email Address / Username', prefixIcon: Icon(Icons.email)),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: mobileCtrl,
                    decoration: const InputDecoration(labelText: 'Mobile Number', prefixIcon: Icon(Icons.phone)),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: passCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Password', prefixIcon: Icon(Icons.lock)),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: ['Owner', 'Manager', 'Staff', 'Waiter', 'Kitchen'].contains(selectedRole) ? selectedRole : 'Staff',
                    decoration: const InputDecoration(labelText: 'Role', prefixIcon: Icon(Icons.badge)),
                    items: ['Owner', 'Manager', 'Staff', 'Waiter', 'Kitchen']
                        .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setDialogState(() => selectedRole = val);
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
              onPressed: () {
                if (nameCtrl.text.trim().isNotEmpty) {
                  final newStaff = {
                    'isSync': true,
                    'id': staff?['id'] ?? staff?['_id'] ?? 'staff_${DateTime.now().millisecondsSinceEpoch}',
                    'staffId': (staff?['staffId'] ?? '').toString().isNotEmpty ? staff!['staffId'] : 'ST-${DateTime.now().millisecondsSinceEpoch % 1000}',
                    'name': nameCtrl.text.trim(),
                    'mobile': mobileCtrl.text.trim(),
                    'empContact': mobileCtrl.text.trim(),
                    'email': emailCtrl.text.trim(),
                    'dob': (staff?['dob'] ?? '01/01/2000').toString(),
                    'password': passCtrl.text.trim().isNotEmpty ? passCtrl.text.trim() : (staff?['password'] ?? '1234'),
                    'status': true,
                    'role': selectedRole,
                    'tokens': (staff?['tokens'] ?? '').toString(),
                    'restName': (staff?['restName'] ?? '').toString(),
                    'restAddress': (staff?['restAddress'] ?? '').toString(),
                    'restId': widget.restId,
                    'createdBy': (staff?['createdBy'] ?? 'Admin').toString(),
                    'updatedBy': 'Admin',
                    'createdAt': staff?['createdAt'] ?? DateTime.now().toIso8601String(),
                    'updatedAt': DateTime.now().toIso8601String(),
                    '__v': (staff?['__v'] as num?)?.toInt() ?? 0,
                  };

                  final staffList = _getStaff();
                  setState(() {
                    if (index != null && index >= 0 && index < staffList.length) {
                      staffList[index] = newStaff;
                    } else {
                      staffList.add(newStaff);
                    }
                    _saveStaff(staffList);
                  });
                  _persistChanges();
                  Navigator.pop(context);
                }
              },
              child: const Text('Save Staff'),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // --- 5. PROMOTIONS & OFFERS TAB ---
  // ==========================================
  Widget _buildPromotionsTab() {
    final promoList = _getPromotions();

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Promotions & Special Offers',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.indigo),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
              icon: const Icon(Icons.local_offer),
              label: const Text('Create New Promotion'),
              onPressed: () => _showPromotionDialog(),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: promoList.isEmpty
              ? const Center(child: Text('No promotions created yet.'))
              : ListView.builder(
                  itemCount: promoList.length,
                  itemBuilder: (context, index) {
                    final p = promoList[index];
                    final title = p['offerName'] ?? p['name'] ?? 'Special Offer';
                    final desc = p['description'] ?? '';
                    final triggerType = p['triggerType'] ?? 'Value';
                    final rewardType = p['rewardTypes'] ?? 'Percent';
                    final rewardValue = p['rewardValue'] ?? 0;
                    final triggerValue = p['triggerValue'] ?? 0;

                    String triggerStr = triggerType == 'Item'
                        ? 'Items: ${(p['triggerItem'] is List ? (p['triggerItem'] as List).map((i) => i['name'] ?? '').join(', ') : '')}'
                        : 'Order Value: £$triggerValue';

                    String rewardStr = rewardType == 'Item'
                        ? 'Free Item: ${(p['rewardItem'] is List ? (p['rewardItem'] as List).map((i) => i['name'] ?? '').join(', ') : '')}'
                        : '$rewardType ($rewardValue)';

                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.orange.shade100,
                          child: Icon(Icons.discount, color: Colors.orange.shade800),
                        ),
                        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('$desc\nTrigger: $triggerStr | Reward: $rewardStr'),
                        isThreeLine: true,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _showPromotionDialog(promo: p, index: index),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () async {
                                final confirm = await _showDeleteConfirmation('Delete Offer', 'Delete promotion "$title"?');
                                if (confirm == true) {
                                  final list = _getPromotions();
                                  list.removeAt(index);
                                  setState(() {
                                    _savePromotions(list);
                                  });
                                  _persistChanges();
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _showPromotionDialog({Map<String, dynamic>? promo, int? index}) {
    final titleCtrl = TextEditingController(text: promo?['offerName'] ?? promo?['name'] ?? '');
    final descCtrl = TextEditingController(text: promo?['description'] ?? '');
    final triggerCtrl = TextEditingController(text: (promo?['triggerValue'] ?? 0).toString());
    final rewardValCtrl = TextEditingController(text: (promo?['rewardValue'] ?? 0).toString());
    
    String triggerType = promo?['triggerType'] ?? 'Value'; // 'Value' or 'Item'
    String rewardType = promo?['rewardTypes'] ?? 'Percent'; // 'Percent', 'Amount', or 'Item'
    bool autoApply = promo?['autoApply'] ?? false;
    bool availableStatus = promo?['availableStatus'] ?? true;

    final allItems = _getItems();

    // Trigger items (if triggerType == 'Item')
    List<Map<String, dynamic>> selectedTriggerItems = promo?['triggerItem'] is List
        ? List<Map<String, dynamic>>.from((promo!['triggerItem'] as List).map((i) => Map<String, dynamic>.from(i)))
        : [];

    // Reward items (if rewardType == 'Item')
    List<Map<String, dynamic>> selectedRewardItems = promo?['rewardItem'] is List
        ? List<Map<String, dynamic>>.from((promo!['rewardItem'] as List).map((i) => Map<String, dynamic>.from(i)))
        : [];

    // Order types applied on
    List<String> selectedOrderTypes = promo?['appliedOnOrderType'] is List
        ? List<String>.from((promo!['appliedOnOrderType'] as List).map((e) => e.toString()))
        : ['DineIn', 'Collection', 'Delivery'];

    Map<String, bool> promoDays = promo?['promoDays'] is Map
        ? Map<String, bool>.from(promo!['promoDays'])
        : {'mon': true, 'tue': true, 'wed': true, 'thu': true, 'fri': true, 'sat': true, 'sun': true};

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(promo == null ? 'Add Promotion' : 'Edit Promotion'),
          content: SizedBox(
            width: 600,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: titleCtrl,
                          decoration: const InputDecoration(labelText: 'Offer Name', prefixIcon: Icon(Icons.local_offer), border: OutlineInputBorder()),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 1,
                        child: SwitchListTile(
                          title: const Text('Auto Apply', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                          value: autoApply,
                          onChanged: (val) => setDialogState(() => autoApply = val),
                          dense: true,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descCtrl,
                    decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 16),

                  // --- TRIGGER SECTION ---
                  const Text('1. Offer Trigger Condition', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.indigo)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: RadioListTile<String>(
                          title: const Text('Minimum Order Value (£)'),
                          value: 'Value',
                          groupValue: triggerType,
                          onChanged: (val) {
                            if (val != null) setDialogState(() => triggerType = val);
                          },
                          dense: true,
                        ),
                      ),
                      Expanded(
                        child: RadioListTile<String>(
                          title: const Text('Specific Food Item(s)'),
                          value: 'Item',
                          groupValue: triggerType,
                          onChanged: (val) {
                            if (val != null) setDialogState(() => triggerType = val);
                          },
                          dense: true,
                        ),
                      ),
                    ],
                  ),
                  if (triggerType == 'Value') ...[
                    TextField(
                      controller: triggerCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Trigger Min Order Amount (£)', prefixIcon: Icon(Icons.shopping_cart), border: OutlineInputBorder()),
                    ),
                  ] else ...[
                    const Text('Select Required Trigger Item(s):', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: allItems.map((item) {
                        final itemId = item['_id'] ?? item['id'] ?? '';
                        final itemName = item['name'] ?? 'Unnamed';
                        final isSel = selectedTriggerItems.any((i) => (i['_id'] ?? i['id']) == itemId);

                        return FilterChip(
                          label: Text(itemName),
                          selected: isSel,
                          selectedColor: Colors.indigo.shade100,
                          onSelected: (val) {
                            setDialogState(() {
                              if (val) {
                                selectedTriggerItems.add({'_id': itemId, 'name': itemName});
                              } else {
                                selectedTriggerItems.removeWhere((i) => (i['_id'] ?? i['id']) == itemId);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ],

                  const SizedBox(height: 16),
                  const Divider(),

                  // --- REWARD SECTION ---
                  const Text('2. Reward Offer Type', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.indigo)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    initialValue: ['Percent', 'Amount', 'Item'].contains(rewardType) ? rewardType : 'Percent',
                    decoration: const InputDecoration(labelText: 'Reward Type', prefixIcon: Icon(Icons.card_giftcard), border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem(value: 'Percent', child: Text('Discount Percentage (%)')),
                      DropdownMenuItem(value: 'Amount', child: Text('Discount Amount (£)')),
                      DropdownMenuItem(value: 'Item', child: Text('Free Reward Food Item(s)')),
                    ],
                    onChanged: (val) {
                      if (val != null) setDialogState(() => rewardType = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  if (rewardType == 'Item') ...[
                    const Text('Select Reward Food Item(s) Given Free:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: allItems.map((item) {
                        final itemId = item['_id'] ?? item['id'] ?? '';
                        final itemName = item['name'] ?? 'Unnamed';
                        final isSel = selectedRewardItems.any((i) => (i['_id'] ?? i['id']) == itemId);

                        return FilterChip(
                          label: Text(itemName),
                          selected: isSel,
                          selectedColor: Colors.orange.shade100,
                          onSelected: (val) {
                            setDialogState(() {
                              if (val) {
                                selectedRewardItems.add({'_id': itemId, 'name': itemName});
                              } else {
                                selectedRewardItems.removeWhere((i) => (i['_id'] ?? i['id']) == itemId);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ] else ...[
                    TextField(
                      controller: rewardValCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: rewardType == 'Percent' ? 'Discount Percentage (e.g. 10 for 10%)' : 'Discount Amount (e.g. 5.00 for £5)',
                        prefixIcon: const Icon(Icons.attach_money),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),
                  const Divider(),

                  // --- ORDER TYPES & DAYS SECTION ---
                  const Text('3. Applicable Order Types & Days', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.indigo)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    children: ['DineIn', 'Collection', 'Delivery', 'Waiting'].map((orderType) {
                      final isSel = selectedOrderTypes.contains(orderType);
                      return FilterChip(
                        label: Text(orderType),
                        selected: isSel,
                        selectedColor: Colors.teal.shade100,
                        onSelected: (val) {
                          setDialogState(() {
                            if (val) {
                              selectedOrderTypes.add(orderType);
                            } else {
                              selectedOrderTypes.remove(orderType);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 10),
                  const Text('Available Days:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  Wrap(
                    spacing: 6,
                    children: ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'].map((day) {
                      final isSel = promoDays[day] ?? true;
                      return FilterChip(
                        label: Text(day.toUpperCase()),
                        selected: isSel,
                        onSelected: (val) {
                          setDialogState(() {
                            promoDays[day] = val;
                          });
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
              onPressed: () {
                if (titleCtrl.text.trim().isNotEmpty) {
                  final newPromo = {
                    '_id': promo?['_id'] ?? 'promo_${DateTime.now().millisecondsSinceEpoch}',
                    'offerName': titleCtrl.text.trim(),
                    'description': descCtrl.text.trim(),
                    'triggerType': triggerType,
                    'triggerValue': double.tryParse(triggerCtrl.text.trim()) ?? 0,
                    'triggerItem': selectedTriggerItems,
                    'rewardTypes': rewardType,
                    'rewardValue': double.tryParse(rewardValCtrl.text.trim()) ?? 0,
                    'rewardItem': selectedRewardItems,
                    'excludedItem': promo?['excludedItem'] is List ? promo!['excludedItem'] : [],
                    'appliedOnOrderType': selectedOrderTypes,
                    'promoDays': promoDays,
                    'exclusive': promo?['exclusive'] ?? false,
                    'autoApply': autoApply,
                    'availableStatus': availableStatus,
                    'restId': widget.restId,
                    'startDate': promo?['startDate'] ?? DateTime.now().toIso8601String(),
                    'endDate': promo?['endDate'] ?? DateTime.now().add(const Duration(days: 365)).toIso8601String(),
                    'startTime': promo?['startTime'] ?? DateTime.now().toIso8601String(),
                    'endTime': promo?['endTime'] ?? DateTime.now().add(const Duration(days: 365)).toIso8601String(),
                    'staffName': promo?['staffName'] ?? 'Admin',
                    'createdAt': promo?['createdAt'] ?? DateTime.now().toIso8601String(),
                    'updatedAt': DateTime.now().toIso8601String(),
                    '__v': (promo?['__v'] as num?)?.toInt() ?? 0,
                  };

                  final list = _getPromotions();
                  setState(() {
                    if (index != null && index >= 0 && index < list.length) {
                      list[index] = newPromo;
                    } else {
                      list.add(newPromo);
                    }
                    _savePromotions(list);
                  });
                  _persistChanges();
                  Navigator.pop(context);
                }
              },
              child: const Text('Save Promotion'),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // --- 6. STOCK MANAGEMENT TAB (VIEW & ENTRY) ---
  // ==========================================
  Widget _buildStockKpiCard(String title, String subtitle, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.15), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey.shade600)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStockManagementTab() {
    final stocks = _getStocks();
    final stockLogs = _getStockLogs();
    final ingredients = _getIngredients();
    final foodItems = _getItems();

    int lowStockCount = 0;
    int outOfStockCount = 0;
    double totalValuation = 0.0;

    for (var s in stocks) {
      final current = (s['currentStock'] as num?)?.toDouble() ?? 0.0;
      final alert = (s['minStockAlert'] as num?)?.toDouble() ?? 0.0;
      final cost = (s['costPrice'] as num?)?.toDouble() ?? 0.0;

      if (current <= 0) {
        outOfStockCount++;
      } else if (current <= alert) {
        lowStockCount++;
      }
      totalValuation += (current * cost);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: Text('Stock View (${stocks.length})'),
                  selected: _stockSubTab == 0,
                  onSelected: (val) { if (val) setState(() => _stockSubTab = 0); },
                ),
                ChoiceChip(
                  label: Text('Movement Logs (${stockLogs.length})'),
                  selected: _stockSubTab == 1,
                  onSelected: (val) { if (val) setState(() => _stockSubTab = 1); },
                ),
                ChoiceChip(
                  label: Text('Ingredients (${ingredients.length})'),
                  selected: _stockSubTab == 2,
                  onSelected: (val) { if (val) setState(() => _stockSubTab = 2); },
                ),
              ],
            ),
            Row(
              children: [
                if (_stockSubTab == 0) ...[
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), foregroundColor: Colors.white),
                    onPressed: () => _showRecordStockMovementDialog(),
                    icon: const Icon(Icons.sync_alt_rounded, size: 18),
                    label: const Text('Record Movement'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
                    onPressed: () => _showAddEditStockDialog(),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add Stock Entry'),
                  ),
                ] else if (_stockSubTab == 1) ...[
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), foregroundColor: Colors.white),
                    onPressed: () => _showRecordStockMovementDialog(),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('New Movement Entry'),
                  ),
                ] else if (_stockSubTab == 2) ...[
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
                    onPressed: () => _showAddEditIngredientDialog(),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add Ingredient'),
                  ),
                ],
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildStockKpiCard('Total Tracked', '${stocks.length} Items', Icons.inventory, Colors.indigo),
            const SizedBox(width: 12),
            _buildStockKpiCard('Low Stock Alert', '$lowStockCount Items', Icons.warning_amber_rounded, Colors.orange),
            const SizedBox(width: 12),
            _buildStockKpiCard('Out of Stock', '$outOfStockCount Items', Icons.do_not_disturb_on_rounded, Colors.red),
            const SizedBox(width: 12),
            _buildStockKpiCard('Stock Value', '৳${totalValuation.toStringAsFixed(2)}', Icons.payments_rounded, Colors.teal),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: _stockSubTab == 0
              ? _buildStockLevelsView(stocks, foodItems)
              : _stockSubTab == 1
                  ? _buildStockLogsView(stockLogs)
                  : _buildIngredientsView(ingredients),
        ),
      ],
    );
  }

  Widget _buildStockLevelsView(List<Map<String, dynamic>> stocks, List<Map<String, dynamic>> foodItems) {
    final filtered = stocks.where((s) {
      final name = (s['foodItemName'] ?? '').toString().toLowerCase();
      final matchesQuery = name.contains(_stockSearchQuery.toLowerCase());

      final current = (s['currentStock'] as num?)?.toDouble() ?? 0.0;
      final alert = (s['minStockAlert'] as num?)?.toDouble() ?? 0.0;

      bool matchesStatus = true;
      if (_stockStatusFilter == 'Low Stock') {
        matchesStatus = current > 0 && current <= alert;
      } else if (_stockStatusFilter == 'Out of Stock') {
        matchesStatus = current <= 0;
      } else if (_stockStatusFilter == 'In Stock') {
        matchesStatus = current > alert;
      }

      return matchesQuery && matchesStatus;
    }).toList();

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                onChanged: (val) => setState(() => _stockSearchQuery = val),
                decoration: InputDecoration(
                  hintText: 'Search stock items by name...',
                  prefixIcon: const Icon(Icons.search),
                  isDense: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            DropdownButton<String>(
              value: _stockStatusFilter,
              onChanged: (val) => setState(() => _stockStatusFilter = val!),
              items: ['All', 'In Stock', 'Low Stock', 'Out of Stock'].map((st) {
                return DropdownMenuItem(value: st, child: Text(st));
              }).toList(),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: filtered.isEmpty
              ? const Center(child: Text('No stock items recorded yet. Click "Add Stock Entry" to create one.'))
              : ListView.separated(
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final item = filtered[index];
                    final current = (item['currentStock'] as num?)?.toDouble() ?? 0.0;
                    final alert = (item['minStockAlert'] as num?)?.toDouble() ?? 0.0;
                    final cost = (item['costPrice'] as num?)?.toDouble() ?? 0.0;
                    final unit = item['unit'] ?? 'pcs';

                    Color statusColor = Colors.green;
                    String statusText = 'In Stock';
                    if (current <= 0) {
                      statusColor = Colors.red;
                      statusText = 'Out of Stock';
                    } else if (current <= alert) {
                      statusColor = Colors.orange;
                      statusText = 'Low Stock Alert';
                    }

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      leading: CircleAvatar(
                        backgroundColor: statusColor.withValues(alpha: 0.1),
                        child: Icon(
                          current <= 0
                              ? Icons.do_not_disturb_on_rounded
                              : current <= alert
                                  ? Icons.warning_amber_rounded
                                  : Icons.check_circle_outline_rounded,
                          color: statusColor,
                        ),
                      ),
                      title: Text(item['foodItemName'] ?? 'Unknown Item', style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('Min Alert: $alert $unit | Cost: ৳${cost.toStringAsFixed(2)} | Total Val: ৳${(current * cost).toStringAsFixed(2)}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: statusColor),
                            ),
                            child: Text(
                              '$current $unit ($statusText)',
                              style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.edit, size: 20, color: Colors.indigo),
                            onPressed: () => _showAddEditStockDialog(stockItem: item, index: index),
                          ),
                          IconButton(
                            icon: const Icon(Icons.sync_alt_rounded, size: 20, color: Colors.teal),
                            tooltip: 'Record Movement / Purchase',
                            onPressed: () => _showRecordStockMovementDialog(preselectedStockId: item['id'] ?? item['_id']),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                            onPressed: () async {
                              final confirm = await _showDeleteConfirmation('Delete Stock Entry', 'Are you sure you want to delete "${item['foodItemName']}"?');
                              if (confirm == true) {
                                final list = _getStocks();
                                setState(() {
                                  list.removeWhere((element) => (element['_id'] ?? element['id']) == (item['_id'] ?? item['id']));
                                  _saveStocks(list);
                                });
                                _persistChanges();
                              }
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildStockLogsView(List<Map<String, dynamic>> stockLogs) {
    if (stockLogs.isEmpty) {
      return const Center(child: Text('No stock movement logs recorded yet. Use "Record Movement" to add entries.'));
    }

    return ListView.separated(
      itemCount: stockLogs.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final log = stockLogs[index];
        final type = (log['type'] ?? 'movement').toString().toUpperCase();
        final change = (log['changeQty'] as num?)?.toDouble() ?? 0.0;
        final prev = (log['previousQty'] as num?)?.toDouble() ?? 0.0;
        final newQty = (log['newQty'] as num?)?.toDouble() ?? 0.0;

        Color badgeColor = Colors.blue;
        if (type.contains('PURCHASE')) badgeColor = Colors.green;
        if (type.contains('SPOILAGE') || type.contains('WASTE')) badgeColor = Colors.red;
        if (type.contains('USAGE') || type.contains('SALE')) badgeColor = Colors.orange;

        return ListTile(
          leading: CircleAvatar(
            backgroundColor: badgeColor.withValues(alpha: 0.1),
            child: Icon(change >= 0 ? Icons.add_circle_outline_rounded : Icons.remove_circle_outline_rounded, color: badgeColor),
          ),
          title: Text('${log['foodItemName'] ?? 'Item'} (${change >= 0 ? "+$change" : "$change"})', style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text('Prev: $prev ➔ New: $newQty | Staff: ${log['staffName'] ?? 'Staff'} | Note: ${log['note'] ?? 'N/A'}'),
          trailing: Text(
            log['timestamp']?.toString().split('T').first ?? '',
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
        );
      },
    );
  }

  Widget _buildIngredientsView(List<Map<String, dynamic>> ingredients) {
    if (ingredients.isEmpty) {
      return const Center(child: Text('No ingredients recorded yet. Click "Add Ingredient" to create one.'));
    }

    return ListView.separated(
      itemCount: ingredients.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final ing = ingredients[index];
        final current = (ing['currentStock'] as num?)?.toDouble() ?? 0.0;
        final alert = (ing['minStockAlert'] as num?)?.toDouble() ?? 0.0;
        final unit = ing['unit'] ?? 'kg';

        return ListTile(
          leading: const CircleAvatar(backgroundColor: Color(0xFFEEF2FF), child: Icon(Icons.grass_rounded, color: Colors.indigo)),
          title: Text(ing['name'] ?? 'Ingredient', style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text('Alert: $alert $unit | Supplier: ${ing['supplierName'] ?? 'N/A'} | Cost/Unit: ৳${(ing['costPerUnit'] as num?)?.toStringAsFixed(2) ?? "0.00"}'),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Chip(label: Text('$current $unit'), backgroundColor: const Color(0xFFEEF2FF)),
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.indigo),
                onPressed: () => _showAddEditIngredientDialog(ingredient: ing, index: index),
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () async {
                  final confirm = await _showDeleteConfirmation('Delete Ingredient', 'Are you sure you want to delete "${ing['name']}"?');
                  if (confirm == true) {
                    final list = _getIngredients();
                    setState(() {
                      list.removeAt(index);
                      _saveIngredients(list);
                    });
                    _persistChanges();
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAddEditStockDialog({Map<String, dynamic>? stockItem, int? index}) {
    final foodItems = _getItems();
    String? selectedFoodId = stockItem?['foodItemId'];
    String foodName = stockItem?['foodItemName'] ?? '';
    final stockCtrl = TextEditingController(text: stockItem != null ? (stockItem['currentStock'] ?? 0).toString() : '100');
    final alertCtrl = TextEditingController(text: stockItem != null ? (stockItem['minStockAlert'] ?? 5).toString() : '5');
    final unitCtrl = TextEditingController(text: stockItem?['unit'] ?? 'pcs');
    final costCtrl = TextEditingController(text: stockItem != null ? (stockItem['costPrice'] ?? 0).toString() : '0');

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(stockItem != null ? 'Edit Stock Entry' : 'Add New Stock Entry'),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 450,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Select Food Item:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 4),
                  DropdownButtonFormField<String>(
                    value: selectedFoodId != null && foodItems.any((f) => (f['_id'] ?? f['id']) == selectedFoodId) ? selectedFoodId : null,
                    decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
                    hint: const Text('Pick Food Item'),
                    items: foodItems.map((item) {
                      final id = (item['_id'] ?? item['id']).toString();
                      return DropdownMenuItem(value: id, child: Text(item['name'] ?? 'Unnamed'));
                    }).toList(),
                    onChanged: (val) {
                      setDialogState(() {
                        selectedFoodId = val;
                        final matched = foodItems.firstWhere((f) => (f['_id'] ?? f['id']).toString() == val, orElse: () => {});
                        foodName = matched['name'] ?? '';
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: stockCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(labelText: 'Current Stock Qty', border: OutlineInputBorder(), isDense: true),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: alertCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(labelText: 'Min Alert Qty', border: OutlineInputBorder(), isDense: true),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: unitCtrl,
                          decoration: const InputDecoration(labelText: 'Unit (pcs, kg, L, etc)', border: OutlineInputBorder(), isDense: true),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: costCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(labelText: 'Cost Price', border: OutlineInputBorder(), isDense: true),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
              onPressed: () {
                if (selectedFoodId != null && selectedFoodId!.isNotEmpty) {
                  final idStr = stockItem?['_id'] ?? stockItem?['id'] ?? 'stock_$selectedFoodId';
                  final newEntry = {
                    '_id': idStr,
                    'id': idStr,
                    'foodItemId': selectedFoodId,
                    'foodItemName': foodName,
                    'portionId': '',
                    'portionName': '',
                    'currentStock': double.tryParse(stockCtrl.text.trim()) ?? 0,
                    'minStockAlert': double.tryParse(alertCtrl.text.trim()) ?? 5,
                    'unit': unitCtrl.text.trim().isNotEmpty ? unitCtrl.text.trim() : 'pcs',
                    'costPrice': double.tryParse(costCtrl.text.trim()) ?? 0,
                    'isTracked': true,
                    'restId': widget.restId,
                    'updatedAt': DateTime.now().toIso8601String(),
                  };

                  final list = _getStocks();
                  setState(() {
                    if (index != null && index >= 0 && index < list.length) {
                      list[index] = newEntry;
                    } else {
                      final existingIdx = list.indexWhere((element) => (element['foodItemId'] == selectedFoodId));
                      if (existingIdx != -1) {
                        list[existingIdx] = newEntry;
                      } else {
                        list.add(newEntry);
                      }
                    }
                    _saveStocks(list);
                  });
                  _persistChanges();
                  Navigator.pop(context);
                }
              },
              child: const Text('Save Stock Entry'),
            ),
          ],
        ),
      ),
    );
  }

  void _showRecordStockMovementDialog({String? preselectedStockId}) {
    final stocks = _getStocks();
    if (stocks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please add at least one Stock Entry first!')));
      return;
    }

    String? selectedStockId = preselectedStockId ?? (stocks.first['_id'] ?? stocks.first['id']);
    String actionType = 'purchase'; // purchase, usage, spoilage, adjustment
    final qtyCtrl = TextEditingController(text: '10');
    final staffCtrl = TextEditingController(text: 'Staff');
    final noteCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Record Stock Movement / Adjustment'),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 450,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Select Stock Item:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 4),
                  DropdownButtonFormField<String>(
                    value: stocks.any((s) => (s['_id'] ?? s['id']) == selectedStockId) ? selectedStockId : (stocks.first['_id'] ?? stocks.first['id']),
                    decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
                    items: stocks.map((s) {
                      final id = (s['_id'] ?? s['id']).toString();
                      return DropdownMenuItem(value: id, child: Text('${s['foodItemName']} (Current: ${s['currentStock']} ${s['unit'] ?? "pcs"})'));
                    }).toList(),
                    onChanged: (val) => setDialogState(() => selectedStockId = val),
                  ),
                  const SizedBox(height: 12),
                  const Text('Movement Action:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 4),
                  DropdownButtonFormField<String>(
                    value: actionType,
                    decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
                    items: const [
                      DropdownMenuItem(value: 'purchase', child: Text('Stock Purchase (+)')),
                      DropdownMenuItem(value: 'usage', child: Text('Stock Usage / Sale (-)')),
                      DropdownMenuItem(value: 'spoilage', child: Text('Spoilage / Waste (-)')),
                      DropdownMenuItem(value: 'adjustment', child: Text('Manual Reset / Set Qty')),
                    ],
                    onChanged: (val) => setDialogState(() => actionType = val!),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: qtyCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Quantity', border: OutlineInputBorder(), isDense: true),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: staffCtrl,
                    decoration: const InputDecoration(labelText: 'Staff Name', border: OutlineInputBorder(), isDense: true),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: noteCtrl,
                    decoration: const InputDecoration(labelText: 'Notes / Voucher Reference', border: OutlineInputBorder(), isDense: true),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), foregroundColor: Colors.white),
              onPressed: () {
                final changeVal = double.tryParse(qtyCtrl.text.trim()) ?? 0;
                final targetIndex = stocks.indexWhere((s) => (s['_id'] ?? s['id']) == selectedStockId);
                if (targetIndex != -1) {
                  final target = stocks[targetIndex];
                  final double prevQty = (target['currentStock'] as num?)?.toDouble() ?? 0.0;
                  double newQty = prevQty;
                  double actualChange = changeVal;

                  if (actionType == 'purchase') {
                    newQty = prevQty + changeVal;
                  } else if (actionType == 'usage' || actionType == 'spoilage') {
                    newQty = prevQty - changeVal;
                    actualChange = -changeVal;
                  } else if (actionType == 'adjustment') {
                    newQty = changeVal;
                    actualChange = newQty - prevQty;
                  }

                  target['currentStock'] = newQty;
                  target['updatedAt'] = DateTime.now().toIso8601String();
                  stocks[targetIndex] = target;

                  final logs = _getStockLogs();
                  final logId = 'log_${DateTime.now().millisecondsSinceEpoch}';
                  logs.insert(0, {
                    '_id': logId,
                    'id': logId,
                    'stockItemId': selectedStockId,
                    'foodItemId': target['foodItemId'],
                    'foodItemName': target['foodItemName'],
                    'changeQty': actualChange,
                    'previousQty': prevQty,
                    'newQty': newQty,
                    'type': actionType,
                    'staffName': staffCtrl.text.trim().isNotEmpty ? staffCtrl.text.trim() : 'Staff',
                    'note': noteCtrl.text.trim(),
                    'timestamp': DateTime.now().toIso8601String(),
                  });

                  setState(() {
                    _saveStocks(stocks);
                    _saveStockLogs(logs);
                  });
                  _persistChanges();
                  Navigator.pop(context);
                }
              },
              child: const Text('Save Movement'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddEditIngredientDialog({Map<String, dynamic>? ingredient, int? index}) {
    final nameCtrl = TextEditingController(text: ingredient?['name'] ?? '');
    final unitCtrl = TextEditingController(text: ingredient?['unit'] ?? 'kg');
    final stockCtrl = TextEditingController(text: ingredient != null ? (ingredient['currentStock'] ?? 0).toString() : '50');
    final alertCtrl = TextEditingController(text: ingredient != null ? (ingredient['minStockAlert'] ?? 2).toString() : '2');
    final costCtrl = TextEditingController(text: ingredient != null ? (ingredient['costPerUnit'] ?? 0).toString() : '0');
    final supplierCtrl = TextEditingController(text: ingredient?['supplierName'] ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(ingredient != null ? 'Edit Ingredient' : 'Add New Ingredient'),
        content: SingleChildScrollView(
          child: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Ingredient Name', border: OutlineInputBorder(), isDense: true),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: unitCtrl,
                        decoration: const InputDecoration(labelText: 'Unit (kg, L, g)', border: OutlineInputBorder(), isDense: true),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: stockCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(labelText: 'Current Stock', border: OutlineInputBorder(), isDense: true),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: alertCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(labelText: 'Min Alert Qty', border: OutlineInputBorder(), isDense: true),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: costCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(labelText: 'Cost / Unit', border: OutlineInputBorder(), isDense: true),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: supplierCtrl,
                  decoration: const InputDecoration(labelText: 'Supplier Name', border: OutlineInputBorder(), isDense: true),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
            onPressed: () {
              if (nameCtrl.text.trim().isNotEmpty) {
                final idStr = ingredient?['_id'] ?? ingredient?['id'] ?? 'ing_${DateTime.now().millisecondsSinceEpoch}';
                final newIng = {
                  '_id': idStr,
                  'id': idStr,
                  'name': nameCtrl.text.trim(),
                  'unit': unitCtrl.text.trim().isNotEmpty ? unitCtrl.text.trim() : 'kg',
                  'currentStock': double.tryParse(stockCtrl.text.trim()) ?? 0,
                  'minStockAlert': double.tryParse(alertCtrl.text.trim()) ?? 2,
                  'costPerUnit': double.tryParse(costCtrl.text.trim()) ?? 0,
                  'supplierName': supplierCtrl.text.trim(),
                  'restId': widget.restId,
                  'updatedAt': DateTime.now().toIso8601String(),
                };

                final list = _getIngredients();
                setState(() {
                  if (index != null && index >= 0 && index < list.length) {
                    list[index] = newIng;
                  } else {
                    list.add(newIng);
                  }
                  _saveIngredients(list);
                });
                _persistChanges();
                Navigator.pop(context);
              }
            },
            child: const Text('Save Ingredient'),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // --- 7. EXPENSE MANAGEMENT TAB (VIEW & ENTRY) ---
  // ==========================================
  Widget _buildExpenseManagementTab() {
    final expenseItems = _getExpenseItems();
    final expenseGroups = _getExpenseGroups();
    final expenseHeads = _getExpenseHeads();

    double totalAmount = 0.0;
    for (var exp in expenseItems) {
      totalAmount += (exp['amount'] as num?)?.toDouble() ?? 0.0;
    }

    final groupNames = ['All', ...expenseGroups.map((g) => g['name']?.toString() ?? '').where((n) => n.isNotEmpty)];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: Text('Expense Entries View (${expenseItems.length})'),
                  selected: _expenseSubTab == 0,
                  onSelected: (val) { if (val) setState(() => _expenseSubTab = 0); },
                ),
                ChoiceChip(
                  label: Text('Groups & Heads (${expenseGroups.length}/${expenseHeads.length})'),
                  selected: _expenseSubTab == 1,
                  onSelected: (val) { if (val) setState(() => _expenseSubTab = 1); },
                ),
              ],
            ),
            Row(
              children: [
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), foregroundColor: Colors.white),
                  onPressed: () => _showAddEditExpenseGroupDialog(),
                  icon: const Icon(Icons.folder_open_rounded, size: 18),
                  label: const Text('Add Group'),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
                  onPressed: () => _showAddEditExpenseHeadDialog(),
                  icon: const Icon(Icons.sell_rounded, size: 18),
                  label: const Text('Add Head'),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
                  onPressed: () => _showAddEditExpenseItemDialog(),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Expense Entry'),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildStockKpiCard('Total Expenses', '৳${totalAmount.toStringAsFixed(2)}', Icons.account_balance_wallet_rounded, Colors.purple),
            const SizedBox(width: 12),
            _buildStockKpiCard('Total Vouchers', '${expenseItems.length} Entries', Icons.receipt_rounded, Colors.blue),
            const SizedBox(width: 12),
            _buildStockKpiCard('Expense Groups', '${expenseGroups.length} Groups', Icons.folder_open_rounded, Colors.orange),
            const SizedBox(width: 12),
            _buildStockKpiCard('Expense Heads', '${expenseHeads.length} Heads', Icons.sell_rounded, Colors.teal),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: _expenseSubTab == 0
              ? _buildExpenseItemsView(expenseItems, groupNames)
              : _buildExpenseGroupsHeadsView(expenseGroups, expenseHeads),
        ),
      ],
    );
  }

  Widget _buildExpenseItemsView(List<Map<String, dynamic>> expenseItems, List<String> groupNames) {
    final filtered = expenseItems.where((exp) {
      final note = (exp['note'] ?? '').toString().toLowerCase();
      final head = (exp['headName'] ?? '').toString().toLowerCase();
      final group = (exp['groupName'] ?? '').toString().toLowerCase();
      final staff = (exp['staffName'] ?? '').toString().toLowerCase();
      final voucher = (exp['voucherNo'] ?? '').toString().toLowerCase();

      final q = _expenseSearchQuery.toLowerCase();
      final matchesQuery = note.contains(q) || head.contains(q) || group.contains(q) || staff.contains(q) || voucher.contains(q);

      final matchesGroup = _selectedExpenseGroupFilter == 'All' || (exp['groupName'] == _selectedExpenseGroupFilter);

      return matchesQuery && matchesGroup;
    }).toList();

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                onChanged: (val) => setState(() => _expenseSearchQuery = val),
                decoration: InputDecoration(
                  hintText: 'Search expense by head, voucher #, staff or notes...',
                  prefixIcon: const Icon(Icons.search),
                  isDense: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            DropdownButton<String>(
              value: groupNames.contains(_selectedExpenseGroupFilter) ? _selectedExpenseGroupFilter : 'All',
              onChanged: (val) => setState(() => _selectedExpenseGroupFilter = val!),
              items: groupNames.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: filtered.isEmpty
              ? const Center(child: Text('No expense entries found. Click "Add Expense Entry" to record one.'))
              : ListView.separated(
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final item = filtered[index];
                    final amt = (item['amount'] as num?)?.toDouble() ?? 0.0;
                    final dateStr = item['date']?.toString().split('T').first ?? '';

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      leading: const CircleAvatar(backgroundColor: Color(0xFFFEF2F2), child: Icon(Icons.receipt_long_rounded, color: Colors.redAccent)),
                      title: Row(
                        children: [
                          Text(item['headName'] ?? 'Expense Head', style: const TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(width: 8),
                          Chip(label: Text(item['groupName'] ?? 'Group', style: const TextStyle(fontSize: 10)), backgroundColor: const Color(0xFFEEF2FF)),
                        ],
                      ),
                      subtitle: Text('Type: ${item['expenseType'] ?? "One-Time"} | Method: ${item['paymentMethod'] ?? "Cash"} | Staff: ${item['staffName'] ?? "Staff"} ${item['note'] != null && item['note'].isNotEmpty ? "| Note: ${item['note']}" : ""}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('৳${amt.toStringAsFixed(2)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.redAccent)),
                              Text(dateStr, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                            ],
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.edit, size: 20, color: Colors.indigo),
                            onPressed: () => _showAddEditExpenseItemDialog(expenseItem: item, index: index),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                            onPressed: () async {
                              final confirm = await _showDeleteConfirmation('Delete Expense Entry', 'Are you sure you want to delete this expense of ৳${amt.toStringAsFixed(2)}?');
                              if (confirm == true) {
                                final list = _getExpenseItems();
                                setState(() {
                                  list.removeWhere((e) => (e['_id'] ?? e['id']) == (item['_id'] ?? item['id']));
                                  _saveExpenseItems(list);
                                });
                                _persistChanges();
                              }
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildExpenseGroupsHeadsView(List<Map<String, dynamic>> groups, List<Map<String, dynamic>> heads) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left Column: Expense Groups
        Expanded(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Expense Groups', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), foregroundColor: Colors.white),
                        onPressed: () => _showAddEditExpenseGroupDialog(),
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Add Group'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: groups.isEmpty
                        ? const Center(child: Text('No Expense Groups defined.'))
                        : ListView.separated(
                            itemCount: groups.length,
                            separatorBuilder: (_, _) => const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final grp = groups[index];
                              return ListTile(
                                leading: const Icon(Icons.folder_open_rounded, color: Colors.orange),
                                title: Text(grp['name'] ?? 'Group Name', style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text(grp['description'] ?? ''),
                                trailing: IconButton(
                                  icon: const Icon(Icons.edit, size: 18, color: Colors.indigo),
                                  onPressed: () => _showAddEditExpenseGroupDialog(group: grp, index: index),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        // Right Column: Expense Heads
        Expanded(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Expense Heads', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
                        onPressed: () => _showAddEditExpenseHeadDialog(),
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Add Head'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: heads.isEmpty
                        ? const Center(child: Text('No Expense Heads defined.'))
                        : ListView.separated(
                            itemCount: heads.length,
                            separatorBuilder: (_, _) => const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final h = heads[index];
                              return ListTile(
                                leading: const Icon(Icons.sell_rounded, color: Colors.teal),
                                title: Text(h['name'] ?? 'Head Name', style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text('Group: ${h['groupName'] ?? "N/A"}'),
                                trailing: IconButton(
                                  icon: const Icon(Icons.edit, size: 18, color: Colors.indigo),
                                  onPressed: () => _showAddEditExpenseHeadDialog(head: h, index: index),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showAddEditExpenseItemDialog({Map<String, dynamic>? expenseItem, int? index}) {
    final heads = _getExpenseHeads();

    String? selectedHeadId = expenseItem?['headId'];
    String headName = expenseItem?['headName'] ?? '';
    String groupId = expenseItem?['groupId'] ?? '';
    String groupName = expenseItem?['groupName'] ?? '';

    if (selectedHeadId == null && heads.isNotEmpty) {
      selectedHeadId = heads.first['_id'] ?? heads.first['id'];
      headName = heads.first['name'] ?? '';
      groupId = heads.first['groupId'] ?? '';
      groupName = heads.first['groupName'] ?? '';
    }

    String expenseType = expenseItem?['expenseType'] ?? 'One-Time';
    String paymentMethod = expenseItem?['paymentMethod'] ?? 'Cash';
    final amountCtrl = TextEditingController(text: expenseItem != null ? (expenseItem['amount'] ?? 0).toString() : '');
    final staffCtrl = TextEditingController(text: expenseItem?['staffName'] ?? 'Staff');
    final voucherCtrl = TextEditingController(text: expenseItem?['voucherNo'] ?? '');
    final noteCtrl = TextEditingController(text: expenseItem?['note'] ?? '');

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(expenseItem != null ? 'Edit Expense Entry' : 'Add New Expense Entry'),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 450,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Select Expense Head:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 4),
                  DropdownButtonFormField<String>(
                    value: heads.any((h) => (h['_id'] ?? h['id']) == selectedHeadId) ? selectedHeadId : null,
                    decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
                    hint: const Text('Pick Expense Head'),
                    items: heads.map((h) {
                      final id = (h['_id'] ?? h['id']).toString();
                      return DropdownMenuItem(value: id, child: Text('${h['name']} (${h['groupName'] ?? "General"})'));
                    }).toList(),
                    onChanged: (val) {
                      setDialogState(() {
                        selectedHeadId = val;
                        final matched = heads.firstWhere((h) => (h['_id'] ?? h['id']).toString() == val, orElse: () => {});
                        headName = matched['name'] ?? '';
                        groupId = matched['groupId'] ?? '';
                        groupName = matched['groupName'] ?? '';
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: expenseType,
                          decoration: const InputDecoration(labelText: 'Expense Type', border: OutlineInputBorder(), isDense: true),
                          items: const [
                            DropdownMenuItem(value: 'One-Time', child: Text('One-Time')),
                            DropdownMenuItem(value: 'Recurring', child: Text('Recurring')),
                          ],
                          onChanged: (val) => setDialogState(() => expenseType = val!),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: paymentMethod,
                          decoration: const InputDecoration(labelText: 'Payment Method', border: OutlineInputBorder(), isDense: true),
                          items: const [
                            DropdownMenuItem(value: 'Cash', child: Text('Cash')),
                            DropdownMenuItem(value: 'Card', child: Text('Card')),
                            DropdownMenuItem(value: 'Bank Transfer', child: Text('Bank Transfer')),
                          ],
                          onChanged: (val) => setDialogState(() => paymentMethod = val!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: amountCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Expense Amount (৳)', border: OutlineInputBorder(), isDense: true),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: staffCtrl,
                          decoration: const InputDecoration(labelText: 'Staff Name', border: OutlineInputBorder(), isDense: true),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: voucherCtrl,
                          decoration: const InputDecoration(labelText: 'Voucher No (Optional)', border: OutlineInputBorder(), isDense: true),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: noteCtrl,
                    decoration: const InputDecoration(labelText: 'Notes / Reference', border: OutlineInputBorder(), isDense: true),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
              onPressed: () {
                final amt = double.tryParse(amountCtrl.text.trim());
                if (amt != null && amt > 0) {
                  final idStr = expenseItem?['_id'] ?? expenseItem?['id'] ?? 'exp_${DateTime.now().millisecondsSinceEpoch}';
                  final newExpense = {
                    '_id': idStr,
                    'id': idStr,
                    'headId': selectedHeadId ?? '',
                    'headName': headName,
                    'groupId': groupId,
                    'groupName': groupName,
                    'expenseType': expenseType,
                    'amount': amt,
                    'paymentMethod': paymentMethod,
                    'date': expenseItem?['date'] ?? DateTime.now().toIso8601String(),
                    'staffName': staffCtrl.text.trim().isNotEmpty ? staffCtrl.text.trim() : 'Staff',
                    'voucherNo': voucherCtrl.text.trim(),
                    'note': noteCtrl.text.trim(),
                    'restId': widget.restId,
                    'createdAt': expenseItem?['createdAt'] ?? DateTime.now().toIso8601String(),
                  };

                  final list = _getExpenseItems();
                  setState(() {
                    if (index != null && index >= 0 && index < list.length) {
                      list[index] = newExpense;
                    } else {
                      list.insert(0, newExpense);
                    }
                    _saveExpenseItems(list);
                  });
                  _persistChanges();
                  Navigator.pop(context);
                }
              },
              child: const Text('Save Expense Entry'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddEditExpenseGroupDialog({Map<String, dynamic>? group, int? index}) {
    final nameCtrl = TextEditingController(text: group?['name'] ?? '');
    final descCtrl = TextEditingController(text: group?['description'] ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(group != null ? 'Edit Expense Group' : 'Add Expense Group'),
        content: SizedBox(
          width: 380,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Group Name (e.g. Utility Bills)', border: OutlineInputBorder(), isDense: true),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: descCtrl,
                decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder(), isDense: true),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
            onPressed: () {
              if (nameCtrl.text.trim().isNotEmpty) {
                final idStr = group?['_id'] ?? group?['id'] ?? 'grp_${DateTime.now().millisecondsSinceEpoch}';
                final newGrp = {
                  '_id': idStr,
                  'id': idStr,
                  'name': nameCtrl.text.trim(),
                  'description': descCtrl.text.trim(),
                  'restId': widget.restId,
                  'updatedAt': DateTime.now().toIso8601String(),
                };

                final list = _getExpenseGroups();
                setState(() {
                  if (index != null && index >= 0 && index < list.length) {
                    list[index] = newGrp;
                  } else {
                    list.add(newGrp);
                  }
                  _saveExpenseGroups(list);
                });
                _persistChanges();
                Navigator.pop(context);
              }
            },
            child: const Text('Save Group'),
          ),
        ],
      ),
    );
  }

  void _showAddEditExpenseHeadDialog({Map<String, dynamic>? head, int? index}) {
    final groups = _getExpenseGroups();
    final nameCtrl = TextEditingController(text: head?['name'] ?? '');
    String? selectedGroupId = head?['groupId'];

    if (selectedGroupId == null && groups.isNotEmpty) {
      selectedGroupId = groups.first['_id'] ?? groups.first['id'];
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(head != null ? 'Edit Expense Head' : 'Add Expense Head'),
          content: SizedBox(
            width: 380,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Head Name (e.g. Electricity Bill)', border: OutlineInputBorder(), isDense: true),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: groups.any((g) => (g['_id'] ?? g['id']) == selectedGroupId) ? selectedGroupId : null,
                  decoration: const InputDecoration(labelText: 'Belongs to Expense Group', border: OutlineInputBorder(), isDense: true),
                  items: groups.map((g) {
                    final id = (g['_id'] ?? g['id']).toString();
                    return DropdownMenuItem(value: id, child: Text(g['name'] ?? 'Group'));
                  }).toList(),
                  onChanged: (val) => setDialogState(() => selectedGroupId = val),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
              onPressed: () {
                if (nameCtrl.text.trim().isNotEmpty && selectedGroupId != null) {
                  final idStr = head?['_id'] ?? head?['id'] ?? 'head_${DateTime.now().millisecondsSinceEpoch}';
                  final matchedGrp = groups.firstWhere((g) => (g['_id'] ?? g['id']).toString() == selectedGroupId, orElse: () => {});
                  final newHead = {
                    '_id': idStr,
                    'id': idStr,
                    'name': nameCtrl.text.trim(),
                    'groupId': selectedGroupId,
                    'groupName': matchedGrp['name'] ?? '',
                    'restId': widget.restId,
                    'updatedAt': DateTime.now().toIso8601String(),
                  };

                  final list = _getExpenseHeads();
                  setState(() {
                    if (index != null && index >= 0 && index < list.length) {
                      list[index] = newHead;
                    } else {
                      list.add(newHead);
                    }
                    _saveExpenseHeads(list);
                  });
                  _persistChanges();
                  Navigator.pop(context);
                }
              },
              child: const Text('Save Head'),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // --- 8. RESTAURANT & SYSTEM SETTINGS TAB ---
  // ==========================================
  Widget _buildRestaurantSystemSettingsTab() {
    return Column(
      children: [
        Row(
          children: [
            ChoiceChip(
              label: const Text('Restaurant Profile & VAT'),
              selected: _systemSettingsSubTab == 0,
              selectedColor: Colors.indigo.shade100,
              onSelected: (val) {
                if (val) setState(() => _systemSettingsSubTab = 0);
              },
            ),
            const SizedBox(width: 12),
            ChoiceChip(
              label: Text('Payment Methods (${_getPaymentMethods().length})'),
              selected: _systemSettingsSubTab == 1,
              selectedColor: Colors.teal.shade100,
              onSelected: (val) {
                if (val) setState(() => _systemSettingsSubTab = 1);
              },
            ),
            const SizedBox(width: 12),
            ChoiceChip(
              label: const Text('Receipt & Kitchen Print Copies'),
              selected: _systemSettingsSubTab == 2,
              selectedColor: Colors.amber.shade100,
              onSelected: (val) {
                if (val) setState(() => _systemSettingsSubTab = 2);
              },
            ),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: _systemSettingsSubTab == 0
              ? _buildBasicRestaurantProfileSubView()
              : _systemSettingsSubTab == 1
                  ? _buildPaymentMethodsSubView()
                  : _buildPrintCopiesSubView(),
        ),
      ],
    );
  }

  // --- SubView 1: Restaurant Profile, VAT & Address ---
  Widget _buildBasicRestaurantProfileSubView() {
    final basic = _getBasicSetting();

    final nameCtrl = TextEditingController(text: basic['restName'] ?? '');
    final vatCtrl = TextEditingController(text: basic['vat'] ?? '20.00');
    final currCtrl = TextEditingController(text: basic['currSym'] ?? '£');
    final openCtrl = TextEditingController(text: basic['openingHour'] ?? '10:00');
    final closeCtrl = TextEditingController(text: basic['closingHour'] ?? '23:00');
    final addr1Ctrl = TextEditingController(text: basic['addrLn1'] ?? '');
    final addr2Ctrl = TextEditingController(text: basic['addrLn2'] ?? '');
    final addr3Ctrl = TextEditingController(text: basic['addrLn3'] ?? '');
    final txt1Ctrl = TextEditingController(text: basic['txtLn1'] ?? 'Thank you for dining with us!');
    final txt2Ctrl = TextEditingController(text: basic['txtLn2'] ?? 'Please visit again.');
    final txt3Ctrl = TextEditingController(text: basic['txtLn3'] ?? '');
    int mealDuration = (basic['setMealDuration'] as num?)?.toInt() ?? 0;

    return SingleChildScrollView(
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.indigo.shade50,
                        radius: 22,
                        child: Icon(Icons.storefront, color: Colors.indigo.shade800),
                      ),
                      const SizedBox(width: 12),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Restaurant General & POS Settings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          Text('These settings directly configure the POS till headers, VAT calculation, and receipt printing', style: TextStyle(color: Colors.grey, fontSize: 13)),
                        ],
                      ),
                    ],
                  ),
                  const Divider(height: 32),

                  // Table Management (manage_table) Setting Card
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: _manageTable ? const Color(0xFFEEF2FF) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: _manageTable ? const Color(0xFFC7D2FE) : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: SwitchListTile(
                      title: Row(
                        children: [
                          const Text('Table Management (manage_table)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: _manageTable ? const Color(0xFF10B981) : const Color(0xFF94A3B8),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              _manageTable ? 'TABLES ACTIVE' : 'COUNTER FAST-ORDER',
                              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      subtitle: Text(
                        _manageTable
                            ? 'Enabled: POS allows table ordering, floor layout & guest seating for Dine-In'
                            : 'Disabled: POS runs in direct fast-order counter mode without table selection',
                        style: TextStyle(fontSize: 12, color: Colors.blueGrey.shade600),
                      ),
                      value: _manageTable,
                      onChanged: (bool value) {
                        setState(() {
                          _manageTable = value;
                          _localSettings['manage_table'] = value;
                        });
                      },
                      secondary: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _manageTable ? const Color(0xFF4F46E5) : const Color(0xFFCBD5E1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.table_restaurant_rounded, color: Colors.white, size: 20),
                      ),
                      contentPadding: EdgeInsets.zero,
                      activeColor: const Color(0xFF4F46E5),
                    ),
                  ),
                  const SizedBox(height: 20),

                  const Text('Restaurant Identity & Tax', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.indigo)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: TextFormField(
                          controller: nameCtrl,
                          decoration: const InputDecoration(labelText: 'Restaurant Display Name', prefixIcon: Icon(Icons.restaurant), border: OutlineInputBorder()),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 1,
                        child: TextFormField(
                          controller: vatCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(labelText: 'VAT Rate (%)', prefixIcon: Icon(Icons.percent), border: OutlineInputBorder()),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 1,
                        child: TextFormField(
                          controller: currCtrl,
                          decoration: const InputDecoration(labelText: 'Currency Symbol', prefixIcon: Icon(Icons.currency_pound), border: OutlineInputBorder()),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: openCtrl,
                          decoration: const InputDecoration(labelText: 'Opening Time (e.g. 10:00)', prefixIcon: Icon(Icons.schedule), border: OutlineInputBorder()),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: closeCtrl,
                          decoration: const InputDecoration(labelText: 'Closing Time (e.g. 23:00)', prefixIcon: Icon(Icons.nightlight_round), border: OutlineInputBorder()),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          value: [0, 15, 30, 45, 60, 75, 90].contains(mealDuration) ? mealDuration : 0,
                          decoration: const InputDecoration(labelText: 'Meal Duration (Minutes)', border: OutlineInputBorder()),
                          items: const [
                            DropdownMenuItem(value: 0, child: Text('Off / Unlimited')),
                            DropdownMenuItem(value: 15, child: Text('15 Minutes')),
                            DropdownMenuItem(value: 30, child: Text('30 Minutes')),
                            DropdownMenuItem(value: 45, child: Text('45 Minutes')),
                            DropdownMenuItem(value: 60, child: Text('60 Minutes')),
                            DropdownMenuItem(value: 75, child: Text('75 Minutes')),
                            DropdownMenuItem(value: 90, child: Text('90 Minutes')),
                          ],
                          onChanged: (val) => mealDuration = val ?? 0,
                        ),
                      ),
                    ],
                  ),

                  const Divider(height: 32),
                  const Text('Restaurant Physical Address', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.indigo)),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: addr1Ctrl,
                    decoration: const InputDecoration(labelText: 'Address Line 1 (Street & Number)', prefixIcon: Icon(Icons.location_on), border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: addr2Ctrl,
                          decoration: const InputDecoration(labelText: 'Address Line 2 (Area / District)', border: OutlineInputBorder()),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: addr3Ctrl,
                          decoration: const InputDecoration(labelText: 'Address Line 3 (City & Postcode)', border: OutlineInputBorder()),
                        ),
                      ),
                    ],
                  ),

                  const Divider(height: 32),
                  const Text('Receipt Header & Footer Messages', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.indigo)),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: txt1Ctrl,
                    decoration: const InputDecoration(labelText: 'Receipt Message Line 1', prefixIcon: Icon(Icons.message), border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: txt2Ctrl,
                    decoration: const InputDecoration(labelText: 'Receipt Message Line 2', prefixIcon: Icon(Icons.message), border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: txt3Ctrl,
                    decoration: const InputDecoration(labelText: 'Receipt Message Line 3 (e.g. WiFi Pass)', prefixIcon: Icon(Icons.wifi), border: OutlineInputBorder()),
                  ),

                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
                      onPressed: () {
                        final updated = Map<String, dynamic>.from(basic);
                        updated['_id'] = basic['_id'] ?? 'setting_${widget.restId}';
                        updated['restName'] = nameCtrl.text.trim();
                        updated['vat'] = vatCtrl.text.trim().isNotEmpty ? vatCtrl.text.trim() : '20.00';
                        updated['currSym'] = currCtrl.text.trim().isNotEmpty ? currCtrl.text.trim() : '£';
                        updated['openingHour'] = openCtrl.text.trim();
                        updated['closingHour'] = closeCtrl.text.trim();
                        updated['setMealDuration'] = mealDuration;
                        updated['addrLn1'] = addr1Ctrl.text.trim();
                        updated['addrLn2'] = addr2Ctrl.text.trim();
                        updated['addrLn3'] = addr3Ctrl.text.trim();
                        updated['txtLn1'] = txt1Ctrl.text.trim();
                        updated['txtLn2'] = txt2Ctrl.text.trim();
                        updated['txtLn3'] = txt3Ctrl.text.trim();
                        updated['restId'] = widget.restId;
                        updated['logo'] = basic['logo'] is List ? basic['logo'] : [];
                        updated['tillId'] = (basic['tillId'] ?? '').toString();
                        updated['androidId'] = (basic['androidId'] ?? '').toString();
                        updated['deliveryAndBag'] = basic['deliveryAndBag'] is Map ? basic['deliveryAndBag'] : {'delivery': [], 'bag': []};
                        updated['manage_table'] = _manageTable;
                        _localSettings['manage_table'] = _manageTable;

                        setState(() {
                          _saveBasicSetting(updated);
                        });
                        _persistChanges();
                      },
                      icon: const Icon(Icons.save),
                      label: const Text('Save Restaurant Profile & Settings', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- SubView 2: Payment Methods Management ---
  Widget _buildPaymentMethodsSubView() {
    final methods = _getPaymentMethods();

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Active Payment Methods (${methods.length})', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal)),
                const Text('Configures checkout payment options available on the POS cash register', style: TextStyle(fontSize: 13, color: Colors.grey)),
              ],
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
              onPressed: () => _showAddEditPaymentMethodDialog(),
              icon: const Icon(Icons.add_card),
              label: const Text('Add Payment Method'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: methods.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.payment, size: 54, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      const Text('No payment methods configured.', style: TextStyle(color: Colors.grey)),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
                        onPressed: () => _showAddEditPaymentMethodDialog(),
                        icon: const Icon(Icons.add),
                        label: const Text('Add Payment Method'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: methods.length,
                  itemBuilder: (context, index) {
                    final pm = methods[index];
                    final name = (pm['paymentMethodsName'] ?? pm['name'] ?? 'Payment Method').toString();
                    final id = (pm['_id'] ?? pm['id'] ?? '').toString();

                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.teal.shade100,
                          child: Icon(Icons.account_balance_wallet, color: Colors.teal.shade800),
                        ),
                        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        subtitle: Text('ID: $id | Sync Status: Connected to POS'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _showAddEditPaymentMethodDialog(method: pm, index: index),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () async {
                                final confirm = await _showDeleteConfirmation('Delete Payment Method', 'Are you sure you want to delete payment method "$name"?');
                                if (confirm == true) {
                                  final list = _getPaymentMethods();
                                  list.removeAt(index);
                                  setState(() {
                                    _savePaymentMethods(list);
                                  });
                                  _persistChanges();
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _showAddEditPaymentMethodDialog({Map<String, dynamic>? method, int? index}) {
    final nameCtrl = TextEditingController(text: method?['paymentMethodsName'] ?? method?['name'] ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(method == null ? 'Add Payment Method' : 'Edit Payment Method'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Payment Method Name (e.g. Cash, Credit Card, bKash)',
                  prefixIcon: Icon(Icons.payment),
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
            onPressed: () {
              if (nameCtrl.text.trim().isNotEmpty) {
                final idStr = method?['_id'] ?? method?['id'] ?? 'pm_${DateTime.now().millisecondsSinceEpoch}';
                final newMethod = {
                  '_id': idStr,
                  'id': idStr,
                  'paymentMethodsName': nameCtrl.text.trim(),
                  'restId': widget.restId,
                  'createdBy': (method?['createdBy'] ?? 'Admin').toString(),
                  'updatedBy': 'Admin',
                  'createdAt': method?['createdAt'] ?? DateTime.now().toIso8601String(),
                  'updatedAt': DateTime.now().toIso8601String(),
                  '__v': (method?['__v'] as num?)?.toInt() ?? 0,
                };

                final list = _getPaymentMethods();
                setState(() {
                  if (index != null && index >= 0 && index < list.length) {
                    list[index] = newMethod;
                  } else {
                    list.add(newMethod);
                  }
                  _savePaymentMethods(list);
                });
                _persistChanges();
                Navigator.pop(context);
              }
            },
            child: const Text('Save Method'),
          ),
        ],
      ),
    );
  }

  // --- SubView 3: Print Copies Configuration ---
  Widget _buildPrintCopiesSubView() {
    final printData = _getPrintCopyData();

    int kAll = (printData['kitchenPrint_all'] as num?)?.toInt() ?? 1;
    int kNew = (printData['kitchenPrint_new'] as num?)?.toInt() ?? 1;
    int kBar = (printData['kitchenPrint_barOnly'] as num?)?.toInt() ?? 1;
    int kKitchen = (printData['kitchenPrint_kitchenOnly'] as num?)?.toInt() ?? 1;
    int guest = (printData['guestPrint'] as num?)?.toInt() ?? 1;
    int release = (printData['releasePrint'] as num?)?.toInt() ?? 1;

    return StatefulBuilder(
      builder: (context, setSubState) {
        return SingleChildScrollView(
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 800),
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: Colors.amber.shade100,
                            radius: 22,
                            child: Icon(Icons.print, color: Colors.amber.shade900),
                          ),
                          const SizedBox(width: 12),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Printer Slip Copies Setup', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              Text('Sets how many receipt/slip copies are automatically printed upon order placement and release', style: TextStyle(color: Colors.grey, fontSize: 13)),
                            ],
                          ),
                        ],
                      ),
                      const Divider(height: 32),

                      const Text('Kitchen & Bar Order Slips', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.indigo)),
                      const SizedBox(height: 12),
                      _buildPrintCopyRow('Kitchen Print (All Items)', 'Print all ordered food and drink items', kAll, (v) => setSubState(() => kAll = v)),
                      _buildPrintCopyRow('Kitchen Print (New Items Only)', 'Print only newly added items on order updates', kNew, (v) => setSubState(() => kNew = v)),
                      _buildPrintCopyRow('Bar Station Slips', 'Print drink orders directed to bar printer', kBar, (v) => setSubState(() => kBar = v)),
                      _buildPrintCopyRow('Kitchen Station Slips', 'Print food orders directed to kitchen printer', kKitchen, (v) => setSubState(() => kKitchen = v)),

                      const Divider(height: 32),
                      const Text('Customer Bill & Release Receipts', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.indigo)),
                      const SizedBox(height: 12),
                      _buildPrintCopyRow('Guest Receipt Copies', 'Printed when customer requests the preliminary bill', guest, (v) => setSubState(() => guest = v)),
                      _buildPrintCopyRow('Release Bill Copies', 'Final payment receipt printed upon table settlement', release, (v) => setSubState(() => release = v)),

                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.amber.shade800, foregroundColor: Colors.white),
                          onPressed: () {
                            final updated = {
                              'kitchenPrint_all': kAll,
                              'kitchenPrint_new': kNew,
                              'kitchenPrint_barOnly': kBar,
                              'kitchenPrint_kitchenOnly': kKitchen,
                              'guestPrint': guest,
                              'releasePrint': release,
                            };
                            setState(() {
                              _savePrintCopyData(updated);
                            });
                            _persistChanges();
                          },
                          icon: const Icon(Icons.save),
                          label: const Text('Save Print Copies Setup', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPrintCopyRow(String title, String subtitle, int currentValue, ValueChanged<int> onChanged) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Text(subtitle, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
              ],
            ),
          ),
          DropdownButton<int>(
            value: currentValue,
            items: [1, 2, 3, 4, 5].map((cnt) {
              return DropdownMenuItem<int>(
                value: cnt,
                child: Text('$cnt ${cnt == 1 ? "Copy" : "Copies"}', style: const TextStyle(fontWeight: FontWeight.bold)),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null) onChanged(val);
            },
          ),
        ],
      ),
    );
  }
}
