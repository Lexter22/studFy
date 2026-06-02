import 'dart:html' as html;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/state/app_state.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../data/repositories/professor_repository.dart';
import '../../domain/models/professor_subject.dart';
import '../widgets/professor_floating_nav_bar.dart';
import 'assignment_detail_screen.dart';

class ProfessorSubjectScreen extends StatefulWidget {
  final ProfessorSubject subject;
  final int initialIndex;
  const ProfessorSubjectScreen({super.key, required this.subject, this.initialIndex = 0});

  @override
  State<ProfessorSubjectScreen> createState() => _ProfessorSubjectScreenState();
}

class _ProfessorSubjectScreenState extends State<ProfessorSubjectScreen> {
  final _repo = const ProfessorRepository();
  late int _currentIndex;
  int? _hoveredNavIdx;
  // 0 = modules view, 1 = students view
  int _contentIndex = 0;
  bool _createMenuOpen = false;

  List<SubjectModule> _modules = [];
  List<SubjectQuiz> _quizzes = [];
  List<SubjectAssignment> _assignments = [];
  List<Map<String, String>> _students = [];
  bool _loading = true;

  final ScrollController _meetingsScrollController = ScrollController();
  final ScrollController _gradesScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _load();
  }

  @override
  void dispose() {
    _meetingsScrollController.dispose();
    _gradesScrollController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final modules = await _repo.fetchModules(widget.subject.id);
      final quizzes = await _repo.fetchQuizzes(widget.subject.id);
      var assignments = await _repo.fetchAssignments(widget.subject.id);
      final students = await _repo.fetchEnrolledStudents(widget.subject.id);
      if (!mounted) return;
      setState(() {
        _modules = modules;
        _quizzes = quizzes;
        _assignments = assignments;
        _students = students;
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── Modules ───────────────────────────────────────────────────────────────

  void _showAddModuleDialog() {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: 450,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.authPrimary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.folder_rounded, color: AppColors.authPrimary, size: 24),
                    ),
                    const SizedBox(width: 14),
                    const Text(
                      'Create Module',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: titleCtrl,
                  decoration: InputDecoration(
                    labelText: 'Module Title',
                    labelStyle: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w500),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade200, width: 1.5),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.authPrimary, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descCtrl,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Description (optional)',
                    labelStyle: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w500),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade200, width: 1.5),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.authPrimary, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.grey.shade600,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () async {
                        if (titleCtrl.text.trim().isEmpty) return;
                        Navigator.pop(ctx);
                        try {
                          await _repo.createModule(
                            widget.subject.id,
                            titleCtrl.text,
                            descCtrl.text,
                          );
                          await _load();
                          if (mounted) AppDialog.result(context, type: DialogType.success, message: 'Module added.');
                        } catch (e) {
                          if (mounted) AppDialog.result(context, type: DialogType.error, message: e.toString());
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.authPrimary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: const Text('Add Module', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _verifyPasswordAndExecute(String actionDescription, Future<void> Function() action) {
    final user = context.read<AppState>().currentUser;
    if (user == null) {
      AppDialog.result(context, type: DialogType.error, message: 'User session not found.');
      return;
    }

    AppDialog.password(
      context,
      title: 'Confirm Password',
      message: 'Please enter your password to confirm $actionDescription.',
      hintText: 'Enter your password',
      onConfirm: (password) async {
        try {
          if (user.email != null && user.email!.toLowerCase() == 'prof@studfy.com') {
            if (password == 'password123') {
              await action();
              return;
            } else {
              throw Exception('Invalid password.');
            }
          }

          // Verify password with Supabase by signing in again
          await Supabase.instance.client.auth.signInWithPassword(
            email: user.email!,
            password: password,
          );
          
          await action();
        } catch (e) {
          if (mounted) {
            AppDialog.result(
              context,
              type: DialogType.error,
              message: 'Authentication failed: ${e.toString().replaceAll('Exception: ', '')}',
            );
          }
        }
      },
    );
  }

  void _confirmDeleteModuleAttachment(SubjectModule module) {
    _verifyPasswordAndExecute('deleting material "${module.fileName ?? module.title}"', () async {
      try {
        await _repo.deleteModuleAttachment(module.id);
        await _load();
        if (mounted) AppDialog.result(context, type: DialogType.success, message: 'Material deleted.');
      } catch (e) {
        if (mounted) AppDialog.result(context, type: DialogType.error, message: e.toString());
      }
    });
  }

  void _confirmDeleteModule(SubjectModule module) {
    _verifyPasswordAndExecute('deleting module "${module.title}"', () async {
      try {
        await _repo.deleteModule(module.id);
        await _load();
        if (mounted) AppDialog.result(context, type: DialogType.success, message: 'Module deleted.');
      } catch (e) {
        if (mounted) AppDialog.result(context, type: DialogType.error, message: e.toString());
      }
    });
  }

  // ── Quizzes ───────────────────────────────────────────────────────────────

  void _showAddQuizDialog() {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    DateTime? deadline;
    String? selectedModuleId = _modules.isNotEmpty ? _modules.first.id : null;
    final questions = <Map<String, dynamic>>[];

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            width: 600,
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.authPrimary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.edit_rounded, color: AppColors.authPrimary, size: 24),
                    ),
                    const SizedBox(width: 14),
                    const Text(
                      'Create New Quiz',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: titleCtrl,
                          decoration: InputDecoration(
                            labelText: 'Quiz Title',
                            labelStyle: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w500),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade200, width: 1.5),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppColors.authPrimary, width: 2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: descCtrl,
                          maxLines: 2,
                          decoration: InputDecoration(
                            labelText: 'Description (optional)',
                            labelStyle: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w500),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade200, width: 1.5),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppColors.authPrimary, width: 2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Module picker
                        if (_modules.isEmpty) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.amber.shade200),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.warning_amber_rounded, color: Colors.amber.shade800),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'No modules found. You must create a module first.',
                                    style: TextStyle(color: Colors.amber.shade900, fontSize: 13, fontWeight: FontWeight.w500),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ] else ...[
                          DropdownButtonFormField<String>(
                            value: selectedModuleId,
                            decoration: InputDecoration(
                              labelText: 'Assign to Module',
                              labelStyle: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w500),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey.shade200, width: 1.5),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: AppColors.authPrimary, width: 2),
                              ),
                            ),
                            items: _modules.map((m) => DropdownMenuItem(value: m.id, child: Text(m.title))).toList(),
                            onChanged: (v) => setS(() => selectedModuleId = v),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Deadline
                        const Text(
                          'Deadline',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87),
                        ),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: ctx,
                              initialDate: deadline ?? DateTime.now().add(const Duration(days: 7)),
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(const Duration(days: 365)),
                            );
                            if (picked != null) setS(() => deadline = picked);
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade200, width: 1.5),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today_rounded, size: 18, color: AppColors.authPrimary),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        deadline == null ? 'No deadline set' : '${deadline!.day}/${deadline!.month}/${deadline!.year}',
                                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.arrow_drop_down, color: Colors.black54),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Questions
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Text('Questions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87)),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.authPrimary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '${questions.length}',
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.authPrimary),
                                  ),
                                ),
                              ],
                            ),
                            TextButton.icon(
                              onPressed: () => setS(() => questions.add({'question': '', 'options': ['', '', '', ''], 'correct_answer': ''})),
                              icon: const Icon(Icons.add_circle_outline, size: 18),
                              label: const Text('Add Question', style: TextStyle(fontWeight: FontWeight.bold)),
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.authPrimary,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (questions.isEmpty)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Column(
                              children: [
                                Icon(Icons.quiz_outlined, size: 36, color: Colors.grey.shade400),
                                const SizedBox(height: 8),
                                Text(
                                  'No questions added yet.',
                                  style: TextStyle(color: Colors.grey.shade500, fontSize: 13, fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          )
                        else
                          ...questions.asMap().entries.map((e) => _QuestionTile(
                            index: e.key,
                            data: e.value,
                            onDelete: () => setS(() => questions.removeAt(e.key)),
                            onChanged: (updated) => setS(() => questions[e.key] = updated),
                          )),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.grey.shade600,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () async {
                        if (titleCtrl.text.trim().isEmpty) {
                          AppDialog.result(ctx, type: DialogType.error, message: 'Please enter a quiz title.');
                          return;
                        }
                        if (selectedModuleId == null) {
                          AppDialog.result(ctx, type: DialogType.error, message: 'Please select a module. Assigning to a module is required.');
                          return;
                        }
                        Navigator.pop(ctx);
                        try {
                          await _repo.createQuiz(
                            subjectId: widget.subject.id,
                            title: titleCtrl.text,
                            description: descCtrl.text,
                            deadline: deadline,
                            moduleId: selectedModuleId,
                            questions: questions,
                          );
                          await _load();
                          if (mounted) AppDialog.result(context, type: DialogType.success, message: 'Quiz created.');
                        } catch (e) {
                          if (mounted) AppDialog.result(context, type: DialogType.error, message: e.toString());
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.authPrimary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: const Text('Create Quiz', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _confirmDeleteQuiz(SubjectQuiz quiz) {
    _verifyPasswordAndExecute('deleting quiz "${quiz.title}"', () async {
      try {
        await _repo.deleteQuiz(quiz.id);
        await _load();
        if (mounted) AppDialog.result(context, type: DialogType.success, message: 'Quiz deleted.');
      } catch (e) {
        if (mounted) AppDialog.result(context, type: DialogType.error, message: e.toString());
      }
    });
  }

  // ── Assignments ───────────────────────────────────────────────────────────

  void _showAddAssignmentDialog() {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    DateTime? deadline;
    String? selectedModuleId = _modules.isNotEmpty ? _modules.first.id : null;
    String? fileUrl;
    String? fileName;
    bool uploading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            width: 450,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.authPrimary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.assignment_rounded, color: AppColors.authPrimary, size: 24),
                      ),
                      const SizedBox(width: 14),
                      const Text(
                        'Create Assignment',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: titleCtrl,
                    decoration: InputDecoration(
                      labelText: 'Assignment Title',
                      labelStyle: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w500),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade200, width: 1.5),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.authPrimary, width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: descCtrl,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'Description (optional)',
                      labelStyle: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w500),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade200, width: 1.5),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.authPrimary, width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Module picker
                  if (_modules.isEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.amber.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning_amber_rounded, color: Colors.amber.shade800),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'No modules found. You must create a module first.',
                              style: TextStyle(color: Colors.amber.shade900, fontSize: 13, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ] else ...[
                    DropdownButtonFormField<String>(
                      value: selectedModuleId,
                      decoration: InputDecoration(
                        labelText: 'Assign to Module',
                        labelStyle: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w500),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade200, width: 1.5),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.authPrimary, width: 2),
                        ),
                      ),
                      items: _modules.map((m) => DropdownMenuItem(value: m.id, child: Text(m.title))).toList(),
                      onChanged: (v) => setS(() => selectedModuleId = v),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Deadline
                  const Text(
                    'Deadline',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate: DateTime.now().add(const Duration(days: 7)),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) setS(() => deadline = picked);
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200, width: 1.5),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today_rounded, size: 18, color: AppColors.authPrimary),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  deadline == null ? 'No deadline set' : '${deadline!.day}/${deadline!.month}/${deadline!.year}',
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_drop_down, color: Colors.black54),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // File Picker Container
                  InkWell(
                    onTap: uploading ? null : () async {
                      final result = await FilePicker.platform.pickFiles(withData: true);
                      if (result == null || result.files.isEmpty) return;
                      final file = result.files.first;
                      if (file.bytes == null) return;
                      setS(() => uploading = true);
                      try {
                        final url = await _repo.uploadAssignmentFile(widget.subject.id, file.name, file.bytes!);
                        setS(() { fileUrl = url; fileName = file.name; uploading = false; });
                      } catch (e) {
                        setS(() => uploading = false);
                        if (ctx.mounted) AppDialog.result(ctx, type: DialogType.error, message: 'Upload failed: $e');
                      }
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: fileUrl != null ? Colors.green.withOpacity(0.04) : AppColors.authPrimary.withOpacity(0.04),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: fileUrl != null ? Colors.green.withOpacity(0.3) : AppColors.authPrimary.withOpacity(0.15),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            uploading
                                ? Icons.hourglass_top_rounded
                                : (fileUrl != null ? Icons.check_circle_rounded : Icons.cloud_upload_outlined),
                            color: fileUrl != null ? Colors.green : AppColors.authPrimary,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  uploading
                                      ? 'Uploading reference file...'
                                      : (fileName ?? 'Attach Reference File'),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: fileUrl != null ? Colors.green.shade800 : AppColors.authPrimary,
                                    fontSize: 13,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (!uploading && fileName == null)
                                  const SizedBox(height: 2),
                                if (!uploading && fileName == null)
                                  Text(
                                    'PDF, Doc, Image, etc.',
                                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                                  ),
                              ],
                            ),
                          ),
                          if (fileUrl != null && !uploading)
                            IconButton(
                              icon: const Icon(Icons.close, size: 16, color: Colors.red),
                              onPressed: () => setS(() { fileUrl = null; fileName = null; }),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.grey.shade600,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: uploading ? null : () async {
                          if (titleCtrl.text.trim().isEmpty) {
                            AppDialog.result(ctx, type: DialogType.error, message: 'Please enter an assignment title.');
                            return;
                          }
                          if (selectedModuleId == null) {
                            AppDialog.result(ctx, type: DialogType.error, message: 'Please select a module. Assigning to a module is required.');
                            return;
                          }
                          Navigator.pop(ctx);
                          try {
                            await _repo.createAssignment(
                              subjectId: widget.subject.id,
                              title: titleCtrl.text,
                              description: descCtrl.text,
                              deadline: deadline,
                              moduleId: selectedModuleId,
                              fileUrl: fileUrl,
                              fileName: fileName,
                            );
                            await _load();
                            if (mounted) AppDialog.result(context, type: DialogType.success, message: 'Assignment created.');
                          } catch (e) {
                            if (mounted) AppDialog.result(context, type: DialogType.error, message: e.toString());
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.authPrimary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: const Text('Create', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _confirmDeleteAssignment(SubjectAssignment a) {
    final isMaterial = (a.description ?? '').startsWith('[MATERIAL]');
    final typeStr = isMaterial ? 'material' : 'assignment';
    _verifyPasswordAndExecute('deleting $typeStr "${a.title}"', () async {
      try {
        await _repo.deleteAssignment(a.id);
        await _load();
        if (mounted) {
          AppDialog.result(
            context,
            type: DialogType.success,
            message: '${isMaterial ? "Material" : "Assignment"} deleted.',
          );
        }
      } catch (e) {
        if (mounted) AppDialog.result(context, type: DialogType.error, message: e.toString());
      }
    });
  }

  void _showAddMaterialDialog() {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String? selectedModuleId = _modules.isNotEmpty ? _modules.first.id : null;
    String? fileUrl;
    String? fileName;
    bool uploading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            width: 450,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.authPrimary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.menu_book_rounded, color: AppColors.authPrimary, size: 24),
                      ),
                      const SizedBox(width: 14),
                      const Text(
                        'Add Material',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: titleCtrl,
                    decoration: InputDecoration(
                      labelText: 'Material Title',
                      labelStyle: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w500),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade200, width: 1.5),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.authPrimary, width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: descCtrl,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'Description (optional)',
                      labelStyle: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w500),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade200, width: 1.5),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.authPrimary, width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Module picker
                  if (_modules.isEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.amber.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning_amber_rounded, color: Colors.amber.shade800),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'No modules found. You must create a module first.',
                              style: TextStyle(color: Colors.amber.shade900, fontSize: 13, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ] else ...[
                    DropdownButtonFormField<String>(
                      value: selectedModuleId,
                      decoration: InputDecoration(
                        labelText: 'Assign to Module',
                        labelStyle: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w500),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade200, width: 1.5),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.authPrimary, width: 2),
                        ),
                      ),
                      items: _modules.map((m) => DropdownMenuItem(value: m.id, child: Text(m.title))).toList(),
                      onChanged: (v) => setS(() => selectedModuleId = v),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // File Picker Container (PDF preferred)
                  InkWell(
                    onTap: uploading ? null : () async {
                      final result = await FilePicker.platform.pickFiles(
                        type: FileType.custom,
                        allowedExtensions: ['pdf'],
                        withData: true,
                      );
                      if (result == null || result.files.isEmpty) return;
                      final file = result.files.first;
                      if (file.bytes == null) return;
                      setS(() => uploading = true);
                      try {
                        final url = await _repo.uploadAssignmentFile(widget.subject.id, file.name, file.bytes!);
                        setS(() { fileUrl = url; fileName = file.name; uploading = false; });
                      } catch (e) {
                        setS(() => uploading = false);
                        if (ctx.mounted) AppDialog.result(ctx, type: DialogType.error, message: 'Upload failed: $e');
                      }
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: fileUrl != null ? Colors.green.withOpacity(0.04) : AppColors.authPrimary.withOpacity(0.04),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: fileUrl != null ? Colors.green.withOpacity(0.3) : AppColors.authPrimary.withOpacity(0.15),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            uploading
                                ? Icons.hourglass_top_rounded
                                : (fileUrl != null ? Icons.check_circle_rounded : Icons.cloud_upload_outlined),
                            color: fileUrl != null ? Colors.green : AppColors.authPrimary,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  uploading
                                      ? 'Uploading PDF...'
                                      : (fileName ?? 'Attach PDF Document'),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: fileUrl != null ? Colors.green.shade800 : AppColors.authPrimary,
                                    fontSize: 13,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (!uploading && fileName == null)
                                  const SizedBox(height: 2),
                                if (!uploading && fileName == null)
                                  Text(
                                    'PDF documents only',
                                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                                  ),
                              ],
                            ),
                          ),
                          if (fileUrl != null && !uploading)
                            IconButton(
                              icon: const Icon(Icons.close, size: 16, color: Colors.red),
                              onPressed: () => setS(() { fileUrl = null; fileName = null; }),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.grey.shade600,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: uploading ? null : () async {
                          if (titleCtrl.text.trim().isEmpty) {
                            AppDialog.result(ctx, type: DialogType.error, message: 'Title is required.');
                            return;
                          }
                          if (selectedModuleId == null) {
                            AppDialog.result(ctx, type: DialogType.error, message: 'Please select a module. Assigning to a module is required.');
                            return;
                          }
                          if (fileUrl == null) {
                            AppDialog.result(ctx, type: DialogType.error, message: 'Please attach a PDF file.');
                            return;
                          }
                          Navigator.pop(ctx);
                          try {
                            final descriptionText = '[MATERIAL] ${descCtrl.text.trim()}'.trim();
                            await _repo.createAssignment(
                              subjectId: widget.subject.id,
                              title: titleCtrl.text,
                              description: descriptionText,
                              deadline: null,
                              moduleId: selectedModuleId,
                              fileUrl: fileUrl,
                              fileName: fileName,
                            );
                            await _load();
                            if (mounted) AppDialog.result(context, type: DialogType.success, message: 'Material added successfully.');
                          } catch (e) {
                            if (mounted) AppDialog.result(context, type: DialogType.error, message: e.toString());
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.authPrimary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: const Text('Add Material', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }


  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppState>().currentUser;
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(90),
        child: AppBar(
          backgroundColor: AppColors.authPrimary,
          elevation: 0,
          automaticallyImplyLeading: false,
          flexibleSpace: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: const [
                      Icon(Icons.school, color: Colors.white, size: 28),
                      SizedBox(height: 2),
                      Text(
                        'STUDFY',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    user?.displayName ?? 'Archie Arevalo',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          SafeArea(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSubjectHeader(),
                      Expanded(
                        child: _contentIndex == 0
                            ? _buildModulesContent()
                            : _contentIndex == 1
                                ? _buildStudentsContent()
                                : _buildAnnouncementsContent(),
                      ),
                    ],
                  ),
          ),
          const ProfessorFloatingNavBar(currentIndex: 1),
        ],
      ),
    );
  }

  Widget _buildSubjectHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.subject.name,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.authPrimary)),
                  const SizedBox(height: 2),
                  Text(
                    '${widget.subject.courseCode} ${widget.subject.yearLevel}-${widget.subject.section}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Segmented Control bar for 3 tabs: Modules (0), Students (1), Announcements (2)
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFFEFEFEF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                _buildSegmentButton(0, 'Modules', Icons.book_rounded),
                _buildSegmentButton(1, 'Students', Icons.people_alt_rounded),
                _buildSegmentButton(2, 'Announcements', Icons.campaign_rounded),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // New Announcement button
              SizedBox(
                height: 36,
                child: ElevatedButton.icon(
                  onPressed: _showNewAnnouncementDialog,
                  icon: const Icon(Icons.add_circle_outline, size: 16),
                  label: const Text('New Announcement', style: TextStyle(fontSize: 13)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.authPrimary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Create dropdown
              _buildCreateButton(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentButton(int index, String label, IconData icon) {
    final isSelected = _contentIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _contentIndex = index;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.authPrimary : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.authPrimary.withOpacity(0.15),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    )
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 14,
                color: isSelected ? Colors.white : Colors.black54,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }




  Widget _buildCreateButton() {
    return SizedBox(
      height: 36,
      child: ElevatedButton.icon(
        onPressed: () {
          showDialog(
            context: context,
            builder: (dialogCtx) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              backgroundColor: Colors.white,
              titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              title: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Create New Content',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: AppColors.authPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${widget.subject.name} - ${widget.subject.courseCode} ${widget.subject.yearLevel}-${widget.subject.section}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: const Icon(Icons.edit_rounded, color: AppColors.authPrimary),
                    title: const Text('Quiz', style: TextStyle(fontWeight: FontWeight.bold)),
                    onTap: () {
                      Navigator.pop(dialogCtx);
                      _showAddQuizDialog();
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.assignment_rounded, color: AppColors.authPrimary),
                    title: const Text('Assignment', style: TextStyle(fontWeight: FontWeight.bold)),
                    onTap: () {
                      Navigator.pop(dialogCtx);
                      _showAddAssignmentDialog();
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.menu_book_rounded, color: AppColors.authPrimary),
                    title: const Text('Material', style: TextStyle(fontWeight: FontWeight.bold)),
                    onTap: () {
                      Navigator.pop(dialogCtx);
                      _showAddMaterialDialog();
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.folder_rounded, color: AppColors.authPrimary),
                    title: const Text('Module', style: TextStyle(fontWeight: FontWeight.bold)),
                    onTap: () {
                      Navigator.pop(dialogCtx);
                      _showAddModuleDialog();
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.video_camera_front_rounded, color: AppColors.authPrimary),
                    title: const Text('Schedule Meeting', style: TextStyle(fontWeight: FontWeight.bold)),
                    onTap: () {
                      Navigator.pop(dialogCtx);
                      _showScheduleMeetingDialog();
                    },
                  ),
                ],
              ),
            ),
          );
        },
        icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
        label: const Text('Create', style: TextStyle(fontSize: 13)),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.authPrimary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 14),
        ),
      ),
    );
  }

  void _showNewAnnouncementDialog() {
    final ctrl = TextEditingController();
    DateTime announcementDate = DateTime.now();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            width: 450,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.authPrimary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.campaign_rounded, color: AppColors.authPrimary, size: 24),
                    ),
                    const SizedBox(width: 14),
                    const Text(
                      'New Announcement',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Text(
                  'Announcement Content',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: ctrl,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'Write your announcement here...',
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    contentPadding: const EdgeInsets.all(16),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade200, width: 1.5),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.authPrimary, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Announcement Date',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: announcementDate,
                      firstDate: DateTime.now().subtract(const Duration(days: 365)),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      setS(() => announcementDate = picked);
                    }
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200, width: 1.5),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_rounded, size: 18, color: AppColors.authPrimary),
                        const SizedBox(width: 12),
                        Text(
                          '${announcementDate.month}/${announcementDate.day}/${announcementDate.year}',
                          style: const TextStyle(fontSize: 14, color: Colors.black87, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.grey.shade600,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () {
                        if (ctrl.text.trim().isEmpty) return;
                        Navigator.pop(ctx);
                        context.read<AppState>().addAnnouncement(
                              widget.subject.name,
                              ctrl.text.trim(),
                              announcementDate,
                            );
                        AppDialog.result(context, type: DialogType.success, message: 'Announcement posted!');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.authPrimary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: const Text('Post', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _confirmDeleteAnnouncement(Map<String, String> ann) {
    AppDialog.confirm(
      context,
      title: 'Delete Announcement',
      message: 'Are you sure you want to delete this announcement?',
      type: DialogType.error,
      onConfirm: () {
        context.read<AppState>().deleteAnnouncement(ann);
        AppDialog.result(context, type: DialogType.success, message: 'Announcement deleted successfully.');
      },
    );
  }

  Widget _buildProfessorAnnouncementCard(Map<String, String> ann) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.calendar_today_rounded, size: 14, color: Colors.grey.shade500),
                  const SizedBox(width: 6),
                  Text(
                    ann['date'] ?? '',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade600),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 18),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () {
                  _confirmDeleteAnnouncement(ann);
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            ann['fullText'] ?? ann['body'] ?? '',
            style: const TextStyle(fontSize: 13, color: Colors.black87, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildModulesContent() {
    final subjectMeetings = context.watch<AppState>().meetings
        .where((m) => m['subject'] == widget.subject.name)
        .toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      children: [
        // Scheduled Meetings Section
        Row(
          children: [
            const Icon(Icons.video_camera_front_rounded, color: AppColors.authPrimary, size: 20),
            const SizedBox(width: 8),
            const Text(
              'Scheduled Meetings',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (subjectMeetings.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade100),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.video_camera_front_outlined, color: Colors.grey.shade400, size: 28),
                const SizedBox(height: 8),
                Text(
                  'No meetings scheduled yet.',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          )
        else
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 200),
            child: Scrollbar(
              controller: _meetingsScrollController,
              thumbVisibility: true,
              child: ListView.builder(
                controller: _meetingsScrollController,
                shrinkWrap: true,
                padding: const EdgeInsets.only(right: 8),
                itemCount: subjectMeetings.length,
                itemBuilder: (ctx, i) {
                  final meet = subjectMeetings[i];
                  return _buildMeetingCard(meet);
                },
              ),
            ),
          ),
        const SizedBox(height: 20),
        const Divider(height: 1),
        const SizedBox(height: 20),
        if (_modules.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Text('No modules yet. Use Create to add module.',
                  style: TextStyle(color: Colors.grey, fontSize: 14)),
            ),
          )
        else
          ..._modules.asMap().entries.map((entry) {
            final i = entry.key;
            final m = entry.value;
            final mQuizzes = _quizzes.where((q) => q.moduleId == m.id).toList();
            final mAssign = _assignments.where((a) => a.moduleId == m.id && !(a.description ?? '').startsWith('[MATERIAL]')).toList();
            final mMaterials = _assignments.where((a) => a.moduleId == m.id && (a.description ?? '').startsWith('[MATERIAL]')).toList();
            return DragTarget<Map<String, dynamic>>(
              onWillAcceptWithDetails: (details) {
                final data = details.data;
                if (data['type'] == 'quiz') {
                  final q = _quizzes.firstWhere((item) => item.id == data['id']);
                  return q.moduleId != m.id;
                } else if (data['type'] == 'assignment') {
                  final a = _assignments.firstWhere((item) => item.id == data['id']);
                  return a.moduleId != m.id;
                } else if (data['type'] == 'material') {
                  if (data['id'] == data['sourceModuleId']) {
                    return data['sourceModuleId'] != m.id;
                  } else {
                    final a = _assignments.firstWhere((item) => item.id == data['id']);
                    return a.moduleId != m.id;
                  }
                }
                return true;
              },
              onAcceptWithDetails: (details) {
                final data = details.data;
                _moveItemToModule(
                  itemType: data['type'].toString(),
                  itemId: data['id'].toString(),
                  targetModuleId: m.id,
                  sourceModuleId: data['sourceModuleId']?.toString(),
                  fileUrl: data['fileUrl']?.toString(),
                  fileName: data['fileName']?.toString(),
                );
              },
              builder: (context, candidateData, rejectedData) {
                final isOver = candidateData.isNotEmpty;
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isOver ? AppColors.authPrimary : Colors.transparent,
                      width: 2,
                    ),
                    color: isOver ? AppColors.authPrimary.withOpacity(0.05) : Colors.transparent,
                  ),
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Module ${i + 1} - ${m.title}',
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87)),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
                            padding: EdgeInsets.zero, constraints: const BoxConstraints(),
                            onPressed: () => _confirmDeleteModule(m),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Legacy module attachment
                      if (m.fileUrl != null)
                        Draggable<Map<String, dynamic>>(
                          data: {
                            'type': 'material',
                            'id': m.id,
                            'sourceModuleId': m.id,
                            'fileUrl': m.fileUrl,
                            'fileName': m.fileName,
                          },
                          feedback: SizedBox(
                            width: MediaQuery.of(context).size.width - 32,
                            child: Material(
                              color: Colors.transparent,
                              child: Opacity(
                                opacity: 0.7,
                                child: _buildContentRow(Icons.menu_book_rounded, m.fileName ?? '${m.title} - Document', 'Material', () {}),
                              ),
                            ),
                          ),
                          childWhenDragging: Opacity(
                            opacity: 0.3,
                            child: _buildContentRow(Icons.menu_book_rounded, m.fileName ?? '${m.title} - Document', 'Material', () {}),
                          ),
                          child: _buildContentRow(
                            Icons.menu_book_rounded,
                            m.fileName ?? '${m.title} - Document',
                            'Material',
                            () => _openUrl(m.fileUrl!),
                            onDelete: () => _confirmDeleteModuleAttachment(m),
                          ),
                        ),
                      // New Materials
                      ...mMaterials.map((mat) => Draggable<Map<String, dynamic>>(
                            data: {
                              'type': 'material',
                              'id': mat.id,
                              'sourceModuleId': m.id,
                              'fileUrl': mat.fileUrl,
                              'fileName': mat.fileName,
                            },
                            feedback: SizedBox(
                              width: MediaQuery.of(context).size.width - 32,
                              child: Material(
                                color: Colors.transparent,
                                child: Opacity(
                                  opacity: 0.7,
                                  child: _buildContentRow(Icons.menu_book_rounded, mat.fileName ?? '${mat.title} - Document', 'Material', () {}, onDelete: () {}),
                                ),
                              ),
                            ),
                            childWhenDragging: Opacity(
                              opacity: 0.3,
                              child: _buildContentRow(Icons.menu_book_rounded, mat.fileName ?? '${mat.title} - Document', 'Material', () {}, onDelete: () {}),
                            ),
                            child: _buildContentRow(
                              Icons.menu_book_rounded,
                              mat.fileName ?? '${mat.title} - Document',
                              'Material',
                              () {
                                if (mat.fileUrl != null) _openUrl(mat.fileUrl!);
                              },
                              onDelete: () => _confirmDeleteAssignment(mat),
                            ),
                          )),
                      // Quizzes
                      ...mQuizzes.map((q) => Draggable<Map<String, dynamic>>(
                            data: {
                              'type': 'quiz',
                              'id': q.id,
                              'sourceModuleId': m.id,
                            },
                            feedback: SizedBox(
                              width: MediaQuery.of(context).size.width - 32,
                              child: Material(
                                color: Colors.transparent,
                                child: Opacity(
                                  opacity: 0.7,
                                  child: _buildContentRow(Icons.edit_rounded, q.title, 'Quiz', () {}, onDelete: () {}),
                                ),
                              ),
                            ),
                            childWhenDragging: Opacity(
                              opacity: 0.3,
                              child: _buildContentRow(Icons.edit_rounded, q.title, 'Quiz', () {}, onDelete: () {}),
                            ),
                            child: _buildContentRow(Icons.edit_rounded, q.title, 'Quiz', () => _showQuizDetailDialog(q), onDelete: () => _confirmDeleteQuiz(q)),
                          )),
                      // Assignments
                      ...mAssign.map((a) => Draggable<Map<String, dynamic>>(
                            data: {
                              'type': 'assignment',
                              'id': a.id,
                              'sourceModuleId': m.id,
                            },
                            feedback: SizedBox(
                              width: MediaQuery.of(context).size.width - 32,
                              child: Material(
                                color: Colors.transparent,
                                child: Opacity(
                                  opacity: 0.7,
                                  child: _buildContentRow(Icons.assignment_rounded, a.title, 'Assignment', () {}, onDelete: () {}),
                                ),
                              ),
                            ),
                            childWhenDragging: Opacity(
                              opacity: 0.3,
                              child: _buildContentRow(Icons.assignment_rounded, a.title, 'Assignment', () {}, onDelete: () {}),
                            ),
                            child: _buildContentRow(
                              Icons.assignment_rounded,
                              a.title,
                              'Assignment',
                              () => Navigator.push(context, MaterialPageRoute(
                                builder: (_) => AssignmentDetailScreen(
                                  assignment: a,
                                  subjectName: widget.subject.name,
                                  totalStudents: widget.subject.studentCount,
                                ),
                              )),
                              onDelete: () => _confirmDeleteAssignment(a),
                            ),
                          )),
                    ],
                  ),
                );
              },
            );
          }),
        // Unlinked quizzes (no moduleId)
        ..._quizzes.where((q) => q.moduleId == null).map((q) => Draggable<Map<String, dynamic>>(
              data: {
                'type': 'quiz',
                'id': q.id,
                'sourceModuleId': null,
              },
              feedback: SizedBox(
                width: MediaQuery.of(context).size.width - 32,
                child: Material(
                  color: Colors.transparent,
                  child: Opacity(
                    opacity: 0.7,
                    child: _buildContentRow(Icons.edit_rounded, q.title, 'Quiz', () {}, onDelete: () {}),
                  ),
                ),
              ),
              childWhenDragging: Opacity(
                opacity: 0.3,
                child: _buildContentRow(Icons.edit_rounded, q.title, 'Quiz', () {}),
              ),
              child: _buildContentRow(Icons.edit_rounded, q.title, 'Quiz', () => _showQuizDetailDialog(q), onDelete: () => _confirmDeleteQuiz(q)),
            )),
        // Unlinked assignments (no moduleId)
        ..._assignments.where((a) => a.moduleId == null && !(a.description ?? '').startsWith('[MATERIAL]')).map((a) => Draggable<Map<String, dynamic>>(
              data: {
                'type': 'assignment',
                'id': a.id,
                'sourceModuleId': null,
              },
              feedback: SizedBox(
                width: MediaQuery.of(context).size.width - 32,
                child: Material(
                  color: Colors.transparent,
                  child: Opacity(
                    opacity: 0.7,
                    child: _buildContentRow(Icons.assignment_rounded, a.title, 'Assignment', () {}, onDelete: () {}),
                  ),
                ),
              ),
              childWhenDragging: Opacity(
                opacity: 0.3,
                child: _buildContentRow(Icons.assignment_rounded, a.title, 'Assignment', () {}),
              ),
              child: _buildContentRow(
                Icons.assignment_rounded,
                a.title,
                'Assignment',
                () => Navigator.push(context, MaterialPageRoute(
                  builder: (_) => AssignmentDetailScreen(
                    assignment: a,
                    subjectName: widget.subject.name,
                    totalStudents: widget.subject.studentCount,
                  ),
                )),
                onDelete: () => _confirmDeleteAssignment(a),
              ),
            )),
        // Unlinked materials (no moduleId)
        ..._assignments.where((a) => a.moduleId == null && (a.description ?? '').startsWith('[MATERIAL]')).map((mat) => Draggable<Map<String, dynamic>>(
              data: {
                'type': 'material',
                'id': mat.id,
                'sourceModuleId': null,
                'fileUrl': mat.fileUrl,
                'fileName': mat.fileName,
              },
              feedback: SizedBox(
                width: MediaQuery.of(context).size.width - 32,
                child: Material(
                  color: Colors.transparent,
                  child: Opacity(
                    opacity: 0.7,
                    child: _buildContentRow(Icons.menu_book_rounded, mat.fileName ?? '${mat.title} - Document', 'Material', () {}, onDelete: () {}),
                  ),
                ),
              ),
              childWhenDragging: Opacity(
                opacity: 0.3,
                child: _buildContentRow(Icons.menu_book_rounded, mat.fileName ?? '${mat.title} - Document', 'Material', () {}),
              ),
              child: _buildContentRow(
                Icons.menu_book_rounded,
                mat.fileName ?? '${mat.title} - Document',
                'Material',
                () {
                  if (mat.fileUrl != null) _openUrl(mat.fileUrl!);
                },
                onDelete: () => _confirmDeleteAssignment(mat),
              ),
            )),
      ],
    );
  }

  Widget _buildContentRow(IconData icon, String title, String type, VoidCallback onTap, {VoidCallback? onDelete}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.authPrimary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 16, color: AppColors.authPrimary),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(title,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.black87))),
            Text(type, style: const TextStyle(fontSize: 11, color: Colors.black38)),
            const SizedBox(width: 4),
            if (onDelete != null) ...[
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red, size: 16),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: onDelete,
              ),
              const SizedBox(width: 4),
            ],
            const Icon(Icons.chevron_right_rounded, size: 16, color: Colors.black26),
          ]),
        ),
      ),
    );
  }

  Widget _buildStudentsContent() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 100),
      children: [
        Row(
          children: [
            const Icon(Icons.analytics_rounded, color: AppColors.authPrimary, size: 20),
            const SizedBox(width: 8),
            const Text(
              'Student Performance Summary',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildPerformanceSummaryCard(),
        const SizedBox(height: 24),
        const Divider(height: 1),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('${_students.length} Student${_students.length == 1 ? '' : 's'} Enrolled',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
          ],
        ),
        const SizedBox(height: 12),
        if (_students.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Text('No students enrolled yet.', style: TextStyle(color: Colors.grey, fontSize: 14)),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _students.length,
            itemBuilder: (_, i) {
              final s = _students[i];
              final initials = (s['name'] ?? '?')[0].toUpperCase();
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  leading: CircleAvatar(
                    backgroundColor: AppColors.authPrimary.withOpacity(0.12),
                    child: Text(initials,
                        style: const TextStyle(color: AppColors.authPrimary, fontWeight: FontWeight.bold)),
                  ),
                  title: Text(s['name'] ?? '',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  subtitle: Text(s['studentNumber'] ?? s['email'] ?? '',
                      style: const TextStyle(fontSize: 12, color: Colors.black45)),
                  trailing: IconButton(
                    icon: const Icon(Icons.person_remove_rounded, size: 18, color: Colors.red),
                    tooltip: 'Unenroll',
                    onPressed: () => _confirmUnenroll(s),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildAnnouncementsContent() {
    final subjectAnnouncements = context.watch<AppState>().announcements
        .where((ann) => ann['subject'] == widget.subject.name)
        .toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      children: [
        Row(
          children: [
            const Icon(Icons.campaign_rounded, color: AppColors.authPrimary, size: 20),
            const SizedBox(width: 8),
            const Text(
              'Announcements Log',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (subjectAnnouncements.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 40),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade100),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.campaign_outlined, color: Colors.grey.shade400, size: 36),
                const SizedBox(height: 8),
                Text(
                  'No announcements posted yet.',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          )
        else
          ...subjectAnnouncements.map((ann) => _buildProfessorAnnouncementCard(ann)),
      ],
    );
  }

  // _buildStudentsTab removed — replaced by _buildStudentsContent above



  void _confirmUnenroll(Map<String, String> student) {
    AppDialog.confirm(
      context,
      title: 'Unenroll Student',
      message: 'Remove ${student['name']} from this subject?',
      type: DialogType.error,
      confirmLabel: 'Remove',
      onConfirm: () async {
        try {
          await _repo.unenrollStudent(widget.subject.id, student['profileId']!);
          await _load();
          if (mounted) AppDialog.result(context, type: DialogType.success, message: 'Student unenrolled.');
        } catch (e) {
          if (mounted) AppDialog.result(context, type: DialogType.error, message: e.toString());
        }
      },
    );
  }

  // Legacy tab methods removed — content now in _buildModulesContent()


  void _openUrl(String url) {
    html.window.open(url, '_blank');
  }

  void _showQuizDetailDialog(SubjectQuiz quiz) async {
    final answerCount = await _repo.fetchQuizAnswerCount(quiz.id);
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: 550,
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.authPrimary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.assignment_turned_in_rounded, color: AppColors.authPrimary, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          quiz.title,
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_rounded, color: Colors.blueAccent),
                    onPressed: () { Navigator.pop(ctx); _showEditQuizDialog(quiz); },
                    tooltip: 'Edit Quiz',
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (quiz.description != null && quiz.description!.isNotEmpty) ...[
                Text(
                  quiz.description!,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13, height: 1.4),
                ),
                const SizedBox(height: 16),
              ],
              Row(
                children: [
                  _chip(Icons.people_rounded, '$answerCount student${answerCount == 1 ? '' : 's'} answered'),
                  const SizedBox(width: 8),
                  if (quiz.deadline != null)
                    _chip(Icons.schedule_rounded, 'Due ${quiz.deadline!.day}/${quiz.deadline!.month}/${quiz.deadline!.year}'),
                ],
              ),
              const SizedBox(height: 20),
              const Text(
                'Questions',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: quiz.questions.asMap().entries.map((e) {
                      final q = e.value;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Q${e.key + 1}: ${q.question}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
                            ),
                            const SizedBox(height: 12),
                            ...q.options.map((opt) {
                              final isCorrect = opt == q.correctAnswer;
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  children: [
                                    Icon(
                                      isCorrect ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                                      size: 18,
                                      color: isCorrect ? Colors.green : Colors.grey.shade400,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        opt,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: isCorrect ? Colors.green.shade800 : Colors.black87,
                                          fontWeight: isCorrect ? FontWeight.bold : FontWeight.normal,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey.shade600,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Close', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditQuizDialog(SubjectQuiz quiz) {
    final titleCtrl = TextEditingController(text: quiz.title);
    final descCtrl = TextEditingController(text: quiz.description ?? '');
    DateTime? deadline = quiz.deadline;
    String? selectedModuleId = quiz.moduleId;
    final questions = quiz.questions.map((q) => <String, dynamic>{
      'question': q.question,
      'options': List<String>.from(q.options),
      'correct_answer': q.correctAnswer,
    }).toList();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            width: 600,
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.authPrimary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.edit_rounded, color: AppColors.authPrimary, size: 24),
                    ),
                    const SizedBox(width: 14),
                    const Text(
                      'Edit Quiz Details',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: titleCtrl,
                          decoration: InputDecoration(
                            labelText: 'Quiz Title',
                            labelStyle: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w500),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade200, width: 1.5),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppColors.authPrimary, width: 2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: descCtrl,
                          maxLines: 2,
                          decoration: InputDecoration(
                            labelText: 'Description (optional)',
                            labelStyle: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w500),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade200, width: 1.5),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppColors.authPrimary, width: 2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Module picker
                        if (_modules.isEmpty) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.amber.shade200),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.warning_amber_rounded, color: Colors.amber.shade800),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'No modules found. You must create a module first.',
                                    style: TextStyle(color: Colors.amber.shade900, fontSize: 13, fontWeight: FontWeight.w500),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ] else ...[
                          DropdownButtonFormField<String>(
                            value: selectedModuleId,
                            decoration: InputDecoration(
                              labelText: 'Module',
                              labelStyle: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w500),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey.shade200, width: 1.5),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: AppColors.authPrimary, width: 2),
                              ),
                            ),
                            items: _modules.map((m) => DropdownMenuItem(value: m.id, child: Text(m.title))).toList(),
                            onChanged: (v) => setS(() => selectedModuleId = v),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Deadline
                        const Text(
                          'Deadline',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87),
                        ),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: ctx,
                              initialDate: deadline ?? DateTime.now().add(const Duration(days: 7)),
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(const Duration(days: 365)),
                            );
                            if (picked != null) setS(() => deadline = picked);
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade200, width: 1.5),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today_rounded, size: 18, color: AppColors.authPrimary),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        deadline == null ? 'No deadline set' : '${deadline!.day}/${deadline!.month}/${deadline!.year}',
                                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.arrow_drop_down, color: Colors.black54),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Questions header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Text('Questions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87)),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.authPrimary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '${questions.length}',
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.authPrimary),
                                  ),
                                ),
                              ],
                            ),
                            TextButton.icon(
                              onPressed: () => setS(() => questions.add({'question': '', 'options': ['', '', '', ''], 'correct_answer': ''})),
                              icon: const Icon(Icons.add_circle_outline, size: 18),
                              label: const Text('Add Question', style: TextStyle(fontWeight: FontWeight.bold)),
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.authPrimary,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (questions.isEmpty)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Column(
                              children: [
                                Icon(Icons.quiz_outlined, size: 36, color: Colors.grey.shade400),
                                const SizedBox(height: 8),
                                Text(
                                  'No questions added yet.',
                                  style: TextStyle(color: Colors.grey.shade500, fontSize: 13, fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          )
                        else
                          ...questions.asMap().entries.map((e) => _QuestionTile(
                            index: e.key,
                            data: e.value,
                            onDelete: () => setS(() => questions.removeAt(e.key)),
                            onChanged: (updated) => setS(() => questions[e.key] = updated),
                          )),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.grey.shade600,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () async {
                        if (titleCtrl.text.trim().isEmpty) {
                          AppDialog.result(ctx, type: DialogType.error, message: 'Please enter a quiz title.');
                          return;
                        }
                        if (selectedModuleId == null) {
                          AppDialog.result(ctx, type: DialogType.error, message: 'Please select a module. Assigning to a module is required.');
                          return;
                        }
                        Navigator.pop(ctx);
                        try {
                          await _repo.updateQuiz(
                            quizId: quiz.id,
                            title: titleCtrl.text,
                            description: descCtrl.text,
                            deadline: deadline,
                            moduleId: selectedModuleId,
                            questions: questions,
                          );
                          await _load();
                          if (mounted) AppDialog.result(context, type: DialogType.success, message: 'Quiz updated.');
                        } catch (e) {
                          if (mounted) AppDialog.result(context, type: DialogType.error, message: e.toString());
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.authPrimary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _chip(IconData icon, String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.black12)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 12, color: Colors.black54),
      const SizedBox(width: 4),
      Text(label, style: const TextStyle(fontSize: 11, color: Colors.black54)),
    ]),
  );

  Widget _empty(String msg) => Center(child: Text(msg, style: const TextStyle(color: Colors.grey, fontSize: 14)));

  Future<void> _moveItemToModule({
    required String itemType,
    required String itemId,
    required String targetModuleId,
    String? sourceModuleId,
    String? fileUrl,
    String? fileName,
  }) async {
    setState(() => _loading = true);
    try {
      final client = Supabase.instance.client;
      if (itemType == 'quiz') {
        await client.from('quizzes').update({'module_id': targetModuleId}).eq('id', itemId);
      } else if (itemType == 'assignment') {
        await client.from('assignments').update({'module_id': targetModuleId}).eq('id', itemId);
      } else if (itemType == 'material') {
        if (fileUrl != null && sourceModuleId != null) {
          await client.from('modules').update({
            'file_url': fileUrl,
            'file_name': fileName,
          }).eq('id', targetModuleId);
          await client.from('modules').update({
            'file_url': null,
            'file_name': null,
          }).eq('id', sourceModuleId);
        }
      }
      if (mounted) {
        AppDialog.result(context, type: DialogType.success, message: 'Item moved successfully!');
      }
    } catch (e) {
      if (mounted) {
        AppDialog.result(context, type: DialogType.error, message: 'Failed to move item: $e');
      }
    } finally {
      _load();
    }
  }

  // Internal floating nav removed — replaced by global ProfessorFloatingNavBar

  Widget _buildMeetingCard(Map<String, dynamic> meet) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200, width: 1.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  meet['title'] ?? '',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded, size: 12, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      '${meet['date']} at ${meet['time']}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(width: 12),
                    const Icon(Icons.link_rounded, size: 12, color: Colors.blue),
                    const SizedBox(width: 4),
                    Text(
                      meet['platform'] ?? '',
                      style: const TextStyle(fontSize: 12, color: Colors.blue, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 18),
            onPressed: () {
              AppDialog.confirm(
                context,
                title: 'Delete Meeting',
                message: 'Are you sure you want to delete this meeting?',
                type: DialogType.error,
                onConfirm: () async {
                  context.read<AppState>().deleteMeeting(meet['id']);
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceSummaryCard() {
    if (_students.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200, width: 1.5),
        ),
        child: const Text(
          'No student data available to calculate performance summary.',
          style: TextStyle(color: Colors.grey, fontSize: 13, fontStyle: FontStyle.italic),
          textAlign: TextAlign.center,
        ),
      );
    }

    // Assign mock grades dynamically
    final List<double> grades = [];
    for (int i = 0; i < _students.length; i++) {
      final grade = 78.0 + ((i * 7) % 21);
      grades.add(grade);
    }

    final double avg = grades.reduce((a, b) => a + b) / grades.length;
    final double maxGrade = grades.reduce((a, b) => a > b ? a : b);

    final passingCount = grades.where((g) => g >= 75).length;
    final passingPercentage = (passingCount / grades.length * 100).round();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatMetric('Class Average', '${avg.toStringAsFixed(1)}%'),
              _buildStatMetric('Passing Rate', '$passingPercentage%'),
              _buildStatMetric('Highest Grade', '${maxGrade.toStringAsFixed(1)}%'),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 12),
          const Text(
            'Student Grades Breakdown',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black54),
          ),
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 120),
            child: Scrollbar(
              controller: _gradesScrollController,
              thumbVisibility: true,
              child: ListView.builder(
                controller: _gradesScrollController,
                shrinkWrap: true,
                itemCount: _students.length,
                itemBuilder: (ctx, i) {
                  final s = _students[i];
                  final grade = grades[i];
                  final isPassing = grade >= 75;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            s['name'] ?? '',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.black87),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Row(
                          children: [
                            Text(
                              '${grade.toStringAsFixed(1)}%',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: isPassing ? Colors.green.shade700 : Colors.red.shade700,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: isPassing ? Colors.green.shade50 : Colors.red.shade50,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                isPassing ? 'PASSED' : 'FAILED',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: isPassing ? Colors.green.shade700 : Colors.red.shade700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatMetric(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.authPrimary),
        ),
      ],
    );
  }

  void _showScheduleMeetingDialog() {
    final titleCtrl = TextEditingController();
    final platformCtrl = TextEditingController(text: 'Google Meet');
    final linkCtrl = TextEditingController();
    DateTime meetingDate = DateTime.now();
    TimeOfDay meetingTime = TimeOfDay.now();

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setS) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            'Schedule Class Meeting',
            style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.authPrimary),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Meeting Title', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 6),
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(
                    hintText: 'e.g., Weekly Consultation',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                ),
                const SizedBox(height: 12),
                const Text('Platform / Location', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 6),
                TextField(
                  controller: platformCtrl,
                  decoration: const InputDecoration(
                    hintText: 'e.g., Google Meet, Room 402',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                ),
                const SizedBox(height: 12),
                const Text('Meeting Link (Optional)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 6),
                TextField(
                  controller: linkCtrl,
                  decoration: const InputDecoration(
                    hintText: 'e.g., meet.google.com/xxx-xxxx-xxx',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Date', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black54)),
                        const SizedBox(height: 4),
                        OutlinedButton(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: meetingDate,
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(const Duration(days: 365)),
                            );
                            if (picked != null) {
                              setS(() => meetingDate = picked);
                            }
                          },
                          child: Text('${meetingDate.month}/${meetingDate.day}/${meetingDate.year}'),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Time', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black54)),
                        const SizedBox(height: 4),
                        OutlinedButton(
                          onPressed: () async {
                            final picked = await showTimePicker(
                              context: context,
                              initialTime: meetingTime,
                            );
                            if (picked != null) {
                              setS(() => meetingTime = picked);
                            }
                          },
                          child: Text(meetingTime.format(context)),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (titleCtrl.text.trim().isEmpty) {
                  AppDialog.result(context, type: DialogType.error, message: 'Please enter a meeting title.');
                  return;
                }
                final dateStr = '${meetingDate.year}-${meetingDate.month.toString().padLeft(2, '0')}-${meetingDate.day.toString().padLeft(2, '0')}';
                final timeStr = meetingTime.format(context);

                context.read<AppState>().addMeeting(
                  subject: widget.subject.name,
                  title: titleCtrl.text.trim(),
                  platform: platformCtrl.text.trim(),
                  link: linkCtrl.text.trim(),
                  date: dateStr,
                  time: timeStr,
                );

                Navigator.pop(dialogCtx);
                AppDialog.result(context, type: DialogType.success, message: 'Meeting scheduled successfully!');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.authPrimary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Schedule'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Question tile widget ──────────────────────────────────────────────────────

class _QuestionTile extends StatefulWidget {
  final int index;
  final Map<String, dynamic> data;
  final VoidCallback onDelete;
  final ValueChanged<Map<String, dynamic>> onChanged;

  const _QuestionTile({required this.index, required this.data, required this.onDelete, required this.onChanged});

  @override
  State<_QuestionTile> createState() => _QuestionTileState();
}

class _QuestionTileState extends State<_QuestionTile> {
  late final TextEditingController _qCtrl;
  late final List<TextEditingController> _optCtrls;
  late String _correct;

  @override
  void initState() {
    super.initState();
    _qCtrl = TextEditingController(text: widget.data['question'] as String? ?? '');
    final opts = List<String>.from(widget.data['options'] as List? ?? ['', '', '', '']);
    _optCtrls = opts.map((o) => TextEditingController(text: o)).toList();
    _correct = widget.data['correct_answer'] as String? ?? '';
  }

  @override
  void dispose() {
    _qCtrl.dispose();
    for (final c in _optCtrls) c.dispose();
    super.dispose();
  }

  void _notify() {
    widget.onChanged({
      'question': _qCtrl.text,
      'options': _optCtrls.map((c) => c.text).toList(),
      'correct_answer': _correct,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.authPrimary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Question ${widget.index + 1}',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.authPrimary, fontSize: 12),
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, size: 20, color: Colors.redAccent),
                onPressed: widget.onDelete,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                tooltip: 'Delete Question',
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _qCtrl,
            onChanged: (_) => _notify(),
            decoration: InputDecoration(
              hintText: 'Enter question text...',
              hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
              filled: true,
              fillColor: Colors.grey.shade50,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade200, width: 1.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.authPrimary, width: 2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Options & Correct Answer',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54),
          ),
          const SizedBox(height: 8),
          ...List.generate(_optCtrls.length, (i) {
            final isCorrect = _correct.isNotEmpty && _correct == _optCtrls[i].text;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: isCorrect ? Colors.green.withOpacity(0.04) : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isCorrect ? Colors.green.withOpacity(0.3) : Colors.transparent,
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Radio<String>(
                    value: _optCtrls[i].text,
                    groupValue: _correct,
                    onChanged: (v) => setState(() {
                      _correct = v ?? '';
                      _notify();
                    }),
                    activeColor: Colors.green,
                  ),
                  Expanded(
                    child: TextField(
                      controller: _optCtrls[i],
                      onChanged: (val) {
                        if (isCorrect) {
                          _correct = val;
                        }
                        _notify();
                      },
                      decoration: InputDecoration(
                        hintText: 'Option ${i + 1}',
                        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                        isDense: true,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                      ),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isCorrect ? FontWeight.bold : FontWeight.normal,
                        color: isCorrect ? Colors.green.shade800 : Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
