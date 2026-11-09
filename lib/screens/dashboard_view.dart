import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/order_model.dart';

class DashboardView extends StatelessWidget {
  final List<OrderModel> orders;
  final Map<String, dynamic> settingsData;
  final VoidCallback onRefresh;
  final Function(int tabIndex)? onNavigateTab;

  const DashboardView({
    super.key,
    required this.orders,
    required this.settingsData,
    required this.onRefresh,
    this.onNavigateTab,
  });

  @override
  Widget build(BuildContext context) {
    final String currencySymbol = (settingsData['basicSettingData'] is List && (settingsData['basicSettingData'] as List).isNotEmpty)
        ? (settingsData['basicSettingData'].first['currSym'] ?? '৳')
        : (settingsData['currSym'] ?? '৳');
    final currencyFormatter = NumberFormat.currency(symbol: currencySymbol, decimalDigits: 2);

    double totalRevenue = 0.0;
    double dineInRevenue = 0.0;
    double takeawayRevenue = 0.0;
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
        dineInRevenue += order.totalAmount;
      } else {
        takeawayOrdersCount++;
        takeawayRevenue += order.totalAmount;
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

    final double avgOrderValue = orders.isEmpty ? 0.0 : totalRevenue / orders.length;
    final int dineInPct = orders.isEmpty ? 0 : ((dineInOrdersCount / orders.length) * 100).round();
    final int takeawayPct = orders.isEmpty ? 0 : 100 - dineInPct;

    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;
    final isWide = screenWidth > 1100;

    return RefreshIndicator(
      color: const Color(0xFF4F46E5),
      onRefresh: () async => onRefresh(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 16.0 : 28.0,
          vertical: isMobile ? 16.0 : 24.0,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Hero Greeting & Command Header
            _buildHeroGreeting(context, isMobile),
            const SizedBox(height: 20),

            // 2. Quick Action Command Center Pills
            _buildQuickActionsBar(context, isMobile),
            const SizedBox(height: 24),

            // 3. Primary KPI Metrics Grid
            LayoutBuilder(
              builder: (context, constraints) {
                final isCardWide = constraints.maxWidth > 960;
                final isCardMedium = constraints.maxWidth > 580;
                final crossAxisCount = isCardWide ? 4 : (isCardMedium ? 2 : 1);
                final childAspectRatio = isCardWide ? 1.5 : (isCardMedium ? 1.6 : 2.2);

                return GridView.count(
                  crossAxisCount: crossAxisCount,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: childAspectRatio,
                  children: [
                    _buildModernMetricCard(
                      context,
                      title: 'Total Gross Revenue',
                      value: currencyFormatter.format(totalRevenue),
                      trend: '+12.5% vs last week',
                      subtext: 'Avg ${currencyFormatter.format(avgOrderValue)} / order',
                      isPositiveTrend: true,
                      icon: Icons.payments_rounded,
                      iconGradient: const [Color(0xFF059669), Color(0xFF10B981)],
                      bgAccent: const Color(0xFFECFDF5),
                    ),
                    _buildModernMetricCard(
                      context,
                      title: 'Completed Orders',
                      value: '${orders.length}',
                      trend: '$totalItemsSold items prepared',
                      subtext: '${(orders.length / 7).toStringAsFixed(1)} avg daily orders',
                      isPositiveTrend: true,
                      icon: Icons.receipt_long_rounded,
                      iconGradient: const [Color(0xFF4338CA), Color(0xFF6366F1)],
                      bgAccent: const Color(0xFFEEF2FF),
                    ),
                    _buildModernMetricCard(
                      context,
                      title: 'Total Guests Served',
                      value: '$totalGuests',
                      trend: 'Avg ${(orders.isEmpty ? 0 : totalGuests / orders.length).toStringAsFixed(1)} guests / party',
                      subtext: '$dineInOrdersCount Dine-In seatings',
                      isPositiveTrend: true,
                      icon: Icons.groups_rounded,
                      iconGradient: const [Color(0xFF0284C7), Color(0xFF38BDF8)],
                      bgAccent: const Color(0xFFF0F9FF),
                    ),
                    _buildModernMetricCard(
                      context,
                      title: 'Channel Breakdown',
                      value: '$dineInPct% / $takeawayPct%',
                      trend: '$dineInOrdersCount Dine-In • $takeawayOrdersCount Takeaway',
                      subtext: '${currencyFormatter.format(dineInRevenue)} vs ${currencyFormatter.format(takeawayRevenue)}',
                      isPositiveTrend: true,
                      icon: Icons.pie_chart_outline_rounded,
                      iconGradient: const [Color(0xFF7C3AED), Color(0xFFA855F7)],
                      bgAccent: const Color(0xFFFAF5FF),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),

            // 4. Analytics Breakdown Section (Top Items + Channel Distribution)
            if (isWide) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 6,
                    child: _buildTopSellingCard(context, topItems, totalItemsSold, currencyFormatter),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    flex: 4,
                    child: _buildChannelBreakdownCard(
                      context,
                      dineInOrdersCount,
                      takeawayOrdersCount,
                      dineInRevenue,
                      takeawayRevenue,
                      totalRevenue,
                      dineInPct,
                      takeawayPct,
                      totalGuests,
                      currencyFormatter,
                    ),
                  ),
                ],
              ),
            ] else ...[
              _buildTopSellingCard(context, topItems, totalItemsSold, currencyFormatter),
              const SizedBox(height: 20),
              _buildChannelBreakdownCard(
                context,
                dineInOrdersCount,
                takeawayOrdersCount,
                dineInRevenue,
                takeawayRevenue,
                totalRevenue,
                dineInPct,
                takeawayPct,
                totalGuests,
                currencyFormatter,
              ),
            ],
          ],
        ),
      ),
    );
  }

  // --- 1. HERO GREETING BANNER ---
  Widget _buildHeroGreeting(BuildContext context, bool isMobile) {
    final now = DateTime.now();
    final dateString = DateFormat('EEEE, MMMM d, yyyy').format(now);

    return Container(
      padding: EdgeInsets.all(isMobile ? 18.0 : 24.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.03),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFA7F3D0)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          CircleAvatar(radius: 3.5, backgroundColor: Color(0xFF10B981)),
                          SizedBox(width: 6),
                          Text(
                            'Live Store Connected',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF065F46),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.refresh_rounded, color: Color(0xFF4F46E5), size: 20),
                      tooltip: 'Refresh Data',
                      onPressed: onRefresh,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Text(
                  'Welcome back, Store Admin 👋',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  dateString,
                  style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                ),
              ],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Welcome back, Store Admin 👋',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFECFDF5),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0xFFA7F3D0)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                CircleAvatar(radius: 3.5, backgroundColor: Color(0xFF10B981)),
                                SizedBox(width: 6),
                                Text(
                                  'Live Pulse Active',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF065F46),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Real-time overview of revenue, live table seatings, and top performing dishes.',
                        style: TextStyle(fontSize: 14, color: Colors.blueGrey.shade600),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today_rounded, size: 16, color: Color(0xFF64748B)),
                          const SizedBox(width: 8),
                          Text(
                            dateString,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF334155),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: onRefresh,
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: const Text('Refresh Sync'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }

  // --- 2. QUICK ACTIONS COMMAND CENTER ---
  Widget _buildQuickActionsBar(BuildContext context, bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'COMMAND CENTER',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: Color(0xFF94A3B8),
                letterSpacing: 1.1,
              ),
            ),
            Text(
              'Shortcuts to core tasks',
              style: TextStyle(fontSize: 12, color: Colors.blueGrey.shade400),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _buildActionPill(
              icon: Icons.add_circle_outline_rounded,
              label: 'Add Menu Item',
              accentColor: const Color(0xFF4F46E5),
              onTap: () => onNavigateTab?.call(2),
            ),
            _buildActionPill(
              icon: Icons.bar_chart_rounded,
              label: 'Staff & Sales Reports',
              accentColor: const Color(0xFF059669),
              onTap: () => onNavigateTab?.call(1),
            ),
            _buildActionPill(
              icon: Icons.table_restaurant_rounded,
              label: 'Tables & Seating Areas',
              accentColor: const Color(0xFFD97706),
              onTap: () => onNavigateTab?.call(2),
            ),
            _buildActionPill(
              icon: Icons.tune_rounded,
              label: 'Restaurant & VAT Settings',
              accentColor: const Color(0xFF7C3AED),
              onTap: () => onNavigateTab?.call(2),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionPill({
    required IconData icon,
    required String label,
    required Color accentColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: accentColor, size: 16),
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.arrow_forward_rounded, size: 14, color: Color(0xFF94A3B8)),
          ],
        ),
      ),
    );
  }

  // --- 3. MODERN KPI METRIC CARD ---
  Widget _buildModernMetricCard(
    BuildContext context, {
    required String title,
    required String value,
    required String trend,
    required String subtext,
    required bool isPositiveTrend,
    required IconData icon,
    required List<Color> iconGradient,
    required Color bgAccent,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: iconGradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: iconGradient.first.withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 18),
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
                fontSize: 26,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.8,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    isPositiveTrend ? Icons.trending_up_rounded : Icons.trending_flat_rounded,
                    size: 15,
                    color: isPositiveTrend ? const Color(0xFF10B981) : const Color(0xFF64748B),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      trend,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isPositiveTrend ? const Color(0xFF047857) : const Color(0xFF64748B),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                subtext,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF94A3B8),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- 4. TOP PERFORMING ITEMS CARD ---
  Widget _buildTopSellingCard(
    BuildContext context,
    List<MapEntry<String, int>> topItems,
    int totalItemsSold,
    NumberFormat currencyFormatter,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(22.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.emoji_events_rounded, color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Top Selling Menu Items',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                      letterSpacing: -0.3,
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
                  '$totalItemsSold Sold Total',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (topItems.isEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 36.0),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.restaurant_outlined, size: 40, color: Colors.grey.shade400),
                    const SizedBox(height: 10),
                    const Text(
                      'No sales transactions recorded yet.',
                      style: TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: topItems.length > 5 ? 5 : topItems.length,
              separatorBuilder: (context, index) => const Divider(color: Color(0xFFF1F5F9), height: 22),
              itemBuilder: (context, index) {
                final item = topItems[index];
                final double percentage = totalItemsSold > 0 ? (item.value / totalItemsSold) : 0.0;

                Color medalColor;
                Color medalBg;
                IconData medalIcon;

                if (index == 0) {
                  medalColor = const Color(0xFFB45309);
                  medalBg = const Color(0xFFFEF3C7);
                  medalIcon = Icons.military_tech_rounded;
                } else if (index == 1) {
                  medalColor = const Color(0xFF475569);
                  medalBg = const Color(0xFFE2E8F0);
                  medalIcon = Icons.military_tech_rounded;
                } else if (index == 2) {
                  medalColor = const Color(0xFF92400E);
                  medalBg = const Color(0xFFFFEDD5);
                  medalIcon = Icons.military_tech_rounded;
                } else {
                  medalColor = const Color(0xFF4F46E5);
                  medalBg = const Color(0xFFEEF2FF);
                  medalIcon = Icons.star_border_rounded;
                }

                return Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: medalBg,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Icon(medalIcon, color: medalColor, size: 18),
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
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              Text(
                                '${item.value} sold',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                  color: Color(0xFF4F46E5),
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
                                    value: percentage.clamp(0.04, 1.0),
                                    backgroundColor: const Color(0xFFF1F5F9),
                                    color: medalColor,
                                    minHeight: 6,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                '${(percentage * 100).toStringAsFixed(1)}%',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF94A3B8),
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
        ],
      ),
    );
  }

  // --- 5. CHANNEL BREAKDOWN & SEATING CARD ---
  Widget _buildChannelBreakdownCard(
    BuildContext context,
    int dineInOrders,
    int takeawayOrders,
    double dineInRevenue,
    double takeawayRevenue,
    double totalRevenue,
    int dineInPct,
    int takeawayPct,
    int totalGuests,
    NumberFormat currencyFormatter,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(22.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.donut_large_rounded, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 12),
              const Text(
                'Order Channels',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Visual Segmented Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 12,
              child: Row(
                children: [
                  Expanded(
                    flex: dineInPct > 0 ? dineInPct : 1,
                    child: Container(color: const Color(0xFF4F46E5)),
                  ),
                  Expanded(
                    flex: takeawayPct > 0 ? takeawayPct : 1,
                    child: Container(color: const Color(0xFF10B981)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Channel 1: Dine-In
          _buildChannelRow(
            title: 'Dine-In Table Orders',
            count: '$dineInOrders orders ($dineInPct%)',
            revenue: currencyFormatter.format(dineInRevenue),
            color: const Color(0xFF4F46E5),
            icon: Icons.table_restaurant_rounded,
          ),
          const Divider(color: Color(0xFFF1F5F9), height: 20),

          // Channel 2: Takeaway / Collection
          _buildChannelRow(
            title: 'Takeaway & Collection',
            count: '$takeawayOrders orders ($takeawayPct%)',
            revenue: currencyFormatter.format(takeawayRevenue),
            color: const Color(0xFF10B981),
            icon: Icons.takeout_dining_rounded,
          ),
          const Divider(color: Color(0xFFF1F5F9), height: 20),

          // Channel 3: Guests Summary
          _buildChannelRow(
            title: 'Guests Hosted',
            count: '$totalGuests total diners',
            revenue: 'Dine-In Area',
            color: const Color(0xFF0284C7),
            icon: Icons.people_alt_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildChannelRow({
    required String title,
    required String count,
    required String revenue,
    required Color color,
    required IconData icon,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
              ),
              Text(
                count,
                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
        Text(
          revenue,
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: color),
        ),
      ],
    );
  }
}
