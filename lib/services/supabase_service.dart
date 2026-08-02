import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/order_model.dart';

class SupabaseService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Fetch app backup entry for a given restId
  Future<Map<String, dynamic>?> fetchBackupByRestId(String restId) async {
    final response = await _supabase
        .from('app_backups')
        .select()
        .eq('rest_id', restId)
        .maybeSingle();

    return response;
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

  // Helper to parse settings map from backup data
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
      return parsed;
    }
    return {};
  }

  // Save updated settings_data back to Supabase
  Future<void> updateSettingsData(String restId, Map<String, dynamic> updatedSettings) async {
    final jsonString = jsonEncode(updatedSettings);
    await _supabase
        .from('app_backups')
        .update({'settings_data': jsonString})
        .eq('rest_id', restId);
  }

  // Save updated orders_data back to Supabase
  Future<void> updateOrdersData(String restId, List<OrderModel> orders) async {
    final jsonList = orders.map((o) => o.toJson()).toList();
    await _supabase
        .from('app_backups')
        .update({'orders_data': jsonList})
        .eq('rest_id', restId);
  }
}
