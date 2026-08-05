import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  final supabase = SupabaseClient(
    'https://upzvvmxislzulcrycrkv.supabase.co',
    'sb_publishable_95-0GNeelo0SNLp8iCvWdg_lnumWPya',
  );

  try {
    final response = await supabase.from('restaurants').insert({
      'name': 'Test Restaurant',
      'owner_name': 'Test Owner',
      'address': 'Test Address',
      'email': 'test@test.com',
      'password': 'password',
      'mobile': '1234567890',
      'currency': 'USD',
      'token': 'test_token',
      'is_active': true,
      'role': 'Owner',
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    }).select();
    
    debugPrint('Success: $response');
  } catch (e) {
    debugPrint('Error caught: $e');
  }
}
