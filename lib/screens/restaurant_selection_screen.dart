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
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFEEF2FF),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFC7D2FE)),
              ),
              child: Text(
                widget.companyName,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF4F46E5)),
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'Outlet Selection Portal',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF0F172A)),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Color(0xFF64748B)),
            tooltip: 'Sign Out Company',
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
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF4F46E5)),
            )
          : Padding(
              padding: const EdgeInsets.all(28.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Select Restaurant Branch',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Company ID: ${widget.companyId} • Found ${_restaurants.length} active outlet(s)',
                            style: const TextStyle(color: Color(0xFF64748B), fontSize: 14),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  Expanded(
                    child: _restaurants.isEmpty
                        ? Center(
                            child: Container(
                              padding: const EdgeInsets.all(32),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Icon(Icons.storefront_outlined, size: 48, color: Color(0xFF94A3B8)),
                                  SizedBox(height: 12),
                                  Text(
                                    'No Outlets Available',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                                  ),
                                  SizedBox(height: 4),
                                  Text('No active restaurant branches found for this company account.', style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                                ],
                              ),
                            ),
                          )
                        : GridView.builder(
                            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: 440,
                              mainAxisExtent: 200,
                              crossAxisSpacing: 20,
                              mainAxisSpacing: 20,
                            ),
                            itemCount: _restaurants.length,
                            itemBuilder: (context, index) {
                              final r = _restaurants[index];
                              final String restId = r['id']?.toString() ?? '1001';
                              final String name = r['name'] ?? 'Restaurant #$restId';
                              final String address = r['address'] ?? 'No address listed';
                              final String mobile = r['mobile'] ?? r['phone'] ?? '+1 (555) 019-2831';

                              return Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: const Color(0xFFE2E8F0)),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.04),
                                      blurRadius: 14,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(20),
                                  onTap: () {
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => MainDashboardScreen(
                                          restId: restId,
                                          companyId: widget.companyId,
                                          companyRestaurants: _restaurants,
                                        ),
                                      ),
                                    );
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(22.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(12),
                                              decoration: BoxDecoration(
                                                gradient: const LinearGradient(
                                                  colors: [Color(0xFF4F46E5), Color(0xFF6366F1)],
                                                ),
                                                borderRadius: BorderRadius.circular(14),
                                              ),
                                              child: const Icon(Icons.storefront_rounded, color: Colors.white, size: 26),
                                            ),
                                            const SizedBox(width: 14),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Expanded(
                                                        child: Text(
                                                          name,
                                                          style: const TextStyle(
                                                            fontWeight: FontWeight.bold,
                                                            fontSize: 16,
                                                            color: Color(0xFF0F172A),
                                                          ),
                                                          maxLines: 1,
                                                          overflow: TextOverflow.ellipsis,
                                                        ),
                                                      ),
                                                      Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                        decoration: BoxDecoration(
                                                          color: const Color(0xFFECFDF5),
                                                          borderRadius: BorderRadius.circular(6),
                                                          border: Border.all(color: const Color(0xFFA7F3D0)),
                                                        ),
                                                        child: Row(
                                                          mainAxisSize: MainAxisSize.min,
                                                          children: const [
                                                            CircleAvatar(radius: 3, backgroundColor: Color(0xFF10B981)),
                                                            SizedBox(width: 4),
                                                            Text(
                                                              'Active',
                                                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF047857)),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    'Outlet ID: #$restId',
                                                    style: const TextStyle(color: Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.w500),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                const Icon(Icons.location_on_outlined, size: 14, color: Color(0xFF94A3B8)),
                                                const SizedBox(width: 4),
                                                Expanded(
                                                  child: Text(
                                                    address,
                                                    style: const TextStyle(color: Color(0xFF475569), fontSize: 12),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                const Icon(Icons.phone_outlined, size: 14, color: Color(0xFF94A3B8)),
                                                const SizedBox(width: 4),
                                                Text(
                                                  mobile,
                                                  style: const TextStyle(color: Color(0xFF475569), fontSize: 12),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.end,
                                          children: const [
                                            Text(
                                              'Launch Dashboard',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13,
                                                color: Color(0xFF4F46E5),
                                              ),
                                            ),
                                            SizedBox(width: 4),
                                            Icon(Icons.arrow_forward_rounded, size: 16, color: Color(0xFF4F46E5)),
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

