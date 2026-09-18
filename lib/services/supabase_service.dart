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

  // Save updated settings_data back to Supabase
  Future<void> updateSettingsData(String restId, Map<String, dynamic> updatedSettings) async {
    // Build the clean settings map to store as proper JSON (not a string)
    final cleanSettings = <String, dynamic>{};
    if (updatedSettings.containsKey('restaurant_id')) cleanSettings['restaurant_id'] = updatedSettings['restaurant_id'];
    if (updatedSettings.containsKey('restaurant_pass')) cleanSettings['restaurant_pass'] = updatedSettings['restaurant_pass'];
    if (updatedSettings.containsKey('data_table')) cleanSettings['data_table'] = updatedSettings['data_table'];

    // If total_data_table exists, use it directly; otherwise rebuild it from top-level keys
    if (updatedSettings.containsKey('total_data_table') && updatedSettings['total_data_table'] is List && (updatedSettings['total_data_table'] as List).isNotEmpty) {
      cleanSettings['total_data_table'] = updatedSettings['total_data_table'];
    } else {
      // Rebuild total_data_table from the flattened top-level keys
      cleanSettings['data_table'] = 'allSettingsData';
      cleanSettings['total_data_table'] = [
        {"staff_data_table": "staffTable", "staffData": updatedSettings['staffData'] ?? updatedSettings['staff'] ?? []},
        {"area_data_table": "areaTable", "areaData": updatedSettings['areaData'] ?? updatedSettings['areas'] ?? []},
        {"table_data_table": "table", "tableData": updatedSettings['tableData'] ?? updatedSettings['tables'] ?? []},
        {"tag_data_table": "tagTable", "tagData": updatedSettings['tagData'] ?? updatedSettings['tags'] ?? []},
        {"cuisine_data_table": "cuisineBox", "cuisineData": updatedSettings['cuisineData'] ?? updatedSettings['cuisines'] ?? []},
        {"category_data_table": "categoryBox", "categoryData": updatedSettings['categoryData'] ?? updatedSettings['categories'] ?? []},
        {"till_data_table": "tillBox", "tillData": updatedSettings['tillData'] ?? updatedSettings['tills'] ?? []},
        {"kitchen_data_table": "KitchenTable", "kitchenData": updatedSettings['kitchenData'] ?? updatedSettings['kitchens'] ?? []},
        {"bar_data_table": "barTable", "barData": updatedSettings['barData'] ?? updatedSettings['bars'] ?? []},
        {"promotion_data_table": "promotionHiveTable", "promotionData": updatedSettings['promotionData'] ?? updatedSettings['promotions'] ?? []},
        {"basicSetting_data_table": "settingBox", "basicSettingData": updatedSettings['basicSettingData'] ?? updatedSettings['basicSettings'] ?? []},
        {"foodSetting_data_table": "foodTable", "foodSettingData": updatedSettings['foodSettingData'] ?? updatedSettings['items'] ?? []},
        {"paymentMethod_data_table": "paymentMethodTable", "paymentMethodSettingData": updatedSettings['paymentMethodSettingData'] ?? updatedSettings['paymentMethods'] ?? []},
        {"customer_data_table": "customerTable", "customerData": updatedSettings['customerData'] ?? updatedSettings['customers'] ?? []},
        {"print_copy_data_table": "printCopyTable", "printCopyData": updatedSettings['printCopyData'] ?? {"kitchenPrint_all": 1, "kitchenPrint_new": 1, "kitchenPrint_barOnly": 1, "kitchenPrint_kitchenOnly": 1, "guestPrint": 1, "releasePrint": 1}},
        {"kukd_data_table": "kukdApiCredential", "kukdData": updatedSettings['kukdData'] ?? {}},
        {"expense_group_data_table": "expenseGroupTable", "expenseGroupData": updatedSettings['expenseGroupData'] ?? updatedSettings['expenseGroups'] ?? []},
        {"expense_head_data_table": "expenseHeadTable", "expenseHeadData": updatedSettings['expenseHeadData'] ?? updatedSettings['expenseHeads'] ?? []},
        {"expense_item_data_table": "expenseItemTable", "expenseItemData": updatedSettings['expenseItemData'] ?? updatedSettings['expenseItems'] ?? []},
        {"stock_data_table": "stockTable", "stockData": updatedSettings['stockData'] ?? updatedSettings['stocks'] ?? []},
        {"stock_log_data_table": "stockLogTable", "stockLogData": updatedSettings['stockLogData'] ?? updatedSettings['stockLogs'] ?? []},
        {"ingredient_data_table": "ingredientTable", "ingredientData": updatedSettings['ingredientData'] ?? updatedSettings['ingredients'] ?? []},
        {"recipe_data_table": "recipeTable", "recipeData": updatedSettings['recipeData'] ?? updatedSettings['recipes'] ?? []},
      ];
    }

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
