import 'dart:html' as html;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../data/repositories/professor_repository.dart';
import '../../domain/models/professor_subject.dart';
import 'assignment_detail_screen.dart';

class ProfessorSubjectScreen extends StatefulWidget {
  final ProfessorSubject subject;
  const ProfessorSubjectScreen({super.key, required this.subject});

  @override
  State<ProfessorSubjectScreen> createState() => _ProfessorSubjectScreenState();
}

class _ProfessorSubjectScreenState extends State<ProfessorSubjectScreen> {
  final _repo = const ProfessorRepository();
  int _currentIndex = 0;
  int? _hoveredNavIdx;

  List<SubjectModule> _modules = [];
  List<SubjectQuiz> _quizzes = [];
  List<SubjectAssignment> _assignments = [];
  List<Map<String, String>> _students = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final modules = await _repo.fetchModules(widget.subject.id);
      final quizzes = await _repo.fetchQuizzes(widget.subject.id);
      final assignments = await _repo.fetchAssignments(widget.subject.id);
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
    String? fileUrl;
    String? fileName;
    bool uploading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text('Add Module'),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Title')),
              TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Description (optional)')),
              const SizedBox(height: 16),
              Row(children: [
                ElevatedButton.icon(
                  onPressed: uploading ? null : () async {
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
                      final url = await _repo.uploadModuleFile(widget.subject.id, file.name, file.bytes!);
                      setS(() { fileUrl = url; fileName = file.name; uploading = false; });
                    } catch (e) {
                      setS(() => uploading = false);
                      if (ctx.mounted) AppDialog.result(ctx, type: DialogType.error, message: 'Upload failed: $e');
                    }
                  },
                  icon: uploading
                      ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.picture_as_pdf, size: 16),
                  label: Text(uploading ? 'Uploading...' : 'Attach PDF'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700, foregroundColor: Colors.white),
                ),
                const SizedBox(width: 8),
                if (fileName != null)
                  Expanded(child: Text(fileName!, style: const TextStyle(fontSize: 12, color: Colors.black54), overflow: TextOverflow.ellipsis)),
              ]),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: uploading ? null : () async {
                if (titleCtrl.text.trim().isEmpty) return;
                Navigator.pop(ctx);
                try {
                  await _repo.createModule(
                    widget.subject.id,
                    titleCtrl.text,
                    descCtrl.text,
                    fileUrl: fileUrl,
                    fileName: fileName,
                  );
                  await _load();
                  if (mounted) AppDialog.result(context, type: DialogType.success, message: 'Module added.');
                } catch (e) {
                  if (mounted) AppDialog.result(context, type: DialogType.error, message: e.toString());
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteModule(SubjectModule module) {
    AppDialog.confirm(context,
      title: 'Delete Module',
      message: 'Delete "${module.title}"? This cannot be undone.',
      type: DialogType.error,
      confirmLabel: 'Delete',
      onConfirm: () async {
        try {
          await _repo.deleteModule(module.id);
          await _load();
          if (mounted) AppDialog.result(context, type: DialogType.success, message: 'Module deleted.');
        } catch (e) {
          if (mounted) AppDialog.result(context, type: DialogType.error, message: e.toString());
        }
      },
    );
  }

  // ── Quizzes ───────────────────────────────────────────────────────────────

  void _showAddQuizDialog() {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    DateTime? deadline;
    String? selectedModuleId;
    final questions = <Map<String, dynamic>>[];

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text('Create Quiz'),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Quiz Title')),
                TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Description (optional)')),
                const SizedBox(height: 12),

                // Module picker
                if (_modules.isNotEmpty) ...[
                  DropdownButtonFormField<String>(
                    value: selectedModuleId,
                    decoration: const InputDecoration(labelText: 'Assign to Module (optional)'),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('None')),
                      ..._modules.map((m) => DropdownMenuItem(value: m.id, child: Text(m.title))),
                    ],
                    onChanged: (v) => setS(() => selectedModuleId = v),
                  ),
                  const SizedBox(height: 12),
                ],

                // Deadline
                Row(children: [
                  const Text('Deadline: ', style: TextStyle(fontSize: 13)),
                  TextButton(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate: DateTime.now().add(const Duration(days: 7)),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) setS(() => deadline = picked);
                    },
                    child: Text(deadline == null ? 'Pick date' : '${deadline!.day}/${deadline!.month}/${deadline!.year}',
                        style: TextStyle(color: AppColors.authPrimary)),
                  ),
                ]),
                const SizedBox(height: 12),

                // Questions
                const Text('Questions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 8),
                ...questions.asMap().entries.map((e) => _QuestionTile(
                  index: e.key,
                  data: e.value,
                  onDelete: () => setS(() => questions.removeAt(e.key)),
                  onChanged: (updated) => setS(() => questions[e.key] = updated),
                )),
                TextButton.icon(
                  onPressed: () => setS(() => questions.add({'question': '', 'options': ['', '', '', ''], 'correct_answer': ''})),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Question'),
                ),
              ]),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (titleCtrl.text.trim().isEmpty) return;
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
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteQuiz(SubjectQuiz quiz) {
    AppDialog.confirm(context,
      title: 'Delete Quiz',
      message: 'Delete "${quiz.title}"?',
      type: DialogType.error,
      confirmLabel: 'Delete',
      onConfirm: () async {
        try {
          await _repo.deleteQuiz(quiz.id);
          await _load();
          if (mounted) AppDialog.result(context, type: DialogType.success, message: 'Quiz deleted.');
        } catch (e) {
          if (mounted) AppDialog.result(context, type: DialogType.error, message: e.toString());
        }
      },
    );
  }

  // ── Assignments ───────────────────────────────────────────────────────────

  void _showAddAssignmentDialog() {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    DateTime? deadline;
    String? selectedModuleId;
    String? fileUrl;
    String? fileName;
    bool uploading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text('Create Assignment'),
          content: SizedBox(
            width: 400,
            child: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Title')),
                TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Description (optional)')),
                const SizedBox(height: 12),

                if (_modules.isNotEmpty)
                  DropdownButtonFormField<String>(
                    value: selectedModuleId,
                    decoration: const InputDecoration(labelText: 'Assign to Module (optional)'),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('None')),
                      ..._modules.map((m) => DropdownMenuItem(value: m.id, child: Text(m.title))),
                    ],
                    onChanged: (v) => setS(() => selectedModuleId = v),
                  ),

                const SizedBox(height: 12),
                Row(children: [
                  const Text('Deadline: ', style: TextStyle(fontSize: 13)),
                  TextButton(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate: DateTime.now().add(const Duration(days: 7)),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) setS(() => deadline = picked);
                    },
                    child: Text(deadline == null ? 'Pick date' : '${deadline!.day}/${deadline!.month}/${deadline!.year}',
                        style: TextStyle(color: AppColors.authPrimary)),
                  ),
                ]),
                const SizedBox(height: 8),

                // File picker
                Row(children: [
                  ElevatedButton.icon(
                    onPressed: uploading ? null : () async {
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
                    icon: uploading ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.attach_file, size: 16),
                    label: Text(uploading ? 'Uploading...' : 'Attach File'),
                  ),
                  const SizedBox(width: 8),
                  if (fileName != null)
                    Expanded(child: Text(fileName!, style: const TextStyle(fontSize: 12, color: Colors.black54), overflow: TextOverflow.ellipsis)),
                ]),
              ]),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: uploading ? null : () async {
                if (titleCtrl.text.trim().isEmpty) return;
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
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteAssignment(SubjectAssignment a) {
    AppDialog.confirm(context,
      title: 'Delete Assignment',
      message: 'Delete "${a.title}"?',
      type: DialogType.error,
      confirmLabel: 'Delete',
      onConfirm: () async {
        try {
          await _repo.deleteAssignment(a.id);
          await _load();
          if (mounted) AppDialog.result(context, type: DialogType.success, message: 'Assignment deleted.');
        } catch (e) {
          if (mounted) AppDialog.result(context, type: DialogType.error, message: e.toString());
        }
      },
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: AppColors.authPrimary,
        elevation: 0,
        toolbarHeight: 70,
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(widget.subject.name, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          Text('${widget.subject.courseCode} • Yr ${widget.subject.yearLevel} Sec ${widget.subject.section} • ${widget.subject.studentCount} students',
              style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ]),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          _loading
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                  padding: const EdgeInsets.only(bottom: 90),
                  child: IndexedStack(
                    index: _currentIndex,
                    children: [
                      _buildModulesTab(),
                      _buildQuizzesTab(),
                      _buildAssignmentsTab(),
                      _buildStudentsTab(),
                    ],
                  ),
                ),
          if (!_loading) _buildFloatingNavBar(),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 85),
        child: FloatingActionButton(
          backgroundColor: AppColors.authPrimary,
          onPressed: () {
            switch (_currentIndex) {
              case 0: _showAddModuleDialog(); break;
              case 1: _showAddQuizDialog(); break;
              case 2: _showAddAssignmentDialog(); break;
              case 3: _showEnrollStudentDialog(); break;
            }
          },
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildStudentsTab() {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Text('${_students.length} student${_students.length == 1 ? '' : 's'} enrolled',
                style: const TextStyle(fontSize: 13, color: Colors.black54)),
          ),
          if (_students.isEmpty)
            const Expanded(child: Center(child: Text('No students enrolled yet.', style: TextStyle(color: Colors.grey, fontSize: 14))))
          else ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: const Color(0xFFF4F4F4),
              child: const Row(children: [
                Expanded(child: Text('Name', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                Expanded(child: Text('Email', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                SizedBox(width: 40),
              ]),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _students.length,
                itemBuilder: (_, i) {
                  final s = _students[i];
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade100))),
                    child: Row(children: [
                      Expanded(child: Text(s['name'] ?? '', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
                      Expanded(child: Text(s['email'] ?? '', style: const TextStyle(fontSize: 12, color: Colors.black54))),
                      SizedBox(
                        width: 40,
                        child: IconButton(
                          icon: const Icon(Icons.person_remove, size: 16, color: Colors.red),
                          tooltip: 'Unenroll',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () => _confirmUnenroll(s),
                        ),
                      ),
                    ]),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showEnrollStudentDialog() {
    final searchCtrl = TextEditingController();
    List<Map<String, String>> results = [];
    bool searching = false;
    final enrolledIds = _students.map((s) => s['profileId'] ?? '').toSet();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text('Enroll Student'),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: searchCtrl,
                  decoration: InputDecoration(
                    hintText: 'Search by student number...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: searching
                        ? const Padding(padding: EdgeInsets.all(12), child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)))
                        : null,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onChanged: (val) async {
                    if (val.trim().length < 2) {
                      setS(() => results = []);
                      return;
                    }
                    setS(() => searching = true);
                    final found = await _repo.searchStudents(val);
                    setS(() { results = found; searching = false; });
                  },
                ),
                const SizedBox(height: 12),
                if (results.isNotEmpty)
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 300),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: results.length,
                      itemBuilder: (_, i) {
                        final s = results[i];
                        final alreadyEnrolled = enrolledIds.contains(s['profileId']);
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppColors.authPrimary.withOpacity(0.1),
                            child: Text(s['name']![0], style: TextStyle(color: AppColors.authPrimary, fontWeight: FontWeight.bold)),
                          ),
                          title: Text(s['name'] ?? ''),
                          subtitle: Text('${s['studentNumber']} • ${s['course']} ${s['yearSection']}'),
                          trailing: alreadyEnrolled
                              ? const Chip(label: Text('Enrolled', style: TextStyle(fontSize: 11)), backgroundColor: Color(0xFFD4EDDA))
                              : ElevatedButton(
                                  onPressed: () async {
                                    try {
                                      await _repo.enrollStudent(widget.subject.id, s['profileId']!);
                                      enrolledIds.add(s['profileId']!);
                                      setS(() {});
                                      await _load();
                                      if (ctx.mounted) AppDialog.result(ctx, type: DialogType.success, message: '${s['name']} enrolled successfully.');
                                    } catch (e) {
                                      if (ctx.mounted) AppDialog.result(ctx, type: DialogType.error, message: e.toString());
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.authPrimary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 12)),
                                  child: const Text('Enroll'),
                                ),
                        );
                      },
                    ),
                  )
                else if (searchCtrl.text.length >= 2 && !searching)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('No students found.', style: TextStyle(color: Colors.grey)),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
          ],
        ),
      ),
    );
  }

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

  Widget _buildModulesTab() {
    if (_modules.isEmpty) return _empty('No modules yet. Tap + to add one.');
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _modules.length,
      itemBuilder: (_, i) {
        final m = _modules[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: const BorderSide(color: Colors.black12),
          ),
          child: ExpansionTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.authPrimary.withOpacity(0.1),
              child: Text('${i + 1}', style: TextStyle(color: AppColors.authPrimary, fontWeight: FontWeight.bold)),
            ),
            title: Text(m.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                  onPressed: () => _confirmDeleteModule(m),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.expand_more),
              ],
            ),
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            expandedCrossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (m.description != null && m.description!.isNotEmpty) ...[
                Text(m.description!, style: const TextStyle(fontSize: 13, color: Colors.black54, height: 1.5)),
                const SizedBox(height: 12),
              ],
              if (m.fileUrl != null) ...[
                const Divider(),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () => _openUrl(m.fileUrl!),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(children: [
                      const Icon(Icons.picture_as_pdf, color: Colors.red, size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          m.fileName ?? 'Download PDF',
                          style: const TextStyle(fontSize: 13, color: Colors.red, fontWeight: FontWeight.w500),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Icon(Icons.download, color: Colors.red, size: 18),
                    ]),
                  ),
                ),
              ] else if (m.description == null || m.description!.isEmpty)
                const Text('No description provided.', style: TextStyle(fontSize: 13, color: Colors.black38, fontStyle: FontStyle.italic)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuizzesTab() {
    if (_quizzes.isEmpty) return _empty('No quizzes yet. Tap + to create one.');
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _quizzes.length,
      itemBuilder: (_, i) {
        final q = _quizzes[i];
        final module = _modules.where((m) => m.id == q.moduleId).firstOrNull;
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: const BorderSide(color: Colors.black12)),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => _showQuizDetailDialog(q),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(child: Text(q.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
                  IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20), onPressed: () => _confirmDeleteQuiz(q), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
                ]),
                if (q.description != null) Text(q.description!, style: const TextStyle(fontSize: 13, color: Colors.black54)),
                const SizedBox(height: 6),
                Wrap(spacing: 8, children: [
                  _chip(Icons.help_outline, '${q.questions.length} questions'),
                  if (q.deadline != null) _chip(Icons.schedule, 'Due ${q.deadline!.day}/${q.deadline!.month}/${q.deadline!.year}'),
                  if (module != null) _chip(Icons.folder_open, module.title),
                ]),
              ]),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAssignmentsTab() {
    if (_assignments.isEmpty) return _empty('No assignments yet. Tap + to create one.');
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _assignments.length,
      itemBuilder: (_, i) {
        final a = _assignments[i];
        final module = _modules.where((m) => m.id == a.moduleId).firstOrNull;
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: const BorderSide(color: Colors.black12)),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => AssignmentDetailScreen(
                assignment: a,
                subjectName: widget.subject.name,
                totalStudents: widget.subject.studentCount,
              )),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(child: Text(a.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
                  IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20), onPressed: () => _confirmDeleteAssignment(a), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
                ]),
                if (a.description != null) Text(a.description!, style: const TextStyle(fontSize: 13, color: Colors.black54), maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 6),
                Wrap(spacing: 8, runSpacing: 4, children: [
                  if (a.deadline != null) _chip(Icons.schedule, 'Due ${a.deadline!.day}/${a.deadline!.month}/${a.deadline!.year}'),
                  if (a.fileName != null) _chip(Icons.attach_file, a.fileName!),
                  if (module != null) _chip(Icons.folder_open, module.title),
                  _chip(Icons.touch_app, 'Tap to view submissions'),
                ]),
              ]),
            ),
          ),
        );
      },
    );
  }

  void _openUrl(String url) {
    html.window.open(url, '_blank');
  }

  void _showQuizDetailDialog(SubjectQuiz quiz) async {
    final answerCount = await _repo.fetchQuizAnswerCount(quiz.id);
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(children: [
          Expanded(child: Text(quiz.title)),
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.blue),
            onPressed: () { Navigator.pop(ctx); _showEditQuizDialog(quiz); },
            tooltip: 'Edit',
          ),
        ]),
        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              if (quiz.description != null) Text(quiz.description!, style: const TextStyle(color: Colors.black54)),
              const SizedBox(height: 8),
              Row(children: [
                _chip(Icons.people, '$answerCount student${answerCount == 1 ? '' : 's'} answered'),
                const SizedBox(width: 8),
                if (quiz.deadline != null) _chip(Icons.schedule, 'Due ${quiz.deadline!.day}/${quiz.deadline!.month}/${quiz.deadline!.year}'),
              ]),
              const SizedBox(height: 16),
              const Text('Questions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 8),
              ...quiz.questions.asMap().entries.map((e) {
                final q = e.value;
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.black12)),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Q${e.key + 1}: ${q.question}', style: const TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    ...q.options.map((opt) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(children: [
                        Icon(
                          opt == q.correctAnswer ? Icons.check_circle : Icons.radio_button_unchecked,
                          size: 16,
                          color: opt == q.correctAnswer ? Colors.green : Colors.black38,
                        ),
                        const SizedBox(width: 6),
                        Text(opt, style: TextStyle(
                          fontSize: 13,
                          color: opt == q.correctAnswer ? Colors.green.shade700 : Colors.black87,
                          fontWeight: opt == q.correctAnswer ? FontWeight.bold : FontWeight.normal,
                        )),
                      ]),
                    )),
                  ]),
                );
              }),
            ]),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
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
        builder: (ctx, setS) => AlertDialog(
          title: const Text('Edit Quiz'),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Quiz Title')),
                TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Description (optional)')),
                const SizedBox(height: 12),
                if (_modules.isNotEmpty)
                  DropdownButtonFormField<String>(
                    value: selectedModuleId,
                    decoration: const InputDecoration(labelText: 'Module (optional)'),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('None')),
                      ..._modules.map((m) => DropdownMenuItem(value: m.id, child: Text(m.title))),
                    ],
                    onChanged: (v) => setS(() => selectedModuleId = v),
                  ),
                const SizedBox(height: 8),
                Row(children: [
                  const Text('Deadline: ', style: TextStyle(fontSize: 13)),
                  TextButton(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate: deadline ?? DateTime.now().add(const Duration(days: 7)),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) setS(() => deadline = picked);
                    },
                    child: Text(deadline == null ? 'Pick date' : '${deadline!.day}/${deadline!.month}/${deadline!.year}',
                        style: TextStyle(color: AppColors.authPrimary)),
                  ),
                ]),
                const SizedBox(height: 8),
                const Text('Questions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 8),
                ...questions.asMap().entries.map((e) => _QuestionTile(
                  index: e.key,
                  data: e.value,
                  onDelete: () => setS(() => questions.removeAt(e.key)),
                  onChanged: (updated) => setS(() => questions[e.key] = updated),
                )),
                TextButton.icon(
                  onPressed: () => setS(() => questions.add({'question': '', 'options': ['', '', '', ''], 'correct_answer': ''})),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Question'),
                ),
              ]),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (titleCtrl.text.trim().isEmpty) return;
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
              child: const Text('Save'),
            ),
          ],
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

  Widget _buildFloatingNavBar() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width > 800 ? 600 : MediaQuery.of(context).size.width - 20,
          ),
          child: Container(
            height: 70,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: AppColors.authPrimary,
              borderRadius: BorderRadius.circular(35),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildFloatingNavItem(Icons.folder_open_rounded, 'MODULES', 0),
                _buildFloatingNavItem(Icons.quiz_rounded, 'QUIZZES', 1),
                _buildFloatingNavItem(Icons.assignment_rounded, 'ASSIGNMENTS', 2),
                _buildFloatingNavItem(Icons.people_rounded, 'STUDENTS', 3),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingNavItem(IconData icon, String label, int index) {
    final bool isHovered = _hoveredNavIdx == index;
    final bool isActive = _currentIndex == index;

    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredNavIdx = index),
      onExit: (_) => setState(() => _hoveredNavIdx = null),
      child: GestureDetector(
        onTap: () => setState(() => _currentIndex = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isActive 
                ? Colors.white.withOpacity(0.15) 
                : (isHovered ? Colors.white.withOpacity(0.08) : Colors.transparent),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 22),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: (isHovered || isActive) ? FontWeight.bold : FontWeight.normal,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
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
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.black12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text('Q${widget.index + 1}', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.authPrimary)),
          const Spacer(),
          IconButton(icon: const Icon(Icons.close, size: 16), onPressed: widget.onDelete, padding: EdgeInsets.zero, constraints: const BoxConstraints()),
        ]),
        TextField(
          controller: _qCtrl,
          onChanged: (_) => _notify(),
          decoration: const InputDecoration(hintText: 'Question', isDense: true, border: UnderlineInputBorder()),
        ),
        const SizedBox(height: 8),
        ...List.generate(_optCtrls.length, (i) => Row(children: [
          Radio<String>(
            value: _optCtrls[i].text,
            groupValue: _correct,
            onChanged: (v) => setState(() { _correct = v ?? ''; _notify(); }),
            activeColor: AppColors.authPrimary,
          ),
          Expanded(child: TextField(
            controller: _optCtrls[i],
            onChanged: (_) => _notify(),
            decoration: InputDecoration(hintText: 'Option ${i + 1}', isDense: true, border: const UnderlineInputBorder()),
            style: const TextStyle(fontSize: 13),
          )),
        ])),
        const SizedBox(height: 4),
        Text('Select the correct answer above', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
      ]),
    );
  }
}
