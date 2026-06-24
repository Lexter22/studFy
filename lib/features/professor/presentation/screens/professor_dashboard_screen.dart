import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/state/app_state.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../data/repositories/professor_repository.dart';
import '../../domain/models/professor_subject.dart';
import '../widgets/professor_floating_nav_bar.dart';
import 'professor_subject_screen.dart';
import 'assignment_detail_screen.dart';

class ProfessorDashboardScreen extends StatefulWidget {
  const ProfessorDashboardScreen({super.key});

  @override
  State<ProfessorDashboardScreen> createState() => _ProfessorDashboardScreenState();
}

class _ProfessorDashboardScreenState extends State<ProfessorDashboardScreen> {
  final _repo = const ProfessorRepository();

  void _verifyPasswordAndExecute(String actionDescription, Future<void> Function() action) {
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
      confirmLabel: 'Confirm',
      onConfirm: () async {
        await action();
      },
    );
  }

  List<ProfessorSubject> _subjects = [];
  List<Map<String, dynamic>> _dashboardAssignments = [];
  List<Map<String, String>> _reminders = [];
  bool _loading = true;

  // Selected date for calendar starting at June 2026
  DateTime _calendarDate = DateTime(2026, 6, 1);
  final List<int> _eventDays = [9, 13];
  DateTime? _selectedDate = DateTime(2026, 6, 11);

  // Computed from _reminders (DB-backed)
  Map<String, List<Map<String, String>>> get _customReminders {
    final Map<String, List<Map<String, String>>> map = {};
    for (final r in _reminders) {
      final dateKey = r['date'] ?? '';
      if (dateKey.isEmpty) continue;
      map.putIfAbsent(dateKey, () => []);
      map[dateKey]!.add(r);
    }
    return map;
  }

  void _showAddReminderDialog(DateTime date) {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    TimeOfDay selectedTime = TimeOfDay.now();

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: const Color(0xFFF8F9FC),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              child: Container(
                width: 440,
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.authPrimary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.alarm_add_rounded, color: AppColors.authPrimary, size: 24),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Add Reminder',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'For: ${_getMonthName(date.month)} ${date.day}, ${date.year}',
                      style: const TextStyle(color: Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(
                        labelText: 'Reminder Title',
                        labelStyle: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w500),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: Colors.grey.shade200, width: 1.5),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: AppColors.authPrimary, width: 2.0),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: descController,
                      decoration: InputDecoration(
                        labelText: 'Description (Optional)',
                        labelStyle: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w500),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: Colors.grey.shade200, width: 1.5),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: AppColors.authPrimary, width: 2.0),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Select Time:',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF475569)),
                        ),
                        InkWell(
                          onTap: () async {
                            final TimeOfDay? time = await showTimePicker(
                              context: context,
                              initialTime: selectedTime,
                              builder: (context, child) {
                                return Theme(
                                  data: Theme.of(context).copyWith(
                                    colorScheme: const ColorScheme.light(
                                      primary: AppColors.authPrimary,
                                      onPrimary: Colors.white,
                                      onSurface: Colors.black87,
                                    ),
                                    textButtonTheme: TextButtonThemeData(
                                      style: TextButton.styleFrom(
                                        foregroundColor: AppColors.authPrimary,
                                      ),
                                    ),
                                  ),
                                  child: child!,
                                );
                              },
                            );
                            if (time != null) {
                              setDialogState(() {
                                selectedTime = time;
                              });
                            }
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade200, width: 1.5),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.access_time_rounded, size: 16, color: AppColors.authPrimary),
                                const SizedBox(width: 8),
                                Text(
                                  selectedTime.format(context),
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: Colors.grey.shade300, width: 1.5),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              backgroundColor: Colors.white,
                              elevation: 0,
                            ),
                            onPressed: () => Navigator.pop(dialogCtx),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.authPrimary,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              elevation: 0,
                            ),
                            onPressed: () async {
                              if (titleController.text.trim().isEmpty) return;
                              
                              Navigator.pop(dialogCtx);
                              try {
                                await _repo.createReminder(
                                  title: titleController.text.trim(),
                                  description: descController.text.trim(),
                                  date: date,
                                  time: selectedTime.format(context),
                                );
                                await _load();
                              } catch (e) {
                                if (mounted) {
                                  AppDialog.result(context, type: DialogType.error, message: 'Failed to save reminder: $e');
                                }
                              }
                            },
                            child: const Text(
                              'Save',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final subjects = await _repo.fetchMySubjects();
      final List<Map<String, dynamic>> loadedAssignments = [];
      
      for (final sub in subjects) {
        final assignments = await _repo.fetchAssignments(sub.id);
        for (final a in assignments) {
          // Skip materials
          if ((a.description ?? '').startsWith('[MATERIAL]')) continue;
          
          final submissionCount = await _repo.fetchAssignmentSubmissionCount(a.id);
          loadedAssignments.add({
            'subject': sub,
            'assignment': a,
            'submissionCount': submissionCount,
          });
        }
      }

      // Load reminders from DB
      List<Map<String, String>> reminders = [];
      try {
        reminders = await _repo.fetchReminders();
      } catch (_) {}
      
      if (mounted) {
        setState(() {
          _subjects = subjects;
          _dashboardAssignments = loadedAssignments;
          _reminders = reminders;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

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
                    user?.displayName ?? 'profname',
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
            child: RefreshIndicator(
              onRefresh: _load,
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                      children: [
                        _buildAssignmentSection(),
                        const SizedBox(height: 24),
                        _buildClassesSection(_subjects),
                        const SizedBox(height: 24),
                        _buildCalendarWidget(),
                        const SizedBox(height: 20),
                      ],
                    ),
            ),
          ),
          const ProfessorFloatingNavBar(currentIndex: 2),
        ],
      ),
    );
  }

  Widget _buildAssignmentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Assignment',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.authPrimary,
          ),
        ),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, constraints) {
            final bool isMobile = constraints.maxWidth < 500;
            return Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.black.withOpacity(0.05)),
              ),
              padding: EdgeInsets.all(isMobile ? 6 : 12),
              child: Column(
                children: [
                  // Header Row
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 6, horizontal: isMobile ? 8 : 16),
                    child: Row(
                      children: const [
                        Expanded(flex: 3, child: Text('Class', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: Color(0xFF1D4E8F)))),
                        Expanded(flex: 3, child: Text('Assignment', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: Color(0xFF1D4E8F)))),
                        Expanded(flex: 2, child: Text('Progress', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: Color(0xFF1D4E8F)))),
                        Expanded(flex: 2, child: Text('Due Date', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: Color(0xFF1D4E8F)))),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_dashboardAssignments.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text(
                          'No assignments found.',
                          style: TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                      ),
                    )
                  else
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: _dashboardAssignments.length > 3
                            ? (isMobile ? 220.0 : 255.0)
                            : double.infinity,
                      ),
                      child: ListView.builder(
                        shrinkWrap: true,
                        padding: EdgeInsets.zero,
                        physics: _dashboardAssignments.length > 3
                            ? const BouncingScrollPhysics()
                            : const NeverScrollableScrollPhysics(),
                        itemCount: _dashboardAssignments.length,
                        itemBuilder: (context, index) {
                          final item = _dashboardAssignments[index];
                          final ProfessorSubject sub = item['subject'];
                          final SubjectAssignment a = item['assignment'];
                          final int subCount = item['submissionCount'];
                          final int totalStudents = sub.studentCount > 0 ? sub.studentCount : 1;
                          final double progressVal = subCount / totalStudents;
                          
                          final String yearStr = a.deadline != null
                              ? (isMobile ? '${a.deadline!.year % 100}' : '${a.deadline!.year}')
                              : '';
                          final String dueDateStr = a.deadline != null 
                              ? '${a.deadline!.month.toString().padLeft(2, '0')}/${a.deadline!.day.toString().padLeft(2, '0')}/$yearStr'
                              : 'No Deadline';
                              
                           return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _buildAssignmentRow(
                              sub.classLabel,
                              sub.name,
                              a.title,
                              '$subCount/${sub.studentCount}',
                              progressVal.clamp(0.0, 1.0),
                              dueDateStr,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => AssignmentDetailScreen(
                                      assignment: a,
                                      subjectName: sub.name,
                                      totalStudents: sub.studentCount,
                                      courseYearSection: sub.classLabel,
                                    ),
                                  ),
                                ).then((_) => _load());
                              },
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            );
          }
        ),
      ],
    );
  }

  Widget _buildAssignmentRow(
    String classCode,
    String title,
    String subtitle,
    String progressText,
    double progressValue,
    String dueDate, {
    required VoidCallback onTap,
  }) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 500;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF3F3F3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 8 : 16,
              vertical: isMobile ? 10 : 14,
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Text(
                      classCode,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: isMobile ? 11 : 13,
                        color: const Color(0xFF2C3E50),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: isMobile ? 11 : 13,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: isMobile ? 9 : 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        progressText,
                        style: TextStyle(
                          fontSize: isMobile ? 10 : 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      SizedBox(
                        width: isMobile ? 50 : 70,
                        height: isMobile ? 4 : 6,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: LinearProgressIndicator(
                            value: progressValue,
                            backgroundColor: const Color(0xFFE0E0E0),
                            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2ECC71)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Text(
                      dueDate,
                      style: TextStyle(
                        color: Colors.black87,
                        fontSize: isMobile ? 10.5 : 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildClassesSection(List<ProfessorSubject> subjects) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'My Classes',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.authPrimary,
          ),
        ),
        const SizedBox(height: 10),
        if (subjects.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text(
                'No classes assigned.',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
            ),
          )
        else
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: subjects.length > 3 ? 285.0 : double.infinity,
            ),
            child: ListView.builder(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              physics: subjects.length > 3
                  ? const BouncingScrollPhysics()
                  : const NeverScrollableScrollPhysics(),
              itemCount: subjects.length,
              itemBuilder: (context, index) {
                final sub = subjects[index];
                return _buildClassCard(sub);
              },
            ),
          ),
      ],
    );
  }

  Widget _buildClassCard(ProfessorSubject sub) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 500;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.black.withOpacity(0.05)),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ProfessorSubjectScreen(subject: sub)),
          ).then((_) => _load());
        },
        borderRadius: BorderRadius.circular(12),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: isMobile ? 100 : 120,
                padding: EdgeInsets.all(isMobile ? 8 : 16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      sub.classLabel,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: isMobile ? 12 : 14,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.people_alt, size: 16, color: Color(0xFF1D4E8F)),
                        const SizedBox(width: 4),
                        Text(
                          '${sub.studentCount}',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1D4E8F)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                width: 1,
                color: Colors.grey.shade300,
                margin: const EdgeInsets.symmetric(vertical: 12),
              ),
              Expanded(
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 12 : 16,
                    vertical: isMobile ? 14 : 20,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    sub.name,
                    style: TextStyle(
                      fontSize: isMobile ? 14 : 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCalendarWidget() {
    final String monthName = _getMonthName(_calendarDate.month);
    final String yearString = _calendarDate.year.toString();

    // Get number of days in month
    final int daysInMonth = DateTime(_calendarDate.year, _calendarDate.month + 1, 0).day;
    // Get day of the week for first day of month (1 = Monday, 7 = Sunday)
    final int firstWeekday = DateTime(_calendarDate.year, _calendarDate.month, 1).weekday;
    final int offset = firstWeekday == 7 ? 0 : firstWeekday; // Adjust so Sunday is 0

    // Get event days dynamically from assignments plus custom reminders
    final Set<int> dynamicEventDays = {};
    for (final item in _dashboardAssignments) {
      final a = item['assignment'] as SubjectAssignment;
      if (a.deadline != null && a.deadline!.year == _calendarDate.year && a.deadline!.month == _calendarDate.month) {
        dynamicEventDays.add(a.deadline!.day);
      }
    }
    _customReminders.forEach((dateKey, reminders) {
      if (reminders.isNotEmpty) {
        final parts = dateKey.split('-');
        if (parts.length == 3) {
          final yr = int.tryParse(parts[0]);
          final mo = int.tryParse(parts[1]);
          final dy = int.tryParse(parts[2]);
          if (yr == _calendarDate.year && mo == _calendarDate.month && dy != null) {
            dynamicEventDays.add(dy);
          }
        }
      }
    });

    final DateTime now = DateTime.now();

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF121212), // Sleek dark theme
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Calendar Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left_rounded, color: Colors.white, size: 24),
                  onPressed: () {
                    setState(() {
                      _calendarDate = DateTime(_calendarDate.year, _calendarDate.month - 1, 1);
                    });
                  },
                ),
                Text(
                  monthName.substring(0, 3).toUpperCase(),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 1.5,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right_rounded, color: Colors.white, size: 24),
                  onPressed: () {
                    setState(() {
                      _calendarDate = DateTime(_calendarDate.year, _calendarDate.month + 1, 1);
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Weekday labels
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _DayName('S', color: const Color(0xFFE57373)),
                _DayName('M', color: const Color(0xFF888888)),
                _DayName('T', color: const Color(0xFF888888)),
                _DayName('W', color: const Color(0xFF888888)),
                _DayName('T', color: const Color(0xFF888888)),
                _DayName('F', color: const Color(0xFF888888)),
                _DayName('S', color: const Color(0xFF888888)),
              ],
            ),
            const SizedBox(height: 12),
            // Grid of days
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 42,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 8,
                crossAxisSpacing: 6,
                childAspectRatio: 0.6, // Tall and narrow cells
              ),
              itemBuilder: (context, index) {
                final int dayNumber = index - offset + 1;
                int displayDay = dayNumber;
                bool isCurrentMonth = true;

                if (dayNumber <= 0) {
                  final prevDaysInMonth = DateTime(_calendarDate.year, _calendarDate.month, 0).day;
                  displayDay = prevDaysInMonth + dayNumber;
                  isCurrentMonth = false;
                } else if (dayNumber > daysInMonth) {
                  displayDay = dayNumber - daysInMonth;
                  isCurrentMonth = false;
                }

                final bool isSelected = isCurrentMonth &&
                    _selectedDate != null &&
                    _selectedDate!.year == _calendarDate.year &&
                    _selectedDate!.month == _calendarDate.month &&
                    _selectedDate!.day == displayDay;

                final bool isEvent = isCurrentMonth && dynamicEventDays.contains(displayDay);
                final bool isToday = isCurrentMonth &&
                    now.year == _calendarDate.year &&
                    now.month == _calendarDate.month &&
                    now.day == displayDay;

                return InkWell(
                  onTap: !isCurrentMonth
                      ? null
                      : () {
                          setState(() {
                            if (isSelected) {
                              _selectedDate = null;
                            } else {
                              _selectedDate = DateTime(_calendarDate.year, _calendarDate.month, displayDay);
                            }
                          });
                        },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E), // Dark cell background
                      borderRadius: BorderRadius.circular(8),
                      border: isSelected
                          ? Border.all(color: Colors.white.withOpacity(0.8), width: 1.5)
                          : isToday
                              ? Border.all(color: AppColors.authPrimary, width: 1.5)
                              : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            displayDay.toString(),
                            style: TextStyle(
                              color: !isCurrentMonth
                                  ? const Color(0xFF444444) // Muted previous/next month day
                                  : index % 7 == 0
                                      ? const Color(0xFFE57373) // Red Sunday
                                      : Colors.white,
                              fontWeight: (isSelected || isToday) ? FontWeight.bold : FontWeight.normal,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        if (isCurrentMonth && (isEvent || isSelected))
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Icon(
                              Icons.sentiment_satisfied_alt_outlined,
                              color: isSelected ? Colors.white : AppColors.authPrimary,
                              size: 14,
                            ),
                          )
                        else
                          const SizedBox(height: 14),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            // Pill add reminder button at bottom
            GestureDetector(
              onTap: () {
                final targetDate = _selectedDate ?? DateTime(_calendarDate.year, _calendarDate.month, 1);
                _showAddReminderDialog(targetDate);
              },
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF333333),
                  borderRadius: BorderRadius.circular(24),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Add on ${_getMonthName((_selectedDate ?? now).month).substring(0, 3)} ${(_selectedDate ?? now).day}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const Icon(Icons.add, color: Colors.white70, size: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedDateEvents() {
    if (_selectedDate == null) return const SizedBox.shrink();

    final dateStr = '${_getMonthName(_selectedDate!.month)} ${_selectedDate!.day}, ${_selectedDate!.year}';
    final dateKey = '${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}';
    
    // Filter real assignments
    final List<Map<String, dynamic>> dueAssignments = _dashboardAssignments.where((item) {
      final a = item['assignment'] as SubjectAssignment;
      if (a.deadline == null) return false;
      return a.deadline!.year == _selectedDate!.year &&
          a.deadline!.month == _selectedDate!.month &&
          a.deadline!.day == _selectedDate!.day;
    }).toList();

    final List<Map<String, String>> reminders = _customReminders[dateKey] ?? [];

    final hasContent = dueAssignments.isNotEmpty || reminders.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Schedule for $dateStr',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1D4E8F),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.alarm_add_rounded, color: AppColors.authPrimary, size: 22),
              tooltip: 'Add Reminder',
              onPressed: () => _showAddReminderDialog(_selectedDate!),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (!hasContent)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                Icon(Icons.event_note_rounded, color: Colors.black26, size: 20),
                SizedBox(width: 8),
                Text(
                  'No events or reminders scheduled.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.black45,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          )
        else ...[
          // Render custom reminders
          ...reminders.asMap().entries.map((entry) {
            final idx = entry.key;
            final rem = entry.value;
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              color: const Color(0xFFFFFDE7),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.amber.withOpacity(0.3)),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.alarm_on_rounded, color: Colors.amber, size: 20),
                ),
                title: Text(
                  rem['title']!,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.brown),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 2),
                    Text(
                      'Time: ${rem['time']!}',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.amber),
                    ),
                    if (rem['description'] != null && rem['description']!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        rem['description']!,
                        style: const TextStyle(fontSize: 11, color: Colors.black54),
                      ),
                    ],
                  ],
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                  onPressed: () {
                    _verifyPasswordAndExecute('deleting reminder "${rem['title'] ?? ''}"', () async {
                      try {
                        final remId = rem['id'];
                        if (remId != null && remId.isNotEmpty) {
                          await _repo.deleteReminder(remId);
                        }
                        await _load();
                      } catch (e) {
                        if (mounted) AppDialog.result(context, type: DialogType.error, message: 'Failed: $e');
                      }
                    });
                  },
                ),
              ),
            );
          }),
          // Render real assignments due
          ...dueAssignments.map((item) {
            final a = item['assignment'] as SubjectAssignment;
            final sub = item['subject'] as ProfessorSubject;
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              color: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.black.withOpacity(0.05)),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.assignment_late_rounded, color: Colors.red, size: 20),
                ),
                title: Text(
                  a.title,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  'Due for Class: ${sub.name} (${sub.classLabel})',
                  style: const TextStyle(fontSize: 11, color: Colors.black54),
                ),
                trailing: const Icon(Icons.chevron_right_rounded, size: 18, color: Colors.black38),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AssignmentDetailScreen(
                        assignment: a,
                        subjectName: sub.name,
                        totalStudents: sub.studentCount,
                        courseYearSection: sub.classLabel,
                      ),
                    ),
                  );
                },
              ),
            );
          }),
        ],
      ],
    );
  }

  String _getMonthName(int month) {
    const months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
    return months[month - 1];
  }
}

class _DayName extends StatelessWidget {
  final String name;
  final Color? color;
  const _DayName(this.name, {this.color});

  @override
  Widget build(BuildContext context) {
    final bool isWeekend = name == 'Su' || name == 'Sa';
    return SizedBox(
      width: 32,
      child: Text(
        name,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: color ?? (isWeekend ? Colors.redAccent.withOpacity(0.8) : Colors.black54),
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}
