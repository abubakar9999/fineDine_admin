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
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        titleSpacing: 20,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4F46E5), Color(0xFF6366F1)],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.restaurant_menu_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            const Text(
              'FineDine Admin',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Color(0xFF0F172A)),
            ),
            const SizedBox(width: 16),
            // Show Dropdown ONLY if company has multiple restaurants (> 1)
            if (_companyRestaurants.length > 1) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFC7D2FE)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _companyRestaurants.any((r) => r['id']?.toString() == _currentRestId)
                        ? _currentRestId
                        : _companyRestaurants.first['id']?.toString(),
                    icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF4F46E5)),
                    style: const TextStyle(
                      color: Color(0xFF4F46E5),
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
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
                            const Icon(Icons.storefront_rounded, size: 16, color: Color(0xFF4F46E5)),
                            const SizedBox(width: 8),
                            Text('$name (ID: #$id)'),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ] else ...[
              // Simple outlet tag
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFC7D2FE)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.storefront_rounded, size: 14, color: Color(0xFF4F46E5)),
                    const SizedBox(width: 6),
                    Text(
                      'Outlet #$_currentRestId',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF4F46E5), fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
            const Spacer(),
            // Live Syncing Chip
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFA7F3D0)),
              ),
              child: Row(
                children: const [
                  CircleAvatar(radius: 4, backgroundColor: Color(0xFF10B981)),
                  SizedBox(width: 6),
                  Text(
                    'Live Supabase Sync',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF047857)),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Color(0xFF64748B)),
            tooltip: 'Sign Out Company Portal',
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const CompanyLoginScreen()),
              );
            },
          ),
          const SizedBox(width: 12),
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
            leading: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20.0),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFC7D2FE)),
                ),
                child: const Icon(Icons.admin_panel_settings_rounded, color: Color(0xFF4F46E5), size: 22),
              ),
            ),
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard_rounded),
                label: Text('Dashboard'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.receipt_long_outlined),
                selectedIcon: Icon(Icons.receipt_long_rounded),
                label: Text('Reports'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings_rounded),
                label: Text('Settings'),
              ),
            ],
          ),
          const VerticalDivider(thickness: 1, width: 1, color: Color(0xFFE2E8F0)),
          // Main Body Content
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF4F46E5)),
                  )
                : _errorMessage != null
                    ? Center(
                        child: Container(
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFFCA5A5)),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error_outline_rounded, size: 48, color: Color(0xFFEF4444)),
                              const SizedBox(height: 16),
                              Text(_errorMessage!, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: _loadBackupData,
                                icon: const Icon(Icons.refresh_rounded),
                                label: const Text('Retry Connection'),
                              ),
                            ],
                          ),
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

