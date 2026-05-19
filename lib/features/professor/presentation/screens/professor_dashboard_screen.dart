import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/state/app_state.dart';
import '../../data/repositories/professor_repository.dart';
import '../../domain/models/professor_subject.dart';
import '../widgets/professor_floating_nav_bar.dart';
import 'professor_subject_screen.dart';

class ProfessorDashboardScreen extends StatefulWidget {
  const ProfessorDashboardScreen({super.key});

  @override
  State<ProfessorDashboardScreen> createState() => _ProfessorDashboardScreenState();
}

class _ProfessorDashboardScreenState extends State<ProfessorDashboardScreen> {
  final _repo = const ProfessorRepository();

  List<ProfessorSubject> _subjects = [];
  bool _loading = true;

  // Selected date for calendar starting at June 2026
  DateTime _calendarDate = DateTime(2026, 6, 1);
  final List<int> _eventDays = [9, 13];

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
                        'STUDYFY',
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
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.black.withOpacity(0.05)),
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              // Header Row
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                child: Row(
                  children: const [
                    Expanded(flex: 2, child: Text('Class', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1D4E8F)))),
                    Expanded(flex: 3, child: Text('Assignment', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1D4E8F)))),
                    Expanded(flex: 3, child: Text('Progress', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1D4E8F)))),
                    Expanded(flex: 2, child: Text('Due Date', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1D4E8F)))),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              _buildAssignmentRow('BSIT 3-1', 'Ethics', 'Lesson 1', '60/60', 1.0, '05/29/2026'),
              const SizedBox(height: 8),
              _buildAssignmentRow('BSIT 4-1', 'PATHFIT', 'Lesson 2', '59/59', 1.0, '05/21/2026'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAssignmentRow(String classCode, String title, String subtitle, String progressText, double progressValue, String dueDate) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              classCode,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87),
            ),
          ),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.grey, fontSize: 11),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  progressText,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                const SizedBox(height: 4),
                SizedBox(
                  width: 80,
                  height: 8,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progressValue,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              dueDate,
              style: const TextStyle(color: Colors.grey, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClassesSection(List<ProfessorSubject> subjects) {
    final displayList = subjects.isNotEmpty
        ? subjects
        : [
            ProfessorSubject(
              id: '1',
              name: 'Art Appreciation',
              courseCode: 'BSIT',
              section: '1',
              yearLevel: 3,
              studentCount: 60,
            ),
            ProfessorSubject(
              id: '2',
              name: 'PATHFIT',
              courseCode: 'BSIT',
              section: '1',
              yearLevel: 4,
              studentCount: 59,
            ),
          ];

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
        Column(
          children: displayList.map((sub) => _buildClassCard(sub)).toList(),
        ),
      ],
    );
  }

  Widget _buildClassCard(ProfessorSubject sub) {
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
                width: 120,
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${sub.courseCode} ${sub.yearLevel} - ${sub.section}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
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
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  alignment: Alignment.center,
                  child: Text(
                    sub.name,
                    style: const TextStyle(
                      fontSize: 16,
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

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.black.withOpacity(0.05)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left, color: Colors.black54),
                  onPressed: () {
                    setState(() {
                      _calendarDate = DateTime(_calendarDate.year, _calendarDate.month - 1, 1);
                    });
                  },
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFE0E0E0)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Text(
                            monthName,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                          const Icon(Icons.arrow_drop_down, size: 20),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFE0E0E0)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Text(
                            yearString,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                          const Icon(Icons.arrow_drop_down, size: 20),
                        ],
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right, color: Colors.black54),
                  onPressed: () {
                    setState(() {
                      _calendarDate = DateTime(_calendarDate.year, _calendarDate.month + 1, 1);
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _DayName('Su'),
                _DayName('Mo'),
                _DayName('Tu'),
                _DayName('We'),
                _DayName('Th'),
                _DayName('Fr'),
                _DayName('Sa'),
              ],
            ),
            const SizedBox(height: 8),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 42,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
              ),
              itemBuilder: (context, index) {
                final int dayNumber = index - offset + 1;
                if (dayNumber <= 0) {
                  return const SizedBox.shrink();
                }

                final bool isEvent = _calendarDate.month == 6 && _calendarDate.year == 2026 && _eventDays.contains(dayNumber);

                if (dayNumber > daysInMonth) {
                  final nextMonthDay = dayNumber - daysInMonth;
                  return Center(
                    child: Text(
                      nextMonthDay.toString(),
                      style: const TextStyle(
                        color: Colors.black26,
                        fontSize: 13,
                      ),
                    ),
                  );
                }

                return Container(
                  decoration: BoxDecoration(
                    color: isEvent ? const Color(0xFF2C2C2C) : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    dayNumber.toString(),
                    style: TextStyle(
                      color: isEvent ? Colors.white : Colors.black87,
                      fontWeight: isEvent ? FontWeight.bold : FontWeight.normal,
                      fontSize: 13,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      }

  String _getMonthName(int month) {
    const months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
    return months[month - 1];
  }
}

class _DayName extends StatelessWidget {
  final String name;
  const _DayName(this.name);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 32,
      child: Text(
        name,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.grey,
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
      ),
    );
  }
}
