import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/studfy_header.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../domain/enums/user_role.dart';
import '../../domain/models/auth_exception.dart';
import '../../domain/services/auth_service.dart';

class AccountCreationScreen extends StatefulWidget {
  const AccountCreationScreen({super.key});

  @override
  State<AccountCreationScreen> createState() => _AccountCreationScreenState();
}

class _AccountCreationScreenState extends State<AccountCreationScreen> {
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = const AuthService();

  // Shared controllers
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _middleNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  // Instructor-only
  final TextEditingController _instructorIdController = TextEditingController();
  final TextEditingController _departmentController = TextEditingController();

  // Student-only
  final TextEditingController _studentNumberController =
      TextEditingController();
  final TextEditingController _enrollmentCodeController =
      TextEditingController();

  String? _selectedRole;
  bool _agreeToTerms = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isButtonEnabled = false;
  bool _isSubmitting = false;

  final List<String> _roles = ['Instructor', 'Student'];

  @override
  void initState() {
    super.initState();
    _addListeners();
  }

  void _addListeners() {
    final controllers = [
      _emailController,
      _firstNameController,
      _middleNameController,
      _lastNameController,
      _passwordController,
      _confirmPasswordController,
      _instructorIdController,
      _departmentController,
      _studentNumberController,
      _enrollmentCodeController,
    ];
    for (final c in controllers) {
      c.addListener(_validateInputs);
    }
  }

