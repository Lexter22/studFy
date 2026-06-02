import 'package:flutter/foundation.dart';

import '../../features/auth/domain/models/app_user.dart';
import '../../features/admin/data/repositories/supabase_admin_repository.dart';
import '../../features/admin/domain/models/instructor.dart';
import '../../features/admin/domain/models/student.dart';
import '../../features/auth/domain/enums/user_role.dart';
import 'supabase_event_repository.dart';

class AppState extends ChangeNotifier {
  final SupabaseAdminRepository _adminRepository =
      const SupabaseAdminRepository();
  final SupabaseEventRepository _eventRepository =
      const SupabaseEventRepository();

  bool _isAuthenticated = false;
  AppUser? _currentUser;

  bool get isAuthenticated => _isAuthenticated;
  AppUser? get currentUser => _currentUser;

  final ValueNotifier<String?> accessDeniedNotifier = ValueNotifier<String?>(
    null,
  );
  final ValueNotifier<List<Map<String, String>>>
  pendingSubjectRequestsNotifier = ValueNotifier<List<Map<String, String>>>(
    const [],
  );
  final ValueNotifier<List<Map<String, String>>>
  pendingInstructorRequestsNotifier = ValueNotifier<List<Map<String, String>>>(
    const [],
  );
  final ValueNotifier<List<Map<String, String>>> subjectOfferingsNotifier =
      ValueNotifier<List<Map<String, String>>>(const []);
  final ValueNotifier<List<Instructor>> instructorsNotifier =
      ValueNotifier<List<Instructor>>(const []);
  final ValueNotifier<List<StudentData>> studentsNotifier =
      ValueNotifier<List<StudentData>>(const []);
  final ValueNotifier<List<Map<String, dynamic>>> enrollmentCodesNotifier =
      ValueNotifier<List<Map<String, dynamic>>>(const []);

  List<Map<String, String>> get pendingSubjectRequests =>
      pendingSubjectRequestsNotifier.value;
  List<Map<String, String>> get pendingInstructorRequests =>
      pendingInstructorRequestsNotifier.value;
  List<Map<String, String>> get subjectOfferings =>
      subjectOfferingsNotifier.value;
  List<Instructor> get instructors => instructorsNotifier.value;
  List<StudentData> get students => studentsNotifier.value;
  List<Map<String, dynamic>> get enrollmentCodes =>
      enrollmentCodesNotifier.value;

  void removeSubjectRequest(String name, String status) {
    final newList = List<Map<String, String>>.from(
      pendingSubjectRequestsNotifier.value,
    );
    newList.removeWhere((r) => r['name'] == name && r['status'] == status);
    pendingSubjectRequestsNotifier.value = newList;
  }

  void removeInstructorRequest(String name, String request) {
    final newList = List<Map<String, String>>.from(
      pendingInstructorRequestsNotifier.value,
    );
    newList.removeWhere((r) => r['name'] == name && r['request'] == request);
    pendingInstructorRequestsNotifier.value = newList;
  }

  Future<void> resolveInstructorRequest({
    required String requestId,
    required bool approve,
  }) async {
    await _adminRepository.resolveRoleRequest(
      requestId: requestId,
      approve: approve,
    );
    await loadAdminData();
  }

  void removeSubjectOffering(
    String name,
    String course,
    String section,
    String professor,
  ) {
    final newList = List<Map<String, String>>.from(
      subjectOfferingsNotifier.value,
    );
    newList.removeWhere(
      (subject) =>
          subject['name'] == name &&
          subject['course'] == course &&
          subject['section'] == section &&
          subject['professor'] == professor,
    );
    subjectOfferingsNotifier.value = newList;
  }

  Future<void> updateInstructor({
    required String profileId,
    required String name,
    required String department,
  }) async {
    await _adminRepository.updateInstructor(
      profileId: profileId,
      name: name,
      department: department,
    );
    await loadAdminData();
  }

  Future<void> updateStudent({
    required String profileId,
    required String name,
    required String course,
    required String yearSection,
  }) async {
    await _adminRepository.updateStudent(
      profileId: profileId,
      name: name,
      course: course,
      yearSection: yearSection,
    );
    await loadAdminData();
  }

