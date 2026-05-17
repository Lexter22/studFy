import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/state/app_state.dart';
import '../../data/repositories/student_repository.dart';
import '../../domain/models/student_subject.dart';
import '../../../professor/domain/models/professor_subject.dart';
import '../widgets/student_floating_nav_bar.dart';

class StudentModulesScreen extends StatefulWidget {
  const StudentModulesScreen({super.key});

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
      setState(() {
        _studentProfile = profile;
        _subjects = subjects;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _handleSubjectSelect(StudentSubject sub) async {
    setState(() {
      _selectedSubject = sub;
      _loadingModules = true;
    });

    try {
      final list = await _repo.fetchModules(sub.id);
      if (mounted) {
        setState(() {
          _selectedModules = list;
          _loadingModules = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingModules = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appUser = context.watch<AppState>().currentUser;
    final String studentName = appUser?.displayName ?? 'Ayisha Romulo';
    final String courseSection = _studentProfile?['year_section'] ?? 'BSIT 3-1';

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A5C36),
        elevation: 0,
        toolbarHeight: 70,
        title: const Row(
          children: [
            Icon(Icons.school, color: Colors.white, size: 28),
            SizedBox(width: 8),
            Text(
              'STUDYFY',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        automaticallyImplyLeading: false,
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    studentName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
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
            ),
          ),
        ],
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
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF0A5C36), size: 20),
                          onPressed: () {
                            setState(() {
                              _selectedSubject = null;
                            });
                          },
                        ),
                        const SizedBox(width: 4),
                      ],
                      Text(
                        _selectedSubject == null ? 'Learning Modules' : _selectedSubject!.name.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0A5C36),
                        ),
                      ),
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

    // Add extra courses to match the long course list in Screenshot 4 left
    final List<Map<String, String>> mockCourseTitles = [
      {'name': 'Ethics', 'code': 'ETHICS'},
      {'name': 'Computer Programming', 'code': 'COMPPROG'},
      {'name': 'PATHFIT', 'code': 'PATHFIT'},
      {'name': 'Information Management', 'code': 'INFOMGMT'},
      {'name': 'IT ELECTIVE 2', 'code': 'ITELECTIVE2'},
      {'name': 'Integration', 'code': 'INTEG'},
      {'name': 'Software Engineering', 'code': 'SOFTENG'},
      {'name': 'Capstone', 'code': 'CAPSTONE'},
    ];

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      itemCount: mockCourseTitles.length,
      itemBuilder: (context, index) {
        final item = mockCourseTitles[index];
        
        // Find if we have a match in the active database subjects
        final dbMatch = _subjects.firstWhere(
          (s) => s.name.toLowerCase() == item['name']!.toLowerCase(),
          orElse: () => StudentSubject(
            id: 'mock-${item['code']!.toLowerCase()}',
            name: item['name']!,
            courseCode: item['code']!,
            section: 'BSIT 3-1',
            yearLevel: 3,
            professorName: 'Sir Dela Cruz',
          ),
        );

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
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              child: Row(
                children: [
                  const Icon(Icons.book_rounded, color: Color(0xFF0A5C36), size: 24),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      item['name']!,
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

    if (_selectedModules.isEmpty) {
      return const Center(child: Text('No modules uploaded yet.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      itemCount: _selectedModules.length,
      itemBuilder: (context, index) {
        final mod = _selectedModules[index];
        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Color(0xFFEEEEEE)),
          ),
          child: InkWell(
            onTap: () => _showModulePreview(mod),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.book_rounded, color: Color(0xFF0A5C36), size: 26),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          mod.title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        if (mod.description != null && mod.description!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            mod.description!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const Text(
                    'May 1', // Static date matching Screenshot 4 right
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showModulePreview(SubjectModule mod) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(mod.title, style: const TextStyle(color: Color(0xFF0A5C36), fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(mod.description ?? 'No description provided.', style: const TextStyle(fontSize: 14)),
              if (mod.fileName != null) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(Icons.attach_file, color: Colors.blue, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        mod.fileName!,
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close', style: TextStyle(color: Colors.grey)),
            ),
            if (mod.fileUrl != null)
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0A5C36)),
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Downloading ${mod.fileName ?? "file"}...')),
                  );
                },
                child: const Text('Download', style: TextStyle(color: Colors.white)),
              ),
          ],
        );
      },
    );
  }

}
