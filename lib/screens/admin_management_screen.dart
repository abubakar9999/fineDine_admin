import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'restaurant_form_screen.dart';
import 'main_dashboard_screen.dart';

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
  String _restaurantSearch = '';
  String _tableFilter = 'all'; // 'all', 'tables_on', 'counter_mode'

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
      try {
        final compRes = await _supabase.from('companies').select().order('created_at', ascending: false);
        _companies = List<Map<String, dynamic>>.from(compRes);
      } catch (_) {
        final compRes = await _supabase.from('companies').select();
        _companies = List<Map<String, dynamic>>.from(compRes);
      }
    } catch (_) {
      _companies = [
        {'id': '1', 'company_id': 'spice', 'name': 'Spice Group Ltd.', 'password': '1234'},
        {'id': '2', 'company_id': 'bistro', 'name': 'Bistro Cafe Holdings', 'password': '1234'},
      ];
    }

    try {
      try {
        final restRes = await _supabase.from('restaurants').select().order('created_at', ascending: false);
        _restaurants = List<Map<String, dynamic>>.from(restRes);
      } catch (_) {
        final restRes = await _supabase.from('restaurants').select();
        _restaurants = List<Map<String, dynamic>>.from(restRes);
      }
    } catch (_) {
      _restaurants = [
        {'id': '1001', 'name': 'Abu Bakar', 'company_id': 'spice', 'email': 'abu@gmail.com', 'mobile': '+1 234-567-890', 'manage_table': true},
        {'id': '10008', 'name': 'AB Restaurant', 'company_id': 'spice', 'email': 'ab@gmail.com', 'mobile': '+1 987-654-321', 'manage_table': false},
      ];
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
                  padding: EdgeInsets.all(isMobile ? 14.0 : 24.0),
                  child: Column(
                    children: [
                      // Header & Create Button
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'All Restaurants (${_restaurants.length})',
                                style: TextStyle(fontSize: isMobile ? 18 : 22, fontWeight: FontWeight.w900, color: const Color(0xFF0F172A)),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Configure outlet operating mode, table management & POS settings',
                                style: TextStyle(fontSize: isMobile ? 11 : 13, color: const Color(0xFF64748B)),
                              ),
                            ],
                          ),
                          ElevatedButton.icon(
                            onPressed: () async {
                              final res = await Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const RestaurantFormScreen()),
                              );
                              if (res == true) _loadData();
                            },
                            icon: const Icon(Icons.add_business_rounded, size: 18),
                            label: const Text('Add Restaurant'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4F46E5),
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(horizontal: isMobile ? 14 : 18, vertical: isMobile ? 12 : 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Search and Operating Mode Filter Bar
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          children: [
                            TextField(
                              decoration: InputDecoration(
                                hintText: 'Search by restaurant name, ID, company, or email...',
                                hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                                prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF64748B), size: 20),
                                isDense: true,
                                filled: true,
                                fillColor: const Color(0xFFF8FAFC),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              ),
                              onChanged: (val) {
                                setState(() {
                                  _restaurantSearch = val.toLowerCase().trim();
                                });
                              },
                            ),
                            const SizedBox(height: 10),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  FilterChip(
                                    label: Text('All (${_restaurants.length})'),
                                    selected: _tableFilter == 'all',
                                    onSelected: (_) => setState(() => _tableFilter = 'all'),
                                    selectedColor: const Color(0xFFEEF2FF),
                                    checkmarkColor: const Color(0xFF4F46E5),
                                    labelStyle: TextStyle(
                                      color: _tableFilter == 'all' ? const Color(0xFF4F46E5) : const Color(0xFF475569),
                                      fontWeight: _tableFilter == 'all' ? FontWeight.bold : FontWeight.w500,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  FilterChip(
                                    avatar: const Icon(Icons.table_restaurant_rounded, size: 14, color: Color(0xFF059669)),
                                    label: Text('Floor Tables: ON (${_restaurants.where((r) => r['manage_table'] != false).length})'),
                                    selected: _tableFilter == 'tables_on',
                                    onSelected: (_) => setState(() => _tableFilter = 'tables_on'),
                                    selectedColor: const Color(0xFFECFDF5),
                                    checkmarkColor: const Color(0xFF059669),
                                    labelStyle: TextStyle(
                                      color: _tableFilter == 'tables_on' ? const Color(0xFF065F46) : const Color(0xFF475569),
                                      fontWeight: _tableFilter == 'tables_on' ? FontWeight.bold : FontWeight.w500,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  FilterChip(
                                    avatar: const Icon(Icons.point_of_sale_rounded, size: 14, color: Color(0xFF6366F1)),
                                    label: Text('Counter Mode: Fast Order (${_restaurants.where((r) => r['manage_table'] == false).length})'),
                                    selected: _tableFilter == 'counter_mode',
                                    onSelected: (_) => setState(() => _tableFilter = 'counter_mode'),
                                    selectedColor: const Color(0xFFEEF2FF),
                                    checkmarkColor: const Color(0xFF4F46E5),
                                    labelStyle: TextStyle(
                                      color: _tableFilter == 'counter_mode' ? const Color(0xFF4338CA) : const Color(0xFF475569),
                                      fontWeight: _tableFilter == 'counter_mode' ? FontWeight.bold : FontWeight.w500,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Filtered Restaurants List
                      Expanded(
                        child: Builder(
                          builder: (context) {
                            final filtered = _restaurants.where((r) {
                              final name = (r['name'] ?? '').toString().toLowerCase();
                              final id = (r['id'] ?? '').toString().toLowerCase();
                              final comp = (r['company_id'] ?? '').toString().toLowerCase();
                              final email = (r['email'] ?? '').toString().toLowerCase();
                              final matchesSearch = _restaurantSearch.isEmpty ||
                                  name.contains(_restaurantSearch) ||
                                  id.contains(_restaurantSearch) ||
                                  comp.contains(_restaurantSearch) ||
                                  email.contains(_restaurantSearch);

                              final bool manageTable = r['manage_table'] ?? true;
                              final matchesFilter = _tableFilter == 'all' ||
                                  (_tableFilter == 'tables_on' && manageTable) ||
                                  (_tableFilter == 'counter_mode' && !manageTable);

                              return matchesSearch && matchesFilter;
                            }).toList();

                            if (filtered.isEmpty) {
                              return Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.storefront_outlined, size: 48, color: Colors.grey.shade400),
                                    const SizedBox(height: 12),
                                    const Text('No restaurants match your search or filter.', style: TextStyle(color: Color(0xFF64748B), fontSize: 14)),
                                  ],
                                ),
                              );
                            }

                            return ListView.builder(
                              itemCount: filtered.length,
                              itemBuilder: (context, index) {
                                final r = filtered[index];
                                final bool manageTable = r['manage_table'] ?? true;
                                final String restId = r['id']?.toString() ?? '';
                                final String restName = r['name'] ?? 'Restaurant #$restId';
                                final String companyId = r['company_id'] ?? 'Unassigned';
                                final String email = r['email'] ?? '';
                                final String mobile = r['mobile'] ?? '';

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 14),
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
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Header Row: Store Icon, Name, ID, Badges, Edit Button
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(10),
                                              decoration: BoxDecoration(
                                                gradient: const LinearGradient(
                                                  colors: [Color(0xFF4F46E5), Color(0xFF6366F1)],
                                                ),
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: const Icon(Icons.storefront_rounded, color: Colors.white, size: 22),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Flexible(
                                                        child: Text(
                                                          restName,
                                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A)),
                                                          overflow: TextOverflow.ellipsis,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                                        decoration: BoxDecoration(
                                                          color: const Color(0xFFF1F5F9),
                                                          borderRadius: BorderRadius.circular(6),
                                                          border: Border.all(color: const Color(0xFFCBD5E1)),
                                                        ),
                                                        child: Text(
                                                          '#$restId',
                                                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 6),
                                                      Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                                        decoration: BoxDecoration(
                                                          color: const Color(0xFFEEF2FF),
                                                          borderRadius: BorderRadius.circular(6),
                                                          border: Border.all(color: const Color(0xFFC7D2FE)),
                                                        ),
                                                        child: Text(
                                                          companyId,
                                                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF4F46E5)),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 3),
                                                  Text(
                                                    '${email.isNotEmpty ? "$email • " : ""}${mobile.isNotEmpty ? "$mobile • " : ""}Company: $companyId',
                                                    style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ],
                                              ),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.edit_rounded, color: Color(0xFF4F46E5), size: 20),
                                              tooltip: 'Edit Restaurant Settings',
                                              onPressed: () async {
                                                final res = await Navigator.push(
                                                  context,
                                                  MaterialPageRoute(builder: (context) => RestaurantFormScreen(restaurant: r)),
                                                );
                                                if (res == true) _loadData();
                                              },
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        const Divider(height: 1, color: Color(0xFFF1F5F9)),
                                        const SizedBox(height: 12),

                                        // Table Management (manage_table) Control Panel
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                          decoration: BoxDecoration(
                                            color: manageTable ? const Color(0xFFECFDF5) : const Color(0xFFF8FAFC),
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(color: manageTable ? const Color(0xFFA7F3D0) : const Color(0xFFE2E8F0)),
                                          ),
                                          child: Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.all(7),
                                                decoration: BoxDecoration(
                                                  color: manageTable ? const Color(0xFF059669) : const Color(0xFF64748B),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Icon(
                                                  manageTable ? Icons.table_restaurant_rounded : Icons.point_of_sale_rounded,
                                                  color: Colors.white,
                                                  size: 18,
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Row(
                                                      children: [
                                                        const Text(
                                                          'Table Management (manage_table)',
                                                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
                                                        ),
                                                        const SizedBox(width: 8),
                                                        Container(
                                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                          decoration: BoxDecoration(
                                                            color: manageTable ? const Color(0xFF10B981) : const Color(0xFF64748B),
                                                            borderRadius: BorderRadius.circular(6),
                                                          ),
                                                          child: Text(
                                                            manageTable ? 'TABLES ON' : 'COUNTER MODE',
                                                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 2),
                                                    Text(
                                                      manageTable
                                                          ? 'Floor tables & dine-in seating active in POS'
                                                          : 'Direct counter / fast takeaway mode (table selection disabled in POS)',
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        color: manageTable ? const Color(0xFF065F46) : const Color(0xFF64748B),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Tooltip(
                                                message: manageTable ? 'Turn Table Management OFF (Counter Mode)' : 'Turn Table Management ON (Floor Tables)',
                                                child: Switch(
                                                  value: manageTable,
                                                  activeColor: const Color(0xFF059669),
                                                  onChanged: (newVal) async {
                                                    setState(() {
                                                      r['manage_table'] = newVal;
                                                    });
                                                    try {
                                                      final orFilter = 'id.eq.$restId${email.isNotEmpty ? ",email.eq.$email" : ""}';
                                                      await _supabase.from('restaurants').update({
                                                        'manage_table': newVal,
                                                        'updated_at': DateTime.now().toIso8601String(),
                                                      }).or(orFilter);

                                                      // Also update settings_data in restaurants table
                                                      if (r['settings_data'] != null && r['settings_data'] is Map) {
                                                        final sData = Map<String, dynamic>.from(r['settings_data']);
                                                        sData['manage_table'] = newVal;
                                                        await _supabase.from('restaurants').update({'settings_data': sData}).or(orFilter);
                                                      }

                                                      // Also update app_backups table if present
                                                      try {
                                                        final numId = int.tryParse(restId);
                                                        final bRow = await _supabase.from('app_backups').select('settings_data').eq('rest_id', numId ?? restId).maybeSingle();
                                                        if (bRow != null && bRow['settings_data'] != null && bRow['settings_data'] is Map) {
                                                          final bData = Map<String, dynamic>.from(bRow['settings_data']);
                                                          bData['manage_table'] = newVal;
                                                          await _supabase.from('app_backups').update({'settings_data': bData}).eq('rest_id', numId ?? restId);
                                                        }
                                                      } catch (_) {}

                                                      if (context.mounted) {
                                                        ScaffoldMessenger.of(context).showSnackBar(
                                                          SnackBar(
                                                            content: Text('$restName: Table Management is now ${newVal ? "ENABLED (Floor Tables ON)" : "DISABLED (Counter Mode)"}'),
                                                            backgroundColor: newVal ? const Color(0xFF059669) : const Color(0xFF475569),
                                                            duration: const Duration(seconds: 2),
                                                          ),
                                                        );
                                                      }
                                                    } catch (e) {
                                                      _loadData();
                                                    }
                                                  },
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 10),

                                        // Quick Launch Web Admin Button
                                        Align(
                                          alignment: Alignment.centerRight,
                                          child: TextButton.icon(
                                            onPressed: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) => MainDashboardScreen(
                                                    restId: restId,
                                                    companyId: companyId,
                                                    companyRestaurants: _restaurants,
                                                  ),
                                                ),
                                              );
                                            },
                                            icon: const Icon(Icons.open_in_new_rounded, size: 15),
                                            label: const Text('Open in Web Admin Portal', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                            style: TextButton.styleFrom(foregroundColor: const Color(0xFF4F46E5)),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
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

