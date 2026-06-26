import 'dart:convert';
import 'dart:js_interop';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:web/web.dart' as web;
import 'package:excel/excel.dart' as xl;

import '../../../../core/constants/app_colors.dart';
import '../../../../core/state/app_state.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../data/repositories/professor_repository.dart';
import '../../domain/models/professor_subject.dart';
import '../widgets/professor_floating_nav_bar.dart';
import 'professor_subject_screen.dart';

class ProfessorClassesScreen extends StatefulWidget {
  const ProfessorClassesScreen({super.key});

  @override
  State<ProfessorClassesScreen> createState() => _ProfessorClassesScreenState();
}

class _ProfessorClassesScreenState extends State<ProfessorClassesScreen> {
  final _repo = const ProfessorRepository();
  bool _loading = true;
  List<ProfessorSubject> _dbSubjects = [];
  List<ProfessorSubject> _localAddedSubjects = [];
  List<ProfessorSubject> _filteredSubjects = [];

  // Filter values
  String? _selectedStudentName;
  int? _selectedYearLevel;
  String? _selectedSubject;
  String? _selectedCourseSection;



  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final subjects = await _repo.fetchMySubjects();
      if (mounted) {
        setState(() {
          _dbSubjects = subjects;
          _loading = false;
          _applyFilters();
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _applyFilters();
        });
      }
    }
  }

  List<ProfessorSubject> get _allSubjects {
    return [..._dbSubjects, ..._localAddedSubjects];
  }

  void _applyFilters() {
    setState(() {
      _filteredSubjects = _allSubjects.where((sub) {
        // Filter by Year Level
        if (_selectedYearLevel != null && sub.yearLevel != _selectedYearLevel) {
          return false;
        }
        // Filter by Subject Name
        if (_selectedSubject != null &&
            !sub.name.toLowerCase().contains(_selectedSubject!.toLowerCase())) {
          return false;
        }
        // Filter by Course & Section
        if (_selectedCourseSection != null) {
          final filterStr = _selectedCourseSection!.toLowerCase();
          final classCode = sub.classLabel.toLowerCase();
          if (!classCode.contains(filterStr)) {
            return false;
          }
        }
        return true;
      }).toList();
    });
  }

  void _resetFilters() {
    setState(() {
      _selectedStudentName = null;
      _selectedYearLevel = null;
      _selectedSubject = null;
      _selectedCourseSection = null;
      _applyFilters();
    });
  }



  void _verifyPasswordAndExecute(String actionDescription, Future<void> Function() action, {String confirmLabel = 'Confirm'}) {
    final user = context.read<AppState>().currentUser;
    if (user == null) {
      AppDialog.result(context, type: DialogType.error, message: 'User session not found.');
      return;
    }

    // Safe confirmation gate (no re-authentication / no hardcoded credentials).
    AppDialog.confirm(
      context,
      title: 'Please Confirm',
      message: 'Are you sure you want to proceed with $actionDescription? This action cannot be undone.',
      type: DialogType.warning,
      confirmLabel: confirmLabel,
      onConfirm: () async {
        await action();
      },
    );
  }

  void _verifyPasswordAndExecuteWithTextarea(
    String actionDescription,
    Future<void> Function(String reason) action, {
    String confirmLabel = 'Confirm',
  }) {
    final user = context.read<AppState>().currentUser;
    if (user == null) {
      AppDialog.result(context, type: DialogType.error, message: 'User session not found.');
      return;
    }

    AppDialog.confirmWithTextarea(
      context,
      title: 'Please Confirm',
      message: 'Are you sure you want to proceed with $actionDescription? This action cannot be undone.',
      textLabel: 'Request message (Optional)',
      type: DialogType.warning,
      confirmLabel: confirmLabel,
      onConfirm: (reason) async {
        await action(reason);
      },
    );
  }

  void _exportStudentList(ProfessorSubject sub, List<Map<String, String>> students) {
    final excel = xl.Excel.createExcel();
    final sheet = excel['Students'];

    // Header row
    sheet.appendRow([
      xl.TextCellValue('Name'),
      xl.TextCellValue('Student Number'),
      xl.TextCellValue('Email'),
      xl.TextCellValue('Course'),
      xl.TextCellValue('Year & Section'),
    ]);

    // Data rows
    for (final s in students) {
      sheet.appendRow([
        xl.TextCellValue(s['name'] ?? ''),
        xl.TextCellValue(s['studentNumber'] ?? ''),
        xl.TextCellValue(s['email'] ?? ''),
        xl.TextCellValue(s['course'] ?? ''),
        xl.TextCellValue(s['yearSection'] ?? ''),
      ]);
    }

    // Remove the default 'Sheet1'
    if (excel.sheets.containsKey('Sheet1')) {
      excel.delete('Sheet1');
    }

    final bytes = excel.encode();
    if (bytes == null) return;

    // Download via browser
    final uint8 = Uint8List.fromList(bytes);
    final blob = web.Blob([uint8.toJS].toJS, web.BlobPropertyBag(type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'));
    final url = web.URL.createObjectURL(blob);
    final anchor = web.document.createElement('a') as web.HTMLAnchorElement;
    anchor.href = url;
    anchor.download = '${sub.name}_${sub.courseCode}_${sub.yearLevel}-${sub.section}_students.xlsx';
    anchor.click();
    web.URL.revokeObjectURL(url);
  }

  void _showViewStudentsDialog(ProfessorSubject sub) async {
    setState(() => _loading = true);
    List<Map<String, String>> students = [];
    try {
      students = await _repo.fetchEnrolledStudents(sub.id);
    } catch (_) {
      students = [];
    } finally {
      setState(() => _loading = false);
    }

    if (!mounted) return;

    String searchQuery = '';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) {
          final filteredStudents = students.where((s) {
            final name = s['name']?.toLowerCase() ?? '';
            return name.contains(searchQuery.toLowerCase());
          }).toList();

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            backgroundColor: const Color(0xFFF8F9FC),
            titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 10),
            contentPadding: const EdgeInsets.symmetric(horizontal: 24),
            actionsPadding: const EdgeInsets.all(24),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.authPrimary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.people_alt_rounded, color: AppColors.authPrimary, size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Student List',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  sub.classLabel,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF475569),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Class Code: ${sub.joinCode ?? '------'}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            content: Container(
              width: 450,
              height: 400,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200, width: 1.5),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search student...',
                        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                        prefixIcon: const Icon(Icons.search, size: 20, color: Colors.grey),
                        isDense: true,
                        filled: true,
                        fillColor: const Color(0xFFF8F9FC),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade200, width: 1.5),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.authPrimary, width: 2),
                        ),
                      ),
                      onChanged: (val) {
                        setS(() {
                          searchQuery = val;
                        });
                      },
                    ),
                  ),
                  const Divider(height: 1, thickness: 1),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Student Name',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          'Actions',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, thickness: 1),
                  Expanded(
                    child: filteredStudents.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.symmetric(vertical: 24),
                            child: Center(child: Text('No students found.')),
                          )
                        : ListView.builder(
                            itemCount: filteredStudents.length,
                            itemBuilder: (_, i) {
                              final s = filteredStudents[i];
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: const BoxDecoration(
                                  border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        s['name'] ?? '',
                                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                                      iconSize: 20,
                                      onPressed: () {
                                        _verifyPasswordAndExecuteWithTextarea(
                                          'unenrolling student "${s['name'] ?? ''}"',
                                          (reason) async {
                                            try {
                                              await _repo.requestUnenrollStudent(
                                                subjectId: sub.id,
                                                studentProfileId: s['profileId']!,
                                                studentName: s['name'] ?? 'Student',
                                                subjectName: sub.name,
                                                classLabel: sub.classLabel,
                                                reason: reason,
                                              );
                                              if (!mounted) return;
                                              AppDialog.result(
                                                context,
                                                type: DialogType.success,
                                                message: 'Unenrollment request submitted for admin approval.',
                                              );
                                            } catch (e) {
                                              if (!mounted) return;
                                              AppDialog.result(
                                                context,
                                                type: DialogType.error,
                                                message: e.toString(),
                                              );
                                            }
                                          },
                                          confirmLabel: 'Confirm Request',
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
            actions: [
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0A5C36),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  elevation: 0,
                ),
                onPressed: () => _exportStudentList(sub, students),
                icon: const Icon(Icons.download_rounded, size: 18),
                label: const Text('Export', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.grey.shade300, width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  backgroundColor: Colors.white,
                  elevation: 0,
                ),
                onPressed: () => Navigator.pop(ctx),
                child: const Text(
                  'Close',
                  style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showAttendanceDialog(ProfessorSubject sub) async {
    setState(() => _loading = true);
    List<Map<String, String>> students = [];
    List<AttendanceSummary> historyData = [];
    List<StudentAttendanceSummary> summaryData = [];
    try {
      students = await _repo.fetchEnrolledStudents(sub.id);
      historyData = await _repo.fetchAttendanceHistory(sub.id);
      summaryData = await _repo.fetchStudentAttendanceSummaries(sub.id);
    } catch (_) {
      students = [];
    } finally {
      setState(() => _loading = false);
    }

    if (!mounted) return;

    // Pre-fill today's attendance from DB if already recorded
    final attendance = <String, String>{};
    try {
      final todayRecords = await _repo.fetchAttendanceByDate(sub.id, DateTime.now());
      for (final r in todayRecords) {
        attendance[r.studentProfileId] = r.status;
      }
    } catch (_) {}
    // Default remaining students to 'present'
    for (final s in students) {
      attendance.putIfAbsent(s['profileId']!, () => 'present');
    }

    String activeView = 'sheet'; // 'sheet', 'history', 'summary'
    bool submitting = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) {
          Widget buildHeaderCol(String label, Color color) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 9, color: Colors.black54, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ],
            );
          }

          Widget buildStatusCheckbox({
            required bool isSelected,
            required Color color,
            required VoidCallback onTap,
          }) {
            return InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(4),
              child: Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: isSelected ? color : Colors.transparent,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: isSelected ? color : Colors.grey.shade300,
                    width: 1.5,
                  ),
                ),
                child: isSelected
                    ? const Icon(Icons.check, color: Colors.white, size: 12)
                    : null,
              ),
            );
          }

          Widget _buildStatBadge(String label, Color bgColor, Color textColor) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                label,
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: textColor),
              ),
            );
          }

          Widget buildHistoryRow(AttendanceSummary summary) {
            final dateStr = '${summary.date.month.toString().padLeft(2, '0')}/${summary.date.day.toString().padLeft(2, '0')}/${summary.date.year}';

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    dateStr,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87),
                  ),
                  Row(
                    children: [
                      _buildStatBadge('${summary.presentCount} Present', const Color(0xFFE0F2F1), const Color(0xFF00796B)),
                      const SizedBox(width: 6),
                      _buildStatBadge('${summary.lateCount} Late', const Color(0xFFFFF3E0), const Color(0xFFEF6C00)),
                      const SizedBox(width: 6),
                      _buildStatBadge('${summary.absentCount} Absent', const Color(0xFFFFEBEE), const Color(0xFFC62828)),
                    ],
                  ),
                ],
              ),
            );
          }

          Widget buildSegmentButton(String viewName, String label, IconData icon) {
            final isSelected = activeView == viewName;
            return Expanded(
              child: GestureDetector(
                onTap: () {
                  setS(() {
                    activeView = viewName;
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
                              color: AppColors.authPrimary.withValues(alpha: 0.15),
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

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            backgroundColor: const Color(0xFFF8F9FC),
            titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 10),
            contentPadding: const EdgeInsets.symmetric(horizontal: 24),
            actionsPadding: const EdgeInsets.all(24),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.authPrimary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.assignment_turned_in_rounded, color: AppColors.authPrimary, size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Attendance Sheet',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '${sub.name} - ${sub.classLabel}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF475569),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Date: ${DateTime.now().month}/${DateTime.now().day}/${DateTime.now().year}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            content: Container(
              width: MediaQuery.of(ctx).size.width * 0.9,
              constraints: BoxConstraints(
                maxWidth: 450,
                maxHeight: MediaQuery.of(ctx).size.height * 0.65,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Segmented control bar
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFEFEF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        buildSegmentButton('sheet', 'Mark Sheet', Icons.assignment_turned_in_outlined),
                        buildSegmentButton('history', 'History', Icons.history),
                        buildSegmentButton('summary', 'Summary', Icons.analytics_outlined),
                      ],
                    ),
                  ),

                  if (activeView == 'history')
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade200, width: 1.5),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.fromLTRB(16, 12, 16, 8),
                              child: Text(
                                'Attendance History',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
                              ),
                            ),
                            const Divider(height: 1),
                            Expanded(
                              child: historyData.isEmpty
                                  ? const Padding(
                                      padding: EdgeInsets.symmetric(vertical: 24),
                                      child: Center(child: Text('No attendance records yet.', style: TextStyle(color: Colors.grey))),
                                    )
                                  : ListView.builder(
                                      itemCount: historyData.length,
                                      itemBuilder: (_, i) => buildHistoryRow(historyData[i]),
                                    ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else if (activeView == 'summary')
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade200, width: 1.5),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.fromLTRB(16, 12, 16, 8),
                              child: Text(
                                'Attendance Summary (Overall)',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
                              ),
                            ),
                            const Divider(height: 1),
                            Expanded(
                              child: summaryData.isEmpty
                                ? const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 24),
                                    child: Center(child: Text('No attendance data yet.', style: TextStyle(color: Colors.grey))),
                                  )
                                : ListView.builder(
                                    itemCount: summaryData.length,
                                    itemBuilder: (_, i) {
                                      final s = summaryData[i];
                                      final pct = s.attendanceRate;
                                      return Container(
                                        color: i % 2 == 0 ? Colors.grey.shade50 : Colors.white,
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                s.studentName,
                                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87),
                                              ),
                                            ),
                                            Row(
                                              children: [
                                                Text(
                                                  '${pct.toStringAsFixed(0)}%',
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w800,
                                                    color: pct > 85 ? const Color(0xFF00796B) : const Color(0xFFEF6C00),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                _buildStatBadge('${s.totalPresent} P', const Color(0xFFE0F2F1), const Color(0xFF00796B)),
                                                const SizedBox(width: 4),
                                                _buildStatBadge('${s.totalLate} L', const Color(0xFFFFF3E0), const Color(0xFFEF6C00)),
                                                const SizedBox(width: 4),
                                                _buildStatBadge('${s.totalAbsent} A', const Color(0xFFFFEBEE), const Color(0xFFC62828)),
                                              ],
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200, width: 1.5),
                      ),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Expanded(
                                  child: Text(
                                    'Student Name',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                                Row(
                                  children: [
                                    SizedBox(width: 50, child: Center(child: buildHeaderCol('Present', const Color(0xFF00796B)))),
                                    SizedBox(width: 50, child: Center(child: buildHeaderCol('Late', const Color(0xFFEF6C00)))),
                                    SizedBox(width: 50, child: Center(child: buildHeaderCol('Absent', const Color(0xFFC62828)))),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const Divider(height: 1, thickness: 1),
                          Expanded(
                            child: students.isEmpty
                                ? const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 24),
                                    child: Center(child: Text('No students found.')),
                                  )
                                : ListView.builder(
                                    itemCount: students.length,
                                    itemBuilder: (_, i) {
                                      final s = students[i];
                                      final pid = s['profileId']!;
                                      final currentStatus = attendance[pid] ?? 'present';

                                      return Container(
                                        color: i % 2 == 0 ? Colors.grey.shade50 : Colors.white,
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                s['name'] ?? '',
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w500,
                                                  color: Colors.black87,
                                                ),
                                              ),
                                            ),
                                            Row(
                                              children: [
                                                SizedBox(
                                                  width: 50,
                                                  child: Center(
                                                    child: buildStatusCheckbox(
                                                      isSelected: currentStatus == 'present',
                                                      color: const Color(0xFF00796B),
                                                      onTap: () => setS(() { attendance[pid] = 'present'; }),
                                                    ),
                                                  ),
                                                ),
                                                SizedBox(
                                                  width: 50,
                                                  child: Center(
                                                    child: buildStatusCheckbox(
                                                      isSelected: currentStatus == 'late',
                                                      color: const Color(0xFFEF6C00),
                                                      onTap: () => setS(() { attendance[pid] = 'late'; }),
                                                    ),
                                                  ),
                                                ),
                                                SizedBox(
                                                  width: 50,
                                                  child: Center(
                                                    child: buildStatusCheckbox(
                                                      isSelected: currentStatus == 'absent',
                                                      color: const Color(0xFFC62828),
                                                      onTap: () => setS(() { attendance[pid] = 'absent'; }),
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
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              if (activeView != 'sheet')
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.grey.shade300, width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    backgroundColor: Colors.white,
                    elevation: 0,
                  ),
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text(
                    'Close',
                    style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold),
                  ),
                )
              else ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.grey.shade300, width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                        backgroundColor: Colors.white,
                        elevation: 0,
                      ),
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.authPrimary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                        elevation: 0,
                      ),
                      onPressed: submitting ? null : () async {
                        setS(() => submitting = true);
                        try {
                          await _repo.saveAttendance(
                            subjectId: sub.id,
                            date: DateTime.now(),
                            attendance: attendance,
                          );
                          if (!ctx.mounted) return;
                          Navigator.pop(ctx);
                          final presentCount = attendance.values.where((v) => v == 'present').length;
                          final lateCount = attendance.values.where((v) => v == 'late').length;
                          final absentCount = attendance.values.where((v) => v == 'absent').length;
                          AppDialog.result(
                            context,
                            type: DialogType.success,
                            message: 'Attendance saved!\n$presentCount Present, $lateCount Late, $absentCount Absent.',
                            buttonLabel: 'Done',
                          );
                        } catch (e) {
                          setS(() => submitting = false);
                          if (ctx.mounted) {
                            AppDialog.result(ctx, type: DialogType.error, message: 'Failed to save: $e');
                          }
                        }
                      },
                      child: Text(
                        submitting ? 'Saving...' : 'Submit Attendance',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppState>().currentUser;

    // Get unique subject names for filter
    final subjectNames = _allSubjects.map((s) => s.name).toSet().toList();
    // Get unique course codes for filter
    final courseSections = _allSubjects
        .map((s) => s.classLabel)
        .toSet()
        .toList();

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
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                    children: [
                      // My Classes title
                      const Text(
                        'My Classes',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.authPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Dropdown Filters grid
                      // Dropdown Filters grid inline
                      Row(
                        children: [
                          Expanded(
                            child: _buildFilterDropdown<String>(
                              label: 'Classname',
                              value: _selectedSubject,
                              items: subjectNames,
                              onChanged: (v) => setState(() {
                                _selectedSubject = v;
                                _applyFilters();
                              }),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildFilterDropdown<String>(
                              label: 'Course & Section',
                              value: _selectedCourseSection,
                              items: courseSections,
                              onChanged: (v) => setState(() {
                                _selectedCourseSection = v;
                                _applyFilters();
                              }),
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            height: 48,
                            child: ElevatedButton.icon(
                              onPressed: _applyFilters,
                              icon: const Icon(Icons.search, size: 16),
                              label: const Text('Search'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.authPrimary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                            ),
                          ),
                          if (_selectedStudentName != null ||
                              _selectedYearLevel != null ||
                              _selectedSubject != null ||
                              _selectedCourseSection != null) ...[
                            const SizedBox(width: 6),
                            SizedBox(
                              height: 48,
                              width: 48,
                              child: IconButton(
                                style: IconButton.styleFrom(
                                  backgroundColor: Colors.grey[200],
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                icon: const Icon(Icons.refresh, color: Colors.black87, size: 20),
                                onPressed: _resetFilters,
                                tooltip: 'Clear Filters',
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Classes List
                      if (_filteredSubjects.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 40),
                          child: Center(
                            child: Text(
                              'No classes match the filter criteria.',
                              style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
                            ),
                          ),
                        )
                      else
                        Column(
                          children: _filteredSubjects
                              .map((sub) => _buildClassRow(sub))
                              .toList(),
                        ),
                    ],
                  ),
          ),
          const ProfessorFloatingNavBar(currentIndex: 1),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown<T>({
    required String label,
    required T? value,
    required List<T> items,
    Map<T, String>? itemLabels,
    required ValueChanged<T?> onChanged,
  }) {
    String displayText = 'All ${label}s';
    if (label.toLowerCase() == 'classname') {
      displayText = 'Class Name';
    } else if (label.toLowerCase() == 'course & section') {
      displayText = 'Course & Section';
    } else if (label.toLowerCase() == 'subject name') {
      displayText = 'Subject Names';
    }

    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          hint: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                displayText,
                style: const TextStyle(color: Colors.black54, fontSize: 13),
              ),
            ],
          ),
          isExpanded: true,
          icon: const Icon(Icons.arrow_drop_down, color: Colors.black54),
          style: const TextStyle(color: Colors.black87, fontSize: 13),
          items: [
            DropdownMenuItem<T>(
              value: null,
              child: Text(displayText, style: const TextStyle(color: Colors.black54)),
            ),
            ...items.map((item) {
              final text = itemLabels != null ? itemLabels[item] : item.toString();
              return DropdownMenuItem<T>(
                value: item,
                child: Text(text ?? ''),
              );
            }),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildClassRow(ProfessorSubject sub) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 0,
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
              colors: [
                Color(0xFFE3F2FD),
                Color(0xFFBBDEFB),
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
            border: Border.all(color: Colors.blue.shade100.withValues(alpha: 0.5)),
          ),
          padding: const EdgeInsets.all(16),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 360;
              if (isNarrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sub.name,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF1565C0)),
                    ),
                    const SizedBox(height: 4),
                    Text(sub.classLabel, style: TextStyle(fontSize: 13, color: Colors.blueGrey.shade800, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text('${sub.studentCount} students', style: TextStyle(fontSize: 12, color: Colors.blueGrey.shade600)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 34,
                            child: ElevatedButton(
                              onPressed: () => _showViewStudentsDialog(sub),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: const Color(0xFF1D4E8F),
                                side: const BorderSide(color: Color(0xFF1D4E8F), width: 1.5),
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                padding: EdgeInsets.zero,
                              ),
                              child: const Text('View Students', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: SizedBox(
                            height: 34,
                            child: ElevatedButton(
                              onPressed: () => _showAttendanceDialog(sub),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: const Color(0xFF1D4E8F),
                                side: const BorderSide(color: Color(0xFF1D4E8F), width: 1.5),
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                padding: EdgeInsets.zero,
                              ),
                              child: const Text('Attendance', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              }
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Left side
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          sub.name,
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF1565C0)),
                        ),
                        const SizedBox(height: 4),
                        Text(sub.classLabel, style: TextStyle(fontSize: 13, color: Colors.blueGrey.shade800, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        Text('${sub.studentCount} students', style: TextStyle(fontSize: 12, color: Colors.blueGrey.shade600)),
                      ],
                    ),
                  ),
                  // Right side buttons
                  Column(
                    children: [
                      SizedBox(
                        width: 130,
                        height: 34,
                        child: ElevatedButton(
                          onPressed: () => _showViewStudentsDialog(sub),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF1D4E8F),
                            side: const BorderSide(color: Color(0xFF1D4E8F), width: 1.5),
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: EdgeInsets.zero,
                          ),
                          child: const Text('View Students', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: 130,
                        height: 34,
                        child: ElevatedButton(
                          onPressed: () => _showAttendanceDialog(sub),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFFE65100),
                            side: const BorderSide(color: Color(0xFFE65100), width: 1.5),
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: EdgeInsets.zero,
                          ),
                          child: const Text('Attendance', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
    );
  }
}
