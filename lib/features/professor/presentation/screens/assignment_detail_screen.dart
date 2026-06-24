import 'package:web/web.dart' as web;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/state/app_state.dart';
import '../../data/repositories/professor_repository.dart';
import '../../domain/models/professor_subject.dart';
import '../widgets/professor_floating_nav_bar.dart';

class AssignmentDetailScreen extends StatefulWidget {
  final SubjectAssignment assignment;
  final String subjectName;
  final int totalStudents;
  final String courseYearSection;

  const AssignmentDetailScreen({
    super.key,
    required this.assignment,
    required this.subjectName,
    required this.totalStudents,
    required this.courseYearSection,
  });

  @override
  State<AssignmentDetailScreen> createState() => _AssignmentDetailScreenState();
}

class _AssignmentDetailScreenState extends State<AssignmentDetailScreen> {
  final _repo = const ProfessorRepository();
  List<Map<String, dynamic>> _submissions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final submissions = await _repo.fetchAssignmentSubmissions(widget.assignment.id);
      if (mounted) setState(() { _submissions = submissions; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return 'No deadline';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  String _formatSubmittedAt(String? iso) {
    if (iso == null) return '';
    final dt = DateTime.tryParse(iso);
    if (dt == null) return '';
    final local = dt.toLocal();
    return '${local.day}/${local.month}/${local.year} ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }

  bool _isLate(String? iso) {
    if (iso == null || widget.assignment.deadline == null) return false;
    final submitted = DateTime.tryParse(iso);
    if (submitted == null) return false;
    return submitted.isAfter(widget.assignment.deadline!);
  }

  @override
  Widget build(BuildContext context) {
    final submitted = _submissions.length;
    final notSubmitted = widget.totalStudents - submitted;
    final user = context.watch<AppState>().currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
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
                    user?.displayName ?? 'thelexter2',
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
          _loading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                    children: [
                      // ── Assignment Title ──────────────────────────────────
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                widget.assignment.title,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            OutlinedButton.icon(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.arrow_back_rounded, size: 16, color: AppColors.authPrimary),
                              label: const Text(
                                'Back',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.authPrimary,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: AppColors.authPrimary, width: 1.5),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // ── Subject Info Banner ──────────────────────────────
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE3F2FD),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.blue.shade100),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade100,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.book_rounded, color: Color(0xFF1565C0), size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Subject',
                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black54, letterSpacing: 0.5),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    widget.subjectName,
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF1565C0)),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    widget.courseYearSection,
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1565C0)),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // ── Assignment Info Card ──────────────────────────────
                      _sectionCard(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(children: [
                            const Icon(Icons.assignment, color: AppColors.authPrimary, size: 20),
                            const SizedBox(width: 8),
                            const Text('Assignment Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          ]),
                          const Divider(height: 20),
                          if (widget.assignment.description != null && widget.assignment.description!.isNotEmpty) ...[
                            Text(widget.assignment.description!, style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.5)),
                            const SizedBox(height: 16),
                          ],
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF3E0),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFFFD180)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.alarm_on_rounded, size: 18, color: Color(0xFFE65100)),
                                const SizedBox(width: 8),
                                Text(
                                  'Deadline: ${_formatDate(widget.assignment.deadline)}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFE65100),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (widget.assignment.fileUrl != null) ...[
                            const SizedBox(height: 12),
                            InkWell(
                              onTap: () => web.window.open(widget.assignment.fileUrl!, '_blank'),
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.blue.shade200),
                                ),
                                child: Row(children: [
                                  const Icon(Icons.attach_file, color: Colors.blue, size: 18),
                                  const SizedBox(width: 8),
                                  Expanded(child: Text(widget.assignment.fileName ?? 'Attachment',
                                      style: const TextStyle(color: Colors.blue, fontSize: 13, fontWeight: FontWeight.w500),
                                      overflow: TextOverflow.ellipsis)),
                                  const Icon(Icons.download, color: Colors.blue, size: 16),
                                ]),
                              ),
                            ),
                          ],
                        ]),
                      ),

                      const SizedBox(height: 16),

                      // ── Submission Stats ──────────────────────────────────
                      Row(children: [
                        Expanded(child: _statCard(
                          icon: Icons.check_circle,
                          color: Colors.green,
                          value: '$submitted',
                          label: 'Submitted',
                        )),
                        const SizedBox(width: 12),
                        Expanded(child: _statCard(
                          icon: Icons.cancel,
                          color: Colors.red,
                          value: '$notSubmitted',
                          label: 'Not Submitted',
                        )),
                        const SizedBox(width: 12),
                        Expanded(child: _statCard(
                          icon: Icons.people,
                          color: AppColors.authPrimary,
                          value: '${widget.totalStudents}',
                          label: 'Total Students',
                        )),
                      ]),

                      const SizedBox(height: 16),

                      // ── Submissions List ──────────────────────────────────
                      _sectionCard(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(children: [
                            const Icon(Icons.upload_file, color: AppColors.authPrimary, size: 20),
                            const SizedBox(width: 8),
                            Text('Student Submissions ($submitted)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          ]),
                          const Divider(height: 20),
                          if (_submissions.isEmpty)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 20),
                              child: Center(child: Text('No submissions yet.', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic))),
                            )
                          else
                            ..._submissions.asMap().entries.map((entry) {
                              final i = entry.key;
                              final s = entry.value;
                              final late = _isLate(s['submitted_at']?.toString());
                              return Container(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  border: Border(bottom: BorderSide(color: i < _submissions.length - 1 ? Colors.grey.shade100 : Colors.transparent)),
                                ),
                                child: Row(children: [
                                  CircleAvatar(
                                    radius: 18,
                                    backgroundColor: AppColors.authPrimary.withOpacity(0.1),
                                    child: Text(
                                      (s['name']?.toString() ?? '?')[0].toUpperCase(),
                                      style: const TextStyle(color: AppColors.authPrimary, fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                      Text(s['name']?.toString() ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                      const SizedBox(height: 2),
                                      Row(children: [
                                        Icon(Icons.access_time, size: 12, color: late ? Colors.red : Colors.black38),
                                        const SizedBox(width: 4),
                                        Text(
                                          _formatSubmittedAt(s['submitted_at']?.toString()),
                                          style: TextStyle(fontSize: 11, color: late ? Colors.red : Colors.black45),
                                        ),
                                        if (late) ...[
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(4), border: Border.all(color: Colors.red.shade200)),
                                            child: const Text('Late', style: TextStyle(fontSize: 10, color: Colors.red, fontWeight: FontWeight.bold)),
                                          ),
                                        ],
                                      ]),
                                    ]),
                                  ),
                                  if (s['file_url'] != null)
                                    IconButton(
                                      icon: const Icon(Icons.download, color: AppColors.authPrimary),
                                      tooltip: 'Download submission',
                                      onPressed: () => web.window.open(s['file_url'].toString(), '_blank'),
                                    )
                                  else
                                    const Padding(
                                      padding: EdgeInsets.all(8),
                                      child: Icon(Icons.text_snippet_outlined, color: Colors.black26, size: 20),
                                    ),
                                ]),
                              );
                            }),
                        ]),
                      ),
                    ],
                  ),
                ),
          const ProfessorFloatingNavBar(currentIndex: 3),
        ],
      ),
    );
  }

  Widget _sectionCard({required Widget child}) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
      border: Border.all(color: Colors.grey.shade100),
    ),
    child: child,
  );

  Widget _statCard({required IconData icon, required Color color, required String value, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.12)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: color),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}
