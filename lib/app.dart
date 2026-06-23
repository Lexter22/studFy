import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/router/app_router.dart';
import 'core/state/app_state.dart';
import 'features/auth/domain/services/auth_service.dart';
import 'features/auth/domain/enums/user_role.dart';

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
  StreamSubscription? _deepLinkSubscription;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    final AppState appState = context.read<AppState>();
    final AuthService authService = context.read<AuthService>();
    _router = createAppRouter(appState);

    _authSubscription = authService.authStateChanges().listen(
      (user) {
        // If a user was returned but has unknown role, they were rejected by
        // _withRole (no profile / not approved). Show access denied message.
        if (user != null && user.role == UserRole.unknown) {
          appState.syncAuthState(null);
          appState.accessDeniedNotifier.value =
              'Your account is not registered in the system. '
              'Please contact your administrator.';
          return;
        }

        appState.syncAuthState(user);

        if (user == null) {
          appState.clearAdminData();
          return;
        }

        if (user.role == UserRole.admin) {
          unawaited(appState.loadAdminData());
        } else {
          appState.clearAdminData();
        }
      },
      onError: (error) {
        // Gracefully handle errors (e.g. JSON parsing failures during hot restart
        // when the Supabase session token in localStorage is corrupted).
        debugPrint('Auth stream error (ignored): $error');
        appState.syncAuthState(null);
      },
    );

    // Handle Supabase deep link (e.g. password reset)
    _deepLinkSubscription = Supabase.instance.client.auth.onAuthStateChange.listen(
      (data) {
        if (data.event == AuthChangeEvent.passwordRecovery) {
          _router.pushNamed(AppRoutes.changePassword);
        }
      },
      onError: (error) {
        // Ignore auth state change errors during hot restart
        debugPrint('Deep link auth stream error (ignored): $error');
      },
    );
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _deepLinkSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    context.watch<AppState>();

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true),
      routerConfig: _router,
    );
  }
}
