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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Card(
              elevation: 6,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      CircleAvatar(
                        radius: 36,
                        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                        child: Icon(
                          Icons.business_rounded,
                          size: 40,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Company Portal Login',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.indigo.shade900,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Enter Company ID & Password to access your dashboard',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                      ),
                      const SizedBox(height: 24),
                      if (_errorMessage != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(color: Colors.red, fontSize: 13),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      TextFormField(
                        controller: _companyIdController,
                        decoration: InputDecoration(
                          labelText: 'Company ID (e.g. spice)',
                          prefixIcon: const Icon(Icons.apartment),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        validator: (value) => value == null || value.isEmpty ? 'Please enter Company ID' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        validator: (value) => value == null || value.isEmpty ? 'Please enter Password' : null,
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: _isLoading
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Text('Login to Portal', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
    );
  }
}
