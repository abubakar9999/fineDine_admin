import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'main_dashboard_screen.dart';
import 'restaurant_selection_screen.dart';
import 'admin_management_screen.dart';

class CompanyLoginScreen extends StatefulWidget {
  const CompanyLoginScreen({super.key});

  @override
  State<CompanyLoginScreen> createState() => _CompanyLoginScreenState();
}

class _CompanyLoginScreenState extends State<CompanyLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _companyIdController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final cid = _companyIdController.text.trim();
    final password = _passwordController.text.trim();

    // Check Super Admin Login (admin / admin1234)
    if (cid.toLowerCase() == 'admin' && password == 'admin1234') {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const AdminManagementScreen()),
        );
      }
      return;
    }

    try {
      final supabase = Supabase.instance.client;

      // Query restaurants by company_id or token/password
      final restResponse = await supabase
          .from('restaurants')
          .select()
          .or('company_id.eq.$cid,token.eq.$cid');

      List<Map<String, dynamic>> companyRests = List<Map<String, dynamic>>.from(restResponse);

      // Check demo fallback for 'spice'
      if (companyRests.isEmpty && cid.toLowerCase() == 'spice' && password == '1234') {
        companyRests = [
          {'id': '1001', 'name': 'Spice Garden Main Branch'},
          {'id': '1002', 'name': 'Spice & Grill Express'},
        ];
      } else if (companyRests.isEmpty && cid.toLowerCase() == 'single' && password == '1234') {
        companyRests = [
          {'id': '1001', 'name': 'Single Bistro Outlet'},
        ];
      }

      if (companyRests.isNotEmpty) {
        if (!mounted) return;

        final companyName = cid.toUpperCase();

        // If company has EXACTLY 1 restaurant, navigate DIRECTLY to dashboard
        if (companyRests.length == 1) {
          final singleRestId = companyRests.first['id']?.toString() ?? '1001';
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => MainDashboardScreen(
                restId: singleRestId,
                companyId: cid,
                companyRestaurants: companyRests,
              ),
            ),
          );
        } else {
          // If company has multiple restaurants, show selection screen or dashboard with dropdown
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => RestaurantSelectionScreen(
                companyId: cid,
                companyName: companyName,
              ),
            ),
          );
        }
        return;
      }

      setState(() {
        _errorMessage = 'Invalid Company ID or Password';
      });
    } catch (e) {
      // Fallback demo handling
      if (cid.toLowerCase() == 'spice' && password == '1234') {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => RestaurantSelectionScreen(
                companyId: 'spice',
                companyName: 'Spice Group',
              ),
            ),
          );
        }
        return;
      }

      setState(() {
        _errorMessage = 'Login failed: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _fillCredentials(String cid, String pass) {
    setState(() {
      _companyIdController.text = cid;
      _passwordController.text = pass;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1E1B4B), // Deep Indigo / Dark Slate
              Color(0xFF312E81),
              Color(0xFF4F46E5), // Vivid Indigo Accent
            ],
          ),
        ),
        child: Stack(
          children: [
            // Decorative background glowing ambient circles
            Positioned(
              top: -80,
              right: -80,
              child: Container(
                width: 320,
                height: 320,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.15),
                ),
              ),
            ),
            Positioned(
              bottom: -100,
              left: -100,
              child: Container(
                width: 380,
                height: 380,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF10B981).withValues(alpha: 0.12),
                ),
              ),
            ),
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Card(
                    elevation: 12,
                    shadowColor: Colors.black.withValues(alpha: 0.25),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                      side: BorderSide(color: Colors.white.withValues(alpha: 0.2), width: 1.5),
                    ),
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(36.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Brand Icon Header
                            Center(
                              child: Container(
                                padding: const EdgeInsets.all(18),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF4F46E5), Color(0xFF6366F1)],
                                  ),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF4F46E5).withValues(alpha: 0.4),
                                      blurRadius: 16,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.restaurant_menu_rounded,
                                  size: 40,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'FineDine Admin',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF0F172A),
                                    letterSpacing: -0.5,
                                  ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Enterprise Restaurant Portal & Analytics',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: const Color(0xFF475569),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 28),

                            // Quick Fill Demo Chips
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: const [
                                      Icon(Icons.flash_on_rounded, size: 14, color: Color(0xFF4F46E5)),
                                      SizedBox(width: 4),
                                      Text(
                                        'Quick Demo Access',
                                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 6,
                                    children: [
                                      ActionChip(
                                        avatar: const Icon(Icons.storefront_rounded, size: 14, color: Color(0xFF4F46E5)),
                                        label: const Text('Spice Group (Multi)'),
                                        onPressed: () => _fillCredentials('spice', '1234'),
                                        backgroundColor: const Color(0xFFEEF2FF),
                                        side: BorderSide.none,
                                        padding: EdgeInsets.zero,
                                      ),
                                      ActionChip(
                                        avatar: const Icon(Icons.admin_panel_settings_rounded, size: 14, color: Color(0xFF10B981)),
                                        label: const Text('Super Admin'),
                                        onPressed: () => _fillCredentials('admin', 'admin1234'),
                                        backgroundColor: const Color(0xFFECFDF5),
                                        side: BorderSide.none,
                                        padding: EdgeInsets.zero,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),

                            if (_errorMessage != null) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEF2F2),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFFFCA5A5)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.error_outline_rounded, size: 18, color: Color(0xFFEF4444)),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _errorMessage!,
                                        style: const TextStyle(color: Color(0xFFDC2626), fontSize: 13, fontWeight: FontWeight.w500),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 18),
                            ],

                            // Company ID Field
                            TextFormField(
                              controller: _companyIdController,
                              decoration: InputDecoration(
                                labelText: 'Company ID or Outlet Token',
                                hintText: 'e.g. spice',
                                prefixIcon: const Icon(Icons.apartment_rounded, color: Color(0xFF64748B)),
                              ),
                              validator: (value) => value == null || value.trim().isEmpty ? 'Please enter Company ID' : null,
                            ),
                            const SizedBox(height: 16),

                            // Password Field
                            TextFormField(
                              controller: _passwordController,
                              obscureText: true,
                              decoration: InputDecoration(
                                labelText: 'Password / Security PIN',
                                hintText: '••••••••',
                                prefixIcon: const Icon(Icons.lock_outline_rounded, color: Color(0xFF64748B)),
                              ),
                              validator: (value) => value == null || value.trim().isEmpty ? 'Please enter Password' : null,
                            ),
                            const SizedBox(height: 28),

                            // Login Action Button
                            SizedBox(
                              height: 52,
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14),
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF4F46E5), Color(0xFF6366F1)],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF4F46E5).withValues(alpha: 0.35),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _login,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                  ),
                                  child: _isLoading
                                      ? const SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                                        )
                                      : FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: const [
                                              Text(
                                                'Sign In to Dashboard',
                                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                                              ),
                                              SizedBox(width: 8),
                                              Icon(Icons.arrow_forward_rounded, size: 20, color: Colors.white),
                                            ],
                                          ),
                                        ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

