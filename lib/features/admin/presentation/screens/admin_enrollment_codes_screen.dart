import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:supabase_flutter/supabase_flutter.dart' hide AuthException;

import '../../../../core/constants/app_colors.dart';
import '../../../../core/state/app_state.dart';
import '../../../../core/utils/upper_case_text_formatter.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../auth/domain/models/auth_exception.dart';
import '../widgets/admin_drawer.dart';

class AdminEnrollmentCodesScreen extends StatelessWidget {
  const AdminEnrollmentCodesScreen({super.key});

  void _showCreateDialog(BuildContext context) {
    final codeCtrl = TextEditingController();
    final courseCtrl = TextEditingController();
    final sectionCtrl = TextEditingController();
    final maxUsesCtrl = TextEditingController();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Create Registration Code'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: codeCtrl,
                  textCapitalization: TextCapitalization.characters,
                  inputFormatters: const [UpperCaseTextFormatter()],
                  decoration: const InputDecoration(
                    labelText: 'Code (e.g. BSIT2A2024)',
                    helperText: 'Always uppercase',
                  ),
                ),
                TextField(
                  controller: courseCtrl,
                  textCapitalization: TextCapitalization.characters,
                  inputFormatters: const [UpperCaseTextFormatter()],
                  decoration: const InputDecoration(labelText: 'Course Code (e.g. BSIT)'),
                ),
                TextField(
                  controller: sectionCtrl,
                  textCapitalization: TextCapitalization.characters,
                  inputFormatters: const [UpperCaseTextFormatter()],
                  decoration: const InputDecoration(labelText: 'Year & Section (e.g. 2-A)'),
                ),
                TextField(
                  controller: maxUsesCtrl,
                  decoration: const InputDecoration(labelText: 'Max Uses (leave blank = unlimited)'),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      if (codeCtrl.text.trim().isEmpty ||
                          courseCtrl.text.trim().isEmpty ||
                          sectionCtrl.text.trim().isEmpty) {
                        AppDialog.alert(ctx, title: 'Error', message: 'Please fill in all required fields.');
                        return;
                      }
                      setDialogState(() => isLoading = true);
                      try {
                        await context.read<AppState>().createEnrollmentCode(
                          code: codeCtrl.text,
                          courseCode: courseCtrl.text,
                          yearSection: sectionCtrl.text,
                          maxUses: int.tryParse(maxUsesCtrl.text.trim()),
                        );
                        if (!ctx.mounted) return;
                        Navigator.pop(ctx);
                        AppDialog.result(context, type: DialogType.success, message: 'Registration code created.');
                      } on AuthException catch (e) {
                        if (!ctx.mounted) return;
                        Navigator.pop(ctx);
                        AppDialog.alert(context, title: 'Error', message: e.message ?? 'Failed to create code.');
                      } catch (e) {
                        if (!ctx.mounted) return;
                        Navigator.pop(ctx);
                        AppDialog.alert(context, title: 'Error', message: e.toString());
                      }
                    },
              child: isLoading
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return Scaffold(
      backgroundColor: AppColors.adminPageBackground,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateDialog(context),
        backgroundColor: AppColors.adminPrimary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: ValueListenableBuilder<List<Map<String, dynamic>>>(
        valueListenable: appState.enrollmentCodesNotifier,
        builder: (context, codes, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Registration Codes',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF800000)),
                    ),
                    Text('Total: ${codes.length}',
                        style: const TextStyle(fontSize: 14, color: Colors.grey)),
                  ],
                ),
                const SizedBox(height: 16),
                if (codes.isEmpty)
                  Container(
                    width: 450,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Text('No registration codes yet.',
                          style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
                    ),
                  )
                else
                  ...codes.map((code) => _CodeCard(code: code)),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _CodeCard extends StatelessWidget {
  final Map<String, dynamic> code;
  const _CodeCard({required this.code});

  void _showDeleteCodeDialog(BuildContext context) {
    final passwordCtrl = TextEditingController();
    bool isLoading = false;
    bool obscurePassword = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
          contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          actionsPadding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Delete Code',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'Delete registration code "${code['code']}"? This cannot be undone.',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.normal),
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
            ],
          ),
          content: Container(
            width: MediaQuery.of(dialogCtx).size.width * 0.9,
            constraints: const BoxConstraints(maxWidth: 400),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 8),
                  TextField(
                    controller: passwordCtrl,
                    obscureText: obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Confirm Admin Password',
                      labelStyle: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                      floatingLabelStyle: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                      prefixIcon: Icon(Icons.lock_outline_rounded, color: Colors.red.withValues(alpha: 0.7), size: 20),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          color: Colors.grey.shade600,
                          size: 20,
                        ),
                        onPressed: () {
                          setDialogState(() {
                            obscurePassword = !obscurePassword;
                          });
                        },
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF8F9FC),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: Colors.grey.shade200, width: 1.5),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Colors.red, width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: isLoading ? null : () => Navigator.pop(dialogCtx),
              child: Text('Cancel', style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: isLoading
                  ? null
                  : () async {
                      final enteredPassword = passwordCtrl.text.trim();
                      if (enteredPassword.isEmpty) {
                        AppDialog.alert(dialogCtx, title: 'Required', message: 'Please enter your admin password.');
                        return;
                      }

                      setDialogState(() => isLoading = true);
                      try {
                        final adminEmail = Supabase.instance.client.auth.currentUser?.email;
                        if (adminEmail != null && !adminEmail.startsWith('mock')) {
                          await Supabase.instance.client.auth.signInWithPassword(
                            email: adminEmail,
                            password: enteredPassword,
                          );
                        } else {
                          if (enteredPassword.isEmpty) {
                            throw Exception('Password cannot be empty');
                          }
                        }

                        // Password verified, proceed with deletion
                        await context.read<AppState>().deleteEnrollmentCode(code['id'].toString());
                        if (!context.mounted) return;
                        Navigator.pop(dialogCtx);
                        await AppDialog.result(context, type: DialogType.success, message: 'Enrollment code deleted successfully.');
                      } catch (e) {
                        setDialogState(() => isLoading = false);
                        if (!context.mounted) return;
                        await AppDialog.alert(dialogCtx, title: 'Error', message: 'Verification failed: Incorrect password.');
                      }
                    },
              child: isLoading
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                  : const Text('Delete Code', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isActive = code['is_active'] as bool? ?? false;
    final maxUses = code['max_uses'];
    final currentUses = code['current_uses'] as int? ?? 0;
    final expiresAt = code['expires_at'];

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isActive ? Colors.green.shade100 : Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      code['code']?.toString() ?? '',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: isActive ? Colors.green.shade50 : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        isActive ? 'Active' : 'Inactive',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isActive ? Colors.green : Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${code['course_code']} · ${code['year_section']}',
                  style: const TextStyle(fontSize: 13, color: Colors.black54),
                ),
                Text(
                  'Uses: $currentUses${maxUses != null ? ' / $maxUses' : ' (unlimited)'}${expiresAt != null ? ' · Expires: ${expiresAt.toString().substring(0, 10)}' : ''}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          Switch(
            value: isActive,
            activeColor: AppColors.adminPrimary,
            onChanged: (val) => context.read<AppState>().toggleEnrollmentCode(
              code['id'].toString(),
              val,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red, size: 20),
            onPressed: () => _showDeleteCodeDialog(context),
          ),
        ],
      ),
    );
  }
}
