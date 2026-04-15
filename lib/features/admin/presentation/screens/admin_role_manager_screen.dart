import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/state/app_state.dart';
import '../../../auth/domain/enums/user_role.dart';
import '../../../auth/domain/services/auth_service.dart';

class AdminRoleManagerScreen extends StatefulWidget {
  const AdminRoleManagerScreen({super.key});

  @override
  State<AdminRoleManagerScreen> createState() => _AdminRoleManagerScreenState();
}

class _AdminRoleManagerScreenState extends State<AdminRoleManagerScreen> {
  final AuthService _authService = const AuthService();
  final TextEditingController _uidController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _displayNameController = TextEditingController();
  UserRole _selectedRole = UserRole.student;
  bool _isSaving = false;

  @override
  void dispose() {
    _uidController.dispose();
    _emailController.dispose();
    _displayNameController.dispose();
    super.dispose();
  }

  Future<void> _saveRole() async {
    final uid = _uidController.text.trim();
    final email = _emailController.text.trim();
    final displayName = _displayNameController.text.trim();

    if (uid.isEmpty || email.isEmpty || displayName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('UID, email, and name are required.')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      await _authService.upsertUserProfile(
        uid: uid,
        email: email,
        displayName: displayName,
        role: _selectedRole,
      );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('User role saved.')));
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to save role: $error')));
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _logout() async {
    await _authService.signOut();
    if (!mounted) {
      return;
    }
    context.read<AppState>().logout();
    context.goNamed(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.adminPageBackground,
      appBar: AppBar(
        title: const Text('Role Manager'),
        backgroundColor: AppColors.adminPrimary,
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _logout,
            child: const Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Assign Role to Existing User',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _uidController,
                decoration: const InputDecoration(
                  labelText: 'Firebase UID',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _displayNameController,
                decoration: const InputDecoration(
                  labelText: 'Display Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<UserRole>(
                initialValue: _selectedRole,
                decoration: const InputDecoration(
                  labelText: 'Role',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: UserRole.admin, child: Text('Admin')),
                  DropdownMenuItem(
                    value: UserRole.professor,
                    child: Text('Professor'),
                  ),
                  DropdownMenuItem(
                    value: UserRole.student,
                    child: Text('Student'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedRole = value);
                  }
                },
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveRole,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.adminPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _isSaving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Save Role',
                          style: TextStyle(color: Colors.white),
                        ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Use this only for accounts that already exist in Firebase Authentication. The UID must match the Auth user.',
                style: TextStyle(color: Colors.black54),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
