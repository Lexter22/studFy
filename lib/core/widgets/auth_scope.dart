import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';

class AuthScope extends StatelessWidget {
  final Widget child;

  const AuthScope({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(create: (_) => AppState(), child: child);
  }
}
