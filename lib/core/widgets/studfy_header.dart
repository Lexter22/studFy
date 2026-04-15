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
      height: 70,
      width: double.infinity,
      color: backgroundColor,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (showBackButton)
            Positioned(
              left: 0,
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                onPressed: onBack ?? () => Navigator.pop(context),
              ),
            ),
          Row(
            mainAxisAlignment: rightTitle == null
                ? MainAxisAlignment.center
                : MainAxisAlignment.spaceBetween,
            children: [
              _Branding(compact: compactBrand),
              if (rightTitle != null)
                Text(
                  rightTitle!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Branding extends StatelessWidget {
  final bool compact;

  const _Branding({required this.compact});

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.school, color: Colors.white, size: 28),
          Text(
            'STUDFY',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
        ],
      );
    }

    return const Row(
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
    );
  }
}
