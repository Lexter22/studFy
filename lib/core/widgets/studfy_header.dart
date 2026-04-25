import 'package:flutter/material.dart';

class StudfyHeader extends StatelessWidget {
  final Color backgroundColor;
  final bool showBackButton;
  final VoidCallback? onBack;
  final String? rightTitle;
  final bool compactBrand;

  const StudfyHeader({
    super.key,
    required this.backgroundColor,
    this.showBackButton = false,
    this.onBack,
    this.rightTitle,
    this.compactBrand = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: backgroundColor,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (showBackButton)
            Positioned(
              left: 0,
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF1A46A0)),
                onPressed: onBack ?? () => Navigator.pop(context),
              ),
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.school, color: Color(0xFF1A46A0), size: 36),
              const SizedBox(width: 10),
              const Text(
                'STUDFY',
                style: TextStyle(
                  color: Color(0xFF1A46A0),
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          if (rightTitle != null)
            Positioned(
              right: 0,
              child: Text(
                rightTitle!,
                style: const TextStyle(
                  color: Color(0xFF1A46A0),
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
