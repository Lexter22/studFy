import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/studfy_footer.dart';
import '../../../../core/widgets/studfy_header.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/services/error_telemetry.dart';
import '../../../../core/state/app_state.dart';
import '../../domain/enums/user_role.dart';
import '../../domain/services/auth_service.dart';
import '../widgets/social_login_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = const AuthService();
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _rememberMe = false;
  bool _obscurePassword = true;
  bool _isButtonEnabled = false;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_validateInputs);
    _passwordController.addListener(_validateInputs);
  }

  void _validateInputs() {
    final bool isNotEmpty = _emailController.text.isNotEmpty && _passwordController.text.isNotEmpty;
    if (isNotEmpty != _isButtonEnabled) {
      setState(() {
        _isButtonEnabled = isNotEmpty;
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: AppColors.authPrimary, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final user = await _authService.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) return;

      if (user.role == UserRole.unknown) {
        await _authService.signOut();
        if (!mounted) return;
        context.read<AppState>().logout();
        _showErrorDialog('Access Denied', 'No role assigned. Please contact the administrator.');
        return;
      }

      context.read<AppState>().login(user);

      if (!user.isEmailVerified) {
        await _authService.sendEmailVerification();
        if (!mounted) return;
        context.goNamed(AppRoutes.verifyEmail);
        return;
      }

      context.go(AppRoutes.pathForRole(user.role));
    } on FirebaseAuthException catch (error, stackTrace) {
      await ErrorTelemetry.captureException(error, stackTrace, operation: 'auth.login');
      String errorMessage = 'Login failed. Please check your credentials.';
      if (error.code == 'user-not-found') errorMessage = 'Account does not exist.';
      if (error.code == 'wrong-password') errorMessage = 'Incorrect password.';
      if (error.code == 'invalid-email') errorMessage = 'The email format is invalid.';
      _showErrorDialog('Login Error', errorMessage);
    } catch (error, stackTrace) {
      await ErrorTelemetry.captureException(error, stackTrace, operation: 'auth.login.unexpected');
      _showErrorDialog('Error', 'An unexpected error occurred.');
    }
  }

@override
Widget build(BuildContext context) {
  final bool isDesktop = MediaQuery.of(context).size.width > 800;

  return Scaffold(
    backgroundColor: AppColors.authPageBackground,
    body: Form(
      key: _formKey,
      child: Column(
        children: [
          const StudfyHeader(backgroundColor: AppColors.authPrimary),
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
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        const Text(
                          'Login to Portal',
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 30),
                        _buildTextField(
                          'Email',
                          isPassword: false,
                          controller: _emailController,
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'Required';
                            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                              return 'Invalid format';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          'Password',
                          isPassword: true,
                          controller: _passwordController,
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'Required';
                            if (value.length < 6) return 'Too short';
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start, // Changed from .center to .start
                            children: [
                              SizedBox(
                                height: 24,
                                width: 24,
                                child: Checkbox(
                                  value: _rememberMe,
                                  activeColor: AppColors.authPrimary,
                                  onChanged: (val) => setState(() => _rememberMe = val ?? false),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Remember me', 
                                style: TextStyle(fontSize: 13),
                              ),
                            ],
                          ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: Opacity(
                            opacity: _isButtonEnabled ? 1.0 : 0.5,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.authPrimary,
                                disabledBackgroundColor: AppColors.authPrimary,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                elevation: 0,
                              ),
                              onPressed: _isButtonEnabled ? _handleLogin : null,
                              child: const Text(
                                'Login',
                                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () => context.goNamed(AppRoutes.forgotPassword),
                          child: const Text(
                            'Forgot Password?',
                            style: TextStyle(color: AppColors.authPrimary, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(width: 30, height: 1.5, color: Colors.black87),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 10),
                              child: Text('or', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            ),
                            Container(width: 30, height: 1.5, color: Colors.black87),
                          ],
                        ),
                        const SizedBox(height: 20),
                        SocialLoginButton(
                          label: 'Continue with Google',
                          assetPath: 'assets/images/google.png',
                          onTap: () {},
                        ),
                        const SizedBox(height: 12),
                        SocialLoginButton(
                          label: 'Continue with Outlook',
                          assetPath: 'assets/images/outlook.png',
                          onTap: () {},
                        ),
                        
                        // --- NEW CODE START ---
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              "Don't have an account? ",
                              style: TextStyle(fontSize: 13, color: Colors.black87),
                            ),
                            GestureDetector(
                              onTap: () {
                                // Update this route to your actual registration page route name
                                // context.goNamed(AppRoutes.register);
                                debugPrint("Register link tapped!");
                              },
                              child: const Text(
                                "Create an account",
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.authPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        // --- NEW CODE END ---
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const StudfyFooter(backgroundColor: AppColors.authPrimary),
        ],
      ),
    ),
  );
}

  Widget _buildTextField(
    String hint, {
    required bool isPassword,
    required TextEditingController controller,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword ? _obscurePassword : false,
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: AppColors.authInputBackground,
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  color: Colors.grey,
                ),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              )
            : null,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
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
      ),
    );
  }
}