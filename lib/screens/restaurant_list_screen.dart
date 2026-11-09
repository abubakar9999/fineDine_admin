import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'restaurant_form_screen.dart';

class RestaurantListScreen extends StatefulWidget {
  const RestaurantListScreen({super.key});

  @override
  State<RestaurantListScreen> createState() => _RestaurantListScreenState();
}

class _RestaurantListScreenState extends State<RestaurantListScreen> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _restaurants = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchRestaurants();
  }

  Future<void> _fetchRestaurants() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final response = await _supabase.from('restaurants').select().order('created_at', ascending: false);
      setState(() {
        _restaurants = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
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
        title: const Text('Restaurants', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchRestaurants,
            tooltip: 'Refresh List',
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _restaurants.isEmpty
              ? const Center(child: Text('No restaurants found.', style: TextStyle(fontSize: 16)))
              : ListView.builder(
                  itemCount: _restaurants.length,
                  itemBuilder: (context, index) {
                    final restaurant = _restaurants[index];
                    final bool manageTable = restaurant['manage_table'] ?? true;
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: CircleAvatar(
                          backgroundColor: manageTable ? const Color(0xFFECFDF5) : const Color(0xFFEEF2FF),
                          child: Icon(
                            manageTable ? Icons.table_restaurant_rounded : Icons.point_of_sale_rounded,
                            color: manageTable ? const Color(0xFF059669) : const Color(0xFF4F46E5),
                          ),
                        ),
                        title: Row(
                          children: [
                            Flexible(
                              child: Text(
                                restaurant['name'] ?? 'Unknown',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: manageTable ? const Color(0xFFECFDF5) : const Color(0xFFEEF2FF),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: manageTable ? const Color(0xFFA7F3D0) : const Color(0xFFC7D2FE)),
                              ),
                              child: Text(
                                manageTable ? 'TABLES ON' : 'COUNTER MODE',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: manageTable ? const Color(0xFF065F46) : const Color(0xFF4338CA),
                                ),
                              ),
                            ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text('ID: #${restaurant['id']} • Company: ${restaurant['company_id'] ?? 'spice'}'),
                            Text('Owner: ${restaurant['owner_name'] ?? 'N/A'} • Mobile: ${restaurant['mobile'] ?? 'N/A'}'),
                          ],
                        ),
                        isThreeLine: true,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Switch(
                              value: manageTable,
                              activeColor: const Color(0xFF059669),
                              onChanged: (newVal) async {
                                setState(() {
                                  restaurant['manage_table'] = newVal;
                                });
                                try {
                                  await _supabase
                                      .from('restaurants')
                                      .update({'manage_table': newVal, 'updated_at': DateTime.now().toIso8601String()})
                                      .eq('id', restaurant['id']);
                                } catch (_) {
                                  _fetchRestaurants();
                                }
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit_rounded, color: Color(0xFF4F46E5)),
                              onPressed: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => RestaurantFormScreen(restaurant: restaurant),
                                  ),
                                );
                                if (result == true) {
                                  _fetchRestaurants(); // Refresh the list if edit was successful
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const RestaurantFormScreen(),
            ),
          );
          if (result == true) {
            _fetchRestaurants(); // Refresh the list if add was successful
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Restaurant'),
      ),
    );
  }
}
