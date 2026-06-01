import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/state/app_state.dart';
import '../../data/repositories/student_repository.dart';
import '../../domain/models/student_subject.dart';
import '../widgets/student_floating_nav_bar.dart';

class StudentDashboardScreen extends StatefulWidget {
  const StudentDashboardScreen({super.key});

  @override
  State<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends State<StudentDashboardScreen> {
  final StudentRepository _repo = const StudentRepository();
  bool _loading = true;
  List<StudentSubject> _subjects = [];
  Map<String, dynamic>? _studentProfile;

  // Selected date for calendar
  DateTime _calendarDate = DateTime.now();
  final List<int> _eventDays = [9, 13];

  // List of hardcoded announcements matching the screenshot exactly
  final List<Map<String, String>> _announcements = [
    {
      'subject': 'Ethics',
      'body': "Class, we're online daw until friday. I will just post our lecture here na lng. No online session kc...",
      'date': 'Today 1:00pm',
      'fullText': "Good Afternoon! Class, we're online daw until friday. I will just post our lecture here na lng. No online session kc I'll be having dentist appointment bukas."
    },
    {
      'subject': 'Capstone',
      'body': "Class, we're online daw until friday. I will just post our lecture here na lng. No online session kc...",
      'date': 'Jan 20 3:01pm',
      'fullText': "Good Afternoon! Capstone class is online today. Please review the Capstone guidelines posted under modules and begin drafting your abstract. I will be on leave today."
    }
  ];

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
            child: RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                children: [

                  // Announcement Section
                  _buildSectionTitle('Announcement'),
                  const SizedBox(height: 10),
                  ..._announcements.map((ann) => _buildAnnouncementCard(ann)),

                  const SizedBox(height: 24),
                  // Upcoming Events & Classes Section
                  _buildSectionTitle('Upcoming Events & Classes'),
                  const SizedBox(height: 10),
                  _buildEventCard(
                    icon: Icons.videocam_rounded,
                    title: 'Ethics',
                    subtitle: 'Monday 3pm - 7pm',
                  ),
                  _buildEventCard(
                    icon: Icons.school_rounded,
                    title: 'Ethics',
                    subtitle: 'Monday 3pm - 7pm',
                  ),

                  const SizedBox(height: 24),
                  // Course List Section
                  _buildSectionTitle('Course List'),
                  const SizedBox(height: 10),
                  _loading
                      ? const Center(child: CircularProgressIndicator())
                      : _subjects.isEmpty
                          ? const Center(child: Text('No courses found.'))
                          : Column(
                              children: _subjects.map((sub) => _buildCourseCard(sub)).toList(),
                            ),

                  const SizedBox(height: 24),
                  // Calendar Widget
                  _buildCalendarWidget(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
          const StudentFloatingNavBar(currentIndex: 0),
        ],
      ),
    );
  }



  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Color(0xFF0A5C36), // Green Color
      ),
    );
  }

  Widget _buildAnnouncementCard(Map<String, String> ann) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFEEEEEE)),
      ),
      child: InkWell(
        onTap: () => _showAnnouncementDetail(ann),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Time / Date indicator on left
              SizedBox(
                width: 70,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ann['date']!.split(' ').first,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.black54,
                      ),
                    ),
                    Text(
                      ann['date']!.split(' ').length > 1
                          ? ann['date']!.split(' ')[1]
                          : '',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Line separator
              Container(
                height: 40,
                width: 2,
                color: const Color(0xFF0A5C36).withOpacity(0.3),
              ),
              const SizedBox(width: 14),
              // Announcement subject and message snippet
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ann['subject']!,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0A5C36),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      ann['body']!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEventCard({required IconData icon, required String title, required String subtitle}) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFEEEEEE)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF0A5C36).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: const Color(0xFF0A5C36), size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCourseCard(StudentSubject sub) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFEEEEEE)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF0A5C36).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.book_rounded, color: const Color(0xFF0A5C36), size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sub.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    sub.professorName,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Interactive Custom Calendar Widget matching Screenshot 1
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
        side: const BorderSide(color: Color(0xFFEEEEEE)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Calendar Header with month and year picker dropdowns
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
            // Days of the week headers
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
            // Grid of days
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 42, // 6 weeks maximum
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
              ),
              itemBuilder: (context, index) {
                final int dayNumber = index - offset + 1;
                if (dayNumber <= 0 || dayNumber > daysInMonth) {
                  return const SizedBox.shrink();
                }

                // Check if this day is an event day (e.g. Sep 9 and 13)
                final bool isEvent = _calendarDate.month == DateTime.now().month && _calendarDate.year == DateTime.now().year && _eventDays.contains(dayNumber);

                return Container(
                  decoration: BoxDecoration(
                    color: isEvent ? const Color(0xFF222222) : Colors.transparent,
                    shape: BoxShape.circle,
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

  void _showAnnouncementDetail(Map<String, String> ann) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Bottom sheet handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Announcement Detail Header
              const Text(
                'Announcement',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0A5C36),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Subject: ${ann['subject']}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              Text(
                'Posted: ${ann['date']}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              const Divider(height: 24, thickness: 1),
              const SizedBox(height: 8),
              // Message Text
              Text(
                ann['fullText'] ?? ann['body']!,
                style: const TextStyle(
                  fontSize: 15,
                  color: Colors.black87,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0A5C36),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Close',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _getMonthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
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
