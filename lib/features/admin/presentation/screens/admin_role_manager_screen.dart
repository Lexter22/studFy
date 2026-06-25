import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/state/app_state.dart';
import '../../../auth/domain/enums/user_role.dart';
import '../widgets/admin_floating_nav_bar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminRoleManagerScreen extends StatefulWidget {
  const AdminRoleManagerScreen({super.key});

  @override
  State<AdminRoleManagerScreen> createState() => _AdminRoleManagerScreenState();
}

class _AdminRoleManagerScreenState extends State<AdminRoleManagerScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  
  // Categorized users
  final Map<String, List<Map<String, dynamic>>> _categorizedUsers = {
    'student': [],
    'professor': [],
    'admin': [],
    'unknown': [],
  };

  // Pagination states for each category
  final Map<String, int> _currentPage = {
    'student': 1,
    'professor': 1,
    'admin': 1,
    'unknown': 1,
  };

  final Map<String, bool> _hasMore = {
    'student': true,
    'professor': true,
    'admin': true,
    'unknown': true,
  };

  final Map<String, int> _totalCount = {
    'student': 0,
    'professor': 0,
    'admin': 0,
    'unknown': 0,
  };

  bool _loading = false;
  bool _isSaving = false;
  final int _pageSize = 10;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_handleTabChange);
    _searchController.addListener(_handleSearchChanged);
    _fetchPage();
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    _searchController.removeListener(_handleSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    if (_tabController.indexIsChanging) return;
    final currentRole = _getActiveRole();
    if (_categorizedUsers[currentRole]!.isEmpty && _hasMore[currentRole]!) {
      _fetchPage();
    }
  }

  void _handleSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.trim();
    });
    _resetAndFetch();
  }

  String _getActiveRole() {
    switch (_tabController.index) {
      case 0:
        return 'student';
      case 1:
        return 'professor';
      case 2:
        return 'admin';
      default:
        return 'unknown';
    }
  }

  void _resetAndFetch() {
    final currentRole = _getActiveRole();
    setState(() {
      _categorizedUsers[currentRole] = [];
      _currentPage[currentRole] = 1;
      _hasMore[currentRole] = true;
    });
    _fetchPage();
  }

  Future<void> _fetchPage() async {
    final currentRole = _getActiveRole();
    if (_loading) return;

    setState(() => _loading = true);

    try {
      // 1. Fetch total count
      var countQuery = Supabase.instance.client
          .from('profiles')
          .select('id');

      if (currentRole == 'unknown') {
        countQuery = countQuery.filter('role', 'is', null);
      } else {
        countQuery = countQuery.eq('role', currentRole);
      }

      if (_searchQuery.isNotEmpty) {
        countQuery = countQuery.or('display_name.ilike.%$_searchQuery%,email.ilike.%$_searchQuery%');
      }

      final countResponse = await countQuery;
      final int totalCount = countResponse.length;

      // 2. Fetch page data
      final page = _currentPage[currentRole]!;
      final from = (page - 1) * _pageSize;
      final to = from + _pageSize - 1;

      var query = Supabase.instance.client
          .from('profiles')
          .select('id, email, display_name, role');

      if (currentRole == 'unknown') {
        query = query.filter('role', 'is', null);
      } else {
        query = query.eq('role', currentRole);
      }

      if (_searchQuery.isNotEmpty) {
        query = query.or('display_name.ilike.%$_searchQuery%,email.ilike.%$_searchQuery%');
      }

      final List<dynamic> response = await query
          .range(from, to)
          .order('display_name', ascending: true);

      final newUsers = response.whereType<Map>().map((r) => Map<String, dynamic>.from(r)).toList();

      setState(() {
        _categorizedUsers[currentRole] = newUsers;
        _totalCount[currentRole] = totalCount;
        _loading = false;
        _hasMore[currentRole] = (from + newUsers.length) < totalCount;
      });
    } catch (e) {
      setState(() => _loading = false);
      AppDialog.result(
        context,
        type: DialogType.error,
        message: 'Failed to load users: $e',
      );
    }
  }

  Future<void> _updateUserRole(String uid, UserRole newRole, String displayName, String email) async {
    setState(() => _isSaving = true);
    try {
      // 1. Update the profiles table
      await Supabase.instance.client
          .from('profiles')
          .update({'role': newRole.value})
          .eq('id', uid);

      // 2. Ensure corresponding profile tables exist
      if (newRole == UserRole.student) {
        final studentProfile = await Supabase.instance.client
            .from('student_profiles')
            .select('profile_id')
            .eq('profile_id', uid)
            .maybeSingle();

        if (studentProfile == null) {
          await Supabase.instance.client.from('student_profiles').insert({
            'profile_id': uid,
            'student_number': 'STUD-${uid.substring(0, min(uid.length, 8)).toUpperCase()}',
            'course_code': 'BSIT',
            'year_section': 'BSIT 3-1',
          });
        }
      } else if (newRole == UserRole.professor) {
        final instructorProfile = await Supabase.instance.client
            .from('instructor_profiles')
            .select('profile_id')
            .eq('profile_id', uid)
            .maybeSingle();

        if (instructorProfile == null) {
          await Supabase.instance.client.from('instructor_profiles').insert({
            'profile_id': uid,
            'instructor_id': 'PROF-${uid.substring(0, min(uid.length, 8)).toUpperCase()}',
            'department': 'CS/IT',
          });
        }
      }

      if (context.mounted) {
        AppDialog.result(
          context,
          type: DialogType.success,
          message: 'User role successfully updated!',
        );
      }

      // Refresh list
      _resetAndFetch();
    } catch (e) {
      if (context.mounted) {
        AppDialog.result(
          context,
          type: DialogType.error,
          message: 'Failed to update role: $e',
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  int min(int a, int b) => a < b ? a : b;

  void _showChangeRoleDialog(Map<String, dynamic> user) {
    UserRole currentSelected = UserRoleX.fromString(user['role'] as String?);
    final TextEditingController passwordController = TextEditingController();
    bool isLocalSaving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: const [
                  Icon(Icons.manage_accounts_rounded, color: AppColors.adminPrimary),
                  SizedBox(width: 8),
                  Text('Change User Role', style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'User: ${user['display_name'] ?? 'Unknown'}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Email: ${user['email'] ?? ''}',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<UserRole>(
                      value: currentSelected == UserRole.unknown ? UserRole.student : currentSelected,
                      decoration: InputDecoration(
                        labelText: 'New Role',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                      items: const [
                        DropdownMenuItem(value: UserRole.student, child: Text('Student')),
                        DropdownMenuItem(value: UserRole.professor, child: Text('Professor')),
                        DropdownMenuItem(value: UserRole.admin, child: Text('Admin')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() {
                            currentSelected = val;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'Your Admin Password',
                        hintText: 'Enter password to authorize',
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isLocalSaving ? null : () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.adminPrimary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: isLocalSaving ? null : () async {
                    final enteredPassword = passwordController.text.trim();
                    if (enteredPassword.isEmpty) {
                      AppDialog.alert(
                        context,
                        title: 'Required',
                        message: 'Please enter your password to authorize.',
                      );
                      return;
                    }

                    setDialogState(() {
                      isLocalSaving = true;
                    });

                    try {
                      final adminEmail = Supabase.instance.client.auth.currentUser?.email;
                      if (adminEmail == null) {
                        throw Exception('Admin email not found. Please log in again.');
                      }

                      // Re-authenticate current admin
                      await Supabase.instance.client.auth.signInWithPassword(
                        email: adminEmail,
                        password: enteredPassword,
                      );

                      // If successful, proceed with update
                      await _updateUserRole(
                        user['id'] as String,
                        currentSelected,
                        user['display_name'] as String? ?? '',
                        user['email'] as String? ?? '',
                      );

                      if (context.mounted) {
                        Navigator.pop(context);
                      }
                    } catch (e) {
                      AppDialog.alert(
                        context,
                        title: 'Error',
                        message: 'Authorization failed: Incorrect password.',
                      );
                    } finally {
                      setDialogState(() {
                        isLocalSaving = false;
                      });
                    }
                  },
                  child: isLocalSaving
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Save Changes', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.adminPageBackground,
      body: Stack(
        children: [
          Column(
            children: [
              // Search & Filter Panel
              Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by name or email...',
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () => _searchController.clear(),
                          )
                        : null,
                    filled: true,
                    fillColor: const Color(0xFFF5F6F9),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              // Role Tabs
              Container(
                color: Colors.white,
                child: TabBar(
                  controller: _tabController,
                  indicatorColor: AppColors.adminPrimary,
                  labelColor: AppColors.adminPrimary,
                  unselectedLabelColor: Colors.grey,
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  tabs: const [
                    Tab(text: 'STUDENTS'),
                    Tab(text: 'PROFESSORS'),
                    Tab(text: 'ADMINS'),
                    Tab(text: 'UNASSIGNED'),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildUserList('student'),
                    _buildUserList('professor'),
                    _buildUserList('admin'),
                    _buildUserList('unknown'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUserList(String roleKey) {
    final list = _categorizedUsers[roleKey]!;
    
    if (_loading && list.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No users found in this category',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: list.length + 1,
      itemBuilder: (context, index) {
        if (index == list.length) {
          final int totalItems = _totalCount[roleKey] ?? 0;
          final int pageCount = (totalItems / _pageSize).ceil();
          final int currentPage = _currentPage[roleKey] ?? 1;

          if (pageCount > 1) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Page $currentPage of $pageCount',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: currentPage > 1 && !_loading
                            ? () {
                                setState(() => _currentPage[roleKey] = currentPage - 1);
                                _fetchPage();
                              }
                            : null,
                        icon: const Icon(Icons.chevron_left_rounded, size: 20),
                        style: IconButton.styleFrom(
                          backgroundColor: currentPage > 1 ? const Color(0xFFF5F6F9) : Colors.transparent,
                          foregroundColor: currentPage > 1 ? Colors.black87 : Colors.grey.shade300,
                          disabledBackgroundColor: Colors.transparent,
                          disabledForegroundColor: Colors.grey.shade300,
                          shape: const CircleBorder(),
                          padding: const EdgeInsets.all(8),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: currentPage < pageCount && !_loading
                            ? () {
                                setState(() => _currentPage[roleKey] = currentPage + 1);
                                _fetchPage();
                              }
                            : null,
                        icon: const Icon(Icons.chevron_right_rounded, size: 20),
                        style: IconButton.styleFrom(
                          backgroundColor: currentPage < pageCount ? const Color(0xFFF5F6F9) : Colors.transparent,
                          foregroundColor: currentPage < pageCount ? Colors.black87 : Colors.grey.shade300,
                          disabledBackgroundColor: Colors.transparent,
                          disabledForegroundColor: Colors.grey.shade300,
                          shape: const CircleBorder(),
                          padding: const EdgeInsets.all(8),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          } else {
            return const SizedBox.shrink();
          }
        }

        final user = list[index];
        final String displayName = user['display_name'] ?? 'Unknown User';
        final String email = user['email'] ?? '';
        final String uid = user['id'] ?? '';
        final String initials = displayName.isNotEmpty
            ? displayName.trim().split(' ').map((e) => e[0]).take(2).join('').toUpperCase()
            : 'U';

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.adminPrimary.withValues(alpha: 0.1),
                  child: Text(
                    initials,
                    style: const TextStyle(
                      color: AppColors.adminPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        email,
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'UID: $uid',
                        style: TextStyle(color: Colors.grey.shade400, fontSize: 11, fontFamily: 'monospace'),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.adminPrimary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    elevation: 0,
                  ),
                  onPressed: () => _showChangeRoleDialog(user),
                  child: const Text('Change Role', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
