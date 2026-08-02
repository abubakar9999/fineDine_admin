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
    final dateFormatter = DateFormat('yyyy-MM-dd HH:mm');

    final filteredOrders = widget.orders.where((order) {
      final matchesSearch = order.sl.toString().contains(_searchQuery) ||
          order.id.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (order.customer?.name.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
      final matchesType = _selectedOrderType == 'All' ||
          order.orderType.toLowerCase() == _selectedOrderType.toLowerCase();

      return matchesSearch && matchesType;
    }).toList();

    return RefreshIndicator(
      onRefresh: () async => widget.onRefresh(),
      child: Padding(
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
                      'Order Reports',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.indigo.shade900,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Detailed view of all store transactions and receipts',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: widget.onRefresh,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Refresh'),
                )
              ],
            ),
            const SizedBox(height: 20),
            // Filter Bar
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Search by Order SL, ID, or Customer name...',
                          prefixIcon: const Icon(Icons.search),
                          isDense: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    DropdownButton<String>(
                      value: _selectedOrderType,
                      underline: const SizedBox(),
                      items: ['All', 'DineIn', 'Takeaway', 'Delivery']
                          .map((type) => DropdownMenuItem(
                                value: type,
                                child: Text('Type: $type'),
                              ))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _selectedOrderType = val;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Orders List / Table
            Expanded(
              child: filteredOrders.isEmpty
                  ? const Center(
                      child: Text('No orders match your search filter.'),
                    )
                  : ListView.builder(
                      itemCount: filteredOrders.length,
                      itemBuilder: (context, index) {
                        final order = filteredOrders[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16),
                            leading: CircleAvatar(
                              radius: 24,
                              backgroundColor: Colors.indigo.shade100,
                              child: Text(
                                '#${order.sl}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.indigo,
                                ),
                              ),
                            ),
                            title: Row(
                              children: [
                                Text(
                                  'Order #${order.sl}',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.indigo.shade50,
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: Colors.indigo.shade200),
                                  ),
                                  child: Text(
                                    order.orderType,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.indigo.shade700,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Customer: ${order.customer?.name ?? 'N/A'} | Guests: ${order.numberOfGuests}',
                                  ),
                                  Text(
                                    'Date: ${order.orderDate != null ? dateFormatter.format(order.orderDate!) : 'N/A'}',
                                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  currencyFormatter.format(order.totalAmount),
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                                Text(
                                  '${order.orderItems.length} Item(s)',
                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                                ),
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

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Order #${order.sl} Details'),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow('Rest ID:', order.restId),
                _buildDetailRow('Order Type:', order.orderType),
                _buildDetailRow('Customer:', order.customer?.name ?? 'N/A'),
                _buildDetailRow('Phone:', order.customer?.phone ?? 'N/A'),
                _buildDetailRow('Guests:', '${order.numberOfGuests}'),
                if (order.tables.isNotEmpty)
                  _buildDetailRow('Table:', order.tables.map((t) => t.name).join(', ')),
                const Divider(height: 24),
                const Text(
                  'Order Items:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                ...order.orderItems.map(
                  (item) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${item.quantity}x ${item.foodName} (${item.portionName})'),
                        Text(currencyFormatter.format(item.price * item.quantity)),
                      ],
                    ),
                  ),
                ),
                const Divider(height: 24),
                _buildDetailRow('Subtotal:', currencyFormatter.format(order.subTotal)),
                _buildDetailRow('Total Amount:', currencyFormatter.format(order.totalAmount), isBold: true),
                if (order.payments.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Text(
                    'Payment Breakdown:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  ...order.payments.map((p) => _buildDetailRow(p.paymentType, currencyFormatter.format(p.paymentAmount))),
                ]
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text(value, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }
}
