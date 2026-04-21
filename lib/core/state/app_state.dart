import 'package:flutter/foundation.dart';

import '../../features/auth/domain/models/app_user.dart';

class AppState extends ChangeNotifier {
  bool _isAuthenticated = false;
  AppUser? _currentUser;

  bool get isAuthenticated => _isAuthenticated;
  AppUser? get currentUser => _currentUser;

  // --- Isolated Subject Requests Notifier ---
  // Using ValueNotifier for requests so updating them doesn't trigger 
  // the GoRouter refreshListenable (which causes unwanted redirects).
  final ValueNotifier<List<Map<String, String>>> pendingSubjectRequestsNotifier = 
      ValueNotifier<List<Map<String, String>>>([
    {'name': 'Ethics', 'status': 'Pending Prof. Designation'},
    {'name': 'Ethics', 'status': 'Pending Student Enrollment'},
    {'name': 'Ethics', 'status': 'Edit Subject'},
  ]);

  List<Map<String, String>> get pendingSubjectRequests => pendingSubjectRequestsNotifier.value;

  void removeSubjectRequest(String name, String status) {
    final newList = List<Map<String, String>>.from(pendingSubjectRequestsNotifier.value);
    newList.removeWhere((r) => r['name'] == name && r['status'] == status);
    pendingSubjectRequestsNotifier.value = newList;
    // Note: We do NOT call notifyListeners() here to avoid GoRouter refresh.
  }

  void login([AppUser? user]) {
    if (_isAuthenticated) {
      _currentUser = user ?? _currentUser;
      return;
    }

    _isAuthenticated = true;
    _currentUser = user;
    notifyListeners();
  }

  void logout() {
    if (!_isAuthenticated) {
      return;
    }

    _isAuthenticated = false;
    _currentUser = null;
    notifyListeners();
  }

  void syncAuthState(AppUser? user) {
    _isAuthenticated = user != null;
    _currentUser = user;
    notifyListeners();
  }

  bool get hasUser => _currentUser != null;
}
