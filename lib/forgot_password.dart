import 'package:flutter/material.dart';

class ForgotPasswordScreen extends StatelessWidget {
  const ForgotPasswordScreen({super.key});

  static const Color studfyBlue = Color(0xFF1D4E8F);
  static const Color pageBackground = Color(0xFFD1D9E6);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pageBackground,
      body: Column(
        children: [
          // Header with Back Button
          SizedBox(
            height: 70,
            width: double.infinity,
            child: Container(
              color: studfyBlue,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned(
                    left: 10,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                      onPressed: () => Navigator.pop(context), // Goes back to Login
                    ),
                  ),
                  const Row(
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
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
                child: Column(
                  children: [
                    const Text(
                      'Forgot Password',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'We’ve sent an email to the address associated with your account. It contains a secure link to reset your password and get you back into your account.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 15, height: 1.6, color: Colors.black87),
                    ),
                    const SizedBox(height: 22),
                    TextButton(
                      onPressed: () {
                        print("Resending reset email...");
                      },
                      child: const Text(
                        'Click to Resend. 60s',
                        style: TextStyle(
                          color: studfyBlue,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Spacer(),
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