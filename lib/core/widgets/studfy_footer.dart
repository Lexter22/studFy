import 'package:flutter/material.dart';

class StudfyFooter extends StatelessWidget {
  final Color backgroundColor;
  final String title;

  const StudfyFooter({
    super.key,
    required this.backgroundColor,
    this.title = 'Academic Portal System',
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 70,
      width: double.infinity,
      child: Container(
        color: backgroundColor,
        alignment: Alignment.center,
        child: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}
