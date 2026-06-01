import 'package:flutter/foundation.dart';

import '../../features/auth/domain/models/app_user.dart';
import '../../features/admin/data/repositories/supabase_admin_repository.dart';
import '../../features/admin/domain/models/instructor.dart';
import '../../features/admin/domain/models/student.dart';

class AppState extends ChangeNotifier {
  final SupabaseAdminRepository _adminRepository =
      const SupabaseAdminRepository();

  bool _isAuthenticated = false;
  AppUser? _currentUser;

  bool get isAuthenticated => _isAuthenticated;
  AppUser? get currentUser => _currentUser;

  final ValueNotifier<String?> accessDeniedNotifier = ValueNotifier<String?>(null);
  final ValueNotifier<List<Map<String, String>>> pendingSubjectRequestsNotifier =
      ValueNotifier<List<Map<String, String>>>(const []);
  final ValueNotifier<List<Map<String, String>>> pendingInstructorRequestsNotifier =
      ValueNotifier<List<Map<String, String>>>(const []);
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

  Future<List<String>> fetchStudentsEnrolledInSubject(String subjectOfferingId) async {
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
      subjectOfferingsNotifier.value =
          await _adminRepository.fetchSubjectOfferings();
      instructorsNotifier.value = await _adminRepository.fetchInstructors();
      studentsNotifier.value = await _adminRepository.fetchStudents();
      enrollmentCodesNotifier.value =
          await _adminRepository.fetchEnrollmentCodes();
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
    notifyListeners();
  }

  void logout() {
    if (!_isAuthenticated) return;
    _isAuthenticated = false;
    _currentUser = null;
    clearAdminData();
    notifyListeners();
  }

  void syncAuthState(AppUser? user) {
    _isAuthenticated = user != null;
    _currentUser = user;
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
    final isToday = dt.year == now.year && dt.month == now.month && dt.day == now.day;
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
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

  // Global meetings list
  final List<Map<String, dynamic>> _meetings = [
    {
      'id': 'meet_1',
      'subject': 'Ethics',
      'title': 'Ethics Online Discussion',
      'platform': 'Google Meet',
      'link': 'https://meet.google.com/abc-defg-hij',
      'date': '2026-06-15',
      'time': '10:00 AM',
    },
    {
      'id': 'meet_2',
      'subject': 'Capstone',
      'title': 'Weekly Capstone Consultation',
      'platform': 'Zoom',
      'link': 'https://zoom.us/j/123456789',
      'date': '2026-06-20',
      'time': '02:00 PM',
    }
  ];

  List<Map<String, dynamic>> get meetings => _meetings;

  void addMeeting({
    required String subject,
    required String title,
    required String platform,
    required String link,
    required String date,
    required String time,
  }) {
    _meetings.insert(0, {
      'id': 'meet_${DateTime.now().millisecondsSinceEpoch}',
      'subject': subject,
      'title': title,
      'platform': platform,
      'link': link,
      'date': date,
      'time': time,
    });
    notifyListeners();
  }

  void deleteMeeting(String id) {
    _meetings.removeWhere((m) => m['id'] == id);
    notifyListeners();
  }
}

