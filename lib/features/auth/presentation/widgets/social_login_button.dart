import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';

class SocialLoginButton extends StatelessWidget {
  final String label;
  final String assetPath;
  final VoidCallback onTap;

  const SocialLoginButton({
    super.key,
    required this.label,
    required this.assetPath,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: double.infinity,
        height: 55,
        decoration: BoxDecoration(
          color: AppColors.authInputBackground,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            const SizedBox(width: 15),
            Image.asset(
              assetPath,
              height: 24,
              width: 24,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(Icons.image_not_supported, color: Colors.red);
              },
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
