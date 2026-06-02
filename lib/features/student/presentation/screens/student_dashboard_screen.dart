import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/state/app_state.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../data/repositories/student_repository.dart';
import '../widgets/student_floating_nav_bar.dart';

class StudentDashboardScreen extends StatefulWidget {
  const StudentDashboardScreen({super.key});

  @override
  State<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends State<StudentDashboardScreen> {
  final StudentRepository _repo = const StudentRepository();
  bool _loading = true;
  Map<String, dynamic>? _studentProfile;

  // Selected date for calendar
  DateTime _calendarDate = DateTime.now();
  DateTime? _selectedDate = DateTime.now();

  // Real calendar events from backend: date -> list of {title, type}
  Map<DateTime, List<Map<String, String>>> _calendarEvents = {};

  // Key format: "yyyy-MM-dd" -> List of reminder maps
  Map<String, List<Map<String, String>>>? __customReminders;
  Map<String, List<Map<String, String>>> get _customReminders {
    __customReminders ??= {};
    return __customReminders!;
  }

  void _showAddReminderDialog(DateTime date) {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    TimeOfDay selectedTime = TimeOfDay.now();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Widget buildDialogField({
              required TextEditingController controller,
              required String label,
              required String hint,
              required IconData prefixIcon,
            }) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: controller,
                    decoration: InputDecoration(
                      hintText: hint,
                      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                      prefixIcon: Icon(prefixIcon, color: const Color(0xFF0A5C36), size: 18),
                      filled: true,
                      fillColor: const Color(0xFFF5F6F9),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF0A5C36), width: 1.5),
                      ),
                    ),
                  ),
                ],
              );
            }

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: Row(
                children: const [
                  Icon(Icons.alarm_add_rounded, color: Color(0xFF0A5C36)),
                  SizedBox(width: 8),
                  Text(
                    'Add Reminder',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0A5C36),
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'For: ${_getMonthName(date.month)} ${date.day}, ${date.year}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 16),
                    buildDialogField(
                      controller: titleController,
                      label: 'Reminder Title',
                      hint: 'e.g., Prepare Lecture Notes',
                      prefixIcon: Icons.title_rounded,
                    ),
                    const SizedBox(height: 16),
                    buildDialogField(
                      controller: descController,
                      label: 'Description',
                      hint: 'e.g., Read chapter 4 before class (optional)',
                      prefixIcon: Icons.description_outlined,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Select Time:',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87),
                        ),
                        InkWell(
                          onTap: () async {
                            final TimeOfDay? time = await showTimePicker(
                              context: context,
                              initialTime: selectedTime,
                            );
                            if (time != null) {
                              setDialogState(() {
                                selectedTime = time;
                              });
                            }
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F6F9),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.access_time_rounded, size: 16, color: Color(0xFF0A5C36)),
                                const SizedBox(width: 8),
                                Text(
                                  selectedTime.format(context),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey.shade600,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0A5C36),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  onPressed: () {
                    if (titleController.text.trim().isEmpty) {
                      AppDialog.result(context, type: DialogType.error, message: 'Please enter a reminder title.');
                      return;
                    }

                    final dateKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

                    setState(() {
                      if (!_customReminders.containsKey(dateKey)) {
                        _customReminders[dateKey] = [];
                      }
                      _customReminders[dateKey]!.add({
                        'title': titleController.text.trim(),
                        'time': selectedTime.format(context),
                        'description': descController.text.trim(),
                      });
                    });

                    Navigator.pop(context);
                  },
                  child: const Text('Save', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final profile = await _repo.fetchStudentProfile();
      final events = await _repo.fetchCalendarEvents();
      if (!mounted) return;
      setState(() {
        _studentProfile = profile;
        _calendarEvents = events;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  String _formatDateTime(String? dt) {
    if (dt == null) return 'TBA';
    try {
      final date = DateTime.parse(dt).toLocal();
      return '${date.month}/${date.day}/${date.year} at ${date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour)}:${date.minute.toString().padLeft(2, '0')} ${date.hour >= 12 ? 'PM' : 'AM'}';
    } catch (_) {
      return 'TBA';
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
            child: RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                children: [
                  // Announcement Section
                  _buildSectionTitle('Announcement'),
                  const SizedBox(height: 10),
                  if (context.watch<AppState>().announcements.isEmpty)
                    Card(
                      elevation: 0,
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: Color(0xFFEEEEEE)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0A5C36).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.campaign_outlined, color: Color(0xFF0A5C36), size: 24),
                            ),
                            const SizedBox(width: 14),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'No announcements yet',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'Check back later for updates from your professors.',
                                    style: TextStyle(fontSize: 11, color: Colors.black54),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ...context.watch<AppState>().announcements.map(
                    (ann) => _buildAnnouncementCard(ann),
                  ),

                  const SizedBox(height: 24),
                  // Upcoming Events & Classes Section
                  _buildSectionTitle('Upcoming Events & Classes'),
                  const SizedBox(height: 10),
                  if (context.watch<AppState>().meetings.isEmpty)
                    Card(
                      elevation: 0,
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: Color(0xFFEEEEEE)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0A5C36).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.event_busy_outlined, color: Color(0xFF0A5C36), size: 24),
                            ),
                            const SizedBox(width: 14),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'No upcoming events',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'Any upcoming virtual classes or events will appear here.',
                                    style: TextStyle(fontSize: 11, color: Colors.black54),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ...context.watch<AppState>().meetings.map(
                    (meet) => _buildEventCard(
                      icon: Icons.videocam_rounded,
                      title: meet['title'] ?? 'Meeting',
                      subtitle: _formatDateTime(meet['start_time']),
                    ),
                  ),

                  const SizedBox(height: 24),
                  // My Class Section
                  _buildSectionTitle('My Class'),
                  const SizedBox(height: 10),
                  (() {
                    final studentSubjects = context
                        .watch<AppState>()
                        .studentSubjects;
                    return _loading && studentSubjects.isEmpty
                        ? const Center(child: CircularProgressIndicator())
                        : studentSubjects.isEmpty
                        ? const Center(child: Text('No courses found.'))
                        : Column(
                            children: studentSubjects
                                .map((sub) => _buildCourseCard(sub))
                                .toList(),
                          );
                  })(),

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
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
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

  Widget _buildEventCard({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
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
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCourseCard(Map<String, dynamic> sub) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFEEEEEE)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          context.pushNamed(AppRoutes.studentModules);
        },
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
                child: const Icon(
                  Icons.book_rounded,
                  color: const Color(0xFF0A5C36),
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sub['subject_name'] ?? 'Unknown Subject',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      sub['course_code'] ?? 'Unknown Course',
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

  // Interactive Custom Calendar Widget matching Screenshot 1
  Widget _buildCalendarWidget() {
    final String monthName = _getMonthName(_calendarDate.month);
    final String yearString = _calendarDate.year.toString();

    // Get number of days in month
    final int daysInMonth = DateTime(
      _calendarDate.year,
      _calendarDate.month + 1,
      0,
    ).day;
    // Get day of the week for first day of month (1 = Monday, 7 = Sunday)
    final int firstWeekday = DateTime(
      _calendarDate.year,
      _calendarDate.month,
      1,
    ).weekday;
    final int offset = firstWeekday == 7
        ? 0
        : firstWeekday; // Adjust so Sunday is 0

    // Get event days from real backend data + custom reminders
    final Set<int> dynamicEventDays = {};

    // Add days from real backend events (assignments + quizzes)
    _calendarEvents.forEach((date, events) {
      if (date.year == _calendarDate.year &&
          date.month == _calendarDate.month) {
        dynamicEventDays.add(date.day);
      }
    });

    // Add days from custom reminders
    _customReminders.forEach((dateKey, reminders) {
      if (reminders.isNotEmpty) {
        final parts = dateKey.split('-');
        if (parts.length == 3) {
          final yr = int.tryParse(parts[0]);
          final mo = int.tryParse(parts[1]);
          final dy = int.tryParse(parts[2]);
          if (yr == _calendarDate.year &&
              mo == _calendarDate.month &&
              dy != null) {
            dynamicEventDays.add(dy);
          }
        }
      }
    });

    final DateTime now = DateTime.now();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: const Color(0xFFF3F3F3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.chevron_left_rounded,
                    color: Colors.black87,
                    size: 24,
                  ),
                  onPressed: () {
                    setState(() {
                      _calendarDate = DateTime(
                        _calendarDate.year,
                        _calendarDate.month - 1,
                        1,
                      );
                    });
                  },
                ),
                Row(
                  children: [
                    PopupMenuButton<int>(
                      tooltip: 'Select Month',
                      initialValue: _calendarDate.month,
                      onSelected: (int selectedMonth) {
                        setState(() {
                          _calendarDate = DateTime(
                            _calendarDate.year,
                            selectedMonth,
                            1,
                          );
                        });
                      },
                      itemBuilder: (BuildContext context) {
                        const monthsList = [
                          'January',
                          'February',
                          'March',
                          'April',
                          'May',
                          'June',
                          'July',
                          'August',
                          'September',
                          'October',
                          'November',
                          'December',
                        ];
                        return List.generate(12, (index) {
                          return PopupMenuItem<int>(
                            value: index + 1,
                            child: Text(monthsList[index]),
                          );
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F5F7),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Text(
                              monthName,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              size: 18,
                              color: Colors.black54,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    PopupMenuButton<int>(
                      tooltip: 'Select Year',
                      initialValue: _calendarDate.year,
                      onSelected: (int selectedYear) {
                        setState(() {
                          _calendarDate = DateTime(
                            selectedYear,
                            _calendarDate.month,
                            1,
                          );
                        });
                      },
                      itemBuilder: (BuildContext context) {
                        final currentYear = DateTime.now().year;
                        return List.generate(11, (index) {
                          final yr = (currentYear - 5) + index;
                          return PopupMenuItem<int>(
                            value: yr,
                            child: Text(yr.toString()),
                          );
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F5F7),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Text(
                              yearString,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              size: 18,
                              color: Colors.black54,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.black87,
                    size: 24,
                  ),
                  onPressed: () {
                    setState(() {
                      _calendarDate = DateTime(
                        _calendarDate.year,
                        _calendarDate.month + 1,
                        1,
                      );
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
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
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 42,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 6,
                crossAxisSpacing: 6,
              ),
              itemBuilder: (context, index) {
                final int dayNumber = index - offset + 1;
                if (dayNumber <= 0 || dayNumber > daysInMonth) {
                  return const SizedBox.shrink();
                }

                final bool isSelected =
                    _selectedDate != null &&
                    _selectedDate!.year == _calendarDate.year &&
                    _selectedDate!.month == _calendarDate.month &&
                    _selectedDate!.day == dayNumber;

                final bool isEvent = dynamicEventDays.contains(dayNumber);
                final bool isToday =
                    now.year == _calendarDate.year &&
                    now.month == _calendarDate.month &&
                    now.day == dayNumber;

                return InkWell(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _selectedDate = null;
                      } else {
                        _selectedDate = DateTime(
                          _calendarDate.year,
                          _calendarDate.month,
                          dayNumber,
                        );
                      }
                    });
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF0A5C36)
                          : isEvent
                          ? const Color(0xFF0A5C36).withOpacity(0.08)
                          : Colors.transparent,
                      shape: BoxShape.circle,
                      border: isToday && !isSelected
                          ? Border.all(
                              color: const Color(0xFF0A5C36),
                              width: 1.5,
                            )
                          : null,
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: const Color(
                                  0xFF0A5C36,
                                ).withOpacity(0.25),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          dayNumber.toString(),
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : isEvent
                                ? const Color(0xFF0A5C36)
                                : Colors.black87,
                            fontWeight: (isSelected || isEvent || isToday)
                                ? FontWeight.bold
                                : FontWeight.normal,
                            fontSize: 13,
                          ),
                        ),
                        if (isEvent) ...[
                          const SizedBox(height: 2),
                          Container(
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.white
                                  : const Color(0xFF0A5C36),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ] else
                          const SizedBox(height: 6),
                      ],
                    ),
                  ),
                );
              },
            ),
            if (_selectedDate != null) ...[
              const Divider(height: 40, thickness: 1, color: Color(0xFFF1F1F1)),
              _buildSelectedDateEvents(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedDateEvents() {
    if (_selectedDate == null) return const SizedBox.shrink();

    final dateStr =
        '${_getMonthName(_selectedDate!.month)} ${_selectedDate!.day}, ${_selectedDate!.year}';
    final dateKey =
        '${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}';

    // Real events from backend
    final selectedDay = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
    );
    final List<Map<String, String>> backendEvents =
        _calendarEvents[selectedDay] ?? [];

    // Custom reminders
    final List<Map<String, String>> reminders = _customReminders[dateKey] ?? [];

    final hasContent = backendEvents.isNotEmpty || reminders.isNotEmpty;

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
                  color: Color(0xFF0A5C36),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(
                Icons.alarm_add_rounded,
                color: Color(0xFF0A5C36),
                size: 22,
              ),
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
          // Backend events (assignments & quizzes)
          ...backendEvents.map((evt) {
            final isQuiz = evt['type'] == 'quiz';
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              color: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: isQuiz
                      ? Colors.blue.withOpacity(0.3)
                      : Colors.orange.withOpacity(0.3),
                ),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isQuiz
                        ? Colors.blue.withOpacity(0.1)
                        : Colors.orange.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isQuiz ? Icons.quiz_rounded : Icons.assignment_rounded,
                    color: isQuiz ? Colors.blue : Colors.orange,
                    size: 20,
                  ),
                ),
                title: Text(
                  evt['title'] ?? '',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  isQuiz ? 'Quiz Deadline' : 'Assignment Deadline',
                  style: TextStyle(
                    fontSize: 11,
                    color: isQuiz ? Colors.blue : Colors.orange,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            );
          }),
          // Custom reminders
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
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.alarm_on_rounded,
                    color: Colors.amber,
                    size: 20,
                  ),
                ),
                title: Text(
                  rem['title']!,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.brown,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Time: ${rem['time']!}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.amber,
                      ),
                    ),
                    if (rem['description'] != null &&
                        rem['description']!.isNotEmpty)
                      Text(
                        rem['description']!,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.black54,
                        ),
                      ),
                  ],
                ),
                trailing: IconButton(
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    color: Colors.redAccent,
                    size: 20,
                  ),
                  onPressed: () =>
                      setState(() => _customReminders[dateKey]!.removeAt(idx)),
                ),
              ),
            );
          }),
        ],
      ],
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
                style: const TextStyle(fontSize: 12, color: Colors.grey),
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
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[month - 1];
  }
}

class _DayName extends StatelessWidget {
  final String name;
  const _DayName(this.name);

  @override
  Widget build(BuildContext context) {
    final bool isWeekend = name == 'Su' || name == 'Sa';
    return SizedBox(
      width: 32,
      child: Text(
        name,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: isWeekend ? Colors.redAccent.withOpacity(0.8) : Colors.black54,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}
