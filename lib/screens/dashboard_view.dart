import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/order_model.dart';

class DashboardView extends StatelessWidget {
  final List<OrderModel> orders;
  final Map<String, dynamic> settingsData;
  final VoidCallback onRefresh;

  const DashboardView({
    super.key,
    required this.orders,
    required this.settingsData,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

    double totalRevenue = 0.0;
    int totalGuests = 0;
    int dineInOrdersCount = 0;
    int takeawayOrdersCount = 0;
    Map<String, int> itemSalesCount = {};
    Map<String, double> itemSalesRevenue = {};

    for (var order in orders) {
      totalRevenue += order.totalAmount;
      totalGuests += order.numberOfGuests;

      if (order.orderType.toLowerCase() == 'dinein') {
        dineInOrdersCount++;
      } else {
        takeawayOrdersCount++;
      }

      for (var item in order.orderItems) {
        final name = item.foodName.isNotEmpty ? item.foodName : 'Unknown';
        itemSalesCount[name] = (itemSalesCount[name] ?? 0) + item.quantity;
        itemSalesRevenue[name] = (itemSalesRevenue[name] ?? 0.0) + (item.price * item.quantity);
      }
    }

    final topItems = itemSalesCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Executive Dashboard',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.indigo.shade900,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Real-time overview of sales, orders & item performance',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: onRefresh,
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Reload Data',
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Key Metrics Cards Grid
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 800;
                final crossAxisCount = isWide ? 4 : 2;
                return GridView.count(
                  crossAxisCount: crossAxisCount,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: isWide ? 1.5 : 1.3,
                  children: [
                    _buildMetricCard(
                      context,
                      title: 'Total Revenue',
                      value: currencyFormatter.format(totalRevenue),
                      icon: Icons.attach_money,
                      color: Colors.teal,
                      bgGradient: const [Color(0xFF11998e), Color(0xFF38ef7d)],
                    ),
                    _buildMetricCard(
                      context,
                      title: 'Total Orders',
                      value: '${orders.length}',
                      icon: Icons.receipt_long,
                      color: Colors.blue,
                      bgGradient: const [Color(0xFF2193b0), Color(0xFF6dd5ed)],
                    ),
                    _buildMetricCard(
                      context,
                      title: 'Total Guests',
                      value: '$totalGuests',
                      icon: Icons.people,
                      color: Colors.orange,
                      bgGradient: const [Color(0xFFFF8008), Color(0xFFFFC837)],
                    ),
                    _buildMetricCard(
                      context,
                      title: 'Dine-In / Takeaway',
                      value: '$dineInOrdersCount / $takeawayOrdersCount',
                      icon: Icons.table_restaurant,
                      color: Colors.purple,
                      bgGradient: const [Color(0xFF8E2DE2), Color(0xFF4A00E0)],
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 32),
            // Top Selling Items Section
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.star, color: Colors.amber.shade700),
                        const SizedBox(width: 8),
                        Text(
                          'Top Selling Items',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    topItems.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.symmetric(vertical: 24.0),
                            child: Center(child: Text('No order item data available.')),
                          )
                        : ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: topItems.length > 5 ? 5 : topItems.length,
                            separatorBuilder: (context, index) => const Divider(),
                            itemBuilder: (context, index) {
                              final item = topItems[index];
                              final revenue = itemSalesRevenue[item.key] ?? 0.0;
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.indigo.shade50,
                                  child: Text(
                                    '#${index + 1}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.indigo.shade800,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  item.key,
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                                subtitle: Text('Qty Sold: ${item.value}'),
                                trailing: Text(
                                  currencyFormatter.format(revenue),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: Colors.green,
                                  ),
                                ),
                              );
                            },
                          ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required MaterialColor color,
    required List<Color> bgGradient,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: bgGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: bgGradient.first.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Icon(icon, color: Colors.white, size: 28),
            ],
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
