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

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _rememberMe = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    try {
      final user = await _authService.signInWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );

      if (!mounted) {
        return;
      }

      if (user.role == UserRole.unknown) {
        await _authService.signOut();
        if (!mounted) {
          return;
        }

        context.read<AppState>().logout();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No role assigned for this account. Ask the admin to set Admin, Professor, or Student in Firestore.',
            ),
          ),
        );
        return;
      }

      context.read<AppState>().login(user);

      if (!user.isEmailVerified) {
        await _authService.sendEmailVerification();
        if (!mounted) {
          return;
        }
        context.goNamed(AppRoutes.verifyEmail);
        return;
      }

      context.go(AppRoutes.pathForRole(user.role));
    } on FirebaseAuthException catch (error, stackTrace) {
      await ErrorTelemetry.captureException(
        error,
        stackTrace,
        operation: 'auth.login',
        extras: {'code': error.code, 'email': _emailController.text.trim()},
      );
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message ?? 'Login failed')));
    } catch (error, stackTrace) {
      await ErrorTelemetry.captureException(
        error,
        stackTrace,
        operation: 'auth.login.unexpected',
        extras: {'email': _emailController.text.trim()},
      );
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Login failed')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.authPageBackground,
      body: Column(
        children: [
          const StudfyHeader(backgroundColor: AppColors.authPrimary),
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 30,
                ),
                child: Column(
                  children: [
                    const Text(
                      'Login to Portal',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 30),
                    _buildTextField(
                      'Email',
                      isPassword: false,
                      controller: _emailController,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      'Password',
                      isPassword: true,
                      controller: _passwordController,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          height: 24,
                          width: 24,
                          child: Checkbox(
                            value: _rememberMe,
                            activeColor: AppColors.authPrimary,
                            onChanged: (val) {
                              setState(() => _rememberMe = val ?? false);
                            },
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
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.authPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        onPressed: _handleLogin,
                        child: const Text(
                          'Login',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        context.goNamed(AppRoutes.forgotPassword);
                      },
                      child: const Text(
                        'Forgot Password?',
                        style: TextStyle(
                          color: AppColors.authPrimary,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 30,
                          height: 1.5,
                          color: Colors.black87,
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          child: Text(
                            'or',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        Container(
                          width: 30,
                          height: 1.5,
                          color: Colors.black87,
                        ),
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
                  ],
                ),
              ),
            ),
          ),
          const StudfyFooter(backgroundColor: AppColors.authPrimary),
        ],
      ),
    );
  }

  Widget _buildTextField(
    String hint, {
    required bool isPassword,
    required TextEditingController controller,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword ? _obscurePassword : false,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: AppColors.authInputBackground,
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: Colors.grey,
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              )
            : null,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
