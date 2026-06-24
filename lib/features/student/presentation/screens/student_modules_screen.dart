import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:web/web.dart' as web;

import '../../../../core/state/app_state.dart';
import '../../../../core/utils/upper_case_text_formatter.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../data/repositories/student_repository.dart';
import '../../domain/models/student_subject.dart';
import '../../../professor/domain/models/professor_subject.dart';
import '../widgets/student_floating_nav_bar.dart';
import 'student_assignment_detail_screen.dart';
import 'student_attendance_screen.dart';
import 'student_grades_screen.dart';
import 'student_quiz_screen.dart';

class StudentModulesScreen extends StatefulWidget {
  final String? subjectId;
  const StudentModulesScreen({super.key, this.subjectId});

  @override
  State<StudentModulesScreen> createState() => _StudentModulesScreenState();
}

class _StudentModulesScreenState extends State<StudentModulesScreen> {
  final StudentRepository _repo = const StudentRepository();
  bool _loading = true;
  List<StudentSubject> _subjects = [];
  Map<String, dynamic>? _studentProfile;

  // Selected subject for detail view (Screenshot 4 right)
  StudentSubject? _selectedSubject;
  List<SubjectModule> _selectedModules = [];
  List<SubjectQuiz> _quizzes = [];
  List<SubjectAssignment> _assignments = [];
  bool _loadingModules = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final profile = await _repo.fetchStudentProfile();
      final subjects = await _repo.fetchEnrolledSubjects();
      if (!mounted) return;

      StudentSubject? autoSelected;
      if (widget.subjectId != null) {
        for (final sub in subjects) {
          if (sub.id == widget.subjectId) {
            autoSelected = sub;
            break;
          }
        }
      }

      setState(() {
        _studentProfile = profile;
        _subjects = subjects;
        _loading = false;
      });

      if (autoSelected != null) {
        _handleSubjectSelect(autoSelected);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _handleSubjectSelect(StudentSubject sub) async {
    setState(() {
      _selectedSubject = sub;
      _loadingModules = true;
      _selectedModules = [];
      _quizzes = [];
      _assignments = [];
    });

    try {
      final list = await _repo.fetchModules(sub.id);
      final assignments = await _repo.fetchAssignments(sub.id);
      final quizzes = await _repo.fetchQuizzes(sub.id);
      if (mounted) {
        setState(() {
          _selectedModules = list;
          _assignments = assignments;
          _quizzes = quizzes;
          _loadingModules = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingModules = false);
    }
  }

  @override
  void didUpdateWidget(covariant StudentModulesScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.subjectId != oldWidget.subjectId) {
      if (widget.subjectId == null) {
        setState(() {
          _selectedSubject = null;
        });
      } else {
        StudentSubject? match;
        for (final sub in _subjects) {
          if (sub.id == widget.subjectId) {
            match = sub;
            break;
          }
        }
        if (match != null) {
          _handleSubjectSelect(match);
        } else {
          _loadData();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appUser = context.watch<AppState>().currentUser;
    final String studentName = appUser?.displayName ?? 'Ayisha Romulo';
    final String courseSection = _studentProfile?['year_section'] ?? 'BSIT 3-1';

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(90),
        child: AppBar(
          backgroundColor: const Color(0xFF0A5C36),
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
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        studentName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        courseSection,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),

                // Dynamic Header / Breadcrumb title
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      if (_selectedSubject != null) ...[
                        InkWell(
                          onTap: () {
                            setState(() {
                              _selectedSubject = null;
                            });
                          },
                          borderRadius: BorderRadius.circular(100),
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.grey.shade100,
                              border: Border.all(color: Colors.grey.shade200, width: 1),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.arrow_back_ios_new_rounded,
                                color: Color(0xFF0A5C36),
                                size: 14,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                      ],
                      Text(
                        _selectedSubject == null ? 'Learning Modules' : _selectedSubject!.name.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0A5C36),
                        ),
                      ),
                      if (_selectedSubject == null) ...[
                        const Spacer(),
                        ElevatedButton.icon(
                          onPressed: _showJoinClassDialog,
                          icon: const Icon(Icons.add_rounded, size: 18),
                          label: const Text('Join Class', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0A5C36),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Main body content (List of courses or List of lessons)
                Expanded(
                  child: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : _selectedSubject == null
                          ? _buildSubjectList()
                          : _buildModulesList(),
                ),
              ],
            ),
          ),
          const StudentFloatingNavBar(currentIndex: 2),
        ],
      ),
    );
  }

