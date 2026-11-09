import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';
import '../models/order_model.dart';
import 'dashboard_view.dart';
import 'order_reports_view.dart';
import 'settings_view.dart';
import 'company_login_screen.dart';
import 'admin_management_screen.dart';

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
  bool _isSidebarCollapsed = false;
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
          _orders = [];
          _settingsData = {};
          _lastSyncedTime = DateTime.now();
          _hasUnsavedChanges = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: const [
                  Icon(Icons.info_outline_rounded, color: Colors.white),
                  SizedBox(width: 10),
                  Text('No existing data found for outlet. Starting fresh.'),
                ],
              ),
              backgroundColor: const Color(0xFFD97706),
              duration: const Duration(seconds: 3),
            ),
          );
        }
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

  // Save settings and sync to Supabase automatically
  Future<void> _handleSaveSettings(Map<String, dynamic> updatedSettings) async {
    setState(() {
      _settingsData = updatedSettings;
      _hasUnsavedChanges = false;
    });

    try {
      await _supabaseService.updateSettingsData(_currentRestId, updatedSettings);
      setState(() {
        _lastSyncedTime = DateTime.now();
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.cloud_done_rounded, color: Colors.white),
                SizedBox(width: 10),
                Expanded(child: Text('Settings saved & synced to Supabase successfully!')),
              ],
            ),
            backgroundColor: Color(0xFF10B981),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _hasUnsavedChanges = true;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Saved locally, but cloud sync pending: $e. Tap Upload to retry.'),
            backgroundColor: const Color(0xFFD97706),
            duration: const Duration(seconds: 4),
          ),
        );
      }
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

  String get _currentTabTitle {
    switch (_selectedIndex) {
      case 0:
        return 'Executive Overview';
      case 1:
        return 'Reports & Analytics';
      case 2:
        return 'Menu & Store Settings';
      default:
        return 'Dashboard';
    }
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.logout_rounded, color: Color(0xFFEF4444)),
            SizedBox(width: 10),
            Text('Sign Out', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: const Text('Are you sure you want to sign out of FineDine Admin?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const CompanyLoginScreen()),
              );
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaWidth = MediaQuery.of(context).size.width;
    final isMobile = mediaWidth < 800;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      // Mobile Top AppBar
      appBar: isMobile
          ? AppBar(
              titleSpacing: 16,
              title: Row(
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
                  const SizedBox(width: 10),
                  Text(
                    _currentTabTitle,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Color(0xFF0F172A)),
                  ),
                ],
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh_rounded, color: Color(0xFF4F46E5), size: 22),
                  tooltip: 'Refresh',
                  onPressed: () => _loadBackupData(),
                ),
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
                  tooltip: 'Sync Up',
                  onPressed: _uploadDataToSupabase,
                ),
                IconButton(
                  icon: const Icon(Icons.logout_rounded, color: Color(0xFF64748B), size: 20),
                  tooltip: 'Sign Out',
                  onPressed: _showLogoutDialog,
                ),
                const SizedBox(width: 8),
              ],
            )
          : null,
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
                  icon: Icon(Icons.bar_chart_rounded),
                  selectedIcon: Icon(Icons.bar_chart_rounded, color: Color(0xFF4F46E5)),
                  label: 'Reports',
                ),
                NavigationDestination(
                  icon: Icon(Icons.tune_rounded),
                  selectedIcon: Icon(Icons.tune_rounded, color: Color(0xFF4F46E5)),
                  label: 'Settings',
                ),
              ],
            )
          : null,
      body: Row(
        children: [
          // Desktop Modern SaaS Collapsible Sidebar
          if (!isMobile) _buildModernSidebar(),

          // Main Screen Content Area
          Expanded(
            child: Column(
              children: [
                // Desktop Header Bar with Breadcrumbs & Sync Controls
                if (!isMobile) _buildDesktopHeaderBar(),

                // Content View
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
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.red.withValues(alpha: 0.05),
                                      blurRadius: 20,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.error_outline_rounded, size: 48, color: Color(0xFFEF4444)),
                                    const SizedBox(height: 16),
                                    Text(
                                      _errorMessage!,
                                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                                      textAlign: TextAlign.center,
                                    ),
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
                                  onNavigateTab: (tabIndex) {
                                    setState(() {
                                      _selectedIndex = tabIndex;
                                    });
                                  },
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
          ),
        ],
      ),
    );
  }

  // --- MODERN SAAS COLLAPSIBLE SIDEBAR ---
  Widget _buildModernSidebar() {
    final double sidebarWidth = _isSidebarCollapsed ? 80 : 260;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeInOutCubic,
      width: sidebarWidth,
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(
          right: BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.02),
            blurRadius: 16,
            offset: const Offset(4, 0),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sidebar Top Brand Emblem
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: _isSidebarCollapsed ? 12 : 16,
              vertical: 20,
            ),
            child: _isSidebarCollapsed
                ? Center(
                    child: IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF4F46E5), Color(0xFF6366F1)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF4F46E5).withValues(alpha: 0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.restaurant_menu_rounded, color: Colors.white, size: 20),
                      ),
                      tooltip: 'Expand Sidebar',
                      onPressed: () {
                        setState(() {
                          _isSidebarCollapsed = false;
                        });
                      },
                    ),
                  )
                : Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF4F46E5), Color(0xFF6366F1)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF4F46E5).withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.restaurant_menu_rounded, color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'FineDine',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF0F172A),
                                letterSpacing: -0.5,
                              ),
                            ),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEEF2FF),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'CLOUD PRO',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF4F46E5),
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.menu_open_rounded,
                          color: Color(0xFF94A3B8),
                          size: 20,
                        ),
                        tooltip: 'Collapse Sidebar',
                        onPressed: () {
                          setState(() {
                            _isSidebarCollapsed = true;
                          });
                        },
                      ),
                    ],
                  ),
          ),

          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 12),

          // Outlet Switcher Widget inside sidebar
          if (!_isSidebarCollapsed) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        CircleAvatar(radius: 3, backgroundColor: Color(0xFF10B981)),
                        SizedBox(width: 6),
                        Text(
                          'ACTIVE OUTLET',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF64748B),
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    if (_companyRestaurants.length > 1) ...[
                      DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          isDense: true,
                          value: _companyRestaurants.any((r) => r['id']?.toString() == _currentRestId)
                              ? _currentRestId
                              : _companyRestaurants.first['id']?.toString(),
                          icon: const Icon(Icons.swap_horiz_rounded, color: Color(0xFF4F46E5), size: 18),
                          style: const TextStyle(
                            color: Color(0xFF0F172A),
                            fontWeight: FontWeight.w700,
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
                              child: Text(
                                '$name (#$id)',
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ] else ...[
                      Text(
                        'Store #$_currentRestId',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ],
                    Builder(builder: (context) {
                      final bool isTableOn = _settingsData['manage_table'] != false;
                      return Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isTableOn ? const Color(0xFFECFDF5) : const Color(0xFFEEF2FF),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: isTableOn ? const Color(0xFFA7F3D0) : const Color(0xFFC7D2FE)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isTableOn ? Icons.table_restaurant_rounded : Icons.point_of_sale_rounded,
                              size: 11,
                              color: isTableOn ? const Color(0xFF059669) : const Color(0xFF4F46E5),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isTableOn ? 'Tables Active' : 'Counter Mode',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isTableOn ? const Color(0xFF065F46) : const Color(0xFF4338CA),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Navigation Section Label
          if (!_isSidebarCollapsed)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              child: Text(
                'MAIN MENU',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF94A3B8),
                  letterSpacing: 1.0,
                ),
              ),
            ),

          // Navigation Items
          _buildSidebarNavItem(
            index: 0,
            title: 'Dashboard',
            icon: Icons.dashboard_rounded,
            badgeText: 'Live',
            badgeColor: const Color(0xFF10B981),
          ),
          _buildSidebarNavItem(
            index: 1,
            title: 'Reports & Analytics',
            icon: Icons.bar_chart_rounded,
            badgeText: _orders.isNotEmpty ? '${_orders.length}' : null,
            badgeColor: const Color(0xFF4F46E5),
          ),
          _buildSidebarNavItem(
            index: 2,
            title: 'Menu & Settings',
            icon: Icons.tune_rounded,
          ),

          // Super Admin & Outlets Portal Button
          Padding(
            padding: EdgeInsets.symmetric(horizontal: _isSidebarCollapsed ? 8 : 12, vertical: 4),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AdminManagementScreen()),
                );
                _loadBackupData();
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: _isSidebarCollapsed ? 8 : 12, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF2FF),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.admin_panel_settings_rounded, color: Color(0xFF4F46E5), size: 18),
                    ),
                    if (!_isSidebarCollapsed) ...[
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Super Admin Outlets',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios_rounded, size: 11, color: Color(0xFF94A3B8)),
                    ],
                  ],
                ),
              ),
            ),
          ),

          const Spacer(),

          // Live Cloud Sync Status Widget
          if (!_isSidebarCollapsed) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _hasUnsavedChanges ? const Color(0xFFFEF3C7) : const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _hasUnsavedChanges ? const Color(0xFFFDE68A) : const Color(0xFFBBF7D0),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 4,
                          backgroundColor: _hasUnsavedChanges ? const Color(0xFFD97706) : const Color(0xFF16A34A),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _hasUnsavedChanges ? 'Unsaved Local Data' : 'Supabase Cloud Live',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: _hasUnsavedChanges ? const Color(0xFF92400E) : const Color(0xFF166534),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _lastSyncedTime != null ? 'Synced ${timeFormatter.format(_lastSyncedTime!)}' : 'Connecting...',
                      style: TextStyle(
                        fontSize: 11,
                        color: _hasUnsavedChanges ? const Color(0xFFB45309) : const Color(0xFF15803D),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],

          const Divider(height: 1, color: Color(0xFFF1F5F9)),

          // User Profile Strip at Bottom
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: _isSidebarCollapsed ? 12 : 16,
              vertical: 16,
            ),
            child: _isSidebarCollapsed
                ? Center(
                    child: InkWell(
                      onTap: _showLogoutDialog,
                      borderRadius: BorderRadius.circular(19),
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF4F46E5), Color(0xFF6366F1)],
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF4F46E5).withValues(alpha: 0.2),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Text(
                            'A',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16),
                          ),
                        ),
                      ),
                    ),
                  )
                : Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF4F46E5), Color(0xFF6366F1)],
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF4F46E5).withValues(alpha: 0.2),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Text(
                            'A',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Store Admin',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'ID #$_currentRestId',
                              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.logout_rounded, color: Color(0xFF94A3B8), size: 18),
                        tooltip: 'Sign Out',
                        onPressed: _showLogoutDialog,
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarNavItem({
    required int index,
    required String title,
    required IconData icon,
    String? badgeText,
    Color? badgeColor,
  }) {
    final bool isSelected = _selectedIndex == index;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedIndex = index;
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: _isSidebarCollapsed ? 12 : 14,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFEEF2FF) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: _isSidebarCollapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFF64748B),
              ),
              if (!_isSidebarCollapsed) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                      color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFF334155),
                    ),
                  ),
                ),
                if (badgeText != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: (badgeColor ?? const Color(0xFF4F46E5)).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      badgeText,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: badgeColor ?? const Color(0xFF4F46E5),
                      ),
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  // --- DESKTOP TOP HEADER BAR ---
  Widget _buildDesktopHeaderBar() {
    return Container(
      height: 68,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Breadcrumbs (Scrollable if narrow)
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  const Icon(Icons.storefront_rounded, size: 18, color: Color(0xFF94A3B8)),
                  const SizedBox(width: 8),
                  const Text(
                    'FineDine Cloud',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text('/', style: TextStyle(fontSize: 14, color: Color(0xFFCBD5E1))),
                  ),
                  Text(
                    _currentTabTitle,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Header Right Controls
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Live Sync Status Chip
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _hasUnsavedChanges ? const Color(0xFFFEF3C7) : const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _hasUnsavedChanges ? const Color(0xFFFDE68A) : const Color(0xFFA7F3D0),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 3.5,
                      backgroundColor: _hasUnsavedChanges ? const Color(0xFFD97706) : const Color(0xFF10B981),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _hasUnsavedChanges ? 'Pending Upload' : 'Supabase Synced',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _hasUnsavedChanges ? const Color(0xFF92400E) : const Color(0xFF065F46),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),

              // Sync Down / Refresh Button
              OutlinedButton.icon(
                onPressed: () => _loadBackupData(),
                icon: const Icon(Icons.sync_rounded, size: 16),
                label: const Text('Sync Down'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  side: const BorderSide(color: Color(0xFFCBD5E1)),
                ),
              ),
              const SizedBox(width: 10),

              // Sync Up / Upload Button
              ElevatedButton.icon(
                onPressed: _uploadDataToSupabase,
                icon: _isUploading
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.cloud_upload_rounded, size: 16),
                label: Text(_isUploading ? 'Uploading...' : 'Sync Up'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _hasUnsavedChanges ? const Color(0xFFD97706) : const Color(0xFF10B981),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
