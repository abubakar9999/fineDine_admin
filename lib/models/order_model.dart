class OrderModel {
  final String id;
  final String restId;
  final int sl;
  final String orderStatus;
  final String orderType;
  final double totalAmount;
  final double subTotal;
  final double totalPaymentAmount;
  final double dueAmount;
  final int numberOfGuests;
  final DateTime? orderDate;
  final CustomerModel? customer;
  final List<TableModel> tables;
  final List<OrderItemModel> orderItems;
  final List<PaymentModel> payments;

  OrderModel({
    required this.id,
    required this.restId,
    required this.sl,
    required this.orderStatus,
    required this.orderType,
    required this.totalAmount,
    required this.subTotal,
    required this.totalPaymentAmount,
    required this.dueAmount,
    required this.numberOfGuests,
    this.orderDate,
    this.customer,
    required this.tables,
    required this.orderItems,
    required this.payments,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['_id'] ?? '',
      restId: json['restId'] ?? '',
      sl: json['sl'] is int ? json['sl'] : int.tryParse(json['sl']?.toString() ?? '0') ?? 0,
      orderStatus: json['orderStatus']?.toString() ?? '',
      orderType: json['orderType']?.toString() ?? 'DineIn',
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
      subTotal: (json['subTotal'] as num?)?.toDouble() ?? 0.0,
      totalPaymentAmount: (json['totalPaymentAmount'] as num?)?.toDouble() ?? 0.0,
      dueAmount: (json['dueAmount'] as num?)?.toDouble() ?? 0.0,
      numberOfGuests: json['numberOfGuests'] is int ? json['numberOfGuests'] : int.tryParse(json['numberOfGuests']?.toString() ?? '1') ?? 1,
      orderDate: json['orderDate'] != null ? DateTime.tryParse(json['orderDate'].toString()) : null,
      customer: json['customer'] != null && json['customer'] is Map<String, dynamic> ? CustomerModel.fromJson(json['customer']) : null,
      tables: json['table'] is List ? (json['table'] as List).map((t) => TableModel.fromJson(t)).toList() : [],
      orderItems: json['orderItems'] is List ? (json['orderItems'] as List).map((i) => OrderItemModel.fromJson(i)).toList() : [],
      payments: json['payment'] is List ? (json['payment'] as List).map((p) => PaymentModel.fromJson(p)).toList() : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'restId': restId,
      'sl': sl,
      'orderStatus': orderStatus,
      'orderType': orderType,
      'totalAmount': totalAmount,
      'subTotal': subTotal,
      'totalPaymentAmount': totalPaymentAmount,
      'dueAmount': dueAmount,
      'numberOfGuests': numberOfGuests,
      'orderDate': orderDate?.toIso8601String(),
      'customer': customer?.toJson(),
      'table': tables.map((t) => t.toJson()).toList(),
      'orderItems': orderItems.map((i) => i.toJson()).toList(),
      'payment': payments.map((p) => p.toJson()).toList(),
    };
  }
}

class CustomerModel {
  final String id;
  final String name;
  final String phone;
  final String notes;

  CustomerModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.notes,
  });

  factory CustomerModel.fromJson(Map<String, dynamic> json) {
    return CustomerModel(
      id: json['_id'] ?? '',
      name: json['name'] ?? 'N/A',
      phone: json['phone'] ?? 'N/A',
      notes: json['notes'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'phone': phone,
      'notes': notes,
    };
  }
}

class TableModel {
  final String id;
  final String name;
  final int capacity;
  final String area;

  TableModel({
    required this.id,
    required this.name,
    required this.capacity,
    required this.area,
  });

  factory TableModel.fromJson(Map<String, dynamic> json) {
    return TableModel(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      capacity: (json['capacity'] as num?)?.toInt() ?? 0,
      area: json['area'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'capacity': capacity,
      'area': area,
    };
  }
}

class OrderItemModel {
  final String id;
  final List<String> foodId;
  final String foodName;
  final double price;
  final int quantity;
  final String portionName;
  final double portionPrice;

  OrderItemModel({
    required this.id,
    required this.foodId,
    required this.foodName,
    required this.price,
    required this.quantity,
    required this.portionName,
    required this.portionPrice,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    String fName = 'Unknown Item';
    String pName = '';
    double pPrice = 0.0;
    int qty = 1;
    double itemPrice = 0.0;

    if (json['food'] is List && (json['food'] as List).isNotEmpty) {
      final f = (json['food'] as List).first;
      if (f is Map<String, dynamic>) {
        fName = f['name'] ?? fName;
        qty = (f['quantity'] as num?)?.toInt() ?? 1;
        itemPrice = (f['price'] as num?)?.toDouble() ?? 0.0;
        if (f['portions'] is List && (f['portions'] as List).isNotEmpty) {
          final p = (f['portions'] as List).first;
          if (p is Map<String, dynamic>) {
            pName = p['portionName'] ?? '';
            pPrice = (p['portionPrice'] as num?)?.toDouble() ?? 0.0;
          }
        }
      }
    }

    return OrderItemModel(
      id: json['_id'] ?? '',
      foodId: json['foodId'] is List ? List<String>.from(json['foodId']) : [],
      foodName: fName,
      price: itemPrice,
      quantity: qty,
      portionName: pName,
      portionPrice: pPrice,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'foodId': foodId,
      'food': [
        {
          'name': foodName,
          'quantity': quantity,
          'price': price,
          'portions': [
            {'portionName': portionName, 'portionPrice': portionPrice}
          ]
        }
      ]
    };
  }
}

class PaymentModel {
  final String id;
  final String paymentType;
  final double paymentAmount;
  final double cashAmount;

  PaymentModel({
    required this.id,
    required this.paymentType,
    required this.paymentAmount,
    required this.cashAmount,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      id: json['_id'] ?? '',
      paymentType: json['paymentType'] ?? '',
      paymentAmount: (json['paymentAmount'] as num?)?.toDouble() ?? 0.0,
      cashAmount: (json['cashAmount'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'paymentType': paymentType,
      'paymentAmount': paymentAmount,
      'cashAmount': cashAmount,
    };
  }
}
