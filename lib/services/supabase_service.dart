import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/order_model.dart';

class SupabaseService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Fetch app backup entry for a given restId (supporting string or integer rest_id)
  Future<Map<String, dynamic>?> fetchBackupByRestId(String restId) async {
    try {
      final response = await _supabase
          .from('app_backups')
          .select()
          .eq('rest_id', restId)
          .maybeSingle();

      if (response != null) return response;
    } catch (_) {}

    final numId = int.tryParse(restId);
    if (numId != null) {
      try {
        final response = await _supabase
            .from('app_backups')
            .select()
            .eq('rest_id', numId)
            .maybeSingle();

        if (response != null) return response;
      } catch (_) {}
    }
    return null;
  }

  // Helper to parse orders array from backup data
  List<OrderModel> parseOrders(dynamic ordersData) {
    if (ordersData == null) return [];
    
    dynamic parsed = ordersData;
    if (ordersData is String) {
      try {
        parsed = jsonDecode(ordersData);
      } catch (e) {
        return [];
      }
    }

    if (parsed is List) {
      return parsed.map((item) => OrderModel.fromJson(Map<String, dynamic>.from(item))).toList();
    }
    return [];
  }

  // Helper to parse settings map from backup data and normalize total_data_table and common aliases
  Map<String, dynamic> parseSettings(dynamic settingsData) {
    if (settingsData == null) return {};

    dynamic parsed = settingsData;
    if (settingsData is String) {
      try {
        parsed = jsonDecode(settingsData);
      } catch (e) {
        return {};
      }
    }

    if (parsed is Map<String, dynamic>) {
      final Map<String, dynamic> settings = Map<String, dynamic>.from(parsed);

      // Extract from total_data_table list if present
      if (settings['total_data_table'] is List) {
        final List totalList = settings['total_data_table'] as List;

        for (var obj in totalList) {
          if (obj is Map<String, dynamic>) {
            if (obj.containsKey('foodSettingData') && obj['foodSettingData'] is List) {
              settings['items'] = obj['foodSettingData'];
              settings['foodSettingData'] = obj['foodSettingData'];
            }
            if (obj.containsKey('categoryData') && obj['categoryData'] is List) {
              settings['categories'] = obj['categoryData'];
              settings['categoryData'] = obj['categoryData'];
            }
            if (obj.containsKey('cuisineData') && obj['cuisineData'] is List) {
              settings['cuisines'] = obj['cuisineData'];
              settings['cuisineData'] = obj['cuisineData'];
            }
            if (obj.containsKey('tagData') && obj['tagData'] is List) {
              settings['tags'] = obj['tagData'];
              settings['tagData'] = obj['tagData'];
            }
            if (obj.containsKey('tableData') && obj['tableData'] is List) {
              settings['tables'] = obj['tableData'];
              settings['tableData'] = obj['tableData'];
            }
            if (obj.containsKey('areaData') && obj['areaData'] is List) {
              settings['areas'] = obj['areaData'];
              settings['areaData'] = obj['areaData'];
            }
            if (obj.containsKey('staffData') && obj['staffData'] is List) {
              settings['staff'] = obj['staffData'];
              settings['staffData'] = obj['staffData'];
            }
            if (obj.containsKey('promotionData') && obj['promotionData'] is List) {
              settings['promotions'] = obj['promotionData'];
              settings['promotionData'] = obj['promotionData'];
            }
            if (obj.containsKey('tillData') && obj['tillData'] is List) {
              settings['tills'] = obj['tillData'];
              settings['tillData'] = obj['tillData'];
            }
            if (obj.containsKey('kitchenData') && obj['kitchenData'] is List) {
              settings['kitchens'] = obj['kitchenData'];
              settings['kitchenData'] = obj['kitchenData'];
            }
            if (obj.containsKey('barData') && obj['barData'] is List) {
              settings['bars'] = obj['barData'];
              settings['barData'] = obj['barData'];
            }
            if (obj.containsKey('paymentMethodSettingData') && obj['paymentMethodSettingData'] is List) {
              settings['paymentMethods'] = obj['paymentMethodSettingData'];
              settings['paymentMethodSettingData'] = obj['paymentMethodSettingData'];
            }
            if (obj.containsKey('customerData') && obj['customer_data_table'] == 'customerTable') {
              settings['customers'] = obj['customerData'];
              settings['customerData'] = obj['customerData'];
            } else if (obj.containsKey('customerData') && obj['print_copy_data_table'] == 'printCopyTable') {
              settings['printCopyData'] = obj['customerData'];
            } else if (obj.containsKey('printCopyData') && obj['print_copy_data_table'] == 'printCopyTable') {
              settings['printCopyData'] = obj['printCopyData'];
            }
            if (obj.containsKey('basicSettingData')) {
              settings['basicSettingData'] = obj['basicSettingData'];
              settings['basicSettings'] = obj['basicSettingData'];
            }
            if (obj.containsKey('kukdData')) {
              settings['kukdData'] = obj['kukdData'];
            }
            if (obj.containsKey('expenseGroupData') && obj['expenseGroupData'] is List) {
              settings['expenseGroups'] = obj['expenseGroupData'];
              settings['expenseGroupData'] = obj['expenseGroupData'];
            }
            if (obj.containsKey('expenseHeadData') && obj['expenseHeadData'] is List) {
              settings['expenseHeads'] = obj['expenseHeadData'];
              settings['expenseHeadData'] = obj['expenseHeadData'];
            }
            if (obj.containsKey('expenseItemData') && obj['expenseItemData'] is List) {
              settings['expenseItems'] = obj['expenseItemData'];
              settings['expenseItemData'] = obj['expenseItemData'];
            }
            if (obj.containsKey('stockData') && obj['stockData'] is List) {
              settings['stocks'] = obj['stockData'];
              settings['stockData'] = obj['stockData'];
            }
            if (obj.containsKey('stockLogData') && obj['stockLogData'] is List) {
              settings['stockLogs'] = obj['stockLogData'];
              settings['stockLogData'] = obj['stockLogData'];
            }
            if (obj.containsKey('ingredientData') && obj['ingredientData'] is List) {
              settings['ingredients'] = obj['ingredientData'];
              settings['ingredientData'] = obj['ingredientData'];
            }
            if (obj.containsKey('recipeData') && obj['recipeData'] is List) {
              settings['recipes'] = obj['recipeData'];
              settings['recipeData'] = obj['recipeData'];
            }
          }
        }
      }

      // Fallback normalization for top-level keys
      if (!settings.containsKey('items') || (settings['items'] is! List || (settings['items'] as List).isEmpty)) {
        for (var key in ['foodItems', 'food_items', 'foodSettingData', 'menuItems']) {
          if (settings[key] is List && (settings[key] as List).isNotEmpty) {
            settings['items'] = settings[key];
            break;
          }
        }
      }

      if (!settings.containsKey('categories') || (settings['categories'] is! List || (settings['categories'] as List).isEmpty)) {
        for (var key in ['foodCategories', 'food_categories', 'categoryData']) {
          if (settings[key] is List && (settings[key] as List).isNotEmpty) {
            settings['categories'] = settings[key];
            break;
          }
        }
      }

      if (!settings.containsKey('cuisines') || (settings['cuisines'] is! List || (settings['cuisines'] as List).isEmpty)) {
        if (settings['cuisineData'] is List && (settings['cuisineData'] as List).isNotEmpty) {
          settings['cuisines'] = settings['cuisineData'];
        }
      }

      if (!settings.containsKey('tags') || (settings['tags'] is! List || (settings['tags'] as List).isEmpty)) {
        if (settings['tagData'] is List && (settings['tagData'] as List).isNotEmpty) {
          settings['tags'] = settings['tagData'];
        }
      }

      if (!settings.containsKey('tables') || (settings['tables'] is! List || (settings['tables'] as List).isEmpty)) {
        for (var key in ['table_list', 'tableData', 'restaurant_tables']) {
          if (settings[key] is List && (settings[key] as List).isNotEmpty) {
            settings['tables'] = settings[key];
            break;
          }
        }
      }

      if (!settings.containsKey('areas') || (settings['areas'] is! List || (settings['areas'] as List).isEmpty)) {
        for (var key in ['area_list', 'areaData', 'restaurant_areas']) {
          if (settings[key] is List && (settings[key] as List).isNotEmpty) {
            settings['areas'] = settings[key];
            break;
          }
        }
      }

      if (!settings.containsKey('staff') && settings['staffData'] is List) {
        settings['staff'] = settings['staffData'];
      }
      if (!settings.containsKey('customers') && settings['customerData'] is List) {
        settings['customers'] = settings['customerData'];
      }
      if (!settings.containsKey('expenseGroups') && settings['expenseGroupData'] is List) {
        settings['expenseGroups'] = settings['expenseGroupData'];
      }
      if (!settings.containsKey('expenseHeads') && settings['expenseHeadData'] is List) {
        settings['expenseHeads'] = settings['expenseHeadData'];
      }
      if (!settings.containsKey('expenseItems') && settings['expenseItemData'] is List) {
        settings['expenseItems'] = settings['expenseItemData'];
      }
      if (!settings.containsKey('stocks') && settings['stockData'] is List) {
        settings['stocks'] = settings['stockData'];
      }
      if (!settings.containsKey('stockLogs') && settings['stockLogData'] is List) {
        settings['stockLogs'] = settings['stockLogData'];
      }
      if (!settings.containsKey('ingredients') && settings['ingredientData'] is List) {
        settings['ingredients'] = settings['ingredientData'];
      }
      if (!settings.containsKey('recipes') && settings['recipeData'] is List) {
        settings['recipes'] = settings['recipeData'];
      }

      return settings;
    }
    return {};
  }

  // Deep sanitizer to ensure 100% compatibility with rest_pos Hive models
  static Map<String, dynamic> sanitizeSettingsData(String restId, Map<String, dynamic> raw) {
    final nowIso = DateTime.now().toIso8601String();

    // Helper to get raw array by potential alias keys
    List<Map<String, dynamic>> extractList(List<String> keys) {
      if (raw['total_data_table'] is List) {
        for (var obj in (raw['total_data_table'] as List)) {
          if (obj is Map<String, dynamic>) {
            for (var k in keys) {
              if (obj.containsKey(k) && obj[k] is List) {
                return List<Map<String, dynamic>>.from(
                  (obj[k] as List).whereType<Map>().map((m) => Map<String, dynamic>.from(m)),
                );
              }
            }
          }
        }
      }
      for (var k in keys) {
        if (raw[k] is List) {
          return List<Map<String, dynamic>>.from(
            (raw[k] as List).whereType<Map>().map((m) => Map<String, dynamic>.from(m)),
          );
        }
      }
      return [];
    }

    // 1. Food Items (foodSettingData)
    final rawItems = extractList(['foodSettingData', 'items', 'foodItems']);
    final cleanItems = rawItems.asMap().entries.map((entry) {
      final idx = entry.key;
      final i = entry.value;

      // Ensure portions have complete structure
      List<Map<String, dynamic>> portions = [];
      if (i['portions'] is List && (i['portions'] as List).isNotEmpty) {
        portions = (i['portions'] as List).whereType<Map>().map((pMap) {
          final p = Map<String, dynamic>.from(pMap);
          final price = (p['portionPriceDineIn'] ?? p['portionPrice'] ?? 0.0).toDouble();
          return {
            '_id': p['_id'] ?? 'p_${DateTime.now().millisecondsSinceEpoch}_$idx',
            'portionName': (p['portionName'] ?? 'Standard').toString(),
            'portionPriceDineIn': (p['portionPriceDineIn'] as num?)?.toDouble() ?? price,
            'portionPriceCollection': (p['portionPriceCollection'] as num?)?.toDouble() ?? price,
            'portionPriceDelivery': (p['portionPriceDelivery'] as num?)?.toDouble() ?? price,
            'portionPriceWaiting': (p['portionPriceWaiting'] as num?)?.toDouble() ?? price,
            'portionPrice': price,
          };
        }).toList();
      }

      if (portions.isEmpty) {
        final pr = (i['price'] as num?)?.toDouble() ?? 0.0;
        portions = [
          {
            '_id': 'p_${DateTime.now().millisecondsSinceEpoch}_$idx',
            'portionName': 'Standard',
            'portionPriceDineIn': pr,
            'portionPriceCollection': pr,
            'portionPriceDelivery': pr,
            'portionPriceWaiting': pr,
            'portionPrice': pr,
          }
        ];
      }

      // Ensure days has all 7 days set to true if missing or empty
      Map<String, dynamic> daysMap = {
        'sat': true,
        'sun': true,
        'mon': true,
        'tue': true,
        'wed': true,
        'thu': true,
        'fri': true,
      };
      if (i['days'] is Map) {
        final d = i['days'] as Map;
        // If at least one day is configured, respect user configuration
        bool anySet = d.values.any((v) => v == true);
        if (anySet) {
          daysMap = {
            'sat': d['sat'] == true,
            'sun': d['sun'] == true,
            'mon': d['mon'] == true,
            'tue': d['tue'] == true,
            'wed': d['wed'] == true,
            'thu': d['thu'] == true,
            'fri': d['fri'] == true,
          };
        }
      }

      return {
        '_id': i['_id'] ?? i['id'] ?? 'item_${DateTime.now().millisecondsSinceEpoch}_$idx',
        'name': (i['name'] ?? '').toString(),
        'shortName': (i['shortName'] ?? '').toString(),
        'description': (i['description'] ?? '').toString(),
        'restId': (i['restId'] ?? restId).toString(),
        'categories': i['categories'] is List ? i['categories'] : [],
        'cuisines': i['cuisines'] is List ? i['cuisines'] : [],
        'tags': i['tags'] is List ? i['tags'] : [],
        'portions': portions,
        'foodTypeList': i['foodTypeList'] is List && (i['foodTypeList'] as List).isNotEmpty
            ? i['foodTypeList']
            : ['DineIn', 'Collection', 'Delivery', 'Waiting'],
        'days': daysMap,
        'status': i['status'] is bool ? i['status'] : true,
        'vatAble': i['vatAble'] is bool ? i['vatAble'] : false,
        'cookingTime': (i['cookingTime'] as num?)?.toInt() ?? 0,
        'startTime': i['startTime'] ?? nowIso,
        'endTime': i['endTime'] ?? DateTime.now().add(const Duration(hours: 14)).toIso8601String(),
        'makedByKitchen': i['makedByKitchen'] is List ? i['makedByKitchen'] : [],
        'makedByBar': i['makedByBar'] is List ? i['makedByBar'] : [],
        'options': i['options'] is List ? i['options'] : [],
        'extras': i['extras'] is List ? i['extras'] : [],
        'relatedItems': i['relatedItems'] is List ? i['relatedItems'] : [],
        'createdBy': (i['createdBy'] ?? 'Admin').toString(),
        'updatedBy': (i['updatedBy'] ?? 'Admin').toString(),
        'createdAt': i['createdAt'] ?? nowIso,
        'updatedAt': nowIso,
        '__v': (i['__v'] as num?)?.toInt() ?? 0,
      };
    }).toList();

    // 2. Categories
    final rawCats = extractList(['categoryData', 'categories', 'foodCategories']);
    final cleanCats = rawCats.asMap().entries.map((entry) {
      final idx = entry.key;
      final c = entry.value;
      return {
        '_id': c['_id'] ?? c['id'] ?? 'cat_${DateTime.now().millisecondsSinceEpoch}_$idx',
        'name': (c['name'] ?? '').toString(),
        'restId': (c['restId'] ?? restId).toString(),
        'sl': (c['sl'] as num?)?.toInt() ?? idx,
        'createdBy': (c['createdBy'] ?? 'Admin').toString(),
        'updatedBy': (c['updatedBy'] ?? 'Admin').toString(),
        'createdAt': c['createdAt'] ?? nowIso,
        'updatedAt': nowIso,
        '__v': (c['__v'] as num?)?.toInt() ?? 0,
      };
    }).toList();

    // 3. Cuisines
    final rawCuis = extractList(['cuisineData', 'cuisines']);
    final cleanCuis = rawCuis.asMap().entries.map((entry) {
      final idx = entry.key;
      final c = entry.value;
      return {
        '_id': c['_id'] ?? c['id'] ?? 'cuis_${DateTime.now().millisecondsSinceEpoch}_$idx',
        'name': (c['name'] ?? '').toString(),
        'restId': (c['restId'] ?? restId).toString(),
        'sl': (c['sl'] as num?)?.toInt() ?? idx,
        'createdBy': (c['createdBy'] ?? 'Admin').toString(),
        'updatedBy': (c['updatedBy'] ?? 'Admin').toString(),
        'createdAt': c['createdAt'] ?? nowIso,
        'updatedAt': nowIso,
        '__v': (c['__v'] as num?)?.toInt() ?? 0,
      };
    }).toList();

    // 4. Tags
    final rawTags = extractList(['tagData', 'tags']);
    final cleanTags = rawTags.asMap().entries.map((entry) {
      final idx = entry.key;
      final t = entry.value;
      return {
        '_id': t['_id'] ?? t['id'] ?? 'tag_${DateTime.now().millisecondsSinceEpoch}_$idx',
        'name': (t['name'] ?? '').toString(),
        'restId': (t['restId'] ?? restId).toString(),
        'createdBy': (t['createdBy'] ?? 'Admin').toString(),
        'updatedBy': (t['updatedBy'] ?? 'Admin').toString(),
        'createdAt': t['createdAt'] ?? nowIso,
        'updatedAt': nowIso,
        '__v': (t['__v'] as num?)?.toInt() ?? 0,
      };
    }).toList();

    // 5. Areas
    final rawAreas = extractList(['areaData', 'areas', 'area_list']);
    final cleanAreas = rawAreas.asMap().entries.map((entry) {
      final idx = entry.key;
      final a = entry.value;
      return {
        '_id': a['_id'] ?? a['id'] ?? 'area_${DateTime.now().millisecondsSinceEpoch}_$idx',
        'name': (a['name'] ?? '').toString(),
        'restId': (a['restId'] ?? restId).toString(),
        'status': a['status'] is bool ? a['status'] : true,
        'createdBy': (a['createdBy'] ?? 'Admin').toString(),
        'updatedBy': (a['updatedBy'] ?? 'Admin').toString(),
        'createdAt': a['createdAt'] ?? nowIso,
        'updatedAt': nowIso,
        '__v': (a['__v'] as num?)?.toInt() ?? 0,
      };
    }).toList();

    // 6. Tables
    final rawTables = extractList(['tableData', 'tables', 'table_list']);
    final cleanTables = rawTables.asMap().entries.map((entry) {
      final idx = entry.key;
      final t = entry.value;
      return {
        '_id': t['_id'] ?? t['id'] ?? 'table_${DateTime.now().millisecondsSinceEpoch}_$idx',
        'name': (t['name'] ?? t['tableName'] ?? 'Table ${idx + 1}').toString(),
        'capacity': (t['capacity'] as num?)?.toInt() ?? 4,
        'status': (t['status'] as num?)?.toInt() ?? 1,
        'area': (t['area'] is Map ? (t['area']['_id'] ?? t['area']['id'] ?? '') : (t['area'] ?? t['areaId'] ?? '')).toString(),
        'restId': (t['restId'] ?? restId).toString(),
        'createdBy': (t['createdBy'] ?? 'Admin').toString(),
        'updatedBy': (t['updatedBy'] ?? 'Admin').toString(),
        'createdAt': t['createdAt'] ?? nowIso,
        'updatedAt': nowIso,
        '__v': (t['__v'] as num?)?.toInt() ?? 0,
      };
    }).toList();

    // 7. Staff
    final rawStaff = extractList(['staffData', 'staff']);
    final cleanStaff = rawStaff.asMap().entries.map((entry) {
      final idx = entry.key;
      final s = entry.value;
      return {
        'id': (s['id'] ?? s['_id'] ?? 'staff_${DateTime.now().millisecondsSinceEpoch}_$idx').toString(),
        'staffId': (s['staffId'] ?? 'ST-${idx + 1}').toString(),
        'name': (s['name'] ?? 'Staff ${idx + 1}').toString(),
        'mobile': (s['mobile'] ?? '').toString(),
        'empContact': (s['empContact'] ?? s['mobile'] ?? '').toString(),
        'email': (s['email'] ?? '').toString(),
        'dob': (s['dob'] ?? '01/01/2000').toString(),
        'password': (s['password'] ?? '1234').toString(),
        'status': s['status'] is bool ? s['status'] : true,
        'role': (s['role'] ?? 'Staff').toString(),
        'restId': (s['restId'] ?? restId).toString(),
        'tokens': (s['tokens'] ?? '').toString(),
        'restName': (s['restName'] ?? '').toString(),
        'restAddress': (s['restAddress'] ?? '').toString(),
        'isSync': s['isSync'] is bool ? s['isSync'] : true,
        'createdBy': (s['createdBy'] ?? 'Admin').toString(),
        'updatedBy': (s['updatedBy'] ?? 'Admin').toString(),
        'createdAt': s['createdAt'] ?? nowIso,
        'updatedAt': nowIso,
        '__v': (s['__v'] as num?)?.toInt() ?? 0,
      };
    }).toList();

    // 8. Tills
    final rawTills = extractList(['tillData', 'tills']);
    final cleanTills = rawTills.asMap().entries.map((entry) {
      final idx = entry.key;
      final t = entry.value;
      return {
        '_id': t['_id'] ?? t['id'] ?? 'till_${DateTime.now().millisecondsSinceEpoch}_$idx',
        'tillName': (t['tillName'] ?? t['name'] ?? 'Till ${idx + 1}').toString(),
        'tillId': (t['tillId'] ?? 'T-${idx + 1}').toString(),
        'tillStatus': t['tillStatus'] is bool ? t['tillStatus'] : false,
        'openingBalance': (t['openingBalance'] as num?)?.toDouble() ?? 0.0,
        'depositAmount': (t['depositAmount'] as num?)?.toDouble() ?? 0.0,
        'withdrawAmount': (t['withdrawAmount'] as num?)?.toDouble() ?? 0.0,
        'totalAmount': (t['totalAmount'] as num?)?.toDouble() ?? 0.0,
        'restId': (t['restId'] ?? restId).toString(),
        'createdAt': t['createdAt'] ?? nowIso,
        'updatedAt': nowIso,
        '__v': (t['__v'] as num?)?.toInt() ?? 0,
      };
    }).toList();

    // 9. Kitchens
    final rawKitchens = extractList(['kitchenData', 'kitchens']);
    final cleanKitchens = rawKitchens.asMap().entries.map((entry) {
      final idx = entry.key;
      final k = entry.value;
      return {
        '_id': k['_id'] ?? k['id'] ?? 'kit_${DateTime.now().millisecondsSinceEpoch}_$idx',
        'name': (k['name'] ?? 'Main Kitchen').toString(),
        'notes': (k['notes'] ?? '').toString(),
        'restId': (k['restId'] ?? restId).toString(),
        'createdBy': (k['createdBy'] ?? 'Admin').toString(),
        'updatedBy': (k['updatedBy'] ?? 'Admin').toString(),
        'createdAt': k['createdAt'] ?? nowIso,
        'updatedAt': nowIso,
        '__v': (k['__v'] as num?)?.toInt() ?? 0,
      };
    }).toList();

    // 10. Bars
    final rawBars = extractList(['barData', 'bars']);
    final cleanBars = rawBars.asMap().entries.map((entry) {
      final idx = entry.key;
      final b = entry.value;
      return {
        '_id': b['_id'] ?? b['id'] ?? 'bar_${DateTime.now().millisecondsSinceEpoch}_$idx',
        'name': (b['name'] ?? 'Main Bar').toString(),
        'notes': (b['notes'] ?? '').toString(),
        'restId': (b['restId'] ?? restId).toString(),
        'createdBy': (b['createdBy'] ?? 'Admin').toString(),
        'updatedBy': (b['updatedBy'] ?? 'Admin').toString(),
        'createdAt': b['createdAt'] ?? nowIso,
        'updatedAt': nowIso,
        '__v': (b['__v'] as num?)?.toInt() ?? 0,
      };
    }).toList();

    // 11. Promotions
    final rawPromos = extractList(['promotionData', 'promotions']);
    final cleanPromos = rawPromos.asMap().entries.map((entry) {
      final idx = entry.key;
      final p = entry.value;
      return {
        '_id': p['_id'] ?? p['id'] ?? 'promo_${DateTime.now().millisecondsSinceEpoch}_$idx',
        'offerName': (p['offerName'] ?? p['name'] ?? 'Special Offer').toString(),
        'description': (p['description'] ?? '').toString(),
        'triggerType': (p['triggerType'] ?? 'Value').toString(),
        'triggerValue': (p['triggerValue'] as num?)?.toDouble() ?? 0.0,
        'triggerItem': p['triggerItem'] is List ? p['triggerItem'] : [],
        'rewardTypes': (p['rewardTypes'] ?? 'Percent').toString(),
        'rewardValue': (p['rewardValue'] as num?)?.toDouble() ?? 0.0,
        'rewardItem': p['rewardItem'] is List ? p['rewardItem'] : [],
        'excludedItem': p['excludedItem'] is List ? p['excludedItem'] : [],
        'appliedOnOrderType': p['appliedOnOrderType'] is List
            ? (p['appliedOnOrderType'] as List).map((e) => e.toString()).toList()
            : ['DineIn', 'Collection', 'Delivery'],
        'promoDays': p['promoDays'] is Map
            ? p['promoDays']
            : {'sat': true, 'sun': true, 'mon': true, 'tue': true, 'wed': true, 'thu': true, 'fri': true},
        'exclusive': p['exclusive'] is bool ? p['exclusive'] : false,
        'autoApply': p['autoApply'] is bool ? p['autoApply'] : false,
        'availableStatus': p['availableStatus'] is bool ? p['availableStatus'] : true,
        'restId': (p['restId'] ?? restId).toString(),
        'startDate': p['startDate'] ?? nowIso,
        'endDate': p['endDate'] ?? DateTime.now().add(const Duration(days: 365)).toIso8601String(),
        'startTime': p['startTime'] ?? nowIso,
        'endTime': p['endTime'] ?? DateTime.now().add(const Duration(days: 365)).toIso8601String(),
        'staffName': (p['staffName'] ?? 'Admin').toString(),
        'createdAt': p['createdAt'] ?? nowIso,
        'updatedAt': nowIso,
        '__v': (p['__v'] as num?)?.toInt() ?? 0,
      };
    }).toList();

    // 12. Basic Settings
    final rawBasic = extractList(['basicSettingData', 'basicSettings']);
    Map<String, dynamic> bMap = rawBasic.isNotEmpty ? rawBasic.first : {};
    final cleanBasic = [
      {
        '_id': bMap['_id'] ?? 'setting_$restId',
        'logo': bMap['logo'] is List ? bMap['logo'] : [],
        'vat': (bMap['vat'] ?? '20.00').toString(),
        'restId': restId,
        'tillId': (bMap['tillId'] ?? '').toString(),
        'androidId': (bMap['androidId'] ?? '').toString(),
        'closingHour': (bMap['closingHour'] ?? '23:00').toString(),
        'openingHour': (bMap['openingHour'] ?? '10:00').toString(),
        'restName': (bMap['restName'] ?? '').toString(),
        'addrLn1': (bMap['addrLn1'] ?? '').toString(),
        'addrLn2': (bMap['addrLn2'] ?? '').toString(),
        'addrLn3': (bMap['addrLn3'] ?? '').toString(),
        'txtLn1': (bMap['txtLn1'] ?? 'Thank you for dining with us!').toString(),
        'txtLn2': (bMap['txtLn2'] ?? 'Please visit again.').toString(),
        'txtLn3': (bMap['txtLn3'] ?? '').toString(),
        'currSym': (bMap['currSym'] ?? '£').toString(),
        'setMealDuration': (bMap['setMealDuration'] as num?)?.toInt() ?? 0,
        'deliveryAndBag': bMap['deliveryAndBag'] is Map
            ? bMap['deliveryAndBag']
            : {'delivery': [], 'bag': []},
      }
    ];

    // 13. Payment Methods
    final rawPay = extractList(['paymentMethodSettingData', 'paymentMethods']);
    List<Map<String, dynamic>> cleanPay = rawPay.asMap().entries.map((entry) {
      final idx = entry.key;
      final pm = entry.value;
      return {
        '_id': pm['_id'] ?? pm['id'] ?? 'pm_${DateTime.now().millisecondsSinceEpoch}_$idx',
        'paymentMethodsName': (pm['paymentMethodsName'] ?? pm['name'] ?? 'Payment Method').toString(),
        'restId': (pm['restId'] ?? restId).toString(),
        'createdBy': (pm['createdBy'] ?? 'Admin').toString(),
        'updatedBy': (pm['updatedBy'] ?? 'Admin').toString(),
        'createdAt': pm['createdAt'] ?? nowIso,
        'updatedAt': nowIso,
        '__v': (pm['__v'] as num?)?.toInt() ?? 0,
      };
    }).toList();

    // Default payment methods if none exist
    if (cleanPay.isEmpty) {
      final defaultMethods = ['Cash', 'Card', 'Online Payment'];
      cleanPay = defaultMethods.asMap().entries.map((e) => {
        '_id': 'pm_default_${e.key}',
        'paymentMethodsName': e.value,
        'restId': restId,
        'createdBy': 'Admin',
        'updatedBy': 'Admin',
        'createdAt': nowIso,
        'updatedAt': nowIso,
        '__v': 0,
      }).toList();
    }

    // 14. Customer Data
    final rawCust = extractList(['customerData', 'customers']);
    final cleanCust = rawCust.asMap().entries.map((entry) {
      final idx = entry.key;
      final c = entry.value;
      return {
        'id': c['id'] ?? c['_id'] ?? 'cust_${DateTime.now().millisecondsSinceEpoch}_$idx',
        'name': (c['name'] ?? 'Customer').toString(),
        'phone': (c['phone'] ?? '').toString(),
        'floorAptNo': (c['floorAptNo'] ?? '').toString(),
        'houseNo': (c['houseNo'] ?? '').toString(),
        'buildingName': (c['buildingName'] ?? '').toString(),
        'streenName': (c['streenName'] ?? c['streetName'] ?? '').toString(),
        'postCode': (c['postCode'] ?? '').toString(),
        'townCity': (c['townCity'] ?? '').toString(),
        'restId': (c['restId'] ?? restId).toString(),
        'notes': (c['notes'] ?? '').toString(),
        'deviceToken': (c['deviceToken'] ?? '').toString(),
        'createdAt': c['createdAt'] ?? nowIso,
        'updatedAt': nowIso,
        '__v': (c['__v'] as num?)?.toInt() ?? 0,
      };
    }).toList();

    // 15. Print Copies
    Map<String, dynamic> printCopyData = {
      "kitchenPrint_all": 1,
      "kitchenPrint_new": 1,
      "kitchenPrint_barOnly": 1,
      "kitchenPrint_kitchenOnly": 1,
      "guestPrint": 1,
      "releasePrint": 1,
    };
    if (raw['printCopyData'] is Map) {
      printCopyData = Map<String, dynamic>.from(raw['printCopyData']);
    } else if (raw['total_data_table'] is List) {
      for (var obj in (raw['total_data_table'] as List)) {
        if (obj is Map && obj.containsKey('printCopyData') && obj['printCopyData'] is Map) {
          printCopyData = Map<String, dynamic>.from(obj['printCopyData']);
          break;
        }
      }
    }

    // 16. Kukd data
    Map<String, dynamic> kukdData = {};
    if (raw['kukdData'] is Map) {
      kukdData = Map<String, dynamic>.from(raw['kukdData']);
    } else if (raw['total_data_table'] is List) {
      for (var obj in (raw['total_data_table'] as List)) {
        if (obj is Map && obj.containsKey('kukdData') && obj['kukdData'] is Map) {
          kukdData = Map<String, dynamic>.from(obj['kukdData']);
          break;
        }
      }
    }

    // 17-23. Expense & Stock
    final cleanExpGroups = extractList(['expenseGroupData', 'expenseGroups']);
    final cleanExpHeads = extractList(['expenseHeadData', 'expenseHeads']);
    final cleanExpItems = extractList(['expenseItemData', 'expenseItems']);
    final cleanStocks = extractList(['stockData', 'stocks']);
    final cleanStockLogs = extractList(['stockLogData', 'stockLogs']);
    final cleanIngredients = extractList(['ingredientData', 'ingredients']);
    final cleanRecipes = extractList(['recipeData', 'recipes']);

    // Assemble the strict total_data_table expected by rest_pos _jsonToHiveSetting
    return {
      'restaurant_id': raw['restaurant_id'] ?? restId,
      'restaurant_pass': raw['restaurant_pass'] ?? '',
      'data_table': 'allSettingsData',
      'total_data_table': [
        {"staff_data_table": "staffTable", "staffData": cleanStaff},
        {"area_data_table": "areaTable", "areaData": cleanAreas},
        {"table_data_table": "table", "tableData": cleanTables},
        {"tag_data_table": "tagTable", "tagData": cleanTags},
        {"cuisine_data_table": "cuisineBox", "cuisineData": cleanCuis},
        {"category_data_table": "categoryBox", "categoryData": cleanCats},
        {"till_data_table": "tillBox", "tillData": cleanTills},
        {"kitchen_data_table": "KitchenTable", "kitchenData": cleanKitchens},
        {"bar_data_table": "barTable", "barData": cleanBars},
        {"promotion_data_table": "promotionHiveTable", "promotionData": cleanPromos},
        {"basicSetting_data_table": "settingBox", "basicSettingData": cleanBasic},
        {"foodSetting_data_table": "foodTable", "foodSettingData": cleanItems},
        {"paymentMethod_data_table": "paymentMethodTable", "paymentMethodSettingData": cleanPay},
        {"customer_data_table": "customerTable", "customerData": cleanCust},
        {"print_copy_data_table": "printCopyTable", "printCopyData": printCopyData},
        {"kukd_data_table": "kukdApiCredential", "kukdData": kukdData},
        {"expense_group_data_table": "expenseGroupTable", "expenseGroupData": cleanExpGroups},
        {"expense_head_data_table": "expenseHeadTable", "expenseHeadData": cleanExpHeads},
        {"expense_item_data_table": "expenseItemTable", "expenseItemData": cleanExpItems},
        {"stock_data_table": "stockTable", "stockData": cleanStocks},
        {"stock_log_data_table": "stockLogTable", "stockLogData": cleanStockLogs},
        {"ingredient_data_table": "ingredientTable", "ingredientData": cleanIngredients},
        {"recipe_data_table": "recipeTable", "recipeData": cleanRecipes},
      ],
    };
  }

  // Save updated settings_data back to Supabase
  Future<void> updateSettingsData(String restId, Map<String, dynamic> updatedSettings) async {
    // Sanitize and guarantee 100% schema alignment with rest_pos
    final cleanSettings = sanitizeSettingsData(restId, updatedSettings);

    try {
      final response = await _supabase
          .from('app_backups')
          .update({'settings_data': cleanSettings})
          .eq('rest_id', restId)
          .select('rest_id');
          
      if (response.isEmpty) {
        await _supabase.from('app_backups').insert({
          'rest_id': restId,
          'settings_data': cleanSettings,
          'orders_data': []
        });
      }
    } catch (_) {
      final numId = int.tryParse(restId);
      if (numId != null) {
        final response2 = await _supabase
            .from('app_backups')
            .update({'settings_data': cleanSettings})
            .eq('rest_id', numId)
            .select('rest_id');
            
        if (response2.isEmpty) {
          await _supabase.from('app_backups').insert({
            'rest_id': numId,
            'settings_data': cleanSettings,
            'orders_data': []
          });
        }
      } else {
        rethrow;
      }
    }

    // Also sync to restaurants table (settings_data & manage_table) for POS live compatibility
    try {
      final Map<String, dynamic> restUpdate = {
        'settings_data': cleanSettings,
        'updated_at': DateTime.now().toIso8601String(),
      };
      if (updatedSettings.containsKey('manage_table')) {
        restUpdate['manage_table'] = updatedSettings['manage_table'] == true;
      }
      final numId = int.tryParse(restId);
      if (numId != null) {
        await _supabase.from('restaurants').update(restUpdate).eq('id', numId);
      } else {
        await _supabase.from('restaurants').update(restUpdate).or('id.eq.$restId,token.eq.$restId');
      }
    } catch (_) {}
  }

  // Save updated orders_data back to Supabase
  Future<void> updateOrdersData(String restId, List<OrderModel> orders) async {
    final jsonList = orders.map((o) => o.toJson()).toList();
    try {
      final response = await _supabase
          .from('app_backups')
          .update({'orders_data': jsonList})
          .eq('rest_id', restId)
          .select('rest_id');
          
      if (response.isEmpty) {
        await _supabase.from('app_backups').insert({
          'rest_id': restId,
          'settings_data': {},
          'orders_data': jsonList
        });
      }
    } catch (_) {
      final numId = int.tryParse(restId);
      if (numId != null) {
        final response2 = await _supabase
            .from('app_backups')
            .update({'orders_data': jsonList})
            .eq('rest_id', numId)
            .select('rest_id');
            
        if (response2.isEmpty) {
          await _supabase.from('app_backups').insert({
            'rest_id': numId,
            'settings_data': {},
            'orders_data': jsonList
          });
        }
      } else {
        rethrow;
      }
    }
  }

}
