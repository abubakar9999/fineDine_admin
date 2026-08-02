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

      return settings;
    }
    return {};
  }

  // Save updated settings_data back to Supabase
  Future<void> updateSettingsData(String restId, Map<String, dynamic> updatedSettings) async {
    final jsonString = jsonEncode(updatedSettings);

    try {
      await _supabase
          .from('app_backups')
          .update({'settings_data': jsonString})
          .eq('rest_id', restId);
    } catch (_) {
      final numId = int.tryParse(restId);
      if (numId != null) {
        await _supabase
            .from('app_backups')
            .update({'settings_data': jsonString})
            .eq('rest_id', numId);
      } else {
        rethrow;
      }
    }
  }

  // Save updated orders_data back to Supabase
  Future<void> updateOrdersData(String restId, List<OrderModel> orders) async {
    final jsonList = orders.map((o) => o.toJson()).toList();
    try {
      await _supabase
          .from('app_backups')
          .update({'orders_data': jsonList})
          .eq('rest_id', restId);
    } catch (_) {
      final numId = int.tryParse(restId);
      if (numId != null) {
        await _supabase
            .from('app_backups')
            .update({'orders_data': jsonList})
            .eq('rest_id', numId);
      } else {
        rethrow;
      }
    }
  }

}
