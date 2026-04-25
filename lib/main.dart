import 'package:flutter/material.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
    throw StateError(
      'Missing Supabase configuration. Run with '
      '--dart-define-from-file=.env or pass SUPABASE_URL and SUPABASE_ANON_KEY.',
    );
  }

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
