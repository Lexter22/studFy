import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/router/app_router.dart';
import 'core/state/app_state.dart';
import 'features/auth/domain/services/auth_service.dart';

class StudfyApp extends StatelessWidget {
  const StudfyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthService>(create: (_) => const AuthService()),
        ChangeNotifierProvider(create: (_) => AppState()),
      ],
      child: const _StudfyAppView(),
    );
  }
}

class _StudfyAppView extends StatefulWidget {
  const _StudfyAppView();

  @override
  State<_StudfyAppView> createState() => _StudfyAppViewState();
}

class _StudfyAppViewState extends State<_StudfyAppView> {
  StreamSubscription? _authSubscription;

  @override
  void initState() {
    super.initState();
    final AuthService authService = context.read<AuthService>();
    final AppState appState = context.read<AppState>();

    _authSubscription = authService.authStateChanges().listen(
      appState.syncAuthState,
    );
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppState appState = context.watch<AppState>();

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true),
      routerConfig: createAppRouter(appState),
    );
  }
}