  Future<void> deleteProfile(String profileId) async {
    await _adminRepository.deleteProfile(profileId);
    await loadAdminData();
  }

  Future<String> createInstructor({
    required String firstName,
    required String lastName,
    required String email,
    required String department,
    String? instructorId,
  }) async {
    final defaultPassword = await _adminRepository.createInstructor(
      firstName: firstName,
      lastName: lastName,
      email: email,
      department: department,
      instructorId: instructorId,
    );
    await loadAdminData();
    return defaultPassword;
  }

  Future<void> createSubject({
    required String subjectName,
    required String courseCode,
    required String section,
    required int yearLevel,
    int? semester,
    String? academicYear,
    String? room,
    String? scheduleLabel,
  }) async {
    await _adminRepository.createSubject(
      subjectName: subjectName,
      courseCode: courseCode,
      section: section,
      yearLevel: yearLevel,
      semester: semester,
      academicYear: academicYear,
      room: room,
      scheduleLabel: scheduleLabel,
    );
    await loadAdminData();
  }

  Future<void> updateSubject({
    required String subjectId,
    required String subjectName,
    required String courseCode,
    required String section,
    String? room,
    String? scheduleLabel,
  }) async {
    await _adminRepository.updateSubject(
      subjectId: subjectId,
      subjectName: subjectName,
      courseCode: courseCode,
      section: section,
      room: room,
      scheduleLabel: scheduleLabel,
    );
    await loadAdminData();
  }

  Future<void> deleteSubject(String subjectId) async {
    await _adminRepository.deleteSubject(subjectId);
    await loadAdminData();
  }

  Future<void> assignProfessorToSubject({
    required String subjectId,
    required String profileId,
  }) async {
    await _adminRepository.assignProfessorToSubject(
      subjectId: subjectId,
      profileId: profileId,
    );
    await loadAdminData();
  }

  Future<void> enrollStudentInSubject({
    required String studentProfileId,
    required String subjectOfferingId,
  }) async {
    await _adminRepository.enrollStudentInSubject(
      studentProfileId: studentProfileId,
      subjectOfferingId: subjectOfferingId,
    );
    await loadAdminData();
  }

  Future<void> unenrollStudentFromSubject({
    required String studentProfileId,
    required String subjectOfferingId,
  }) async {
    await _adminRepository.unenrollStudentFromSubject(
      studentProfileId: studentProfileId,
      subjectOfferingId: subjectOfferingId,
    );
    await loadAdminData();
  }

  Future<List<String>> fetchStudentsEnrolledInSubject(
    String subjectOfferingId,
  ) async {
    return _adminRepository.fetchStudentsEnrolledInSubject(subjectOfferingId);
  }

  Future<List<String>> fetchEnrolledSubjectIds(String studentProfileId) async {
    return _adminRepository.fetchEnrolledSubjectIds(studentProfileId);
  }

  Future<String> createStudent({
    required String firstName,
    required String lastName,
    required String email,
    required String courseCode,
    required String yearSection,
    String? studentNumber,
  }) async {
    final defaultPassword = await _adminRepository.createStudent(
      firstName: firstName,
      lastName: lastName,
      email: email,
      courseCode: courseCode,
      yearSection: yearSection,
      studentNumber: studentNumber,
    );
    await loadAdminData();
    return defaultPassword;
  }

  Future<void> createEnrollmentCode({
    required String code,
    required String courseCode,
    required String yearSection,
    int? maxUses,
    DateTime? expiresAt,
  }) async {
    await _adminRepository.createEnrollmentCode(
      code: code,
      courseCode: courseCode,
      yearSection: yearSection,
      maxUses: maxUses,
      expiresAt: expiresAt,
    );
    await loadAdminData();
  }

  Future<void> toggleEnrollmentCode(String id, bool isActive) async {
    await _adminRepository.toggleEnrollmentCode(id, isActive);
    await loadAdminData();
  }

  Future<void> deleteEnrollmentCode(String id) async {
    await _adminRepository.deleteEnrollmentCode(id);
    await loadAdminData();
  }

