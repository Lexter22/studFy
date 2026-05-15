import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/state/app_state.dart';
import '../../../../features/auth/domain/services/auth_service.dart';
import '../../data/repositories/professor_repository.dart';
import '../../domain/models/professor_subject.dart';
import '../../presentation/widgets/professor_drawer.dart';
import 'professor_subject_screen.dart';

class ProfessorDashboardScreen extends StatefulWidget {
  const ProfessorDashboardScreen({super.key});

  @override
  State<ProfessorDashboardScreen> createState() => _ProfessorDashboardScreenState();
}

class _ProfessorDashboardScreenState extends State<ProfessorDashboardScreen> {
  final _repo = const ProfessorRepository();
  final _auth = const AuthService();

  List<ProfessorSubject> _subjects = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final subjects = await _repo.fetchMySubjects();
      if (mounted) setState(() { _subjects = subjects; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _logout() async {
    await _auth.signOut();
    if (!mounted) return;
    context.read<AppState>().logout();
    context.goNamed(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppState>().currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: AppColors.authPrimary,
        elevation: 0,
        toolbarHeight: 70,
        title: const Row(children: [
          Icon(Icons.school, color: Colors.white, size: 28),
          SizedBox(width: 8),
          Text('STUDFY', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
        ]),
        actions: [
          Center(child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(user?.displayName ?? user?.email ?? '', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
          )),
          IconButton(icon: const Icon(Icons.logout, color: Colors.white), onPressed: _logout, tooltip: 'Logout'),
        ],
      ),
      drawer: const ProfessorDrawer(),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _subjects.isEmpty
                ? const Center(child: Text('No subjects assigned yet.', style: TextStyle(color: Colors.grey, fontSize: 15)))
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Text('My Subjects', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.authPrimary)),
                      const SizedBox(height: 4),
                      Text('${_subjects.length} subject${_subjects.length == 1 ? '' : 's'} assigned', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                      const SizedBox(height: 16),
                      ..._subjects.map((s) => _SubjectCard(subject: s, onTap: () async {
                        await Navigator.push(context, MaterialPageRoute(builder: (_) => ProfessorSubjectScreen(subject: s)));
                        _load();
                      })),
                    ],
                  ),
      ),
    );
  }
}

class _SubjectCard extends StatelessWidget {
  final ProfessorSubject subject;
  final VoidCallback onTap;

  const _SubjectCard({required this.subject, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Colors.black12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(color: AppColors.authPrimary.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                child: Icon(Icons.menu_book, color: AppColors.authPrimary, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(subject.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87)),
                    const SizedBox(height: 4),
                    Text('${subject.courseCode} • Year ${subject.yearLevel} • Section ${subject.section}',
                        style: const TextStyle(fontSize: 12, color: Colors.black54)),
                    if (subject.scheduleLabel != null) ...[
                      const SizedBox(height: 2),
                      Text(subject.scheduleLabel!, style: const TextStyle(fontSize: 12, color: Colors.black45)),
                    ],
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: AppColors.authPrimary, borderRadius: BorderRadius.circular(20)),
                    child: Text('${subject.studentCount}', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 2),
                  const Text('students', style: TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, color: Colors.black38),
            ],
          ),
        ),
      ),
    );
  }
}
