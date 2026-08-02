import 'package:flutter/material.dart';

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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _localSettings = Map<String, dynamic>.from(widget.settingsData);
  }

  @override
  void didUpdateWidget(covariant SettingsView oldWidget) {
    super.didUpdateWidget(oldWidget);
    _localSettings = Map<String, dynamic>.from(widget.settingsData);
  }

  List<dynamic> _getItems() {
    if (_localSettings['items'] is List) {
      return List<dynamic>.from(_localSettings['items']);
    }
    return [];
  }

  List<dynamic> _getCategories() {
    if (_localSettings['categories'] is List) {
      return List<dynamic>.from(_localSettings['categories']);
    }
    return [];
  }

  List<dynamic> _getTables() {
    if (_localSettings['tables'] is List) {
      return List<dynamic>.from(_localSettings['tables']);
    }
    return [];
  }

  Future<void> _persistChanges() async {
    await widget.onSaveSettings(_localSettings);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settings saved successfully!'), backgroundColor: Colors.green),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
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
            'Manage food items, categories, portions, and restaurant layout',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
          ),
          const SizedBox(height: 16),
          TabBar(
            controller: _tabController,
            labelColor: Colors.indigo,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.indigo,
            tabs: const [
              Tab(icon: Icon(Icons.restaurant_menu), text: 'Food Items'),
              Tab(icon: Icon(Icons.category), text: 'Categories'),
              Tab(icon: Icon(Icons.table_restaurant), text: 'Tables'),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildFoodItemsTab(),
                _buildCategoriesTab(),
                _buildTablesTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Food Items Tab ---
  Widget _buildFoodItemsTab() {
    final items = _getItems();

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Food Items (${items.length})', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ElevatedButton.icon(
              onPressed: () => _showFoodItemDialog(),
              icon: const Icon(Icons.add),
              label: const Text('Create Item'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: items.isEmpty
              ? const Center(child: Text('No food items found.'))
              : ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final String name = item['name'] ?? 'Unnamed';
                    final double price = (item['price'] as num?)?.toDouble() ?? 0.0;
                    final List portions = item['portions'] is List ? item['portions'] : [];

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.orange.shade100,
                          child: Icon(Icons.fastfood, color: Colors.orange.shade800),
                        ),
                        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('Price: \$${price.toStringAsFixed(2)} | Portions: ${portions.length}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _showFoodItemDialog(item: item, index: index),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                setState(() {
                                  items.removeAt(index);
                                  _localSettings['items'] = items;
                                });
                                _persistChanges();
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

  void _showFoodItemDialog({Map<String, dynamic>? item, int? index}) {
    final nameCtrl = TextEditingController(text: item?['name'] ?? '');
    final priceCtrl = TextEditingController(text: item?['price']?.toString() ?? '0.0');
    final portionNameCtrl = TextEditingController();
    final portionPriceCtrl = TextEditingController();

    List<Map<String, dynamic>> portions = item?['portions'] is List
        ? List<Map<String, dynamic>>.from((item!['portions'] as List).map((p) => Map<String, dynamic>.from(p)))
        : [];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(item == null ? 'Create Food Item' : 'Edit Food Item'),
          content: SizedBox(
            width: 450,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Item Name', prefixIcon: Icon(Icons.fastfood)),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: priceCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Default Price', prefixIcon: Icon(Icons.attach_money)),
                  ),
                  const SizedBox(height: 16),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Portions', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  ...portions.map((p) => ListTile(
                        dense: true,
                        title: Text(p['portionName'] ?? ''),
                        subtitle: Text('\$${p['portionPrice']}'),
                        trailing: IconButton(
                          icon: const Icon(Icons.close, size: 18, color: Colors.red),
                          onPressed: () {
                            setDialogState(() {
                              portions.remove(p);
                            });
                          },
                        ),
                      )),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: portionNameCtrl,
                          decoration: const InputDecoration(labelText: 'Portion Name', isDense: true),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: portionPriceCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Price', isDense: true),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle, color: Colors.green),
                        onPressed: () {
                          if (portionNameCtrl.text.isNotEmpty) {
                            setDialogState(() {
                              portions.add({
                                '_id': 'p_${DateTime.now().millisecondsSinceEpoch}',
                                'portionName': portionNameCtrl.text.trim(),
                                'portionPrice': double.tryParse(portionPriceCtrl.text.trim()) ?? 0.0,
                              });
                              portionNameCtrl.clear();
                              portionPriceCtrl.clear();
                            });
                          }
                        },
                      )
                    ],
                  )
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                final newItem = {
                  '_id': item?['_id'] ?? 'item_${DateTime.now().millisecondsSinceEpoch}',
                  'name': nameCtrl.text.trim(),
                  'price': double.tryParse(priceCtrl.text.trim()) ?? 0.0,
                  'restId': widget.restId,
                  'portions': portions,
                };

                final items = _getItems();
                setState(() {
                  if (index != null) {
                    items[index] = newItem;
                  } else {
                    items.add(newItem);
                  }
                  _localSettings['items'] = items;
                });
                _persistChanges();
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  // --- Categories Tab ---
  Widget _buildCategoriesTab() {
    final categories = _getCategories();

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Categories (${categories.length})', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ElevatedButton.icon(
              onPressed: () => _showCategoryDialog(),
              icon: const Icon(Icons.add),
              label: const Text('Add Category'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: categories.isEmpty
              ? const Center(child: Text('No categories found.'))
              : ListView.builder(
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final cat = categories[index];
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue.shade100,
                          child: Icon(Icons.category, color: Colors.blue.shade800),
                        ),
                        title: Text(cat['name'] ?? 'Unnamed', style: const TextStyle(fontWeight: FontWeight.bold)),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            setState(() {
                              categories.removeAt(index);
                              _localSettings['categories'] = categories;
                            });
                            _persistChanges();
                          },
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _showCategoryDialog() {
    final nameCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Category'),
        content: TextField(
          controller: nameCtrl,
          decoration: const InputDecoration(labelText: 'Category Name'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.isNotEmpty) {
                final categories = _getCategories();
                setState(() {
                  categories.add({
                    '_id': 'cat_${DateTime.now().millisecondsSinceEpoch}',
                    'name': nameCtrl.text.trim(),
                    'restId': widget.restId,
                  });
                  _localSettings['categories'] = categories;
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

  // --- Tables Tab ---
  Widget _buildTablesTab() {
    final tables = _getTables();

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Tables (${tables.length})', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ElevatedButton.icon(
              onPressed: () => _showTableDialog(),
              icon: const Icon(Icons.add),
              label: const Text('Add Table'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: tables.isEmpty
              ? const Center(child: Text('No tables configured.'))
              : ListView.builder(
                  itemCount: tables.length,
                  itemBuilder: (context, index) {
                    final t = tables[index];
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.purple.shade100,
                          child: Icon(Icons.table_restaurant, color: Colors.purple.shade800),
                        ),
                        title: Text(t['name'] ?? 'Table', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('Capacity: ${t['capacity'] ?? 0} guests'),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            setState(() {
                              tables.removeAt(index);
                              _localSettings['tables'] = tables;
                            });
                            _persistChanges();
                          },
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _showTableDialog() {
    final nameCtrl = TextEditingController();
    final capCtrl = TextEditingController(text: '4');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Table'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Table Name')),
            const SizedBox(height: 12),
            TextField(controller: capCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Capacity')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.isNotEmpty) {
                final tables = _getTables();
                setState(() {
                  tables.add({
                    '_id': 't_${DateTime.now().millisecondsSinceEpoch}',
                    'name': nameCtrl.text.trim(),
                    'capacity': int.tryParse(capCtrl.text.trim()) ?? 4,
                    'restId': widget.restId,
                  });
                  _localSettings['tables'] = tables;
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
}