  Future<void> loadAdminData() async {
    try {
      final requests = await _adminRepository.fetchRequests();
      final subjectRequests = requests
          .where(_isSubjectRequest)
          .map(_requestCard)
          .toList();
      final instructorRequests = requests
          .where(_isInstructorRequest)
          .map(_requestCard)
          .toList();

      pendingSubjectRequestsNotifier.value = subjectRequests;
      pendingInstructorRequestsNotifier.value = instructorRequests;
      subjectOfferingsNotifier.value = await _adminRepository
          .fetchSubjectOfferings();
      instructorsNotifier.value = await _adminRepository.fetchInstructors();
      studentsNotifier.value = await _adminRepository.fetchStudents();
      enrollmentCodesNotifier.value = await _adminRepository
          .fetchEnrollmentCodes();
    } catch (error) {
      debugPrint('Failed to load admin data: $error');
      clearAdminData();
    } finally {
      notifyListeners();
    }
  }

  void clearAdminData() {
    pendingSubjectRequestsNotifier.value = const [];
    pendingInstructorRequestsNotifier.value = const [];
    subjectOfferingsNotifier.value = const [];
    instructorsNotifier.value = const [];
    studentsNotifier.value = const [];
    enrollmentCodesNotifier.value = const [];
  }

  void login([AppUser? user]) {
    if (_isAuthenticated) {
      _currentUser = user ?? _currentUser;
      return;
    }
    _isAuthenticated = true;
    _currentUser = user;
    if (user != null) loadEventsAndTasks();
    notifyListeners();
  }

  void logout() {
    if (!_isAuthenticated) return;
    _isAuthenticated = false;
    _currentUser = null;
    clearAdminData();
    _meetings = [];
    _quizzes = [];
    _activities = [];
    _tasks = [];
    _studentSubjects = [];
    notifyListeners();
  }

  void syncAuthState(AppUser? user) {
    _isAuthenticated = user != null;
    _currentUser = user;
    if (user != null) loadEventsAndTasks();
    notifyListeners();
  }

  bool get hasUser => _currentUser != null;

  bool _isSubjectRequest(Map<String, String> request) {
    switch (request['kind']) {
      case 'subject_update':
      case 'class_creation':
      case 'schedule_conflict':
        return true;
      default:
        return false;
    }
  }

  bool _isInstructorRequest(Map<String, String> request) {
    switch (request['kind']) {
      case 'account_edit':
      case 'role_assignment':
        return true;
      default:
        return false;
    }
  }

  Map<String, String> _requestCard(Map<String, String> request) {
    return {
      'id': request['id'] ?? '',
      'name': request['name'] ?? '',
      'status': request['status'] ?? 'Pending Request',
      'request': request['status'] ?? 'Pending Request',
      'requester_profile_id': request['requester_profile_id'] ?? '',
      'kind': request['kind'] ?? '',
      'details': request['details'] ?? '',
      'requested_role': request['requested_role'] ?? '',
    };
  }

  // Global announcements list
  final List<Map<String, String>> _announcements = [];

  List<Map<String, String>> get announcements => _announcements;

  void addAnnouncement(String subject, String text, DateTime date) {
    final dateStr = _formatAnnouncementDate(date);
    final snippet = text.length > 80 ? '${text.substring(0, 80)}...' : text;
    _announcements.insert(0, {
      'subject': subject,
      'body': snippet,
      'date': dateStr,
      'fullText': text,
    });
    notifyListeners();
  }

  void deleteAnnouncement(Map<String, String> ann) {
    _announcements.remove(ann);
    notifyListeners();
  }

  String _formatAnnouncementDate(DateTime dt) {
    final now = DateTime.now();
    final isToday =
        dt.year == now.year && dt.month == now.month && dt.day == now.day;
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final m = months[dt.month - 1];
    final hr = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final ampm = dt.hour >= 12 ? 'pm' : 'am';
    final min = dt.minute.toString().padLeft(2, '0');
    if (isToday) {
      return 'Today $hr:$min$ampm';
    } else {
      return '$m ${dt.day} $hr:$min$ampm';
    }
  }

  // Live Events & Tasks Backend State
  List<Map<String, dynamic>> _meetings = [];
  List<Map<String, dynamic>> _quizzes = [];
  List<Map<String, dynamic>> _activities = [];
  List<Map<String, dynamic>> _tasks = [];

