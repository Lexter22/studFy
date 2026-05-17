import 'dart:html' as html;
import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../data/repositories/professor_repository.dart';
import '../../domain/models/professor_subject.dart';

class AssignmentDetailScreen extends StatefulWidget {
  final SubjectAssignment assignment;
  final String subjectName;
  final int totalStudents;

  const AssignmentDetailScreen({
    super.key,
    required this.assignment,
    required this.subjectName,
    required this.totalStudents,
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

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: AppColors.authPrimary,
        elevation: 0,
        toolbarHeight: 70,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(widget.assignment.title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          Text(widget.subjectName, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ]),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
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
                        const SizedBox(height: 12),
                      ],
                      Row(children: [
                        const Icon(Icons.schedule, size: 16, color: Colors.black45),
                        const SizedBox(width: 6),
                        Text('Deadline: ${_formatDate(widget.assignment.deadline)}',
                            style: const TextStyle(fontSize: 13, color: Colors.black54)),
                      ]),
                      if (widget.assignment.fileUrl != null) ...[
                        const SizedBox(height: 12),
                        InkWell(
                          onTap: () => html.window.open(widget.assignment.fileUrl!, '_blank'),
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
                                  onPressed: () => html.window.open(s['file_url'].toString(), '_blank'),
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
    );
  }

  Widget _sectionCard({required Widget child}) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.black12),
    ),
    child: child,
  );

  Widget _statCard({required IconData icon, required Color color, required String value, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 6),
        Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.black45)),
      ]),
    );
  }
}
