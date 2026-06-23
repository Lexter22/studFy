import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
      subjectRequests.sort((a, b) {
        final aName = a['name'] ?? '';
        final bName = b['name'] ?? '';
        return aName.toLowerCase().compareTo(bName.toLowerCase());
      });

      final instructorRequests = requests
          .where(_isInstructorRequest)
          .map(_requestCard)
          .toList();
      instructorRequests.sort((a, b) {
        final aName = a['name'] ?? '';
        final bName = b['name'] ?? '';
        return aName.toLowerCase().compareTo(bName.toLowerCase());
      });

      pendingSubjectRequestsNotifier.value = subjectRequests;
      pendingInstructorRequestsNotifier.value = instructorRequests;

      final offerings = await _adminRepository.fetchSubjectOfferings();
      offerings.sort((a, b) {
        final aName = a['name'] ?? '';
        final bName = b['name'] ?? '';
        return aName.toLowerCase().compareTo(bName.toLowerCase());
      });
      subjectOfferingsNotifier.value = offerings;

      final instructors = await _adminRepository.fetchInstructors();
      instructors.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      instructorsNotifier.value = instructors;

      final students = await _adminRepository.fetchStudents();
      students.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      studentsNotifier.value = students;

      final codes = await _adminRepository.fetchEnrollmentCodes();
      codes.sort((a, b) {
        final aCode = a['code']?.toString() ?? '';
        final bCode = b['code']?.toString() ?? '';
        return aCode.toLowerCase().compareTo(bCode.toLowerCase());
      });
      enrollmentCodesNotifier.value = codes;
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

  /// Bulk import students from a list of parsed rows (e.g. from Excel).
  /// Each map should have: name, email, course, yearSection, studentNumber (optional).
  /// Returns the summary and per-row results from the Edge Function.
  Future<Map<String, dynamic>> bulkImportStudents(
    List<Map<String, String>> students,
  ) async {
    final result = await _adminRepository.bulkImportStudents(students);
    await loadAdminData();
    return result;
  }

  void login([AppUser? user]) {
    if (_isAuthenticated) {
      _currentUser = user ?? _currentUser;
      return;
    }
    _isAuthenticated = true;
    _currentUser = user;
    notifyListeners();
    // Load persistent data from DB
    loadAnnouncements();
    loadMeetings();
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

  // Global announcements list (loaded from DB)
  List<Map<String, String>> _announcements = [];

  List<Map<String, String>> get announcements => _announcements;

  /// Load announcements from the database
  Future<void> loadAnnouncements() async {
    try {
      final client = Supabase.instance.client;
      final rows = await client
          .from('announcements')
          .select('id,subject_offering_id,content,posted_by,created_at')
          .order('created_at', ascending: false)
          .limit(50);

      if ((rows as List).isEmpty) {
        _announcements = [];
        notifyListeners();
        return;
      }

      // Get subject names
      final subjectIds = rows.map((r) => r['subject_offering_id']?.toString()).whereType<String>().toSet().toList();
      final subjectRows = await client
          .from('subject_offerings')
          .select('id,subject_name')
          .inFilter('id', subjectIds);
      final Map<String, String> subjectNameMap = {};
      for (final r in (subjectRows as List)) {
        subjectNameMap[r['id'].toString()] = r['subject_name']?.toString() ?? '';
      }

      _announcements = rows.map((r) {
        final createdAt = DateTime.tryParse(r['created_at']?.toString() ?? '');
        final dateStr = createdAt != null ? _formatAnnouncementDate(createdAt) : '';
        final content = r['content']?.toString() ?? '';
        final snippet = content.length > 80 ? '${content.substring(0, 80)}...' : content;
        final subjectId = r['subject_offering_id']?.toString() ?? '';
        return <String, String>{
          'id': r['id']?.toString() ?? '',
          'subject': subjectNameMap[subjectId] ?? '',
          'subject_offering_id': subjectId,
          'body': snippet,
          'fullText': content,
          'date': dateStr,
        };
      }).toList();
      notifyListeners();
    } catch (_) {
      // Keep existing state on error
    }
  }

  void addAnnouncement(String subject, String text, DateTime date) async {
    // Legacy method — now saves to DB
    try {
      final client = Supabase.instance.client;
      final uid = client.auth.currentUser?.id;
      if (uid == null) return;

      // Find the subject offering ID by name
      final subjectRows = await client
          .from('subject_offerings')
          .select('id')
          .eq('subject_name', subject)
          .eq('professor_profile_id', uid)
          .limit(1);

      if ((subjectRows as List).isEmpty) return;
      final subjectId = subjectRows.first['id'].toString();

      await client.from('announcements').insert({
        'subject_offering_id': subjectId,
        'content': text.trim(),
        'posted_by': uid,
      });

      await loadAnnouncements();
    } catch (_) {
      // Fallback: add locally
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
  }

  void deleteAnnouncement(Map<String, String> ann) async {
    final id = ann['id'];
    if (id != null && id.isNotEmpty) {
      try {
        await Supabase.instance.client.from('announcements').delete().eq('id', id);
      } catch (_) {}
    }
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

  // Global meetings list (loaded from DB)
  List<Map<String, dynamic>> _meetings = [];

  List<Map<String, dynamic>> get meetings => _meetings;

  /// Load meetings from the database
  Future<void> loadMeetings() async {
    try {
      final client = Supabase.instance.client;
      final rows = await client
          .from('meetings')
          .select('id,subject_offering_id,title,platform,link,meeting_date,meeting_time')
          .order('meeting_date', ascending: false)
          .limit(50);

      if ((rows as List).isEmpty) {
        _meetings = [];
        notifyListeners();
        return;
      }

      final subjectIds = rows.map((r) => r['subject_offering_id']?.toString()).whereType<String>().toSet().toList();
      final subjectRows = await client
          .from('subject_offerings')
          .select('id,subject_name')
          .inFilter('id', subjectIds);
      final Map<String, String> subjectNameMap = {};
      for (final r in (subjectRows as List)) {
        subjectNameMap[r['id'].toString()] = r['subject_name']?.toString() ?? '';
      }

      _meetings = rows.map((r) {
        final subjectId = r['subject_offering_id']?.toString() ?? '';
        return <String, dynamic>{
          'id': r['id']?.toString() ?? '',
          'subject': subjectNameMap[subjectId] ?? '',
          'subject_offering_id': subjectId,
          'title': r['title']?.toString() ?? '',
          'platform': r['platform']?.toString() ?? '',
          'link': r['link']?.toString() ?? '',
          'date': r['meeting_date']?.toString() ?? '',
          'time': r['meeting_time']?.toString() ?? '',
        };
      }).toList();
      notifyListeners();
    } catch (_) {
      // Keep existing state on error
    }
  }

  void addMeeting({
    required String subject,
    required String title,
    required String platform,
    required String link,
    required String date,
    required String time,
  }) async {
    // Legacy method — now saves to DB
    try {
      final client = Supabase.instance.client;
      final uid = client.auth.currentUser?.id;
      if (uid == null) return;

      // Find the subject offering ID by name
      final subjectRows = await client
          .from('subject_offerings')
          .select('id')
          .eq('subject_name', subject)
          .eq('professor_profile_id', uid)
          .limit(1);

      if ((subjectRows as List).isEmpty) return;
      final subjectId = subjectRows.first['id'].toString();

      await client.from('meetings').insert({
        'subject_offering_id': subjectId,
        'title': title.trim(),
        'platform': platform.trim(),
        if (link.trim().isNotEmpty) 'link': link.trim(),
        'meeting_date': date,
        'meeting_time': time.trim(),
        'created_by': uid,
      });

      await loadMeetings();
    } catch (_) {
      // Fallback: add locally
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
  }

  void deleteMeeting(String id) async {
    if (id.isNotEmpty && !id.startsWith('meet_')) {
      try {
        await Supabase.instance.client.from('meetings').delete().eq('id', id);
      } catch (_) {}
    }
    _meetings.removeWhere((m) => m['id'] == id);
    notifyListeners();
  }
}

