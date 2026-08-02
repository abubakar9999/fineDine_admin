class SettingsCategoryModel {
  final String id;
  final String name;
  final String restId;
  final int sl;

  SettingsCategoryModel({
    required this.id,
    required this.name,
    required this.restId,
    this.sl = 0,
  });

  factory SettingsCategoryModel.fromJson(Map<String, dynamic> json) {
    return SettingsCategoryModel(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      restId: json['restId'] ?? '',
      sl: (json['sl'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'restId': restId,
      'sl': sl,
    };
  }
}

class PortionModel {
  final String id;
  final String portionName;
  final double portionPrice;

  PortionModel({
    required this.id,
    required this.portionName,
    required this.portionPrice,
  });

  factory PortionModel.fromJson(Map<String, dynamic> json) {
    return PortionModel(
      id: json['_id'] ?? json['id'] ?? '',
      portionName: json['portionName'] ?? '',
      portionPrice: (json['portionPrice'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'portionName': portionName,
      'portionPrice': portionPrice,
    };
  }
}

class SettingsItemModel {
  final String id;
  final String name;
  final String categoryId;
  final String categoryName;
  final List<PortionModel> portions;
  final double price;
  final String restId;

  SettingsItemModel({
    required this.id,
    required this.name,
    required this.categoryId,
    required this.categoryName,
    required this.portions,
    required this.price,
    required this.restId,
  });

  factory SettingsItemModel.fromJson(Map<String, dynamic> json) {
    List<PortionModel> pList = [];
    if (json['portions'] is List) {
      pList = (json['portions'] as List).map((p) => PortionModel.fromJson(p)).toList();
    }
    String cId = '';
    String cName = '';
    if (json['categories'] is List && (json['categories'] as List).isNotEmpty) {
      final cat = (json['categories'] as List).first;
      if (cat is Map<String, dynamic>) {
        cId = cat['_id'] ?? cat['id'] ?? '';
        cName = cat['name'] ?? '';
      }
    } else if (json['categoryId'] != null) {
      cId = json['categoryId'].toString();
    }

    return SettingsItemModel(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      categoryId: cId,
      categoryName: cName,
      portions: pList,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      restId: json['restId'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'price': price,
      'restId': restId,
      'categories': [
        {'_id': categoryId, 'name': categoryName, 'restId': restId}
      ],
      'portions': portions.map((p) => p.toJson()).toList(),
    };
  }
}

class AreaModel {
  final String id;
  final String name;
  final String restId;

  AreaModel({required this.id, required this.name, required this.restId});

  factory AreaModel.fromJson(Map<String, dynamic> json) {
    return AreaModel(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      restId: json['restId'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'restId': restId,
    };
  }
}
