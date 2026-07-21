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
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: CircleAvatar(
                          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                          child: Icon(Icons.restaurant, color: Theme.of(context).colorScheme.onPrimaryContainer),
                        ),
                        title: Text(restaurant['name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text('Owner: ${restaurant['owner_name'] ?? 'N/A'}'),
                            Text('Mobile: ${restaurant['mobile'] ?? 'N/A'}'),
                          ],
                        ),
                        isThreeLine: true,
                        trailing: IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
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
