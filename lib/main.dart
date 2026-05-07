import 'package:flutter/material.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
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

  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);

  const dsn = String.fromEnvironment('SENTRY_DSN');
  if (dsn.isNotEmpty) {
    await SentryFlutter.init(
      (options) {
        options.dsn = dsn;
        options.tracesSampleRate = 0.1;
      },
      appRunner: () {
        runApp(const StudfyApp());
      },
    );
  } else {
    runApp(const StudfyApp());
  }
}
