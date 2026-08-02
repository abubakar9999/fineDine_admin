import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';
import '../models/order_model.dart';
import 'dashboard_view.dart';
import 'order_reports_view.dart';
import 'settings_view.dart';
import 'company_login_screen.dart';

class MainDashboardScreen extends StatefulWidget {
  final String restId;
  final String? companyId;
  final List<Map<String, dynamic>>? companyRestaurants;

  const MainDashboardScreen({
    super.key,
    this.restId = '1001',
    this.companyId,
    this.companyRestaurants,
  });

  @override
  State<MainDashboardScreen> createState() => _MainDashboardScreenState();
}

class _MainDashboardScreenState extends State<MainDashboardScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  late String _currentRestId;
  List<Map<String, dynamic>> _companyRestaurants = [];

  int _selectedIndex = 0;
  bool _isLoading = true;
  String? _errorMessage;

  List<OrderModel> _orders = [];
  Map<String, dynamic> _settingsData = {};

  @override
  void initState() {
    super.initState();
    _currentRestId = widget.restId;
    if (widget.companyRestaurants != null && widget.companyRestaurants!.isNotEmpty) {
      _companyRestaurants = widget.companyRestaurants!;
    }
    _fetchCompanyOutletsIfNeeded();
    _loadBackupData();
  }

  Future<void> _fetchCompanyOutletsIfNeeded() async {
    if (_companyRestaurants.isNotEmpty || widget.companyId == null) return;

    try {
      final supabase = Supabase.instance.client;
      final response = await supabase
          .from('restaurants')
          .select()
          .or('company_id.eq.${widget.companyId},token.eq.${widget.companyId}');

      final list = List<Map<String, dynamic>>.from(response);
      if (list.isNotEmpty && mounted) {
        setState(() {
          _companyRestaurants = list;
        });
      }
    } catch (_) {
      // Fallback for demo mode
      if (widget.companyId?.toLowerCase() == 'spice' && mounted) {
        setState(() {
          _companyRestaurants = [
            {'id': '1001', 'name': 'Spice Garden Main Branch'},
            {'id': '1002', 'name': 'Spice & Grill Express'},
          ];
        });
      }
    }
  }

  Future<void> _loadBackupData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final backup = await _supabaseService.fetchBackupByRestId(_currentRestId);
      if (backup != null) {
        final parsedOrders = _supabaseService.parseOrders(backup['orders_data']);
        final parsedSettings = _supabaseService.parseSettings(backup['settings_data']);

        setState(() {
          _orders = parsedOrders;
          _settingsData = parsedSettings;
        });
      } else {
        setState(() {
          _errorMessage = 'No backup record found for Rest ID: $_currentRestId';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading backup data: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _handleSaveSettings(Map<String, dynamic> updatedSettings) async {
    try {
      await _supabaseService.updateSettingsData(_currentRestId, updatedSettings);
      setState(() {
        _settingsData = updatedSettings;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save settings: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text(
              'FineDine Admin',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 16),
            // Show Dropdown ONLY if company has multiple restaurants (> 1)
            if (_companyRestaurants.length > 1) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.indigo.shade200),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _companyRestaurants.any((r) => r['id']?.toString() == _currentRestId)
                        ? _currentRestId
                        : _companyRestaurants.first['id']?.toString(),
                    icon: const Icon(Icons.arrow_drop_down, color: Colors.indigo),
                    style: const TextStyle(
                      color: Colors.indigo,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    onChanged: (String? newRestId) {
                      if (newRestId != null && newRestId != _currentRestId) {
                        setState(() {
                          _currentRestId = newRestId;
                        });
                        _loadBackupData();
                      }
                    },
                    items: _companyRestaurants.map((r) {
                      final id = r['id']?.toString() ?? '';
                      final name = r['name'] ?? 'Restaurant #$id';
                      return DropdownMenuItem<String>(
                        value: id,
                        child: Row(
                          children: [
                            const Icon(Icons.storefront, size: 18, color: Colors.indigo),
                            const SizedBox(width: 8),
                            Text('$name (ID: $id)'),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ] else ...[
              // Display simple tag if only 1 restaurant or no company dropdown
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.indigo.shade50,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Outlet ID: $_currentRestId',
                  style: TextStyle(fontSize: 13, color: Colors.indigo.shade800, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout Company Portal',
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const CompanyLoginScreen()),
              );
            },
          ),
        ],
      ),
      body: Row(
        children: [
          // Sidebar / Navigation Rail
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (int index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            labelType: NavigationRailLabelType.all,
            leading: const Padding(
              padding: EdgeInsets.symmetric(vertical: 16.0),
              child: CircleAvatar(
                radius: 20,
                backgroundColor: Colors.indigo,
                child: Icon(Icons.admin_panel_settings, color: Colors.white),
              ),
            ),
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard),
                label: Text('Dashboard'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.receipt_long_outlined),
                selectedIcon: Icon(Icons.receipt_long),
                label: Text('Reports'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings),
                label: Text('Settings'),
              ),
            ],
          ),
          const VerticalDivider(thickness: 1, width: 1),
          // Main Body Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline, size: 48, color: Colors.red),
                            const SizedBox(height: 16),
                            Text(_errorMessage!, style: const TextStyle(fontSize: 16)),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadBackupData,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : IndexedStack(
                        index: _selectedIndex,
                        children: [
                          DashboardView(
                            orders: _orders,
                            settingsData: _settingsData,
                            onRefresh: _loadBackupData,
                          ),
                          OrderReportsView(
                            orders: _orders,
                            onRefresh: _loadBackupData,
                          ),
                          SettingsView(
                            settingsData: _settingsData,
                            restId: _currentRestId,
                            onSaveSettings: _handleSaveSettings,
                          ),
                        ],
                      ),
          ),
        ],
      ),
    );
  }
}