  void _validateInputs() {
    bool filled =
        _emailController.text.isNotEmpty &&
        _firstNameController.text.isNotEmpty &&
        _lastNameController.text.isNotEmpty &&
        _passwordController.text.isNotEmpty &&
        _confirmPasswordController.text.isNotEmpty &&
        _selectedRole != null &&
        _agreeToTerms;

    if (_selectedRole == 'Instructor') {
      filled =
          filled &&
          _instructorIdController.text.isNotEmpty &&
          _departmentController.text.isNotEmpty;
    } else if (_selectedRole == 'Student') {
      filled = filled &&
          _studentNumberController.text.isNotEmpty &&
          _enrollmentCodeController.text.isNotEmpty;
    }

    if (filled != _isButtonEnabled) {
      setState(() => _isButtonEnabled = filled);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _firstNameController.dispose();
    _middleNameController.dispose();
    _lastNameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _instructorIdController.dispose();
    _departmentController.dispose();
    _studentNumberController.dispose();
    _enrollmentCodeController.dispose();
    super.dispose();
  }

  // ── Pop-ups ────────────────────────────────────────────────────────────────

  // ── Submit ─────────────────────────────────────────────────────────────────

  Future<void> _handleSubmit() async {
    // All fields check (belt-and-suspenders for middle name being optional)
    final bool anyEmpty =
        _emailController.text.isEmpty ||
        _firstNameController.text.isEmpty ||
        _lastNameController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty ||
        (_selectedRole == 'Instructor' &&
            (_instructorIdController.text.isEmpty ||
                _departmentController.text.isEmpty)) ||
        (_selectedRole == 'Student' &&
            (_studentNumberController.text.isEmpty ||
                _enrollmentCodeController.text.isEmpty));

    if (anyEmpty) {
      AppDialog.alert(
        context,
        title: 'Incomplete Form',
        message: 'All fields must be filled before submitting.',
        type: DialogType.warning,
      );
      return;
    }

    // Email format
    if (!RegExp(
      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
    ).hasMatch(_emailController.text.trim())) {
      AppDialog.alert(
        context,
        title: 'Invalid Email',
        message: 'Please enter a valid email address (e.g. name@domain.com).',
      );
      return;
    }

    // Password length
    if (_passwordController.text.length < 8) {
      AppDialog.alert(
        context,
        title: 'Weak Password',
        message: 'Password must be at least 8 characters long.',
      );
      return;
    }

    // Password match
    if (_passwordController.text != _confirmPasswordController.text) {
      AppDialog.alert(
        context,
        title: 'Password Mismatch',
        message: 'Password and Confirm Password do not match.',
      );
      return;
    }

    final role = _selectedRole == 'Instructor'
        ? UserRole.professor
        : UserRole.student;

    setState(() => _isSubmitting = true);
    try {
      await _authService.registerPendingAccount(
        email: _emailController.text,
        password: _passwordController.text,
        firstName: _firstNameController.text,
        middleName: _middleNameController.text,
        lastName: _lastNameController.text,
        role: role,
        instructorId: _instructorIdController.text,
        department: _departmentController.text,
        studentNumber: _studentNumberController.text,
        enrollmentCode: _enrollmentCodeController.text,
      );

      if (!mounted) return;

      final message = role == UserRole.student
          ? 'Registration successful! You can now log in.'
          : 'Registration submitted.\nYour account is pending admin approval.';

      await AppDialog.result(
        context,
        type: DialogType.success,
        message: message,
        buttonLabel: 'Go to Login',
        onDismiss: () => context.goNamed(AppRoutes.login),
      );
    } on AuthException catch (error) {
      if (!mounted) {
        return;
      }
      await AppDialog.alert(
        context,
        title: 'Registration Failed',
        message: error.message ?? 'Unable to submit registration request.',
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      await AppDialog.alert(
        context,
        title: 'Registration Failed',
        message: 'Unexpected error: $error',
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      backgroundColor: AppColors.authPageBackground,
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            const StudfyHeader(backgroundColor: AppColors.authPageBackground),
            Expanded(
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: isDesktop ? 500 : double.infinity,
                    minHeight: double.infinity,
                  ),
                  child: Container(
                    margin: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 16,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 32,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.max,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── Back button ──────────────────────────────────
                          Align(
                            alignment: Alignment.centerLeft,
                            child: MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: GestureDetector(
                                onTap: () => context.goNamed(AppRoutes.login),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.arrow_back_ios_new_rounded,
                                      size: 16,
                                      color: AppColors.authPrimary,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'Back',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.authPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // ── Title ────────────────────────────────────────
                          const Center(
                            child: Text(
                              'ACCOUNT CREATION FORM',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // ── Role Dropdown ────────────────────────────────
                          _buildLabel('Role'),
                          _buildDropdown(),
                          const SizedBox(height: 14),

                          // ── Email ────────────────────────────────────────
                          _buildLabel('Email'),
                          _buildTextField(controller: _emailController),
                          const SizedBox(height: 14),

                          // ── Role-specific fields ─────────────────────────
                          KeyedSubtree(
                            key: ValueKey(_selectedRole),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (_selectedRole == 'Instructor')
                                  ..._instructorFields(),
                                if (_selectedRole == 'Student')
                                  ..._studentFields(),
                              ],
                            ),
                          ),

                          // ── Password ─────────────────────────────────────
                          _buildLabel('Password'),
                          _buildPasswordField(
                            controller: _passwordController,
                            obscure: _obscurePassword,
                            onToggle: () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
                          ),
                          const SizedBox(height: 14),

                          // ── Confirm Password ─────────────────────────────
                          _buildLabel('Confirm Password'),
                          _buildPasswordField(
                            controller: _confirmPasswordController,
                            obscure: _obscureConfirmPassword,
                            onToggle: () => setState(
                              () => _obscureConfirmPassword =
                                  !_obscureConfirmPassword,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // ── Terms ────────────────────────────────────────
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              SizedBox(
                                height: 24,
                                width: 24,
                                child: Checkbox(
                                  value: _agreeToTerms,
                                  activeColor: AppColors.authPrimary,
                                  onChanged: (val) {
                                    setState(
                                      () => _agreeToTerms = val ?? false,
                                    );
                                    _validateInputs();
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: RichText(
                                  text: TextSpan(
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.black87,
                                    ),
                                    children: [
                                      const TextSpan(
                                        text:
                                            'I Agree to the Terms of Service and\nPrivacy ',
                                      ),
                                      WidgetSpan(
                                        child: MouseRegion(
                                          cursor: SystemMouseCursors.click,
                                          child: GestureDetector(
                                            onTap: () => debugPrint(
                                              'Privacy Policy tapped',
                                            ),
                                            child: const Text(
                                              'Policy.',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: AppColors.authPrimary,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // ── Submit Button ────────────────────────────────
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: Opacity(
                              opacity: _isButtonEnabled ? 1.0 : 0.5,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.authPrimary,
                                  disabledBackgroundColor:
                                      AppColors.authPrimary,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: 0,
                                ),
                                onPressed: _isButtonEnabled
                                    ? (_isSubmitting ? null : _handleSubmit)
                                    : null,
                                child: _isSubmitting
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text(
                                        'Submit',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Instructor Fields ──────────────────────────────────────────────────────

  List<Widget> _instructorFields() => [
    _buildLabel('Instructor ID'),
    _buildTextField(controller: _instructorIdController),
    const SizedBox(height: 14),
    _buildLabel('First Name'),
    _buildTextField(controller: _firstNameController),
    const SizedBox(height: 14),
    _buildLabel('Middle Name'),
    _buildTextField(controller: _middleNameController),
    const SizedBox(height: 14),
    _buildLabel('Last Name'),
    _buildTextField(controller: _lastNameController),
    const SizedBox(height: 14),
    _buildLabel('Department'),
    _buildTextField(controller: _departmentController),
    const SizedBox(height: 14),
  ];

  // ── Student Fields ─────────────────────────────────────────────────────────

  List<Widget> _studentFields() => [
    _buildLabel('Student Number'),
    _buildTextField(controller: _studentNumberController),
    const SizedBox(height: 14),
    _buildLabel('First Name'),
    _buildTextField(controller: _firstNameController),
    const SizedBox(height: 14),
    _buildLabel('Middle Name'),
    _buildTextField(controller: _middleNameController),
    const SizedBox(height: 14),
    _buildLabel('Last Name'),
    _buildTextField(controller: _lastNameController),
    const SizedBox(height: 14),
    _buildLabel('Enrollment Code'),
    _buildTextField(controller: _enrollmentCodeController),
    const SizedBox(height: 14),
  ];

  // ── Helpers ────────────────────────────────────────────────────────────────

  Widget _buildLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(
      text,
      style: const TextStyle(fontSize: 13, color: Colors.black87),
    ),
  );

  Widget _buildDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedRole,
      hint: const Text(''),
      decoration: _inputDecoration(),
      items: _roles
          .map((role) => DropdownMenuItem(value: role, child: Text(role)))
          .toList(),
      onChanged: (value) {
        setState(() {
          _selectedRole = value;
          // Reset role-specific fields when switching
          _instructorIdController.clear();
          _departmentController.clear();
          _studentNumberController.clear();
          _enrollmentCodeController.clear();
          _firstNameController.clear();
          _middleNameController.clear();
          _lastNameController.clear();
        });
        _validateInputs();
      },
    );
  }

  Widget _buildTextField({required TextEditingController controller}) {
    return TextFormField(
      controller: controller,
      decoration: _inputDecoration(),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required bool obscure,
    required VoidCallback onToggle,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      decoration: _inputDecoration().copyWith(
        suffixIcon: IconButton(
          icon: Icon(
            obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            color: Colors.grey,
          ),
          onPressed: onToggle,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration() => InputDecoration(
    filled: true,
    fillColor: AppColors.authInputBackground,
    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: BorderSide.none,
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: const BorderSide(color: Colors.red, width: 1.5),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: const BorderSide(color: Colors.red, width: 2.0),
    ),
  );
}
