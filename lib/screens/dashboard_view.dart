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
    int totalItemsSold = 0;

    for (var order in orders) {
      totalRevenue += order.totalAmount;
      totalGuests += order.numberOfGuests;

      if (order.orderType.toLowerCase() == 'dinein') {
        dineInOrdersCount++;
      } else {
        takeawayOrdersCount++;
      }

      for (var item in order.orderItems) {
        final name = item.foodName.isNotEmpty ? item.foodName : 'Unknown Item';
        itemSalesCount[name] = (itemSalesCount[name] ?? 0) + item.quantity;
        itemSalesRevenue[name] = (itemSalesRevenue[name] ?? 0.0) + (item.price * item.quantity);
        totalItemsSold += item.quantity;
      }
    }

    final topItems = itemSalesCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return RefreshIndicator(
      color: const Color(0xFF4F46E5),
      onRefresh: () async => onRefresh(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(isMobile ? 16.0 : 28.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Responsive Header
            if (isMobile) ...[
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Executive Overview',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Real-time metrics, order breakdown & top menu sales',
                    style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: onRefresh,
                      icon: const Icon(Icons.refresh_rounded, size: 16),
                      label: const Text('Refresh Data'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ] else ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Executive Overview',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                          letterSpacing: -0.5,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Real-time store metrics, order breakdown & top menu sales',
                        style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
                      ),
                    ],
                  ),
                  ElevatedButton.icon(
                    onPressed: onRefresh,
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('Refresh Data'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                    ),
                  ),
                ],
              ),
            ],
            SizedBox(height: isMobile ? 20 : 28),

            // Key Metrics Cards Grid
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 900;
                final isMedium = constraints.maxWidth > 550;
                final crossAxisCount = isWide ? 4 : (isMedium ? 2 : 1);
                final childAspectRatio = isWide ? 1.45 : (isMedium ? 1.55 : 2.1);

                return GridView.count(
                  crossAxisCount: crossAxisCount,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: isMobile ? 10 : 18,
                  mainAxisSpacing: isMobile ? 10 : 18,
                  childAspectRatio: childAspectRatio,
                  children: [
                    _buildMetricCard(
                      context,
                      title: 'Total Revenue',
                      value: currencyFormatter.format(totalRevenue),
                      trend: '+12.5% vs last week',
                      isPositiveTrend: true,
                      icon: Icons.attach_money_rounded,
                      iconGradient: const [Color(0xFF10B981), Color(0xFF059669)],
                    ),
                    _buildMetricCard(
                      context,
                      title: 'Total Orders',
                      value: '${orders.length}',
                      trend: '${orders.isEmpty ? 0 : (orders.length * 1.2).round()} items processed',
                      isPositiveTrend: true,
                      icon: Icons.receipt_long_rounded,
                      iconGradient: const [Color(0xFF4F46E5), Color(0xFF6366F1)],
                    ),
                    _buildMetricCard(
                      context,
                      title: 'Total Guests Served',
                      value: '$totalGuests',
                      trend: 'Avg ${(orders.isEmpty ? 0 : totalGuests / orders.length).toStringAsFixed(1)} guests/order',
                      isPositiveTrend: true,
                      icon: Icons.people_alt_rounded,
                      iconGradient: const [Color(0xFF06B6D4), Color(0xFF0284C7)],
                    ),
                    _buildMetricCard(
                      context,
                      title: 'Dine-In vs Takeaway',
                      value: '$dineInOrdersCount / $takeawayOrdersCount',
                      trend: '${orders.isEmpty ? 0 : ((dineInOrdersCount / orders.length) * 100).round()}% Dine-in share',
                      isPositiveTrend: true,
                      icon: Icons.table_restaurant_rounded,
                      iconGradient: const [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
                    ),
                  ],
                );
              },
            ),
            SizedBox(height: isMobile ? 20 : 32),

            // Top Selling Items & Performance Section
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            alignment: WrapAlignment.spaceBetween,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 12,
                            runSpacing: 10,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFEF3C7),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(Icons.star_rounded, color: Color(0xFFD97706), size: 20),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Top Performing Menu Items',
                                    style: TextStyle(
                                      fontSize: isMobile ? 16 : 18,
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFF0F172A),
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '$totalItemsSold Total Items Sold',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          topItems.isEmpty
                              ? const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 36.0),
                                  child: Center(
                                    child: Text(
                                      'No sales transaction data recorded yet.',
                                      style: TextStyle(color: Color(0xFF94A3B8)),
                                    ),
                                  ),
                                )
                              : ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: topItems.length > 5 ? 5 : topItems.length,
                                  separatorBuilder: (context, index) => const Divider(color: Color(0xFFF1F5F9), height: 24),
                                  itemBuilder: (context, index) {
                                    final item = topItems[index];
                                    final revenue = itemSalesRevenue[item.key] ?? 0.0;
                                    final double percentage = totalItemsSold > 0 ? (item.value / totalItemsSold) : 0.0;

                                    Color rankColor;
                                    Color rankBg;
                                    if (index == 0) {
                                      rankColor = const Color(0xFFD97706);
                                      rankBg = const Color(0xFFFEF3C7);
                                    } else if (index == 1) {
                                      rankColor = const Color(0xFF64748B);
                                      rankBg = const Color(0xFFF1F5F9);
                                    } else if (index == 2) {
                                      rankColor = const Color(0xFFB45309);
                                      rankBg = const Color(0xFFFFEDD5);
                                    } else {
                                      rankColor = const Color(0xFF4F46E5);
                                      rankBg = const Color(0xFFEEF2FF);
                                    }

                                    return Row(
                                      children: [
                                        Container(
                                          width: 36,
                                          height: 36,
                                          decoration: BoxDecoration(
                                            color: rankBg,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Center(
                                            child: Text(
                                              '#${index + 1}',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13,
                                                color: rankColor,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Text(
                                                    item.key,
                                                    style: const TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 15,
                                                      color: Color(0xFF0F172A),
                                                    ),
                                                  ),
                                                  Text(
                                                    currencyFormatter.format(revenue),
                                                    style: const TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 15,
                                                      color: Color(0xFF10B981),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 6),
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: ClipRRect(
                                                      borderRadius: BorderRadius.circular(4),
                                                      child: LinearProgressIndicator(
                                                        value: percentage.clamp(0.05, 1.0),
                                                        backgroundColor: const Color(0xFFF1F5F9),
                                                        color: rankColor,
                                                        minHeight: 6,
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Text(
                                                    '${item.value} sold',
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.w600,
                                                      color: Color(0xFF64748B),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
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
    required String trend,
    required bool isPositiveTrend,
    required IconData icon,
    required List<Color> iconGradient,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 14,
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
                  color: Color(0xFF64748B),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: iconGradient),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
            ],
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 24,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
          ),
          Row(
            children: [
              Icon(
                isPositiveTrend ? Icons.trending_up_rounded : Icons.trending_flat_rounded,
                size: 14,
                color: isPositiveTrend ? const Color(0xFF10B981) : const Color(0xFF64748B),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  trend,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isPositiveTrend ? const Color(0xFF047857) : const Color(0xFF64748B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