  // Student's real enrolled subjects
  List<Map<String, dynamic>> _studentSubjects = [];
  List<Map<String, dynamic>> get studentSubjects => _studentSubjects;

  List<Map<String, dynamic>> get meetings => _meetings;
  List<Map<String, dynamic>> get quizzes => _quizzes;
  List<Map<String, dynamic>> get activities => _activities;
  List<Map<String, dynamic>> get tasks => _tasks;

  // A combined, unified To-Do list for the UI (Activities, Quizzes, and incomplete Tasks)
  List<Map<String, dynamic>> get unifiedToDoList {
    final List<Map<String, dynamic>> list = [];

    // 1. Add class activities & quizzes
    for (final event in [..._activities, ..._quizzes]) {
      list.add({
        'id': event['id'],
        'title': event['title'],
        'description': event['description'],
        'dueDate': event['end_time'] ?? event['start_time'],
        'type': event['event_type'], // 'activity' or 'quiz'
        'subject': event['subject_offerings']?['subject_name'] ?? 'Class Event',
      });
    }

    // 2. Add pending personal tasks
    for (final task in _tasks.where((t) => t['is_completed'] != true)) {
      list.add({
        'id': task['id'],
        'title': task['title'],
        'description': task['description'],
        'dueDate': task['due_date'],
        'type': 'task',
        'subject': 'Personal',
      });
    }

    // 3. Sort by closest deadline
    list.sort((a, b) {
      if (a['dueDate'] == null) return 1;
      if (b['dueDate'] == null) return -1;
      return DateTime.parse(
        a['dueDate'],
      ).compareTo(DateTime.parse(b['dueDate']));
    });

    return list;
  }

