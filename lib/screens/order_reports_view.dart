import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
  String _searchQuery = '';
  String _selectedOrderType = 'All';

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    final dateFormatter = DateFormat('MMM dd, yyyy • hh:mm a');

    final filteredOrders = widget.orders.where((order) {
      final matchesSearch = order.sl.toString().contains(_searchQuery) ||
          order.id.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (order.customer?.name.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
      final matchesType = _selectedOrderType == 'All' ||
          order.orderType.toLowerCase() == _selectedOrderType.toLowerCase();

      return matchesSearch && matchesType;
    }).toList();

    return RefreshIndicator(
      color: const Color(0xFF4F46E5),
      onRefresh: () async => widget.onRefresh(),
      child: Padding(
        padding: const EdgeInsets.all(28.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Order Reports & Receipts',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.5,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Search, filter and inspect store transaction receipts',
                      style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: widget.onRefresh,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Refresh'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  ),
                )
              ],
            ),
            const SizedBox(height: 24),

            // Filter & Search Header Card
            Container(
              padding: const EdgeInsets.all(20.0),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'Search by Order #, Order ID, or Customer name...',
                            prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF64748B)),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear_rounded, size: 18),
                                    onPressed: () => setState(() => _searchQuery = ''),
                                  )
                                : null,
                            isDense: true,
                          ),
                          onChanged: (value) {
                            setState(() {
                              _searchQuery = value;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      const Text(
                        'Filter Order Type: ',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                      ),
                      const SizedBox(width: 8),
                      Wrap(
                        spacing: 8,
                        children: ['All', 'DineIn', 'Takeaway'].map((type) {
                          final isSelected = _selectedOrderType.toLowerCase() == type.toLowerCase();
                          return ChoiceChip(
                            label: Text(type),
                            selected: isSelected,
                            onSelected: (selected) {
                              if (selected) {
                                setState(() {
                                  _selectedOrderType = type;
                                });
                              }
                            },
                            selectedColor: const Color(0xFFEEF2FF),
                            labelStyle: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFF64748B),
                            ),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            side: BorderSide(
                              color: isSelected ? const Color(0xFFC7D2FE) : const Color(0xFFE2E8F0),
                            ),
                          );
                        }).toList(),
                      ),
                      const Spacer(),
                      Text(
                        'Showing ${filteredOrders.length} of ${widget.orders.length} orders',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Orders List / Table
            Expanded(
              child: filteredOrders.isEmpty
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
                            Icon(Icons.search_off_rounded, size: 48, color: Color(0xFF94A3B8)),
                            SizedBox(height: 12),
                            Text(
                              'No Matching Orders Found',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                            ),
                            SizedBox(height: 4),
                            Text('Try adjusting your search criteria or order type filter.', style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
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
                          margin: const EdgeInsets.only(bottom: 12),
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
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            leading: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: isDineIn ? const Color(0xFFECFDF5) : const Color(0xFFEEF2FF),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: isDineIn ? const Color(0xFFA7F3D0) : const Color(0xFFC7D2FE)),
                              ),
                              child: Center(
                                child: Text(
                                  '#${order.sl}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: isDineIn ? const Color(0xFF047857) : const Color(0xFF4F46E5),
                                  ),
                                ),
                              ),
                            ),
                            title: Row(
                              children: [
                                Text(
                                  'Order #${order.sl}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A)),
                                ),
                                const SizedBox(width: 10),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: isDineIn ? const Color(0xFFECFDF5) : const Color(0xFFF3E8FF),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: isDineIn ? const Color(0xFFA7F3D0) : const Color(0xFFDDD6FE)),
                                  ),
                                  child: Text(
                                    order.orderType.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isDineIn ? const Color(0xFF047857) : const Color(0xFF6D28D9),
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 6.0),
                              child: Row(
                                children: [
                                  Icon(Icons.person_outline_rounded, size: 14, color: const Color(0xFF64748B)),
                                  const SizedBox(width: 4),
                                  Text(
                                    order.customer?.name ?? 'Walk-in Guest',
                                    style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF334155), fontSize: 13),
                                  ),
                                  const SizedBox(width: 12),
                                  Icon(Icons.people_outline_rounded, size: 14, color: const Color(0xFF64748B)),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${order.numberOfGuests} Guest(s)',
                                    style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                                  ),
                                  const SizedBox(width: 12),
                                  Icon(Icons.schedule_rounded, size: 14, color: const Color(0xFF64748B)),
                                  const SizedBox(width: 4),
                                  Text(
                                    order.orderDate != null ? dateFormatter.format(order.orderDate!) : 'N/A',
                                    style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      currencyFormatter.format(order.totalAmount),
                                      style: const TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF10B981),
                                      ),
                                    ),
                                    Text(
                                      '${order.orderItems.length} Item(s)',
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF64748B)),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 12),
                                const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
                              ],
                            ),
                            onTap: () => _showOrderDetailsDialog(context, order),
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

  void _showOrderDetailsDialog(BuildContext context, OrderModel order) {
    final currencyFormatter = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    final dateFormatter = DateFormat('MMM dd, yyyy • hh:mm a');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titlePadding: EdgeInsets.zero,
        contentPadding: const EdgeInsets.all(24),
        content: SizedBox(
          width: 520,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Dialog Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEF2FF),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.receipt_long_rounded, color: Color(0xFF4F46E5), size: 24),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Order Receipt #${order.sl}',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                          ),
                          Text(
                            order.orderDate != null ? dateFormatter.format(order.orderDate!) : '',
                            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(color: Color(0xFFE2E8F0)),
              const SizedBox(height: 12),

              // Details Info Box
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    _buildDetailRow('Restaurant Outlet ID:', '#${order.restId}'),
                    _buildDetailRow('Order Mode:', order.orderType.toUpperCase()),
                    _buildDetailRow('Customer Name:', order.customer?.name ?? 'Walk-in Customer'),
                    _buildDetailRow('Phone Number:', order.customer?.phone ?? 'N/A'),
                    _buildDetailRow('Guests Count:', '${order.numberOfGuests} Person(s)'),
                    if (order.tables.isNotEmpty)
                      _buildDetailRow('Table Allocation:', order.tables.map((t) => t.name).join(', ')),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Itemized Orders',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 10),
              ...order.orderItems.map(
                (item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          '${item.quantity}x ${item.foodName} (${item.portionName})',
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF334155)),
                        ),
                      ),
                      Text(
                        currencyFormatter.format(item.price * item.quantity),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Divider(color: Color(0xFFE2E8F0)),
              const SizedBox(height: 10),
              _buildDetailRow('Subtotal:', currencyFormatter.format(order.subTotal)),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFA7F3D0)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total Paid Amount',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Color(0xFF047857)),
                    ),
                    Text(
                      currencyFormatter.format(order.totalAmount),
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Color(0xFF047857)),
                    ),
                  ],
                ),
              ),
              if (order.payments.isNotEmpty) ...[
                const SizedBox(height: 14),
                const Text(
                  'Payment Method Breakdown',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF475569)),
                ),
                const SizedBox(height: 6),
                ...order.payments.map((p) => _buildDetailRow(p.paymentType, currencyFormatter.format(p.paymentAmount))),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF0F172A))),
        ],
      ),
    );
  }
}

