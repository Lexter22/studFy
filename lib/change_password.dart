import 'package:flutter/material.dart';

/*

  NOT YET LINKED
  MUST HAVE AI INTEGRATION
  FROM GOOGLE TO THIS SCREEN, USER MUST BE ABLE TO CHANGE THEIR PASSWORD
  AFTER FORGOTTING IT

 */

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  final Color studfyBlue = const Color(0xFF1D4E8F);
  final Color inputBackground = const Color(0xFFF3F4F6);
  final Color pageBackground = const Color(0xFFD1D9E6);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pageBackground,
      body: Column(
        children: [
          // Header
          SizedBox(
            height: 70,
            width: double.infinity,
            child: Container(
              color: studfyBlue,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
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

          // Main Content
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
                      'Change Password',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 30),
                    
                    // New Password Field
                    TextField(
                      obscureText: _obscureNewPassword,
                      decoration: InputDecoration(
                        labelText: 'New Password',
                        filled: true,
                        fillColor: inputBackground,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide.none,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureNewPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            color: Colors.grey,
                          ),
                          onPressed: () {
                            setState(() => _obscureNewPassword = !_obscureNewPassword);
                          },
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Confirm Password Field
                    TextField(
                      obscureText: _obscureConfirmPassword,
                      decoration: InputDecoration(
                        labelText: 'Confirm Password',
                        filled: true,
                        fillColor: inputBackground,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide.none,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            color: Colors.grey,
                          ),
                          onPressed: () {
                            setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
                          },
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Confirm Password Button
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
                          print("Confirm Password Pressed");
                        },
                        child: const Text(
                          'Confirm Password',
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
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
}
