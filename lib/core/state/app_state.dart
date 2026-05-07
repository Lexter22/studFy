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
}