  Future<void> loadEventsAndTasks() async {
    if (_currentUser == null) return;

    try {
      // Load Events (Quizzes, Activities, Meetings)
      final eventsData = await _eventRepository.fetchClassEvents();

      _meetings = eventsData.where((e) => e['event_type'] == 'meeting').map((
        e,
      ) {
        String platform = 'Unknown';
        String link = '';
        final desc = e['description']?.toString() ?? '';
        if (desc.contains(' - ')) {
          final parts = desc.split(' - ');
          platform = parts[0];
          link = parts.sublist(1).join(' - ');
        } else {
          platform = desc;
        }

        String dateStr = '';
        String timeStr = '';
        final startStr = e['start_time']?.toString();
        if (startStr != null) {
          final dt = DateTime.tryParse(startStr)?.toLocal();
          if (dt != null) {
            dateStr =
                '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
            final hr = dt.hour > 12
                ? dt.hour - 12
                : (dt.hour == 0 ? 12 : dt.hour);
            final ampm = dt.hour >= 12 ? 'PM' : 'AM';
            timeStr = '$hr:${dt.minute.toString().padLeft(2, '0')} $ampm';
          }
        }

        return {
          'id': e['id'],
          'subject': e['subject_offerings']?['subject_name'] ?? 'Class Event',
          'title': e['title'] ?? 'Meeting',
          'platform': platform,
          'link': link,
          'date': dateStr,
          'time': timeStr,
          'start_time': e['start_time'],
        };
      }).toList();
      _quizzes = eventsData.where((e) => e['event_type'] == 'quiz').toList();
      _activities = eventsData
          .where((e) => e['event_type'] == 'activity')
          .toList();

      // Load Tasks (Only applicable for students)
      if (_currentUser!.role.value == 'student') {
        _tasks = await _eventRepository.fetchStudentTasks(_currentUser!.uid);

        // Fetch real quizzes and assignments created by professors
        final profQuizzes = await _eventRepository.fetchStudentQuizzes(
          _currentUser!.uid,
        );
        final profAssignments = await _eventRepository.fetchStudentAssignments(
          _currentUser!.uid,
        );

        for (final q in profQuizzes) {
          _quizzes.add({
            'id': q['id'],
            'title': q['title'] ?? 'Quiz',
            'description': q['description'],
            'end_time': q['deadline'],
            'event_type': 'quiz',
            'subject_offerings': q['subject_offerings'],
          });
        }

        for (final a in profAssignments) {
          _activities.add({
            'id': a['id'],
            'title': a['title'] ?? 'Assignment',
            'description': a['description'],
            'end_time': a['deadline'],
            'event_type': 'activity',
            'subject_offerings': a['subject_offerings'],
          });
        }

        // Load Live Enrolled Subjects
        final enrollments = await _eventRepository.fetchStudentSubjects(
          _currentUser!.uid,
        );
        _studentSubjects = enrollments
            .map((e) => e['subject_offerings'])
            .where((s) => s != null)
            .cast<Map<String, dynamic>>()
            .toList();
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error loading events/tasks: $e');
    }
  }

  // Generalized method to add any class event
  Future<void> addClassEvent({
    required String subjectOfferingId,
    required String eventType, // 'quiz', 'activity', 'meeting'
    required String title,
    String? description,
    DateTime? startTime,
    DateTime? endTime,
  }) async {
    // Clean up any newlines or weird spacing from the UI string
    String cleanSubject = subjectOfferingId
        .replaceAll('\n', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    String resolvedSubjectId = cleanSubject;

    // If subjectOfferingId is not a UUID, look it up in the database
    if (!RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    ).hasMatch(cleanSubject)) {
      final fetchedId = await _eventRepository.getSubjectId(cleanSubject);
      if (fetchedId != null) {
        resolvedSubjectId = fetchedId;
      } else {
        debugPrint(
          'Error: Cannot add event. Subject "$cleanSubject" not found in DB.',
        );
        return; // Abort instead of hitting DB with an invalid UUID string
      }
    }

    try {
      await _eventRepository.addClassEvent(
        subjectOfferingId: resolvedSubjectId,
        eventType: eventType,
        title: title,
        description: description,
        startTime: startTime,
        endTime: endTime,
        createdBy: _currentUser?.uid,
      );
      await loadEventsAndTasks();
    } catch (e) {
      debugPrint('Error adding event: $e');
    }
  }

  Future<void> deleteClassEvent(String id) async {
    try {
      await _eventRepository.deleteClassEvent(id);
      await loadEventsAndTasks();
    } catch (e) {
      debugPrint('Error deleting event: $e');
    }
  }

  // Methods for Student Tasks
  Future<void> addStudentTask({
    required String title,
    String? description,
    DateTime? dueDate,
  }) async {
    if (_currentUser?.uid == null) return;
    try {
      await _eventRepository.addStudentTask(
        studentProfileId: _currentUser!.uid,
        title: title,
        description: description,
        dueDate: dueDate,
      );
      await loadEventsAndTasks();
    } catch (e) {
      debugPrint('Error adding task: $e');
    }
  }

  Future<void> toggleTaskCompletion(String id, bool isCompleted) async {
    try {
      await _eventRepository.toggleTaskCompletion(id, isCompleted);
      await loadEventsAndTasks();
    } catch (e) {
      debugPrint('Error toggling task completion: $e');
    }
  }

  Future<void> deleteStudentTask(String id) async {
    try {
      await _eventRepository.deleteStudentTask(id);
      await loadEventsAndTasks();
    } catch (e) {
      debugPrint('Error deleting task: $e');
    }
  }

  // Legacy aliases for backward compatibility with Professor UI
  Future<void> addMeeting({
    required String subject,
    required String title,
    required String platform,
    required String link,
    required String date,
    required String time,
  }) async {
    DateTime? startTime;
    try {
      final dateParts = date.split('-');
      if (dateParts.length == 3) {
        final year = int.parse(dateParts[0]);
        final month = int.parse(dateParts[1]);
        final day = int.parse(dateParts[2]);

        int hour = 0;
        int minute = 0;

        final timeParts = time.split(' ');
        if (timeParts.length == 2) {
          final hm = timeParts[0].split(':');
          hour = int.parse(hm[0]);
          minute = int.parse(hm[1]);
          if (timeParts[1].toUpperCase() == 'PM' && hour < 12) hour += 12;
          if (timeParts[1].toUpperCase() == 'AM' && hour == 12) hour = 0;
        }
        startTime = DateTime(year, month, day, hour, minute);
      }
    } catch (_) {}

    await addClassEvent(
      subjectOfferingId: subject,
      eventType: 'meeting',
      title: title,
      description: '$platform - $link',
      startTime: startTime,
    );
  }

  Future<void> deleteMeeting(String id) async {
    await deleteClassEvent(id);
  }
}
