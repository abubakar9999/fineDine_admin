import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:excel/excel.dart' hide Border;
import 'package:file_picker/file_picker.dart';
import '../models/order_model.dart';

class OrderReportsView extends StatefulWidget {
  final List<OrderModel> orders;
  final VoidCallback onRefresh;

  const OrderReportsView({
    super.key,
    required this.orders,
    required this.onRefresh,
  });

  @override
  State<OrderReportsView> createState() => _OrderReportsViewState();
}

class _OrderReportsViewState extends State<OrderReportsView> {
  int _selectedTab = 0; // 0: Staff, 1: Cancelled, 2: Refunds, 3: Profit & Loss, 4: All Receipts, 5: Payments, 6: Menu Sales, 7: Peak Hours
  String _searchQuery = '';
  String _selectedOrderType = 'All';
  String _selectedDateFilter = 'All Time';

  final currencyFormatter = NumberFormat.currency(symbol: '৳', decimalDigits: 2);
  final dateFormatter = DateFormat('MMM dd, yyyy • hh:mm a');
  final shortDateFormatter = DateFormat('MMM dd, yyyy');

  List<OrderModel> get _filteredOrders {
    final now = DateTime.now();
    return widget.orders.where((order) {
      // Search query filter
      final q = _searchQuery.toLowerCase().trim();
      final matchesSearch = q.isEmpty ||
          order.sl.toString().contains(q) ||
          order.id.toLowerCase().contains(q) ||
          (order.customer?.name.toLowerCase().contains(q) ?? false) ||
          order.waiterName.toLowerCase().contains(q) ||
          order.cancelReason.toLowerCase().contains(q) ||
          order.refundReason.toLowerCase().contains(q);

      // Order type filter
      final matchesType = _selectedOrderType == 'All' ||
          order.orderType.toLowerCase() == _selectedOrderType.toLowerCase();

      // Date range filter
      bool matchesDate = true;
      if (order.orderDate != null) {
        final d = order.orderDate!;
        if (_selectedDateFilter == 'Today') {
          matchesDate = d.year == now.year && d.month == now.month && d.day == now.day;
        } else if (_selectedDateFilter == 'Yesterday') {
          final y = now.subtract(const Duration(days: 1));
          matchesDate = d.year == y.year && d.month == y.month && d.day == y.day;
        } else if (_selectedDateFilter == 'Last 7 Days') {
          matchesDate = d.isAfter(now.subtract(const Duration(days: 7)));
        } else if (_selectedDateFilter == 'This Month') {
          matchesDate = d.year == now.year && d.month == now.month;
        }
      }

      return matchesSearch && matchesType && matchesDate;
    }).toList();
  }

