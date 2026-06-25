import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/upper_case_text_formatter.dart';
import '../../../../core/widgets/studfy_header.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/widgets/app_dialog.dart';

class AccountCreationScreen extends StatefulWidget {
  const AccountCreationScreen({super.key});

  @override
  State<AccountCreationScreen> createState() => _AccountCreationScreenState();
}

class _AccountCreationScreenState extends State<AccountCreationScreen> {
  final _formKey = GlobalKey<FormState>();

  // Shared controllers
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _middleNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  // Instructor-only
  final TextEditingController _instructorIdController = TextEditingController();
  final TextEditingController _departmentController = TextEditingController();

  // Student-only
  final TextEditingController _studentNumberController = TextEditingController();
  final TextEditingController _courseController = TextEditingController();
  final TextEditingController _yearSectionController = TextEditingController();

  String? _selectedRole;
  bool _agreeToTerms = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isButtonEnabled = false;

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
      _courseController,
      _yearSectionController,
    ];
    for (final c in controllers) {
      c.addListener(_validateInputs);
    }
  }

  void _validateInputs() {
    bool filled = _emailController.text.isNotEmpty &&
        _firstNameController.text.isNotEmpty &&
        _lastNameController.text.isNotEmpty &&
        _passwordController.text.isNotEmpty &&
        _confirmPasswordController.text.isNotEmpty &&
        _selectedRole != null &&
        _agreeToTerms;

    if (_selectedRole == 'Instructor') {
      filled = filled &&
          _instructorIdController.text.isNotEmpty &&
          _departmentController.text.isNotEmpty;
    } else if (_selectedRole == 'Student') {
      filled = filled &&
          _studentNumberController.text.isNotEmpty &&
          _courseController.text.isNotEmpty &&
          _yearSectionController.text.isNotEmpty;
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
    _courseController.dispose();
    _yearSectionController.dispose();
    super.dispose();
  }

  // ── Pop-ups ────────────────────────────────────────────────────────────────



  // ── Submit ─────────────────────────────────────────────────────────────────

  Future<void> _handleSubmit() async {
    // All fields check (belt-and-suspenders for middle name being optional)
    final bool anyEmpty = _emailController.text.isEmpty ||
        _firstNameController.text.isEmpty ||
        _lastNameController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty ||
        (_selectedRole == 'Instructor' &&
            (_instructorIdController.text.isEmpty || _departmentController.text.isEmpty)) ||
        (_selectedRole == 'Student' &&
            (_studentNumberController.text.isEmpty ||
                _courseController.text.isEmpty ||
                _yearSectionController.text.isEmpty));

    if (anyEmpty) {
      AppDialog.alert(context,
          title: 'Incomplete Form',
          message: 'All fields must be filled before submitting.',
          type: DialogType.warning);
      return;
    }

    // Email format
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(_emailController.text.trim())) {
      AppDialog.alert(context,
          title: 'Invalid Email',
          message: 'Please enter a valid email address (e.g. name@domain.com).');
      return;
    }

    // Password length
    if (_passwordController.text.length < 8) {
      AppDialog.alert(context,
          title: 'Weak Password',
          message: 'Password must be at least 8 characters long.');
      return;
    }

    // Password match
    if (_passwordController.text != _confirmPasswordController.text) {
      AppDialog.alert(context,
          title: 'Password Mismatch',
          message: 'Password and Confirm Password do not match.');
      return;
    }

    // TODO: Implement actual Firebase account creation here

    AppDialog.result(context,
        type: DialogType.success,
        message: 'Your account has been created successfully.\nYou may now log in.',
        buttonLabel: 'Go to Login',
        onDismiss: () => context.goNamed(AppRoutes.login));
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
                    margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 24,
                          offset: const Offset(0, 12),
                        ),
                      ],
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
                                    Icon(Icons.arrow_back_ios_new_rounded,
                                        size: 16, color: AppColors.authPrimary),
                                    SizedBox(width: 4),
                                    Text(
                                      'Back',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.authPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          // ── Title ────────────────────────────────────────
                          const Text(
                            'Create an Account',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: AppColors.authPrimary,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Please fill in the form below',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 32),

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
                                if (_selectedRole == 'Instructor') ..._instructorFields(),
                                if (_selectedRole == 'Student') ..._studentFields(),
                              ],
                            ),
                          ),

                          // ── Password ─────────────────────────────────────
                          _buildLabel('Password'),
                          _buildPasswordField(
                            controller: _passwordController,
                            obscure: _obscurePassword,
                            onToggle: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                          const SizedBox(height: 14),

                          // ── Confirm Password ─────────────────────────────
                          _buildLabel('Confirm Password'),
                          _buildPasswordField(
                            controller: _confirmPasswordController,
                            obscure: _obscureConfirmPassword,
                            onToggle: () =>
                                setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                          ),
                          const SizedBox(height: 16),

                          // ── Terms ────────────────────────────────────────
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                height: 24,
                                width: 24,
                                child: Checkbox(
                                  value: _agreeToTerms,
                                  activeColor: AppColors.authPrimary,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                  side: BorderSide(color: Colors.grey.shade400, width: 1.5),
                                  onChanged: (val) {
                                    setState(() => _agreeToTerms = val ?? false);
                                    _validateInputs();
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: RichText(
                                    text: TextSpan(
                                      style: TextStyle(fontSize: 13, color: Colors.grey.shade700, height: 1.4),
                                      children: [
                                        const TextSpan(text: 'I agree to the Terms of Service and '),
                                        WidgetSpan(
                                          child: MouseRegion(
                                            cursor: SystemMouseCursors.click,
                                            child: GestureDetector(
                                              onTap: () => debugPrint('Privacy Policy tapped'),
                                              child: const Text(
                                                'Privacy Policy.',
                                                style: TextStyle(
                                                  fontSize: 13,
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
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),

                          // ── Submit Button ────────────────────────────────
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: Opacity(
                              opacity: _isButtonEnabled ? 1.0 : 0.6,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.authPrimary,
                                  disabledBackgroundColor: AppColors.authPrimary,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  elevation: _isButtonEnabled ? 8 : 0,
                                  shadowColor: AppColors.authPrimary.withValues(alpha: 0.4),
                                ),
                                onPressed: _isButtonEnabled ? _handleSubmit : null,
                                child: const Text(
                                  'Submit',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.5,
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
        _buildTextField(controller: _instructorIdController, uppercase: true),
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
        _buildTextField(controller: _departmentController, uppercase: true),
        const SizedBox(height: 14),
      ];

  // ── Student Fields ─────────────────────────────────────────────────────────

  List<Widget> _studentFields() => [
        _buildLabel('Student Number'),
        _buildTextField(controller: _studentNumberController, uppercase: true),
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
        _buildLabel('Course'),
        _buildTextField(controller: _courseController, uppercase: true),
        const SizedBox(height: 14),
        _buildLabel('Year & Section'),
        _buildTextField(controller: _yearSectionController, uppercase: true),
        const SizedBox(height: 14),
      ];

  // ── Helpers ────────────────────────────────────────────────────────────────

  Widget _buildLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade800,
            fontWeight: FontWeight.w600,
          ),
        ),
      );

  Widget _buildDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedRole,
      hint: Text('Select Role', style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w400)),
      decoration: _inputDecoration(),
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.black87),
      icon: Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey.shade600),
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
          _courseController.clear();
          _yearSectionController.clear();
          _firstNameController.clear();
          _middleNameController.clear();
          _lastNameController.clear();
        });
        _validateInputs();
      },
    );
  }

  Widget _buildTextField({required TextEditingController controller, bool uppercase = false}) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.black87),
      textCapitalization: uppercase ? TextCapitalization.characters : TextCapitalization.none,
      inputFormatters: uppercase ? const [UpperCaseTextFormatter()] : null,
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
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.black87),
      decoration: _inputDecoration().copyWith(
        suffixIcon: IconButton(
          icon: Icon(
            obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            color: Colors.grey.shade600,
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
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.transparent, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.authPrimary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.redAccent, width: 2.0),
        ),
      );
}
