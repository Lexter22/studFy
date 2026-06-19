import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://zhlrzzhwumcxtstuybdb.supabase.co',
  );
  const supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InpobHJ6emh3dW1jeHRzdHV5YmRiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzY2NjQxNjksImV4cCI6MjA5MjI0MDE2OX0.hk8O5-WU5iXcHPDGXxLr3bBoKj4A9pcjKO2hWsAbt34',
  );

  try {
    await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
  } catch (e) {
    // On hot restart, the stored session in localStorage may be corrupted
    // causing a JSON parse failure. Initialize without the cached session.
    debugPrint('Supabase init error (likely hot restart): $e');
  }

  runApp(const StudfyApp());
}
