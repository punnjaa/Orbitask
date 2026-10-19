import 'package:flutter/foundation.dart';

class Env {
  static const supabaseUrl = 'https://YOUR-PROJECT.supabase.co';
  static const supabaseAnon = 'YOUR-ANON-KEY'; // ใส่ Publishable key (sb_publishable_...) หรือ anon key เท่านั้น ห้ามใส่ Secret/service_role
  // Android emulator เรียกเครื่องตัวเองด้วย 10.0.2.2
  static String get api => kIsWeb ? 'http://localhost:8000' : 'http://10.0.2.2:8000';
}
