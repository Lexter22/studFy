import 'package:flutter/material.dart';
import 'forgot_password.dart'; 
import 'admin_dashboard.dart'; // Ensure this file exists in your lib folder

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true),
      home: const LoginScreen(),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _rememberMe = false;
  bool _obscurePassword = true;

  // Controllers to capture input
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final Color studfyBlue = const Color(0xFF1D4E8F);
  final Color inputBackground = const Color(0xFFF3F4F6);

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD1D9E6),
      body: Column(
        children: [
          // Header
          SizedBox(
            height: 70,
            width: double.infinity,
            child: Container(
              color: studfyBlue,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.school, color: Colors.white, size: 30),
                  SizedBox(width: 10),
                  Text(
                    'STUDFY',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ),

          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
                child: Column(
                  children: [
                    const Text(
                      'Login to Portal',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 30),

                    _buildTextField('Username', isPassword: false, controller: _usernameController),
                    const SizedBox(height: 16),
                    
                    _buildTextField('Password', isPassword: true, controller: _passwordController),

                    const SizedBox(height: 12),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          height: 24,
                          width: 24,
                          child: Checkbox(
                            value: _rememberMe,
                            activeColor: studfyBlue,
                            onChanged: (val) => setState(() => _rememberMe = val ?? false),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text('Remember me', style: TextStyle(fontSize: 13)),
                      ],
                    ),

                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: studfyBlue,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                        onPressed: () {
                          // Logic to check credentials
                          if (_usernameController.text == 'admin' && _passwordController.text == 'admin') {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const AdminDashboardScreen()),
                            );
                          } else {
                            // Optional: Show error if credentials don't match
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Invalid username or password')),
                            );
                          }
                        },
                        child: const Text('Login',
                            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                    ),

                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ForgotPasswordScreen(),
                          ),
                        );
                      },
                      child: Text('Forgot Password?',
                          style: TextStyle(color: studfyBlue, fontSize: 11, fontWeight: FontWeight.bold)),
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

                    _buildSocialButton(
                      'Continue with Google',
                      assetPath: 'assets/images/google.png',
                      onTap: () => print("Google Login Pressed"),
                    ),
                    const SizedBox(height: 12),

                    _buildSocialButton(
                      'Continue with Outlook',
                      assetPath: 'assets/images/outlook.png',
                      onTap: () => print("Outlook Login Pressed"),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Footer
          SizedBox(
            height: 70,
            width: double.infinity,
            child: Container(
              color: studfyBlue,
              alignment: Alignment.center,
              child: const Text(
                'Academic Portal System',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(String hint, {required bool isPassword, required TextEditingController controller}) {
    return TextField(
      controller: controller,
      obscureText: isPassword ? _obscurePassword : false,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: inputBackground,
        suffixIcon: isPassword 
            ? IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  color: Colors.grey,
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              )
            : null,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _buildSocialButton(String label, {required String assetPath, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: double.infinity,
        height: 55,
        decoration: BoxDecoration(
          color: inputBackground,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            const SizedBox(width: 15),
            Image.asset(
              assetPath,
              height: 24,
              width: 24,
              errorBuilder: (context, error, stackTrace) => const Icon(Icons.image_not_supported, color: Colors.red),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(color: Colors.grey, fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
    );
  }
}