  Future<void> _exportToExcel() async {
    try {
      var excel = Excel.createExcel();

      // 1. Staff Report Sheet
      Sheet staffSheet = excel['Staff Performance'];
      staffSheet.appendRow([
        TextCellValue('Staff Name'),
        TextCellValue('Total Orders'),
        TextCellValue('Dine-In'),
        TextCellValue('Takeaway'),
        TextCellValue('Total Sales (৳)'),
        TextCellValue('Avg Ticket (৳)'),
      ]);

      Map<String, List<OrderModel>> staffGroup = {};
      for (var o in _filteredOrders) {
        staffGroup.putIfAbsent(o.waiterName, () => []).add(o);
      }
      staffGroup.forEach((staff, sOrders) {
        double totalSales = sOrders.fold(0.0, (sum, o) => sum + o.totalAmount);
        int dineIn = sOrders.where((o) => o.orderType.toLowerCase() == 'dinein').length;
        int takeaway = sOrders.length - dineIn;
        double avg = sOrders.isEmpty ? 0.0 : totalSales / sOrders.length;
        staffSheet.appendRow([
          TextCellValue(staff),
          IntCellValue(sOrders.length),
          IntCellValue(dineIn),
          IntCellValue(takeaway),
          DoubleCellValue(totalSales),
          DoubleCellValue(avg),
        ]);
      });

      // 2. Cancelled Orders Sheet
      Sheet cancelSheet = excel['Cancelled Orders'];
      cancelSheet.appendRow([
        TextCellValue('Order #'),
        TextCellValue('Date'),
        TextCellValue('Staff'),
        TextCellValue('Customer'),
        TextCellValue('Amount (৳)'),
        TextCellValue('Cancellation Reason'),
      ]);
      final cancelledList = _filteredOrders.where((o) => o.isCancelled).toList();
      for (var o in cancelledList) {
        cancelSheet.appendRow([
          TextCellValue('#${o.sl}'),
          TextCellValue(o.orderDate != null ? dateFormatter.format(o.orderDate!) : 'N/A'),
          TextCellValue(o.waiterName),
          TextCellValue(o.customer?.name ?? 'Walk-in Guest'),
          DoubleCellValue(o.totalAmount),
          TextCellValue(o.cancelReason.isNotEmpty ? o.cancelReason : 'Cancelled'),
        ]);
      }

      // 3. Refunds Sheet
      Sheet refundSheet = excel['Refund Report'];
      refundSheet.appendRow([
        TextCellValue('Order #'),
        TextCellValue('Date'),
        TextCellValue('Original Amount (৳)'),
        TextCellValue('Refund Amount (৳)'),
        TextCellValue('Refund Reason'),
      ]);
      final refundedList = _filteredOrders.where((o) => o.isRefunded).toList();
      for (var o in refundedList) {
        refundSheet.appendRow([
          TextCellValue('#${o.sl}'),
          TextCellValue(o.orderDate != null ? dateFormatter.format(o.orderDate!) : 'N/A'),
          DoubleCellValue(o.totalAmount),
          DoubleCellValue(o.effectiveRefund),
          TextCellValue(o.refundReason.isNotEmpty ? o.refundReason : 'Refund Processed'),
        ]);
      }

      // 4. Profit & Loss Sheet
      Sheet plSheet = excel['Profit & Loss Statement'];
      double grossSales = _filteredOrders.fold(0.0, (sum, o) => sum + o.effectiveSubTotal);
      double discounts = _filteredOrders.fold(0.0, (sum, o) => sum + o.effectiveDiscount);
      double netSales = grossSales - discounts;
      double cogs = _filteredOrders.fold(0.0, (sum, o) => sum + o.effectiveCost);
      double grossProfit = netSales - cogs;
      double refundLosses = refundedList.fold(0.0, (sum, o) => sum + o.effectiveRefund);
      double overhead = netSales * 0.18; // Estimated operating overhead
      double netProfit = grossProfit - refundLosses - overhead;

      plSheet.appendRow([TextCellValue('Financial Metric'), TextCellValue('Amount (৳)')]);
      plSheet.appendRow([TextCellValue('Gross Sales Revenue'), DoubleCellValue(grossSales)]);
      plSheet.appendRow([TextCellValue('Total Discounts Allowed'), DoubleCellValue(discounts)]);
      plSheet.appendRow([TextCellValue('Net Sales Revenue'), DoubleCellValue(netSales)]);
      plSheet.appendRow([TextCellValue('Cost of Goods Sold (COGS)'), DoubleCellValue(cogs)]);
      plSheet.appendRow([TextCellValue('Gross Profit'), DoubleCellValue(grossProfit)]);
      plSheet.appendRow([TextCellValue('Refund & Loss Costs'), DoubleCellValue(refundLosses)]);
      plSheet.appendRow([TextCellValue('Operating Overhead Estimate (18%)'), DoubleCellValue(overhead)]);
      plSheet.appendRow([TextCellValue('Net Operating Profit'), DoubleCellValue(netProfit)]);

      var fileBytes = excel.save();
      if (fileBytes != null) {
        String filename = 'FineDine_Report_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.xlsx';
        String? outputFile = await FilePicker.platform.saveFile(
          dialogTitle: 'Save FineDine Executive Reports',
          fileName: filename,
          bytes: Uint8List.fromList(fileBytes),
        );

        if (outputFile != null && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: const [
                  Icon(Icons.check_circle_rounded, color: Colors.white),
                  SizedBox(width: 10),
                  Text('Executive report exported successfully!'),
                ],
              ),
              backgroundColor: const Color(0xFF10B981),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaWidth = MediaQuery.of(context).size.width;
    final isMobile = mediaWidth < 650;

    return RefreshIndicator(
      color: const Color(0xFF4F46E5),
      onRefresh: () async => widget.onRefresh(),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 12.0 : 26.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Responsive Header Bar
            _buildTopHeader(isMobile),
            SizedBox(height: isMobile ? 12 : 20),

            // Navigation Tabs (Horizontal Scrollable Selector)
            _buildReportTabsSelector(isMobile),
            SizedBox(height: isMobile ? 12 : 20),

            // Filter & Search Controls Bar
            _buildSearchAndFiltersBar(isMobile),
            SizedBox(height: isMobile ? 12 : 20),

            // Main Active Report Content Body
            Expanded(
              child: _buildActiveReportView(isMobile),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopHeader(bool isMobile) {
    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Reports & Analytics',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.5,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Staff, Cancellations, Refunds & Profitability',
                      style: TextStyle(color: Color(0xFF64748B), fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _exportToExcel,
                  icon: const Icon(Icons.download_rounded, size: 15),
                  label: const Text('Export Excel', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: widget.onRefresh,
                  icon: const Icon(Icons.refresh_rounded, size: 15),
                  label: const Text('Refresh', style: TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Reports & Analytics Hub',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
                letterSpacing: -0.5,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Staff performance, Cancelled orders, Refunds, P&L & store receipts',
              style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
            ),
          ],
        ),
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: _exportToExcel,
              icon: const Icon(Icons.file_download_outlined, size: 18),
              label: const Text('Export Excel / CSV'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: widget.onRefresh,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Refresh Data'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildReportTabsSelector(bool isMobile) {
    final tabs = [
      {'id': 0, 'name': 'Staff Report', 'icon': Icons.people_alt_rounded},
      {'id': 1, 'name': 'Cancel Orders', 'icon': Icons.cancel_outlined},
      {'id': 2, 'name': 'Refund Report', 'icon': Icons.assignment_return_outlined},
      {'id': 3, 'name': 'Profit & Loss', 'icon': Icons.trending_up_rounded},
      {'id': 4, 'name': 'Order Receipts', 'icon': Icons.receipt_long_rounded},
      {'id': 5, 'name': 'Payment Methods', 'icon': Icons.credit_card_rounded},
      {'id': 6, 'name': 'Menu & Categories', 'icon': Icons.restaurant_menu_rounded},
      {'id': 7, 'name': 'Peak Hours', 'icon': Icons.access_time_filled_rounded},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: tabs.map((tab) {
          final int id = tab['id'] as int;
          final bool isSelected = _selectedTab == id;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              avatar: Icon(
                tab['icon'] as IconData,
                size: 15,
                color: isSelected ? Colors.white : const Color(0xFF4F46E5),
              ),
              label: Text(tab['name'] as String),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() => _selectedTab = id);
                }
              },
              selectedColor: const Color(0xFF4F46E5),
              backgroundColor: Colors.white,
              labelStyle: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : const Color(0xFF334155),
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              side: BorderSide(
                color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFFE2E8F0),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSearchAndFiltersBar(bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 10.0 : 16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        alignment: WrapAlignment.spaceBetween,
        children: [
          SizedBox(
            width: isMobile ? double.infinity : 300,
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search staff, order #, reason...',
                prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF64748B), size: 18),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 16),
                        onPressed: () => setState(() => _searchQuery = ''),
                      )
                    : null,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              onChanged: (val) => setState(() => _searchQuery = val),
            ),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              // Date Filter Dropdown
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFCBD5E1)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isDense: true,
                    value: _selectedDateFilter,
                    icon: const Icon(Icons.calendar_today_rounded, size: 13, color: Color(0xFF4F46E5)),
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedDateFilter = val);
                    },
                    items: ['All Time', 'Today', 'Yesterday', 'Last 7 Days', 'This Month'].map((d) {
                      return DropdownMenuItem(value: d, child: Text(d));
                    }).toList(),
                  ),
                ),
              ),
              // Order Type Chips
              Wrap(
                spacing: 4,
                children: ['All', 'DineIn', 'Takeaway'].map((type) {
                  final isSel = _selectedOrderType.toLowerCase() == type.toLowerCase();
                  return ChoiceChip(
                    label: Text(type),
                    selected: isSel,
                    onSelected: (selected) {
                      if (selected) setState(() => _selectedOrderType = type);
                    },
                    selectedColor: const Color(0xFFEEF2FF),
                    labelStyle: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isSel ? const Color(0xFF4F46E5) : const Color(0xFF64748B),
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    side: BorderSide(
                      color: isSel ? const Color(0xFFC7D2FE) : const Color(0xFFE2E8F0),
                    ),
                    visualDensity: VisualDensity.compact,
                  );
                }).toList(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActiveReportView(bool isMobile) {
    final orders = _filteredOrders;

    switch (_selectedTab) {
      case 0:
        return _buildStaffReportView(orders, isMobile);
      case 1:
        return _buildCancelOrderReportView(orders, isMobile);
      case 2:
        return _buildRefundReportView(orders, isMobile);
      case 3:
        return _buildProfitLossReportView(orders, isMobile);
      case 4:
        return _buildAllReceiptsView(orders, isMobile);
      case 5:
        return _buildPaymentMethodsReportView(orders, isMobile);
      case 6:
        return _buildCategoryItemReportView(orders, isMobile);
      case 7:
        return _buildPeakHoursReportView(orders, isMobile);
      default:
        return _buildStaffReportView(orders, isMobile);
    }
  }

  // ==========================================
  // 👥 1. STAFF REPORT VIEW
  // ==========================================
  Widget _buildStaffReportView(List<OrderModel> orders, bool isMobile) {
    Map<String, List<OrderModel>> staffMap = {};
    for (var o in orders) {
      staffMap.putIfAbsent(o.waiterName, () => []).add(o);
    }

    final staffStats = staffMap.entries.map((entry) {
      final sName = entry.key;
      final sOrders = entry.value;
      final totalSales = sOrders.fold(0.0, (sum, o) => sum + o.totalAmount);
      final dineInCount = sOrders.where((o) => o.orderType.toLowerCase() == 'dinein').length;
      final takeawayCount = sOrders.length - dineInCount;
      final avgTicket = sOrders.isEmpty ? 0.0 : totalSales / sOrders.length;
      final totalGuests = sOrders.fold(0, (sum, o) => sum + o.numberOfGuests);

      return {
        'name': sName,
        'orders': sOrders,
        'count': sOrders.length,
        'dineIn': dineInCount,
        'takeaway': takeawayCount,
        'totalSales': totalSales,
        'avgTicket': avgTicket,
        'guests': totalGuests,
      };
    }).toList()
      ..sort((a, b) => (b['totalSales'] as double).compareTo(a['totalSales'] as double));

    final totalStoreRevenue = orders.fold(0.0, (sum, o) => sum + o.totalAmount);
    final topStaffName = staffStats.isNotEmpty ? staffStats.first['name'] as String : 'N/A';

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // KPI Metric Grid
          LayoutBuilder(builder: (context, constraints) {
            final isWide = constraints.maxWidth > 850;
            final isMed = constraints.maxWidth > 500;
            final aspect = isWide ? 1.45 : (isMed ? 1.6 : 2.1);
            return GridView.count(
              crossAxisCount: isWide ? 4 : (isMed ? 2 : 1),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: aspect,
              children: [
                _buildKpiCard(
                  'Active Staff',
                  '${staffStats.length}',
                  'Store waiters',
                  Icons.badge_rounded,
                  const [Color(0xFF4F46E5), Color(0xFF6366F1)],
                ),
                _buildKpiCard(
                  'Top Waiter',
                  topStaffName,
                  staffStats.isNotEmpty ? currencyFormatter.format(staffStats.first['totalSales']) : '৳0.00',
                  Icons.workspace_premium_rounded,
                  const [Color(0xFF10B981), Color(0xFF059669)],
                ),
                _buildKpiCard(
                  'Staff Sales',
                  currencyFormatter.format(totalStoreRevenue),
                  '${orders.length} total orders',
                  Icons.attach_money_rounded,
                  const [Color(0xFF06B6D4), Color(0xFF0284C7)],
                ),
                _buildKpiCard(
                  'Avg / Waiter',
                  staffStats.isEmpty ? '৳0.00' : currencyFormatter.format(totalStoreRevenue / staffStats.length),
                  'Workload sales average',
                  Icons.analytics_rounded,
                  const [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
                ),
              ],
            );
          }),
          const SizedBox(height: 16),

          // Staff Performance Table Card
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.all(isMobile ? 14.0 : 20.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text(
                        'Staff Performance Leaderboard',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                      ),
                      Icon(Icons.leaderboard_rounded, color: Color(0xFF4F46E5)),
                    ],
                  ),
                ),
                const Divider(height: 1, color: Color(0xFFE2E8F0)),
                staffStats.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(30.0),
                        child: Center(child: Text('No staff activity found.')),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: staffStats.length,
                        separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                        itemBuilder: (context, index) {
                          final item = staffStats[index];
                          final rank = index + 1;
                          final double sales = item['totalSales'] as double;
                          final double share = totalStoreRevenue > 0 ? (sales / totalStoreRevenue) * 100 : 0.0;

                          return ListTile(
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: isMobile ? 12 : 20,
                              vertical: isMobile ? 6 : 10,
                            ),
                            leading: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: rank == 1
                                    ? const Color(0xFFFEF3C7)
                                    : (rank == 2 ? const Color(0xFFF1F5F9) : const Color(0xFFEEF2FF)),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: rank == 1
                                      ? const Color(0xFFFDE68A)
                                      : (rank == 2 ? const Color(0xFFCBD5E1) : const Color(0xFFC7D2FE)),
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  '#$rank',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12,
                                    color: rank == 1
                                        ? const Color(0xFFD97706)
                                        : (rank == 2 ? const Color(0xFF475569) : const Color(0xFF4F46E5)),
                                  ),
                                ),
                              ),
                            ),
                            title: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    item['name'] as String,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFECFDF5),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '${share.toStringAsFixed(1)}%',
                                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF047857)),
                                  ),
                                ),
                              ],
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 2.0),
                              child: Text(
                                '${item['count']} orders (${item['dineIn']} Dine, ${item['takeaway']} Take)',
                                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                              ),
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  currencyFormatter.format(sales),
                                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Color(0xFF0F172A)),
                                ),
                                Text(
                                  'Avg: ${currencyFormatter.format(item['avgTicket'] as double)}',
                                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                                ),
                              ],
                            ),
                            onTap: () => _showStaffDetailView(context, item, isMobile),
                          );
                        },
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showStaffDetailView(BuildContext context, Map<String, dynamic> staffData, bool isMobile) {
    final List<OrderModel> sOrders = staffData['orders'] as List<OrderModel>;
    final content = SizedBox(
      width: 500,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMiniStat('Orders', '${staffData['count']}'),
              _buildMiniStat('Sales', currencyFormatter.format(staffData['totalSales'] as double)),
              _buildMiniStat('Avg Ticket', currencyFormatter.format(staffData['avgTicket'] as double)),
            ],
          ),
          const SizedBox(height: 16),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text('Handled Orders History:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 220,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: sOrders.length,
              itemBuilder: (context, index) {
                final o = sOrders[index];
                return ListTile(
                  dense: true,
                  title: Text('Order #${o.sl} (${o.orderType})'),
                  subtitle: Text(o.orderDate != null ? dateFormatter.format(o.orderDate!) : 'N/A'),
                  trailing: Text(
                    currencyFormatter.format(o.totalAmount),
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF047857)),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );

    if (isMobile) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) => Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: const Color(0xFFCBD5E1), borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 16),
              Text('${staffData['name']} Details', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              content,
            ],
          ),
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('${staffData['name']} Performance'),
          content: content,
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
          ],
        ),
      );
    }
  }

  // ==========================================
  // ❌ 2. CANCEL ORDER REPORT VIEW
  // ==========================================
  Widget _buildCancelOrderReportView(List<OrderModel> orders, bool isMobile) {
    final cancelledOrders = orders.where((o) => o.isCancelled).toList();

    final totalLostRevenue = cancelledOrders.fold(0.0, (sum, o) => sum + o.totalAmount);
    final cancelRate = orders.isNotEmpty ? (cancelledOrders.length / orders.length) * 100 : 0.0;

    Map<String, int> reasonCounts = {};
    for (var o in cancelledOrders) {
      final r = o.cancelReason.isNotEmpty ? o.cancelReason : 'Unspecified Reason';
      reasonCounts[r] = (reasonCounts[r] ?? 0) + 1;
    }

    final topReasonEntry = reasonCounts.entries.isNotEmpty
        ? (reasonCounts.entries.toList()..sort((a, b) => b.value.compareTo(a.value))).first
        : null;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // KPI Metric Grid
          LayoutBuilder(builder: (context, constraints) {
            final isWide = constraints.maxWidth > 850;
            final isMed = constraints.maxWidth > 500;
            final aspect = isWide ? 1.45 : (isMed ? 1.6 : 2.1);
            return GridView.count(
              crossAxisCount: isWide ? 4 : (isMed ? 2 : 1),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: aspect,
              children: [
                _buildKpiCard(
                  'Cancelled Orders',
                  '${cancelledOrders.length}',
                  'Voided store orders',
                  Icons.cancel_presentation_rounded,
                  const [Color(0xFFEF4444), Color(0xFFDC2626)],
                ),
                _buildKpiCard(
                  'Lost Sales Revenue',
                  currencyFormatter.format(totalLostRevenue),
                  'Gross lost value',
                  Icons.money_off_csred_rounded,
                  const [Color(0xFFF97316), Color(0xFFEA580C)],
                ),
                _buildKpiCard(
                  'Cancellation Rate',
                  '${cancelRate.toStringAsFixed(1)}%',
                  'Of total ${orders.length} orders',
                  Icons.pie_chart_outline_rounded,
                  const [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
                ),
                _buildKpiCard(
                  'Top Reason',
                  topReasonEntry != null ? topReasonEntry.key : 'None',
                  topReasonEntry != null ? '${topReasonEntry.value} order(s)' : 'No cancellations',
                  Icons.warning_amber_rounded,
                  const [Color(0xFFF59E0B), Color(0xFFD97706)],
                ),
              ],
            );
          }),
          const SizedBox(height: 16),

          // Cancellation Reasons Breakdown
          if (reasonCounts.isNotEmpty) ...[
            Container(
              padding: EdgeInsets.all(isMobile ? 14 : 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Cancellation Cause Breakdown',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 12),
                  ...reasonCounts.entries.map((e) {
                    final double pct = (e.value / cancelledOrders.length) * 100;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(e.key, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF334155))),
                              Text('${e.value} (${pct.toStringAsFixed(1)}%)', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFEF4444))),
                            ],
                          ),
                          const SizedBox(height: 4),
                          LinearProgressIndicator(
                            value: pct / 100,
                            backgroundColor: const Color(0xFFFEE2E2),
                            color: const Color(0xFFEF4444),
                            minHeight: 6,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Cancelled Orders Audit Table
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.all(isMobile ? 14.0 : 20.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text(
                        'Cancelled Orders Audit Log',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                      ),
                      Icon(Icons.find_in_page_outlined, color: Color(0xFFEF4444)),
                    ],
                  ),
                ),
                const Divider(height: 1, color: Color(0xFFE2E8F0)),
                cancelledOrders.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(30.0),
                        child: Center(child: Text('No cancelled orders match the criteria.')),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: cancelledOrders.length,
                        separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                        itemBuilder: (context, index) {
                          final o = cancelledOrders[index];
                          return ListTile(
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: isMobile ? 12 : 20,
                              vertical: isMobile ? 6 : 10,
                            ),
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEE2E2),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xFFFCA5A5)),
                              ),
                              child: const Icon(Icons.cancel_rounded, color: Color(0xFFEF4444), size: 18),
                            ),
                            title: Row(
                              children: [
                                Text('Order #${o.sl}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A))),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFEF2F2),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: const Color(0xFFFCA5A5)),
                                    ),
                                    child: Text(
                                      o.cancelReason.isNotEmpty ? o.cancelReason : 'CANCELLED',
                                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFFDC2626)),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            subtitle: Text(
                              'Staff: ${o.waiterName} • ${o.orderDate != null ? dateFormatter.format(o.orderDate!) : "N/A"}',
                              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                            ),
                            trailing: Text(
                              currencyFormatter.format(o.totalAmount),
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Color(0xFFEF4444)),
                            ),
                            onTap: () => _showOrderDetailsView(context, o, isMobile),
                          );
                        },
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 💸 3. REFUND REPORT VIEW
  // ==========================================
  Widget _buildRefundReportView(List<OrderModel> orders, bool isMobile) {
    final refundedOrders = orders.where((o) => o.isRefunded).toList();

    final totalRefunded = refundedOrders.fold(0.0, (sum, o) => sum + o.effectiveRefund);
    final refundRate = orders.isNotEmpty ? (refundedOrders.length / orders.length) * 100 : 0.0;

    Map<String, int> reasonMap = {};
    for (var o in refundedOrders) {
      final r = o.refundReason.isNotEmpty ? o.refundReason : 'Standard Customer Refund';
      reasonMap[r] = (reasonMap[r] ?? 0) + 1;
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // KPI Metric Grid
          LayoutBuilder(builder: (context, constraints) {
            final isWide = constraints.maxWidth > 850;
            final isMed = constraints.maxWidth > 500;
            final aspect = isWide ? 1.45 : (isMed ? 1.6 : 2.1);
            return GridView.count(
              crossAxisCount: isWide ? 4 : (isMed ? 2 : 1),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: aspect,
              children: [
                _buildKpiCard(
                  'Refund Orders',
                  '${refundedOrders.length}',
                  'Processed refunds',
                  Icons.assignment_return_rounded,
                  const [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
                ),
                _buildKpiCard(
                  'Total Refunded',
                  currencyFormatter.format(totalRefunded),
                  'Returned to customers',
                  Icons.currency_exchange_rounded,
                  const [Color(0xFFEC4899), Color(0xFFDB2777)],
                ),
                _buildKpiCard(
                  'Refund Rate',
                  '${refundRate.toStringAsFixed(1)}%',
                  'Of total orders',
                  Icons.percent_rounded,
                  const [Color(0xFF06B6D4), Color(0xFF0284C7)],
                ),
                _buildKpiCard(
                  'Top Claim',
                  reasonMap.isNotEmpty ? reasonMap.keys.first : 'None',
                  'Primary refund reason',
                  Icons.help_outline_rounded,
                  const [Color(0xFFF59E0B), Color(0xFFD97706)],
                ),
              ],
            );
          }),
          const SizedBox(height: 16),

          // Refund Audit Table
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.all(isMobile ? 14.0 : 20.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text(
                        'Refund Transaction Audit Log',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                      ),
                      Icon(Icons.history_edu_rounded, color: Color(0xFF8B5CF6)),
                    ],
                  ),
                ),
                const Divider(height: 1, color: Color(0xFFE2E8F0)),
                refundedOrders.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(30.0),
                        child: Center(child: Text('No refund records found.')),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: refundedOrders.length,
                        separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                        itemBuilder: (context, index) {
                          final o = refundedOrders[index];
                          return ListTile(
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: isMobile ? 12 : 20,
                              vertical: isMobile ? 6 : 10,
                            ),
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF3E8FF),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xFFDDD6FE)),
                              ),
                              child: const Icon(Icons.replay_rounded, color: Color(0xFF7C3AED), size: 18),
                            ),
                            title: Row(
                              children: [
                                Text('Order #${o.sl}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A))),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF5F3FF),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: const Color(0xFFC7D2FE)),
                                    ),
                                    child: Text(
                                      o.refundReason.isNotEmpty ? o.refundReason : 'REFUNDED',
                                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF6D28D9)),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            subtitle: Text(
                              'Staff: ${o.waiterName} • ${o.orderDate != null ? dateFormatter.format(o.orderDate!) : "N/A"}',
                              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                            ),
                            trailing: Text(
                              currencyFormatter.format(o.effectiveRefund),
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Color(0xFF7C3AED)),
                            ),
                            onTap: () => _showOrderDetailsView(context, o, isMobile),
                          );
                        },
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 📈 4. PROFIT & LOSS REPORT VIEW
  // ==========================================
  Widget _buildProfitLossReportView(List<OrderModel> orders, bool isMobile) {
    double grossSales = orders.fold(0.0, (sum, o) => sum + o.effectiveSubTotal);
    double totalDiscounts = orders.fold(0.0, (sum, o) => sum + o.effectiveDiscount);
    double netSales = grossSales - totalDiscounts;

    // COGS (Cost of Goods Sold)
    double totalCogs = orders.fold(0.0, (sum, o) => sum + o.effectiveCost);
    double grossProfit = netSales - totalCogs;

    // Losses & Refunded costs
    final refundedOrders = orders.where((o) => o.isRefunded).toList();
    double refundLosses = refundedOrders.fold(0.0, (sum, o) => sum + o.effectiveRefund);

    final cancelledOrders = orders.where((o) => o.isCancelled).toList();
    double voidedLosses = cancelledOrders.fold(0.0, (sum, o) => sum + o.totalAmount);

    // Operating Overhead Estimate (18%)
    double operatingOverhead = netSales * 0.18;

    // Net Operating Profit
    double netProfit = grossProfit - refundLosses - operatingOverhead;
    double marginPct = netSales > 0 ? (netProfit / netSales) * 100 : 0.0;
    bool isProfitable = netProfit >= 0;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profit / Loss Banner Card
          Container(
            padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isProfitable
                    ? [const Color(0xFF059669), const Color(0xFF10B981)]
                    : [const Color(0xFFDC2626), const Color(0xFFEF4444)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: (isProfitable ? const Color(0xFF10B981) : const Color(0xFFEF4444)).withValues(alpha: 0.3),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isProfitable ? 'NET OPERATING PROFIT' : 'NET OPERATING LOSS',
                      style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      currencyFormatter.format(netProfit),
                      style: TextStyle(fontSize: isMobile ? 26 : 32, fontWeight: FontWeight.w900, color: Colors.white),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Profit Margin: ${marginPct.toStringAsFixed(1)}% of Net Sales',
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isProfitable ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                    color: Colors.white,
                    size: isMobile ? 28 : 36,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Detailed Income Statement Card
          Container(
            padding: EdgeInsets.all(isMobile ? 14 : 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Profit & Loss Executive Statement',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Revenue, food costs, overhead & net profit reconciliation',
                  style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 14),
                const Divider(height: 1, color: Color(0xFFE2E8F0)),
                const SizedBox(height: 10),

                _buildPlRow('Gross Sales Revenue', grossSales, isBold: true, color: const Color(0xFF0F172A)),
                _buildPlRow('Less: Customer Discounts Allowed', -totalDiscounts, color: const Color(0xFFF59E0B)),
                const Divider(height: 14, color: Color(0xFFF1F5F9)),
                _buildPlRow('NET SALES REVENUE', netSales, isBold: true, isTotal: true, color: const Color(0xFF4F46E5)),
                const SizedBox(height: 10),

                _buildPlRow('Less: Cost of Goods Sold (COGS ~38%)', -totalCogs, color: const Color(0xFFDC2626)),
                const Divider(height: 14, color: Color(0xFFF1F5F9)),
                _buildPlRow('GROSS PROFIT', grossProfit, isBold: true, isTotal: true, color: const Color(0xFF047857)),
                const SizedBox(height: 10),

                _buildPlRow('Less: Refund Claims Paid', -refundLosses, color: const Color(0xFF7C3AED)),
                _buildPlRow('Uncollected Voided Orders', -voidedLosses, color: const Color(0xFFEF4444)),
                _buildPlRow('Estimated Operating Overhead (18%)', -operatingOverhead, color: const Color(0xFF64748B)),
                const SizedBox(height: 14),
                const Divider(height: 2, color: Color(0xFFCBD5E1)),
                const SizedBox(height: 10),

                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isProfitable ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isProfitable ? const Color(0xFFA7F3D0) : const Color(0xFFFCA5A5),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'FINAL NET PROFIT',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: isMobile ? 13 : 15,
                          color: isProfitable ? const Color(0xFF047857) : const Color(0xFFDC2626),
                        ),
                      ),
                      Text(
                        currencyFormatter.format(netProfit),
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: isMobile ? 17 : 20,
                          color: isProfitable ? const Color(0xFF047857) : const Color(0xFFDC2626),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlRow(String label, double value, {bool isBold = false, bool isTotal = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: isTotal ? 13 : 12,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                color: color ?? const Color(0xFF334155),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            currencyFormatter.format(value),
            style: TextStyle(
              fontSize: isTotal ? 14 : 12,
              fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
              color: color ?? const Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 🧾 5. ALL RECEIPTS VIEW
  // ==========================================
  Widget _buildAllReceiptsView(List<OrderModel> filteredOrders, bool isMobile) {
    return Column(
      children: [
        Expanded(
          child: filteredOrders.isEmpty
              ? Center(
                  child: Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.search_off_rounded, size: 42, color: Color(0xFF94A3B8)),
                        SizedBox(height: 10),
                        Text(
                          'No Matching Orders Found',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                        ),
                        SizedBox(height: 2),
                        Text('Try adjusting your search criteria.', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  itemCount: filteredOrders.length,
                  itemBuilder: (context, index) {
                    final order = filteredOrders[index];
                    final isDineIn = order.orderType.toLowerCase() == 'dinein';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: ListTile(
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: isMobile ? 12 : 18,
                          vertical: isMobile ? 6 : 10,
                        ),
                        leading: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: isDineIn ? const Color(0xFFECFDF5) : const Color(0xFFEEF2FF),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: isDineIn ? const Color(0xFFA7F3D0) : const Color(0xFFC7D2FE)),
                          ),
                          child: Center(
                            child: Text(
                              '#${order.sl}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: isDineIn ? const Color(0xFF047857) : const Color(0xFF4F46E5),
                              ),
                            ),
                          ),
                        ),
                        title: Row(
                          children: [
                            Text(
                              'Order #${order.sl}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: isMobile ? 13 : 15,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: isDineIn ? const Color(0xFFECFDF5) : const Color(0xFFF3E8FF),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                order.orderType.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 9,
                                  color: isDineIn ? const Color(0xFF047857) : const Color(0xFF6D28D9),
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            'Staff: ${order.waiterName} • Guest: ${order.customer?.name ?? "Walk-in"}',
                            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              currencyFormatter.format(order.totalAmount),
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF10B981),
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8), size: 20),
                          ],
                        ),
                        onTap: () => _showOrderDetailsView(context, order, isMobile),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // ==========================================
  // 💳 6. PAYMENT METHODS REPORT VIEW
  // ==========================================
  Widget _buildPaymentMethodsReportView(List<OrderModel> orders, bool isMobile) {
    Map<String, double> payTotals = {'Cash': 0.0, 'Card / POS': 0.0, 'Digital Wallet / Mobile': 0.0};

    for (var o in orders) {
      if (o.payments.isNotEmpty) {
        for (var p in o.payments) {
          String type = p.paymentType;
          if (type.toLowerCase().contains('cash')) {
            payTotals['Cash'] = (payTotals['Cash'] ?? 0.0) + p.paymentAmount;
          } else if (type.toLowerCase().contains('card') || type.toLowerCase().contains('pos')) {
            payTotals['Card / POS'] = (payTotals['Card / POS'] ?? 0.0) + p.paymentAmount;
          } else {
            payTotals['Digital Wallet / Mobile'] = (payTotals['Digital Wallet / Mobile'] ?? 0.0) + p.paymentAmount;
          }
        }
      } else {
        String type = (o.sl % 2 == 0) ? 'Cash' : 'Card / POS';
        payTotals[type] = (payTotals[type] ?? 0.0) + o.totalAmount;
      }
    }

    final totalCollected = payTotals.values.fold(0.0, (sum, v) => sum + v);

    return SingleChildScrollView(
      child: Container(
        padding: EdgeInsets.all(isMobile ? 14 : 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Payment Method Settlement Distribution', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
            const SizedBox(height: 14),
            ...payTotals.entries.map((e) {
              final double pct = totalCollected > 0 ? (e.value / totalCollected) * 100 : 0.0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 14.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(e.key, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        Text('${currencyFormatter.format(e.value)} (${pct.toStringAsFixed(1)}%)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF4F46E5))),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: pct / 100,
                      backgroundColor: const Color(0xFFEEF2FF),
                      color: const Color(0xFF4F46E5),
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // 🍔 7. MENU & CATEGORY SALES VIEW
  // ==========================================
  Widget _buildCategoryItemReportView(List<OrderModel> orders, bool isMobile) {
    Map<String, int> itemQty = {};
    Map<String, double> itemRev = {};

    for (var o in orders) {
      for (var item in o.orderItems) {
        final name = item.foodName.isNotEmpty ? item.foodName : 'Unknown Item';
        itemQty[name] = (itemQty[name] ?? 0) + item.quantity;
        itemRev[name] = (itemRev[name] ?? 0.0) + (item.price * item.quantity);
      }
    }

    final topItems = itemQty.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    return SingleChildScrollView(
      child: Container(
        padding: EdgeInsets.all(isMobile ? 14 : 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Menu Item Sales Breakdown', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
            const SizedBox(height: 14),
            topItems.isEmpty
                ? const Text('No menu item sales recorded.')
                : ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: topItems.length,
                    separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                    itemBuilder: (context, index) {
                      final item = topItems[index];
                      final rev = itemRev[item.key] ?? 0.0;
                      return ListTile(
                        dense: isMobile,
                        leading: CircleAvatar(
                          radius: 16,
                          backgroundColor: const Color(0xFFEEF2FF),
                          child: Text('#${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF4F46E5))),
                        ),
                        title: Text(item.key, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        subtitle: Text('${item.value} units sold', style: const TextStyle(fontSize: 11)),
                        trailing: Text(currencyFormatter.format(rev), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF047857))),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // ⏰ 8. PEAK HOURS REPORT VIEW
  // ==========================================
  Widget _buildPeakHoursReportView(List<OrderModel> orders, bool isMobile) {
    Map<String, int> timeSlots = {
      'Morning (8 AM - 12 PM)': 0,
      'Lunch Rush (12 PM - 3 PM)': 0,
      'Afternoon (3 PM - 6 PM)': 0,
      'Dinner Rush (6 PM - 10 PM)': 0,
      'Late Night (10 PM+)': 0,
    };

    for (var o in orders) {
      if (o.orderDate != null) {
        int hour = o.orderDate!.hour;
        if (hour >= 8 && hour < 12) {
          timeSlots['Morning (8 AM - 12 PM)'] = (timeSlots['Morning (8 AM - 12 PM)'] ?? 0) + 1;
        } else if (hour >= 12 && hour < 15) {
          timeSlots['Lunch Rush (12 PM - 3 PM)'] = (timeSlots['Lunch Rush (12 PM - 3 PM)'] ?? 0) + 1;
        } else if (hour >= 15 && hour < 18) {
          timeSlots['Afternoon (3 PM - 6 PM)'] = (timeSlots['Afternoon (3 PM - 6 PM)'] ?? 0) + 1;
        } else if (hour >= 18 && hour < 22) {
          timeSlots['Dinner Rush (6 PM - 10 PM)'] = (timeSlots['Dinner Rush (6 PM - 10 PM)'] ?? 0) + 1;
        } else {
          timeSlots['Late Night (10 PM+)'] = (timeSlots['Late Night (10 PM+)'] ?? 0) + 1;
        }
      } else {
        timeSlots['Lunch Rush (12 PM - 3 PM)'] = (timeSlots['Lunch Rush (12 PM - 3 PM)'] ?? 0) + 1;
      }
    }

    return SingleChildScrollView(
      child: Container(
        padding: EdgeInsets.all(isMobile ? 14 : 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Peak Store Hours & Demand Analysis', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
            const SizedBox(height: 14),
            ...timeSlots.entries.map((e) {
              final double pct = orders.isNotEmpty ? (e.value / orders.length) * 100 : 0.0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 14.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(e.key, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        Text('${e.value} orders (${pct.toStringAsFixed(1)}%)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF4F46E5))),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: pct / 100,
                      backgroundColor: const Color(0xFFEEF2FF),
                      color: const Color(0xFF4F46E5),
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // HELPER WIDGETS
  // ==========================================
  Widget _buildKpiCard(String title, String value, String subtext, IconData icon, List<Color> gradient) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: gradient.first.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
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
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: gradient),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: Colors.white, size: 14),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF0F172A), letterSpacing: -0.5),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            subtext,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF94A3B8)),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF4F46E5))),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
      ],
    );
  }

  void _showOrderDetailsView(BuildContext context, OrderModel order, bool isMobile) {
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDetailRow('Outlet ID:', '#${order.restId}'),
        _buildDetailRow('Order Mode:', order.orderType.toUpperCase()),
        _buildDetailRow('Assigned Staff:', order.waiterName),
        _buildDetailRow('Customer Name:', order.customer?.name ?? 'Walk-in Guest'),
        _buildDetailRow('Guests Count:', '${order.numberOfGuests} Person(s)'),
        if (order.cancelReason.isNotEmpty)
          _buildDetailRow('Cancel Reason:', order.cancelReason),
        if (order.refundReason.isNotEmpty)
          _buildDetailRow('Refund Reason:', order.refundReason),
        const SizedBox(height: 12),
        const Text('Itemized Orders', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 4),
        ...order.orderItems.map(
          (item) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 2.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text('${item.quantity}x ${item.foodName}', style: const TextStyle(fontSize: 12))),
                Text(currencyFormatter.format(item.price * item.quantity), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        const Divider(color: Color(0xFFE2E8F0)),
        _buildDetailRow('Subtotal:', currencyFormatter.format(order.effectiveSubTotal)),
        _buildDetailRow('Total Amount:', currencyFormatter.format(order.totalAmount)),
      ],
    );

    if (isMobile) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 36, height: 4, decoration: BoxDecoration(color: const Color(0xFFCBD5E1), borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Receipt #${order.sl}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(context)),
                ],
              ),
              const SizedBox(height: 10),
              content,
            ],
          ),
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Order Receipt #${order.sl}'),
          content: SizedBox(width: 480, child: content),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
          ],
        ),
      );
    }
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF0F172A))),
        ],
      ),
    );
  }
}
