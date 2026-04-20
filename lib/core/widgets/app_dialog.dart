import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

/// Unified dialog utility for the entire StudFy app.
///
/// Usage:
///   AppDialog.alert(context, title: 'Error', message: '...');
///   AppDialog.confirm(context, title: '...', message: '...', onConfirm: () {});
///   AppDialog.result(context, type: DialogType.success, message: '...');
///   AppDialog.password(context, title: '...', message: '...', onConfirm: (pw) {});

enum DialogType { success, error, warning, info }

class AppDialog {
  AppDialog._();

  // ── Design tokens ─────────────────────────────────────────────────────────

  static const double _radius = 20;
  static const double _iconSize = 52;

  static Color _typeColor(DialogType type) {
    switch (type) {
      case DialogType.success:
        return const Color(0xFF28A745);
      case DialogType.error:
        return const Color(0xFFDC3545);
      case DialogType.warning:
        return const Color(0xFFBDA702);
      case DialogType.info:
        return AppColors.authPrimary;
    }
  }

  static IconData _typeIcon(DialogType type) {
    switch (type) {
      case DialogType.success:
        return Icons.check_circle_rounded;
      case DialogType.error:
        return Icons.cancel_rounded;
      case DialogType.warning:
        return Icons.warning_rounded;
      case DialogType.info:
        return Icons.info_rounded;
    }
  }

  // ── Shared shape ──────────────────────────────────────────────────────────

  static ShapeBorder get _shape =>
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(_radius));

  // ── 1. Alert — single OK button, optional icon ────────────────────────────
  ///
  /// Use for: errors, validation messages, info notices.
  static Future<void> alert(
    BuildContext context, {
    required String title,
    required String message,
    DialogType type = DialogType.error,
    String buttonLabel = 'OK',
    VoidCallback? onDismiss,
  }) {
    final color = _typeColor(type);
    return showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: _shape,
        contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        title: Row(
          children: [
            Icon(_typeIcon(type), color: color, size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Text(message, style: const TextStyle(fontSize: 14, height: 1.5)),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                elevation: 0,
              ),
              onPressed: () {
                Navigator.pop(ctx);
                onDismiss?.call();
              },
              child: Text(
                buttonLabel,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── 2. Confirm — Cancel + action button ───────────────────────────────────
  ///
  /// Use for: approve, reject, delete, save confirmations.
  static Future<void> confirm(
    BuildContext context, {
    required String title,
    required String message,
    required VoidCallback onConfirm,
    DialogType type = DialogType.info,
    String confirmLabel = 'Confirm',
    String cancelLabel = 'Cancel',
  }) {
    final color = _typeColor(type);
    return showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: _shape,
        contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
        actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        title: Row(
          children: [
            Icon(_typeIcon(type), color: color, size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Text(message, style: const TextStyle(fontSize: 14, height: 1.5)),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.black26),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(
                    cancelLabel,
                    style: const TextStyle(
                        color: Colors.black54, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    elevation: 0,
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    onConfirm();
                  },
                  child: Text(
                    confirmLabel,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── 3. Result — centered icon + message, OK button ────────────────────────
  ///
  /// Use for: post-action feedback (approved, saved, deleted, etc.)
  static Future<void> result(
    BuildContext context, {
    required DialogType type,
    required String message,
    String buttonLabel = 'OK',
    VoidCallback? onDismiss,
  }) {
    final color = _typeColor(type);
    return showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: _shape,
        contentPadding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
        actionsPadding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(_typeIcon(type), color: color, size: _iconSize),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w600, height: 1.4),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                elevation: 0,
              ),
              onPressed: () {
                Navigator.pop(ctx);
                onDismiss?.call();
              },
              child: Text(
                buttonLabel,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── 4. Password confirm — confirm with password field ─────────────────────
  ///
  /// Use for: delete with admin password verification.
  static Future<void> password(
    BuildContext context, {
    required String title,
    required String message,
    required Future<void> Function(String password) onConfirm,
    String confirmLabel = 'Confirm',
    String cancelLabel = 'Cancel',
    DialogType type = DialogType.error,
  }) {
    final color = _typeColor(type);
    final controller = TextEditingController();

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: _shape,
        contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
        actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        title: Row(
          children: [
            Icon(_typeIcon(type), color: color, size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message,
                style: const TextStyle(fontSize: 14, height: 1.5)),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              obscureText: true,
              decoration: InputDecoration(
                hintText: 'Admin Password',
                prefixIcon: const Icon(Icons.lock_outline, size: 20),
                filled: true,
                fillColor: Colors.grey.shade100,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.black26),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () {
                    controller.dispose();
                    Navigator.pop(ctx);
                  },
                  child: Text(
                    cancelLabel,
                    style: const TextStyle(
                        color: Colors.black54, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    elevation: 0,
                  ),
                  onPressed: () async {
                    final pw = controller.text;
                    controller.dispose();
                    Navigator.pop(ctx);
                    await onConfirm(pw);
                  },
                  child: Text(
                    confirmLabel,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
