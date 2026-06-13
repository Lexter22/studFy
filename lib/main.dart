import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://mkneaeisrwxnbahephay.supabase.co',
  );
  const supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1rbmVhZWlzcnd4bmJhaGVwaGF5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzk5NjYwODIsImV4cCI6MjA5NTU0MjA4Mn0.RMsvnzbqNB1d5KsdJZ61oaRL5RpfDlQVKhm9OpQhpSc',
  );

  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);

  runApp(const StudfyApp());
}
