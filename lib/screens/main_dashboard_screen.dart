import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
  bool _isUploading = false;
  bool _hasUnsavedChanges = false;
  DateTime? _lastSyncedTime;
  String? _errorMessage;

  List<OrderModel> _orders = [];
  Map<String, dynamic> _settingsData = {};

  final timeFormatter = DateFormat('hh:mm a');

  @override
  void initState() {
    super.initState();
    _currentRestId = widget.restId;
    if (widget.companyRestaurants != null && widget.companyRestaurants!.isNotEmpty) {
      _companyRestaurants = widget.companyRestaurants!;
    }
    _fetchCompanyOutletsIfNeeded();
    _loadBackupData(isInitial: true);
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

  // Refresh data from Supabase (Sync Down)
  Future<void> _loadBackupData({bool isInitial = false}) async {
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
          _lastSyncedTime = DateTime.now();
          _hasUnsavedChanges = false;
        });

        if (!isInitial && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: const [
                  Icon(Icons.cloud_download_rounded, color: Colors.white),
                  SizedBox(width: 10),
                  Text('Data refreshed successfully from Supabase!'),
                ],
              ),
              backgroundColor: const Color(0xFF4F46E5),
              duration: const Duration(seconds: 2),
            ),
          );
        }
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

  // Save settings locally (Minimize automatic Supabase hits)
  Future<void> _handleSaveSettings(Map<String, dynamic> updatedSettings) async {
    setState(() {
      _settingsData = updatedSettings;
      _hasUnsavedChanges = true;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.edit_note_rounded, color: Colors.white),
              SizedBox(width: 10),
              Expanded(child: Text('Settings updated locally. Tap "Upload" to push to Supabase.')),
            ],
          ),
          backgroundColor: const Color(0xFFD97706),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  // Upload local changes to Supabase (Sync Up)
  Future<void> _uploadDataToSupabase() async {
    if (_isUploading) return;

    setState(() {
      _isUploading = true;
    });

    try {
      await _supabaseService.updateSettingsData(_currentRestId, _settingsData);
      await _supabaseService.updateOrdersData(_currentRestId, _orders);

      setState(() {
        _hasUnsavedChanges = false;
        _lastSyncedTime = DateTime.now();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.cloud_done_rounded, color: Colors.white),
                SizedBox(width: 10),
                Text('All updates successfully uploaded to Supabase!'),
              ],
            ),
            backgroundColor: const Color(0xFF10B981),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaWidth = MediaQuery.of(context).size.width;
    final isMobile = mediaWidth < 700;
    final isVerySmall = mediaWidth < 450;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        titleSpacing: isMobile ? 12 : 20,
        title: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4F46E5), Color(0xFF6366F1)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.restaurant_menu_rounded, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 8),
              Text(
                isVerySmall ? 'FineDine' : 'FineDine Admin',
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Color(0xFF0F172A)),
              ),
              const SizedBox(width: 10),
              // Outlet selector dropdown
              if (_companyRestaurants.length > 1) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFC7D2FE)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isDense: true,
                      value: _companyRestaurants.any((r) => r['id']?.toString() == _currentRestId)
                          ? _currentRestId
                          : _companyRestaurants.first['id']?.toString(),
                      icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF4F46E5), size: 18),
                      style: const TextStyle(
                        color: Color(0xFF4F46E5),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
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
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.storefront_rounded, size: 14, color: Color(0xFF4F46E5)),
                              const SizedBox(width: 6),
                              Text(isVerySmall ? '#$id' : '$name (ID: #$id)'),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFC7D2FE)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.storefront_rounded, size: 12, color: Color(0xFF4F46E5)),
                      const SizedBox(width: 4),
                      Text(
                        'Outlet #$_currentRestId',
                        style: const TextStyle(fontSize: 11, color: Color(0xFF4F46E5), fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
              if (_hasUnsavedChanges) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      CircleAvatar(radius: 3, backgroundColor: Color(0xFFD97706)),
                      SizedBox(width: 4),
                      Text(
                        'Unsaved',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFB45309)),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          // Refresh / Sync Down Button
          IconButton(
            icon: const Icon(Icons.sync_rounded, color: Color(0xFF4F46E5), size: 22),
            tooltip: _lastSyncedTime != null ? 'Refresh from Supabase (Synced ${timeFormatter.format(_lastSyncedTime!)})' : 'Refresh from Supabase',
            onPressed: () => _loadBackupData(),
          ),
          // Upload / Sync Up Button
          IconButton(
            icon: _isUploading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF10B981)),
                  )
                : Icon(
                    Icons.cloud_upload_rounded,
                    color: _hasUnsavedChanges ? const Color(0xFFD97706) : const Color(0xFF10B981),
                    size: 22,
                  ),
            tooltip: _hasUnsavedChanges ? 'Upload Unsaved Changes to Supabase' : 'Upload Data to Supabase',
            onPressed: _uploadDataToSupabase,
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Color(0xFF64748B), size: 20),
            tooltip: 'Sign Out',
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const CompanyLoginScreen()),
              );
            },
          ),
          SizedBox(width: isMobile ? 4 : 10),
        ],
      ),
      bottomNavigationBar: isMobile
          ? NavigationBar(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (int index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
              backgroundColor: Colors.white,
              indicatorColor: const Color(0xFFEEF2FF),
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.dashboard_outlined),
                  selectedIcon: Icon(Icons.dashboard_rounded, color: Color(0xFF4F46E5)),
                  label: 'Dashboard',
                ),
                NavigationDestination(
                  icon: Icon(Icons.receipt_long_outlined),
                  selectedIcon: Icon(Icons.receipt_long_rounded, color: Color(0xFF4F46E5)),
                  label: 'Reports',
                ),
                NavigationDestination(
                  icon: Icon(Icons.settings_outlined),
                  selectedIcon: Icon(Icons.settings_rounded, color: Color(0xFF4F46E5)),
                  label: 'Settings',
                ),
              ],
            )
          : null,
      body: Row(
        children: [
          if (!isMobile) ...[
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
          ],
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
                                onPressed: () => _loadBackupData(),
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
                            onRefresh: () => _loadBackupData(),
                          ),
                          OrderReportsView(
                            orders: _orders,
                            onRefresh: () => _loadBackupData(),
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
