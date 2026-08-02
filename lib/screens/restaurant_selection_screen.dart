import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'main_dashboard_screen.dart';
import 'company_login_screen.dart';

class RestaurantSelectionScreen extends StatefulWidget {
  final String companyId;
  final String companyName;

  const RestaurantSelectionScreen({
    super.key,
    required this.companyId,
    required this.companyName,
  });

  @override
  State<RestaurantSelectionScreen> createState() => _RestaurantSelectionScreenState();
}

class _RestaurantSelectionScreenState extends State<RestaurantSelectionScreen> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _restaurants = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCompanyRestaurants();
  }

  Future<void> _fetchCompanyRestaurants() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Fetch restaurants belonging to this company_id
      final response = await _supabase
          .from('restaurants')
          .select()
          .or('company_id.eq.${widget.companyId},token.eq.${widget.companyId}');

      final list = List<Map<String, dynamic>>.from(response);

      // If no database match found yet for demo, provide fallback mock restaurants for 'spice'
      if (list.isEmpty && widget.companyId.toLowerCase() == 'spice') {
        setState(() {
          _restaurants = [
            {
              'id': '1001',
              'name': 'Spice Garden Main Branch',
              'address': 'Downtown St 102',
              'mobile': '+1 234-567-890',
              'is_active': true,
            },
            {
              'id': '1002',
              'name': 'Spice & Grill Express',
              'address': 'Westside Plaza, Floor 2',
              'mobile': '+1 987-654-321',
              'is_active': true,
            },
          ];
        });
      } else {
        setState(() {
          _restaurants = list;
        });
      }
    } catch (e) {
      // Fallback for demo mode if column doesn't exist yet
      if (widget.companyId.toLowerCase() == 'spice') {
        setState(() {
          _restaurants = [
            {
              'id': '1001',
              'name': 'Spice Garden Main Branch',
              'address': 'Downtown St 102',
              'mobile': '+1 234-567-890',
              'is_active': true,
            },
            {
              'id': '1002',
              'name': 'Spice & Grill Express',
              'address': 'Westside Plaza, Floor 2',
              'mobile': '+1 987-654-321',
              'is_active': true,
            },
          ];
        });
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading restaurants: $e')));
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
        title: Text('${widget.companyName} - Outlets', style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout Company',
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const CompanyLoginScreen()),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select a Restaurant Branch',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.indigo.shade900,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Company ID: ${widget.companyId} • Found ${_restaurants.length} outlet(s)',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: _restaurants.isEmpty
                        ? const Center(child: Text('No restaurant outlets found under this company.'))
                        : GridView.builder(
                            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: 400,
                              mainAxisExtent: 180,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                            ),
                            itemCount: _restaurants.length,
                            itemBuilder: (context, index) {
                              final r = _restaurants[index];
                              final String restId = r['id']?.toString() ?? '1001';
                              final String name = r['name'] ?? 'Restaurant #$restId';
                              final String address = r['address'] ?? 'No address provided';

                              return Card(
                                elevation: 4,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(16),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => MainDashboardScreen(restId: restId),
                                      ),
                                    );
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(20.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            CircleAvatar(
                                              backgroundColor: Colors.indigo.shade100,
                                              child: Icon(Icons.storefront, color: Colors.indigo.shade800),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    name,
                                                    style: const TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 16,
                                                    ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                  Text(
                                                    'Rest ID: $restId',
                                                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        Text(
                                          address,
                                          style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.end,
                                          children: const [
                                            Text(
                                              'Open Dashboard',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.indigo,
                                              ),
                                            ),
                                            SizedBox(width: 4),
                                            Icon(Icons.arrow_forward, size: 16, color: Colors.indigo),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }
}