  Widget _buildSubjectList() {
    if (_subjects.isEmpty) {
      return const Center(child: Text('No courses assigned.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      itemCount: _subjects.length,
      itemBuilder: (context, index) {
        final dbMatch = _subjects[index];

        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Color(0xFFEEEEEE)),
          ),
          child: InkWell(
            onTap: () => _handleSubjectSelect(dbMatch),
            borderRadius: BorderRadius.circular(12),
            hoverColor: const Color(0xFF0A5C36).withValues(alpha: 0.04),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              child: Row(
                children: [
                  const Icon(Icons.book_rounded, color: Color(0xFF0A5C36), size: 24),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      dbMatch.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildModulesList() {
    if (_loadingModules) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_selectedModules.isEmpty && _quizzes.isEmpty && _assignments.isEmpty) {
      return const Center(child: Text('No modules uploaded yet.'));
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      children: [
        // Quick access buttons for Grades and Attendance
        Row(
          children: [
            Expanded(
              child: _buildQuickAccessButton(
                icon: Icons.grade_rounded,
                label: 'My Grades',
                color: const Color(0xFF0A5C36),
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(
                    builder: (_) => StudentGradesScreen(subject: _selectedSubject),
                  ));
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildQuickAccessButton(
                icon: Icons.event_available_rounded,
                label: 'Attendance',
                color: const Color(0xFF0A5C36),
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(
                    builder: (_) => StudentAttendanceScreen(subject: _selectedSubject),
                  ));
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ..._selectedModules.asMap().entries.map((entry) {
          final i = entry.key;
          final m = entry.value;
          final mMaterials = _assignments.where((a) => a.moduleId == m.id && (a.description ?? '').startsWith('[MATERIAL]')).toList();
          final mAssignments = _assignments.where((a) => a.moduleId == m.id && !(a.description ?? '').startsWith('[MATERIAL]')).toList();
          final mQuizzes = _quizzes.where((q) => q.moduleId == m.id).toList();


          final bool hasLegacyFile = m.fileUrl != null;

          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.white,
              border: Border.all(color: const Color(0xFFEEEEEE)),
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Module ${i + 1} - ${m.title}',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0A5C36)),
                ),
                if (m.description != null && m.description!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    m.description!,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
                const SizedBox(height: 12),

                // Legacy module file (if any)
                if (hasLegacyFile)
                  _buildStudentContentRow(
                    Icons.menu_book_rounded,
                    m.fileName ?? '${m.title} - Document',
                    'Material',
                    () => _openUrl(m.fileUrl!),
                  ),

                // Materials (new style)
                ...mMaterials.map((mat) => _buildStudentContentRow(
                      Icons.menu_book_rounded,
                      mat.fileName ?? '${mat.title} - Document',
                      'Material',
                      () {
                        if (mat.fileUrl != null) _openUrl(mat.fileUrl!);
                      },
                    )),

                // Assignments
                ...mAssignments.map((ass) => _buildStudentContentRow(
                      Icons.assignment_rounded,
                      ass.title,
                      'Assignment',
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => StudentAssignmentDetailScreen(
                              subject: _selectedSubject!,
                              assignment: ass,
                            ),
                          ),
                        );
                      },
                    )),

                // Quizzes
                ...mQuizzes.map((quiz) => _buildStudentContentRow(
                      Icons.fact_check_rounded,
                      quiz.title,
                      'Quiz',
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => StudentQuizScreen(
                              subject: _selectedSubject!,
                              quiz: quiz,
                            ),
                          ),
                        );
                      },
                    )),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildStudentContentRow(IconData icon, String title, String type, VoidCallback onTap) {
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
        hoverColor: const Color(0xFF0A5C36).withValues(alpha: 0.04),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF0A5C36).withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 16, color: const Color(0xFF0A5C36)),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(title,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.black87))),
            Text(type, style: const TextStyle(fontSize: 11, color: Colors.black38)),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right_rounded, size: 16, color: Colors.black26),
          ]),
        ),
      ),
    );
  }

  void _openUrl(String url) {
    web.window.open(url, '_blank');
  }

  void _showJoinClassDialog() {
    final codeCtrl = TextEditingController();
    bool joining = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: Colors.white,
          title: Row(
            children: [
              const Icon(Icons.group_add_rounded, color: Color(0xFF0A5C36)),
              const SizedBox(width: 10),
              const Text('Join a Class', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Ask your professor for the class code, then enter it below.',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600, height: 1.4),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: codeCtrl,
                textCapitalization: TextCapitalization.characters,
                inputFormatters: const [UpperCaseTextFormatter()],
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 4, color: Color(0xFF0A5C36)),
                decoration: InputDecoration(
                  hintText: 'CODE',
                  hintStyle: TextStyle(color: Colors.grey.shade300, letterSpacing: 4),
                  filled: true,
                  fillColor: const Color(0xFF0A5C36).withOpacity(0.04),
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade200, width: 1.5),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF0A5C36), width: 2),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: joining ? null : () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0A5C36),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: joining
                  ? null
                  : () async {
                      final code = codeCtrl.text.trim();
                      if (code.isEmpty) return;
                      setS(() => joining = true);
                      try {
                        final result = await _repo.joinClassByCode(code);
                        final status = result['status'];
                        if (!ctx.mounted) return;
                        if (status == 'ok') {
                          Navigator.pop(ctx);
                          await _loadData();
                          if (mounted) {
                            AppDialog.result(context, type: DialogType.success,
                                message: 'Joined ${result['subjectName']}!');
                          }
                        } else if (status == 'already') {
                          Navigator.pop(ctx);
                          if (mounted) {
                            AppDialog.result(context, type: DialogType.info,
                                message: 'You are already enrolled in ${result['subjectName']}.');
                          }
                        } else if (status == 'not_student') {
                          setS(() => joining = false);
                          AppDialog.result(ctx, type: DialogType.error,
                              message: 'Your account is not set up as a student yet.');
                        } else {
                          setS(() => joining = false);
                          AppDialog.result(ctx, type: DialogType.error,
                              message: 'Invalid class code. Please check and try again.');
                        }
                      } catch (e) {
                        setS(() => joining = false);
                        if (ctx.mounted) {
                          AppDialog.result(ctx, type: DialogType.error, message: 'Failed to join: $e');
                        }
                      }
                    },
              child: Text(joining ? 'Joining...' : 'Join'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAccessButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }
}
