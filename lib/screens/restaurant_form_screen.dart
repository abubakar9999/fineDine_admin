import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RestaurantFormScreen extends StatefulWidget {
  final Map<String, dynamic>? restaurant;

  const RestaurantFormScreen({super.key, this.restaurant});

  @override
  State<RestaurantFormScreen> createState() => _RestaurantFormScreenState();
}

class _RestaurantFormScreenState extends State<RestaurantFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _idController = TextEditingController();
  final _nameController = TextEditingController();
  final _ownerNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _mobileController = TextEditingController();
  final _currencyController = TextEditingController(text: 'USD');
  final _tokenController = TextEditingController();
  final _companyIdController = TextEditingController(text: 'spice');

  bool _isLoading = false;
  bool _isActive = true;
  bool _manageTable = true;
  bool get _isEditMode => widget.restaurant != null;

  @override
  void initState() {
    super.initState();
    if (_isEditMode) {
      final r = widget.restaurant!;
      _idController.text = r['id']?.toString() ?? '';
      _nameController.text = r['name'] ?? '';
      _ownerNameController.text = r['owner_name'] ?? '';
      _addressController.text = r['address'] ?? '';
      _emailController.text = r['email'] ?? '';
      _passwordController.text = r['password'] ?? '';
      _mobileController.text = r['mobile'] ?? '';
      _currencyController.text = r['currency'] ?? 'USD';
      _tokenController.text = r['token'] ?? '';
      _companyIdController.text = r['company_id'] ?? 'spice';
      _isActive = r['is_active'] ?? true;
      _manageTable = r['manage_table'] ?? true;
    }
  }

  @override
  void dispose() {
    _idController.dispose();
    _nameController.dispose();
    _ownerNameController.dispose();
    _addressController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _mobileController.dispose();
    _currencyController.dispose();
    _tokenController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final supabase = Supabase.instance.client;
      final data = {
        'id': int.tryParse(_idController.text.trim()),
        'name': _nameController.text.trim(),
        'owner_name': _ownerNameController.text.trim(),
        'address': _addressController.text.trim(),
        'email': _emailController.text.trim(),
        'password': _passwordController.text.trim(),
        'mobile': _mobileController.text.trim(),
        'currency': _currencyController.text.trim(),
        'token': _tokenController.text.trim(),
        'company_id': _companyIdController.text.trim().toLowerCase(),
        'is_active': _isActive,
        'manage_table': _manageTable,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (_isEditMode) {
        await supabase.from('restaurants').update(data).eq('id', widget.restaurant!['id']);
      } else {
        data['role'] = 'Owner';
        data['created_at'] = DateTime.now().toIso8601String();
        await supabase.from('restaurants').insert(data);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_isEditMode ? 'Restaurant updated successfully!' : 'Restaurant added successfully!'), backgroundColor: Colors.green));
        Navigator.pop(context, true); // Return true to signal the list to refresh
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
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
      appBar: AppBar(
        title: Text(_isEditMode ? 'Edit Restaurant' : 'Add Restaurant', style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _isEditMode ? 'Update Details' : 'New Restaurant Entry',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      _buildTextField(
                        controller: _idController,
                        label: 'Restaurant ID',
                        icon: Icons.numbers,
                        keyboardType: TextInputType.number,
                        readOnly: _isEditMode,
                        validator: (value) => value == null || value.isEmpty ? 'Required' : (int.tryParse(value) == null ? 'Must be a number' : null),
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(controller: _nameController, label: 'Restaurant Name', icon: Icons.restaurant, validator: (value) => value == null || value.isEmpty ? 'Required' : null),
                      const SizedBox(height: 16),
                      _buildTextField(controller: _ownerNameController, label: 'Owner Name', icon: Icons.person, validator: (value) => value == null || value.isEmpty ? 'Required' : null),
                      const SizedBox(height: 16),
                      _buildTextField(controller: _addressController, label: 'Address', icon: Icons.location_on, maxLines: 2, validator: (value) => value == null || value.isEmpty ? 'Required' : null),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _emailController,
                        label: 'Email',
                        icon: Icons.email,
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Required';
                          if (!value.contains('@')) return 'Invalid email';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(controller: _passwordController, label: 'Password', icon: Icons.lock, obscureText: true, validator: (value) => value == null || value.isEmpty ? 'Required' : null),
                      const SizedBox(height: 16),
                      _buildTextField(controller: _mobileController, label: 'Mobile', icon: Icons.phone, keyboardType: TextInputType.phone, validator: (value) => value == null || value.isEmpty ? 'Required' : null),
                      const SizedBox(height: 16),
                      _buildTextField(controller: _currencyController, label: 'Currency', icon: Icons.attach_money, validator: (value) => value == null || value.isEmpty ? 'Required' : null),
                      const SizedBox(height: 16),
                      _buildTextField(controller: _tokenController, label: 'Token', icon: Icons.vpn_key, validator: (value) => value == null || value.isEmpty ? 'Required' : null),
                      const SizedBox(height: 16),
                      _buildTextField(controller: _companyIdController, label: 'Company ID (e.g. spice)', icon: Icons.apartment, validator: (value) => value == null || value.isEmpty ? 'Required' : null),
                      const SizedBox(height: 18),
                      // Table Management Switch Card
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: _manageTable ? const Color(0xFFEEF2FF) : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: _manageTable ? const Color(0xFFC7D2FE) : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: SwitchListTile(
                          title: Row(
                            children: [
                              const Text('Table Management (manage_table)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: _manageTable ? const Color(0xFF10B981) : const Color(0xFF94A3B8),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  _manageTable ? 'ON' : 'OFF',
                                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          subtitle: Text(
                            _manageTable
                                ? 'Enabled: POS allows assigning tables, floor plans & guest seating'
                                : 'Disabled: POS operates in direct counter / fast takeaway mode without tables',
                            style: TextStyle(fontSize: 12, color: Colors.blueGrey.shade600),
                          ),
                          value: _manageTable,
                          onChanged: (bool value) {
                            setState(() {
                              _manageTable = value;
                            });
                          },
                          secondary: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: _manageTable ? const Color(0xFF4F46E5) : const Color(0xFFCBD5E1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.table_restaurant_rounded, color: Colors.white, size: 20),
                          ),
                          contentPadding: EdgeInsets.zero,
                          activeColor: const Color(0xFF4F46E5),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Is Active Switch Card
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: _isActive ? const Color(0xFFECFDF5) : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: _isActive ? const Color(0xFFA7F3D0) : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: SwitchListTile(
                          title: Row(
                            children: [
                              const Text('Restaurant Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: _isActive ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  _isActive ? 'ACTIVE' : 'INACTIVE',
                                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          subtitle: Text(
                            _isActive ? 'Outlet is active and accessible' : 'Outlet is suspended/hidden',
                            style: TextStyle(fontSize: 12, color: Colors.blueGrey.shade600),
                          ),
                          value: _isActive,
                          onChanged: (bool value) {
                            setState(() {
                              _isActive = value;
                            });
                          },
                          secondary: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: _isActive ? const Color(0xFF10B981) : const Color(0xFFCBD5E1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                          ),
                          contentPadding: EdgeInsets.zero,
                          activeColor: const Color(0xFF10B981),
                        ),
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        height: 54,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _submitForm,
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            foregroundColor: Theme.of(context).colorScheme.onPrimary,
                          ),
                          child: _isLoading ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : Text(_isEditMode ? 'Save Changes' : 'Add Restaurant', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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

  Widget _buildTextField({required TextEditingController controller, required String label, required IconData icon, bool obscureText = false, bool readOnly = false, int maxLines = 1, TextInputType? keyboardType, String? Function(String?)? validator}) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      obscureText: obscureText,
      maxLines: obscureText ? 1 : maxLines,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
        ),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
      ),
    );
  }
}
