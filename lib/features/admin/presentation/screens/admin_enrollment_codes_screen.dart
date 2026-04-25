import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/state/app_state.dart';
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
          title: const Text('Create Enrollment Code'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: codeCtrl,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    labelText: 'Code (e.g. BSIT2A2024)',
                    helperText: 'Will be auto-uppercased',
                  ),
                ),
                TextField(
                  controller: courseCtrl,
                  decoration: const InputDecoration(labelText: 'Course Code (e.g. BSIT)'),
                ),
                TextField(
                  controller: sectionCtrl,
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
                        AppDialog.result(context, type: DialogType.success, message: 'Enrollment code created.');
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
      appBar: AppBar(
        backgroundColor: AppColors.adminPrimary,
        elevation: 0,
        toolbarHeight: 70,
        title: const Row(
          children: [
            Icon(Icons.school, color: Colors.white, size: 28),
            SizedBox(width: 8),
            Text('STUDFY', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            tooltip: 'Create Code',
            onPressed: () => _showCreateDialog(context),
          ),
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text('Admin 1', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      drawer: const AdminDrawer(),
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
                      'Enrollment Codes',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF800000)),
                    ),
                    Text('Total: ${codes.length}',
                        style: const TextStyle(fontSize: 14, color: Colors.grey)),
                  ],
                ),
                const SizedBox(height: 16),
                if (codes.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Text('No enrollment codes yet.',
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
            onPressed: () => AppDialog.confirm(
              context,
              title: 'Delete Code',
              message: 'Delete enrollment code "${code['code']}"?',
              type: DialogType.error,
              confirmLabel: 'Delete',
              onConfirm: () => context.read<AppState>().deleteEnrollmentCode(code['id'].toString()),
            ),
          ),
        ],
      ),
    );
  }
}
