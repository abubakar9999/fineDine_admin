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
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.admin_panel_settings_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 8),
            Text(
              isMobile ? 'Super Admin' : 'Super Admin Console',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: isMobile ? 16 : 18, color: Colors.white),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF1E1B4B),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: const Color(0xFF94A3B8),
          indicatorColor: const Color(0xFF10B981),
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(icon: Icon(Icons.apartment_rounded, size: 18), text: 'Companies'),
            Tab(icon: Icon(Icons.storefront_rounded, size: 18), text: 'Restaurants'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF4F46E5)))
          : TabBarView(
              controller: _tabController,
              children: [
                // Companies List Tab
                Padding(
                  padding: EdgeInsets.all(isMobile ? 16.0 : 28.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'All Companies (${_companies.length})',
                            style: TextStyle(fontSize: isMobile ? 17 : 20, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A)),
                          ),
                          ElevatedButton.icon(
                            onPressed: _showCreateCompanyDialog,
                            icon: const Icon(Icons.add_rounded, size: 18),
                            label: Text(isMobile ? 'Add' : 'Create Company'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4F46E5),
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(
                                horizontal: isMobile ? 12 : 18,
                                vertical: isMobile ? 10 : 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Expanded(
                        child: ListView.builder(
                          itemCount: _companies.length,
                          itemBuilder: (context, index) {
                            final c = _companies[index];
                            final linkedCount = _restaurants.where((r) => r['company_id'] == c['company_id']).length;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.02),
                                    blurRadius: 10,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                leading: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEEF2FF),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(Icons.apartment_rounded, color: Color(0xFF4F46E5), size: 24),
                                ),
                                title: Text(c['name'] ?? 'Unnamed Company', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A))),
                                subtitle: Text('Company ID: ${c['company_id']} • Linked Outlets: $linkedCount', style: const TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                                trailing: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: const Color(0xFFE2E8F0)),
                                  ),
                                  child: Text('PIN: ${c['password'] ?? '1234'}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
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
                  padding: EdgeInsets.all(isMobile ? 16.0 : 28.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'All Restaurants (${_restaurants.length})',
                            style: TextStyle(fontSize: isMobile ? 17 : 20, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A)),
                          ),
                          ElevatedButton.icon(
                            onPressed: () async {
                              final res = await Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const RestaurantFormScreen()),
                              );
                              if (res == true) _loadData();
                            },
                            icon: const Icon(Icons.add_rounded, size: 18),
                            label: const Text('Create Restaurant'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4F46E5),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Expanded(
                        child: ListView.builder(
                          itemCount: _restaurants.length,
                          itemBuilder: (context, index) {
                            final r = _restaurants[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.02),
                                    blurRadius: 10,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                leading: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFEF3C7),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(Icons.storefront_rounded, color: Color(0xFFD97706), size: 24),
                                ),
                                title: Text(r['name'] ?? 'Restaurant', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A))),
                                subtitle: Text('Outlet ID: #${r['id']} • Company ID: ${r['company_id'] ?? 'Unassigned'}', style: const TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                                trailing: IconButton(
                                  icon: const Icon(Icons.edit_rounded, color: Color(0xFF4F46E5)),
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

