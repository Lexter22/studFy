import 'package:flutter/widgets.dart';

/// Returns a responsive dialog/container width that never exceeds the screen.
/// Uses [preferred] on wide screens, shrinks to screen minus [padding] on phones.
double responsiveDialogWidth(BuildContext context, {double preferred = 450, double padding = 32}) {
  final screenWidth = MediaQuery.of(context).size.width;
  return screenWidth > preferred + padding ? preferred : screenWidth - padding;
}
