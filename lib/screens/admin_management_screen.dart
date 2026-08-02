import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'restaurant_form_screen.dart';

class AdminManagementScreen extends StatefulWidget {
  const AdminManagementScreen({super.key});

  @override
  State<AdminManagementScreen> createState() => _AdminManagementScreenState();
}

class _AdminManagementScreenState extends State<AdminManagementScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _supabase = Supabase.instance.client;

  List<Map<String, dynamic>> _companies = [];
  List<Map<String, dynamic>> _restaurants = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final compRes = await _supabase.from('companies').select().order('created_at', ascending: false);
      final restRes = await _supabase.from('restaurants').select().order('created_at', ascending: false);

      setState(() {
        _companies = List<Map<String, dynamic>>.from(compRes);
        _restaurants = List<Map<String, dynamic>>.from(restRes);
      });
    } catch (_) {
      // Demo fallbacks if table doesn't exist yet
      setState(() {
        _companies = [
          {'id': '1', 'company_id': 'spice', 'name': 'Spice Group Ltd.', 'password': '1234'},
          {'id': '2', 'company_id': 'bistro', 'name': 'Bistro Cafe Holdings', 'password': '1234'},
        ];
        _restaurants = [
          {'id': '1001', 'name': 'Spice Garden Main Branch', 'company_id': 'spice', 'mobile': '+1 234-567-890'},
          {'id': '1002', 'name': 'Spice & Grill Express', 'company_id': 'spice', 'mobile': '+1 987-654-321'},
        ];
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showCreateCompanyDialog() {
    final cidCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    final passCtrl = TextEditingController(text: '1234');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.business, color: Colors.indigo),
            SizedBox(width: 8),
            Text('Create New Company'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: cidCtrl,
              decoration: const InputDecoration(
                labelText: 'Company ID (e.g. spice)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Company Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: passCtrl,
              decoration: const InputDecoration(
                labelText: 'Login Password',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (cidCtrl.text.isNotEmpty && nameCtrl.text.isNotEmpty) {
                try {
                  await _supabase.from('companies').insert({
                    'company_id': cidCtrl.text.trim().toLowerCase(),
                    'name': nameCtrl.text.trim(),
                    'password': passCtrl.text.trim(),
                    'created_at': DateTime.now().toIso8601String(),
                  });
                } catch (_) {}
                _loadData();
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: const Text('Create Company'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Super Admin Console', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.indigo.shade800,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.amber,
          tabs: const [
            Tab(icon: Icon(Icons.apartment), text: 'Companies'),
            Tab(icon: Icon(Icons.storefront), text: 'Restaurants'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                // Companies List Tab
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('All Companies (${_companies.length})', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          ElevatedButton.icon(
                            onPressed: _showCreateCompanyDialog,
                            icon: const Icon(Icons.add),
                            label: const Text('Create Company'),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: ListView.builder(
                          itemCount: _companies.length,
                          itemBuilder: (context, index) {
                            final c = _companies[index];
                            final linkedCount = _restaurants.where((r) => r['company_id'] == c['company_id']).length;

                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              elevation: 2,
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.indigo.shade100,
                                  child: Icon(Icons.business, color: Colors.indigo.shade800),
                                ),
                                title: Text(c['name'] ?? 'Unnamed', style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text('Company ID: ${c['company_id']} | Linked Outlets: $linkedCount'),
                                trailing: Chip(
                                  label: Text('Pass: ${c['password'] ?? '1234'}'),
                                  backgroundColor: Colors.grey.shade100,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                // Restaurants List Tab
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('All Restaurants (${_restaurants.length})', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          ElevatedButton.icon(
                            onPressed: () async {
                              final res = await Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const RestaurantFormScreen()),
                              );
                              if (res == true) _loadData();
                            },
                            icon: const Icon(Icons.add),
                            label: const Text('Create Restaurant'),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: ListView.builder(
                          itemCount: _restaurants.length,
                          itemBuilder: (context, index) {
                            final r = _restaurants[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.orange.shade100,
                                  child: Icon(Icons.restaurant, color: Colors.orange.shade800),
                                ),
                                title: Text(r['name'] ?? 'Restaurant', style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text('Rest ID: ${r['id']} | Company ID: ${r['company_id'] ?? 'Unassigned'}'),
                                trailing: IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.blue),
                                  onPressed: () async {
                                    final res = await Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => RestaurantFormScreen(restaurant: r)),
                                    );
                                    if (res == true) _loadData();
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
