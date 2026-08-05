import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart' as xl;

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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
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

    // Sync inside total_data_table structure if present
    if (_localSettings['total_data_table'] is List) {
      final List totalList = List<dynamic>.from(_localSettings['total_data_table']);

      for (int i = 0; i < totalList.length; i++) {
        final obj = totalList[i];
        if (obj is Map<String, dynamic>) {
          final Map<String, dynamic> mutableObj = Map<String, dynamic>.from(obj);
          if (mutableObj.containsKey('foodSettingData') || mutableObj['foodSetting_data_table'] == 'foodTable') {
            mutableObj['foodSettingData'] = items;
            totalList[i] = mutableObj;
          } else if (mutableObj.containsKey('categoryData') || mutableObj['category_data_table'] == 'categoryBox') {
            mutableObj['categoryData'] = categories;
            totalList[i] = mutableObj;
          } else if (mutableObj.containsKey('cuisineData') || mutableObj['cuisine_data_table'] == 'cuisineBox') {
            mutableObj['cuisineData'] = cuisines;
            totalList[i] = mutableObj;
          } else if (mutableObj.containsKey('tagData') || mutableObj['tag_data_table'] == 'tagTable') {
            mutableObj['tagData'] = tags;
            totalList[i] = mutableObj;
          } else if (mutableObj.containsKey('tableData') || mutableObj['table_data_table'] == 'table') {
            mutableObj['tableData'] = tables;
            totalList[i] = mutableObj;
          } else if (mutableObj.containsKey('areaData') || mutableObj['area_data_table'] == 'areaTable') {
            mutableObj['areaData'] = areas;
            totalList[i] = mutableObj;
          } else if (mutableObj.containsKey('staffData') || mutableObj['staff_data_table'] == 'staffTable') {
            mutableObj['staffData'] = staff;
            totalList[i] = mutableObj;
          } else if (mutableObj.containsKey('promotionData') || mutableObj['promotion_data_table'] == 'promotionHiveTable') {
            mutableObj['promotionData'] = promotions;
            totalList[i] = mutableObj;
          } else if (mutableObj.containsKey('tillData') || mutableObj['till_data_table'] == 'tillBox') {
            mutableObj['tillData'] = tills;
            totalList[i] = mutableObj;
          } else if (mutableObj.containsKey('kitchenData') || mutableObj['kitchen_data_table'] == 'KitchenTable') {
            mutableObj['kitchenData'] = kitchens;
            totalList[i] = mutableObj;
          } else if (mutableObj.containsKey('barData') || mutableObj['bar_data_table'] == 'barTable') {
            mutableObj['barData'] = bars;
            totalList[i] = mutableObj;
          } else if (mutableObj.containsKey('paymentMethodSettingData') || mutableObj['paymentMethod_data_table'] == 'paymentMethodTable') {
            mutableObj['paymentMethodSettingData'] = paymentMethods;
            totalList[i] = mutableObj;
          }
        }
      }

      _localSettings['total_data_table'] = totalList;
    }
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

  @override
  Widget build(BuildContext context) {
    final mediaWidth = MediaQuery.of(context).size.width;
    final isMobile = mediaWidth < 600;

    return Padding(
      padding: EdgeInsets.all(isMobile ? 14.0 : 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isMobile) ...[
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Settings & Menu',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.indigo.shade900,
                        ),
                      ),
                    ),
                    if (_isSaving) ...[
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2.0),
                      ),
                      const SizedBox(width: 6),
                      const Text('Saving...', style: TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold, fontSize: 12)),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Manage Items, Categories, Tables, Staff & Offers',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
            ),
          ] else ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Settings & Menu Management',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.indigo.shade900,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Manage Food Items, Categories, Cuisines, Tags, Portions, Tables & Areas',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                    ),
                  ],
                ),
                Row(
                  children: [
                    if (_isSaving) ...[
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      ),
                      const SizedBox(width: 8),
                      const Text('Saving...', style: TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold)),
                    ],
                  ],
                ),
              ],
            ),
          ],
          SizedBox(height: isMobile ? 10 : 16),
          TabBar(
            controller: _tabController,
            labelColor: Colors.indigo,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.indigo,
            indicatorWeight: 3,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: const [
              Tab(icon: Icon(Icons.restaurant_menu), text: 'Food Items'),
              Tab(icon: Icon(Icons.category), text: 'Categories, Cuisines & Tags'),
              Tab(icon: Icon(Icons.table_restaurant), text: 'Tables & Areas'),
              Tab(icon: Icon(Icons.people), text: 'Staff & Tills'),
              Tab(icon: Icon(Icons.local_offer), text: 'Promotions & Offers'),
            ],
          ),
          SizedBox(height: isMobile ? 10 : 16),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildFoodItemsTab(),
                _buildCategoriesCuisinesTagsTab(),
                _buildTablesAndAreasTab(),
                _buildStaffAndTillsTab(),
                _buildPromotionsTab(),
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
        Row(
          children: [
            Expanded(
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search food items by name...',
                  prefixIcon: const Icon(Icons.search),
                  isDense: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onChanged: (val) => setState(() => _itemSearchQuery = val),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: categoryNames.contains(_selectedCategoryFilter) ? _selectedCategoryFilter : 'All',
                  icon: const Icon(Icons.filter_alt, size: 20),
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
            const SizedBox(width: 12),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.teal.shade700,
                side: BorderSide(color: Colors.teal.shade300),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              ),
              onPressed: _downloadExcelTemplate,
              icon: const Icon(Icons.download, size: 18),
              label: const Text('Template'),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              onPressed: _importFoodItemsFromExcel,
              icon: const Icon(Icons.upload_file),
              label: const Text('Import Excel'),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              onPressed: () => _showFoodItemDialog(),
              icon: const Icon(Icons.add),
              label: Text('Create Item (${allItems.length})'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: filteredItems.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.fastfood_outlined, size: 48, color: Colors.grey.shade400),
                      const SizedBox(height: 8),
                      Text(
                        _itemSearchQuery.isNotEmpty || _selectedCategoryFilter != 'All'
                            ? 'No food items match your filter.'
                            : 'No food items added yet.',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
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

                    final originalIndex = allItems.indexWhere((element) => (element['_id'] ?? element['id']) == id);

                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 20,
                                  backgroundColor: Colors.orange.shade100,
                                  child: Icon(Icons.fastfood, color: Colors.orange.shade800, size: 20),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                      if (item['shortName'] != null && item['shortName'].toString().isNotEmpty)
                                        Text('Code: ${item['shortName']}', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.blue),
                                  tooltip: 'Edit Item',
                                  onPressed: () => _showFoodItemDialog(item: item, index: originalIndex >= 0 ? originalIndex : index),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
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
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: [
                                ...catNames.map((c) => _buildBadge(c, Colors.indigo)),
                                ...cuisineNames.map((c) => _buildBadge(c, Colors.teal)),
                                ...tagNames.map((t) => _buildBadge(t, Colors.deepOrange)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Portions: ${portions.length} ${portions.isNotEmpty ? "(${portions.map((p) => "${p['portionName'] ?? ''}: \$${p['portionPriceDineIn'] ?? p['portionPrice'] ?? 0}").join(', ')})" : ""}',
                              style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
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

  Widget _buildBadge(String label, MaterialColor color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.shade50,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.shade200),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, color: color.shade800, fontWeight: FontWeight.w600),
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
                              decoration: const InputDecoration(labelText: 'Price (\$)', isDense: true, border: InputBorder.none),
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
                          decoration: const InputDecoration(labelText: 'Price (\$)', isDense: true),
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
                  'vatAble': false,
                  'foodTypeList': ['DineIn', 'Collection', 'Delivery', 'Waiting'],
                  'createdAt': item?['createdAt'] ?? DateTime.now().toIso8601String(),
                  'updatedAt': DateTime.now().toIso8601String(),
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
  // --- EXCEL IMPORT FOR FOOD ITEMS ---
  // ==========================================

  void _downloadExcelTemplate() {
    try {
      // Create CSV content which is 100% compatible with Excel, Google Sheets, and Web browsers
      const csvHeader = 'name,shortName,description,portionName,price,category,cuisine,tag\n';
      const sampleRows = 
        'Chicken Biryani,CB01,Fragrant rice dish,Regular,12.99,Main Course,Indian,halal\n'
        'Mango Lassi,ML01,Sweet yogurt drink,Standard,4.50,Drinks,Indian,\n'
        'Garlic Naan,GN01,Fresh baked bread,Regular,3.00,Bread,Indian,vegetarian\n';

      final String csvContent = csvHeader + sampleRows;
      final bytes = Uint8List.fromList(utf8.encode(csvContent));

      _downloadViaAnchor(bytes, 'food_items_template.csv', 'text/csv');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create template: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  void _downloadViaAnchor(Uint8List bytes, String fileName, String mimeType) {
    try {
      FilePicker.platform.saveFile(
        dialogTitle: 'Save Import Template',
        fileName: fileName,
        bytes: bytes,
      );
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
      int? portionNameCol = columnMap['portionname'] ?? columnMap['portion_name'] ?? columnMap['portion'];
      int? priceCol = columnMap['price'] ?? columnMap['portionprice'] ?? columnMap['portion_price'];
      int? categoryCol = columnMap['category'] ?? columnMap['categories'];
      int? cuisineCol = columnMap['cuisine'] ?? columnMap['cuisines'];
      int? tagCol = columnMap['tag'] ?? columnMap['tags'];

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
        final portionName = getCellStr(portionNameCol).isNotEmpty ? getCellStr(portionNameCol) : 'Standard';
        final priceStr = getCellStr(priceCol);
        final price = double.tryParse(priceStr) ?? 0.0;
        final categoryName = getCellStr(categoryCol);
        final cuisineName = getCellStr(cuisineCol);
        final tagName = getCellStr(tagCol);

        // Match category
        List<Map<String, dynamic>> matchedCategories = [];
        if (categoryName.isNotEmpty) {
          final match = categories.where((c) => (c['name'] ?? '').toString().toLowerCase() == categoryName.toLowerCase()).toList();
          if (match.isNotEmpty) {
            matchedCategories = match;
          } else {
            warnings.add('Row ${rowIdx + 1}: Category "$categoryName" not found (skipped tagging)');
          }
        }

        // Match cuisine
        List<Map<String, dynamic>> matchedCuisines = [];
        if (cuisineName.isNotEmpty) {
          final match = cuisines.where((c) => (c['name'] ?? '').toString().toLowerCase() == cuisineName.toLowerCase()).toList();
          if (match.isNotEmpty) {
            matchedCuisines = match;
          } else {
            warnings.add('Row ${rowIdx + 1}: Cuisine "$cuisineName" not found (skipped tagging)');
          }
        }

        // Match tag
        List<Map<String, dynamic>> matchedTags = [];
        if (tagName.isNotEmpty) {
          final match = tags.where((t) => (t['name'] ?? '').toString().toLowerCase() == tagName.toLowerCase()).toList();
          if (match.isNotEmpty) {
            matchedTags = match;
          } else {
            warnings.add('Row ${rowIdx + 1}: Tag "$tagName" not found (skipped tagging)');
          }
        }

        final newItem = {
          '_id': 'import_${DateTime.now().millisecondsSinceEpoch}_$rowIdx',
          'name': name,
          'shortName': shortName,
          'description': description,
          'restId': widget.restId,
          'categories': matchedCategories,
          'cuisines': matchedCuisines,
          'tags': matchedTags,
          'portions': [
            {
              '_id': 'p_${DateTime.now().millisecondsSinceEpoch}_$rowIdx',
              'portionName': portionName,
              'portionPriceDineIn': price,
              'portionPriceCollection': price,
              'portionPriceDelivery': price,
              'portionPriceWaiting': price,
              'portionPrice': price,
            }
          ],
          'status': true,
          'vatAble': false,
          'foodTypeList': ['DineIn', 'Collection', 'Delivery', 'Waiting'],
          'days': {'sat': true, 'sun': true, 'mon': true, 'tue': true, 'wed': true, 'thu': true, 'fri': true},
          'makedByKitchen': [],
          'makedByBar': [],
          'relatedItems': [],
          'options': [],
          'extras': [],
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
        _showImportPreviewDialog(parsedItems, warnings, file.name);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        String errorMsg = e.toString();
        if (errorMsg.contains('LateInitialization')) {
          errorMsg = 'File format error. Please use the "Template" button to download a valid .xlsx template, fill it in, and try again.';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error importing Excel file: $errorMsg'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  void _showImportPreviewDialog(List<Map<String, dynamic>> parsedItems, List<String> warnings, String fileName) {
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
                    '$fileName — ${parsedItems.length} item${parsedItems.length == 1 ? '' : 's'} found',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.normal),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 700,
          height: 450,
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
                      ...warnings.take(5).map((w) => Padding(
                            padding: const EdgeInsets.only(left: 24, top: 2),
                            child: Text(w, style: TextStyle(fontSize: 12, color: Colors.amber.shade900)),
                          )),
                      if (warnings.length > 5)
                        Padding(
                          padding: const EdgeInsets.only(left: 24, top: 4),
                          child: Text(
                            '...and ${warnings.length - 5} more',
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
                    columnSpacing: 16,
                    dataRowMinHeight: 36,
                    dataRowMaxHeight: 52,
                    columns: const [
                      DataColumn(label: Text('#', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Name', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Code', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Portion', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Price', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
                      DataColumn(label: Text('Category', style: TextStyle(fontWeight: FontWeight.bold))),
                    ],
                    rows: parsedItems.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final item = entry.value;
                      final portions = item['portions'] as List? ?? [];
                      final portionName = portions.isNotEmpty ? (portions[0]['portionName'] ?? 'Standard') : 'Standard';
                      final price = portions.isNotEmpty ? (portions[0]['portionPriceDineIn'] ?? 0) : 0;
                      final cats = item['categories'] as List? ?? [];
                      final catName = cats.isNotEmpty ? (cats[0]['name'] ?? '') : '';

                      return DataRow(cells: [
                        DataCell(Text('${idx + 1}')),
                        DataCell(Text(item['name'] ?? '', overflow: TextOverflow.ellipsis)),
                        DataCell(Text(item['shortName'] ?? '', style: TextStyle(color: Colors.grey.shade600, fontSize: 12))),
                        DataCell(Text(portionName.toString())),
                        DataCell(Text('\$${(price is num ? price : 0).toStringAsFixed(2)}')),
                        DataCell(Text(catName.toString(), style: TextStyle(color: Colors.indigo.shade600, fontSize: 12))),
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
              ? Center(child: Text('No $typeName added yet.'))
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
                  'sl': 0,
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
              ? Center(child: Text('No tables added yet.'))
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
                    'createdBy': selectedCreatedBy,
                    'updatedBy': '',
                    'restId': widget.restId,
                    'createdAt': table?['createdAt'] ?? DateTime.now().toIso8601String(),
                    'updatedAt': DateTime.now().toIso8601String(),
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
              ? Center(child: Text('No dining areas added yet.'))
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
              ? const Center(child: Text('No staff members registered yet.'))
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
              ? const Center(child: Text('No cash tills added yet.'))
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
                        subtitle: Text('Till ID: $tillId | Total: \$$total'),
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
                  'tillId': idCtrl.text.trim(),
                  'tillStatus': false,
                  'openingBalance': till?['openingBalance'] ?? 0,
                  'depositAmount': till?['depositAmount'] ?? 0,
                  'withdrawAmount': till?['withdrawAmount'] ?? 0,
                  'totalAmount': till?['totalAmount'] ?? 0,
                  'restId': widget.restId,
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
                    'id': staff?['id'] ?? 'staff_${DateTime.now().millisecondsSinceEpoch}',
                    'staffId': staff?['staffId'] ?? '',
                    'name': nameCtrl.text.trim(),
                    'mobile': mobileCtrl.text.trim(),
                    'empContact': mobileCtrl.text.trim(),
                    'email': emailCtrl.text.trim(),
                    'password': passCtrl.text.trim(),
                    'status': true,
                    'role': selectedRole,
                    'restId': widget.restId,
                    'createdAt': staff?['createdAt'] ?? DateTime.now().toIso8601String(),
                    'updatedAt': DateTime.now().toIso8601String(),
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
                    'createdAt': promo?['createdAt'] ?? DateTime.now().toIso8601String(),
                    'updatedAt': DateTime.now().toIso8601String(),
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
}
