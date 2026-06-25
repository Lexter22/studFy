import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../auth/domain/models/auth_exception.dart' as app_auth;
import '../../domain/models/instructor.dart';
import '../../domain/models/student.dart';

class SupabaseAdminRepository {
  const SupabaseAdminRepository();

  SupabaseClient get _client => Supabase.instance.client;

  bool _functionFailed(int? status, dynamic data) {
    if (status == null || status == 200 || status == 201) return false;
    if (status < 400) return false;
    return true;
  }

  String _functionError(dynamic data, String fallback) {
    if (data == null) return fallback;
    if (data is Map) return data['error']?.toString() ?? fallback;
    if (data is String && data.isNotEmpty) return data;
    return fallback;
  }

  Future<List<Map<String, String>>> fetchRequests() async {
    try {
      final rows = await _selectRows(
        'requests',
        columns: 'id,kind,title,details,status,requester_profile_id,metadata,created_at',
        equals: {'status': 'pending'},
        orderBy: 'created_at',
        ascending: false,
      );

      final requesterIds = rows
          .map((row) => row['requester_profile_id']?.toString())
          .whereType<String>()
          .toSet()
          .toList();
      final requesterNames = await _fetchProfileDisplayNames(requesterIds);

      return rows.map((row) {
        final metadata = Map<String, dynamic>.from(
          (row['metadata'] is Map ? row['metadata'] as Map : <String, dynamic>{})
        );
        final reqId = row['requester_profile_id']?.toString() ?? '';
        return <String, String>{
          'id': row['id']?.toString() ?? '',
          'kind': row['kind']?.toString() ?? '',
          'requester_profile_id': reqId,
          'requester_name': requesterNames[reqId] ?? 'Professor',
          'name': row['title']?.toString() ?? '',
          'status': _requestLabel(row['kind']?.toString(), metadata),
          'details': row['details']?.toString() ?? '',
          'requested_role': metadata['requested_role']?.toString() ?? '',
          'reason': metadata['reason']?.toString() ?? '',
        };
      }).toList();
    } on PostgrestException catch (error) {
      throw app_auth.AuthException(code: error.code ?? 'db-error', message: error.message);
    }
  }

  Future<List<Map<String, String>>> fetchSubjectOfferings() async {
    try {
      final rows = await _selectRows(
        'subject_offerings',
        columns: 'id,subject_name,course_code,section,professor_profile_id,status',
        orderBy: 'subject_name',
      );
      final professorNames = await _fetchProfileDisplayNames(
        rows.map((row) => row['professor_profile_id']?.toString()).whereType<String>().toList(),
      );

      return rows.map((row) {
        final professorId = row['professor_profile_id']?.toString() ?? '';
        final rawCourse = row['course_code']?.toString() ?? '';
        final cleanedCourse = (rawCourse == 'IT 001' || rawCourse.toLowerCase().contains('it 0')) ? 'BSIT' : rawCourse;
        return <String, String>{
          'id': row['id']?.toString() ?? '',
          'name': row['subject_name']?.toString() ?? '',
          'course': cleanedCourse,
          'section': row['section']?.toString() ?? '',
          'professor': professorNames[professorId] ?? 'Unassigned',
        };
      }).toList();
    } on PostgrestException catch (error) {
      throw app_auth.AuthException(code: error.code ?? 'db-error', message: error.message);
    }
  }

  Future<List<Instructor>> fetchInstructors() async {
    try {
      final rows = await _selectRows(
        'instructor_profiles',
        columns: 'profile_id,instructor_id,department',
        orderBy: 'created_at',
      );

      final profileNames = await _fetchProfileDisplayNames(
        rows.map((row) => row['profile_id']?.toString()).whereType<String>().toList(),
      );

      final subjectRows = await _selectRows(
        'subject_offerings',
        columns: 'professor_profile_id,subject_name',
        orderBy: 'subject_name',
      );

      final Map<String, List<String>> subjectsByInstructor = {};
      for (final row in subjectRows) {
        final profileId = row['professor_profile_id']?.toString();
        final subjectName = row['subject_name']?.toString() ?? '';
        if (profileId == null || subjectName.isEmpty) continue;
        subjectsByInstructor.putIfAbsent(profileId, () => []).add(subjectName);
      }

      return rows.map((row) {
        final profileId = row['profile_id']?.toString() ?? '';
        final displayName = profileNames[profileId]
            ?? row['instructor_id']?.toString()
            ?? 'Instructor';
        final department = row['department']?.toString() ?? 'Unassigned';
        final subject = subjectsByInstructor[profileId]?.isNotEmpty == true
            ? subjectsByInstructor[profileId]!.first
            : 'Unassigned';
        return Instructor(profileId: profileId, name: displayName, course: department, subject: subject);
      }).toList();
    } on PostgrestException catch (error) {
      throw app_auth.AuthException(code: error.code ?? 'db-error', message: error.message);
    }
  }

  Future<List<StudentData>> fetchStudents() async {
    try {
      final studentRows = await _selectRows(
        'student_profiles',
        columns: 'profile_id,student_number,course_code,year_section',
        orderBy: 'created_at',
      );
      final profileNames = await _fetchProfileDisplayNames(
        studentRows.map((row) => row['profile_id']?.toString()).whereType<String>().toList(),
      );

      return studentRows.map((row) {
        final profileId = row['profile_id']?.toString() ?? '';
        final name = profileNames[profileId] ?? row['student_number']?.toString() ?? 'Student';
        return StudentData(
          profileId: profileId,
          name: name,
          course: row['course_code']?.toString() ?? '',
          yearSection: row['year_section']?.toString() ?? '',
        );
      }).toList();
    } on PostgrestException catch (error) {
      throw app_auth.AuthException(code: error.code ?? 'db-error', message: error.message);
    }
  }

  Future<List<Map<String, dynamic>>> _selectRows(
    String table, {
    required String columns,
    String? orderBy,
    bool ascending = true,
    Map<String, dynamic>? equals,
  }) async {
    dynamic query = _client.from(table).select(columns);

    if (equals != null) {
      for (final entry in equals.entries) {
        query = query.eq(entry.key, entry.value);
      }
    }

    final dynamic response = orderBy == null
        ? await query
        : await query.order(orderBy, ascending: ascending);

    if (response is! List) return [];
    return response
        .whereType<Map>()
        .map((row) => Map<String, dynamic>.from(row))
        .toList();
  }

  Future<void> resolveRoleRequest({
    required String requestId,
    required bool approve,
  }) async {
    try {
      final reqRows = await _client.from('requests').select('kind, metadata').eq('id', requestId);
      if (reqRows != null && (reqRows as List).isNotEmpty) {
        final req = reqRows.first;
        final kind = req['kind']?.toString();
        if (kind == 'student_unenroll') {
          // Handle student unenroll request
          await _client.from('requests').update({
            'status': approve ? 'approved' : 'rejected',
            'resolved_at': DateTime.now().toIso8601String(),
          }).eq('id', requestId);

          if (approve) {
            final metadata = req['metadata'] is Map ? req['metadata'] as Map : {};
            final studentId = metadata['student_id']?.toString();
            final subjectId = metadata['subject_id']?.toString();
            if (studentId != null && subjectId != null) {
              await unenrollStudentFromSubject(
                studentProfileId: studentId,
                subjectOfferingId: subjectId,
              );
            }
          }
          return;
        }
      }
    } catch (e) {
      debugPrint('Failed in local resolveRoleRequest check: $e');
    }

    final response = await _client.functions.invoke(
      'resolve-role-request',
      body: {'requestId': requestId, 'approve': approve},
    );
    if (_functionFailed(response.status, response.data)) {
      throw app_auth.AuthException(
        code: 'function-error',
        message: _functionError(response.data, 'Failed to resolve request.'),
      );
    }
  }

  Future<void> updateInstructor({
    required String profileId,
    required String name,
    required String department,
  }) async {
    final response = await _client.functions.invoke(
      'update-instructor',
      body: {'profileId': profileId, 'name': name.trim(), 'department': department.trim()},
    );
    if (_functionFailed(response.status, response.data)) {
      throw app_auth.AuthException(
        code: 'function-error',
        message: _functionError(response.data, 'Failed to update instructor.'),
      );
    }
  }

  Future<void> updateStudent({
    required String profileId,
    required String name,
    required String course,
    required String yearSection,
  }) async {
    final response = await _client.functions.invoke(
      'update-student',
      body: {'profileId': profileId, 'name': name.trim(), 'course': course.trim(), 'yearSection': yearSection.trim()},
    );
    if (_functionFailed(response.status, response.data)) {
      throw app_auth.AuthException(
        code: 'function-error',
        message: _functionError(response.data, 'Failed to update student.'),
      );
    }
  }

  Future<void> deleteProfile(String profileId) async {
    final response = await _client.functions.invoke(
      'delete-user',
      body: {'profileId': profileId},
    );
    if (_functionFailed(response.status, response.data)) {
      throw app_auth.AuthException(
        code: 'function-error',
        message: _functionError(response.data, 'Failed to delete user.'),
      );
    }
  }

  Future<String> createInstructor({
    required String firstName,
    required String lastName,
    required String email,
    required String department,
    String? instructorId,
  }) async {
    final response = await _client.functions.invoke(
      'create-instructor',
      body: {
        'firstName': firstName.trim(),
        'lastName': lastName.trim(),
        'email': email.trim().toLowerCase(),
        'department': department.trim(),
        'instructorId': (instructorId ?? '').trim(),
      },
    );
    if (_functionFailed(response.status, response.data)) {
      throw app_auth.AuthException(
        code: 'function-error',
        message: _functionError(response.data, 'Failed to create instructor.'),
      );
    }
    return (response.data is Map ? response.data['defaultPassword']?.toString() : null) ?? 'Studfy@123';
  }

  Future<String> createStudent({
    required String firstName,
    required String lastName,
    required String email,
    required String courseCode,
    required String yearSection,
    String? studentNumber,
  }) async {
    final response = await _client.functions.invoke(
      'create-student',
      body: {
        'firstName': firstName.trim(),
        'lastName': lastName.trim(),
        'email': email.trim().toLowerCase(),
        'courseCode': courseCode.trim(),
        'yearSection': yearSection.trim(),
        'studentNumber': (studentNumber ?? '').trim(),
      },
    );
    if (_functionFailed(response.status, response.data)) {
      throw app_auth.AuthException(
        code: 'function-error',
        message: _functionError(response.data, 'Failed to create student.'),
      );
    }
    return (response.data is Map ? response.data['defaultPassword']?.toString() : null) ?? 'Studfy@123';
  }

  Future<void> enrollStudentInSubject({
    required String studentProfileId,
    required String subjectOfferingId,
  }) async {
    try {
      await _client.from('subject_enrollments').upsert({
        'student_profile_id': studentProfileId,
        'subject_offering_id': subjectOfferingId,
      }, onConflict: 'student_profile_id,subject_offering_id');
    } on PostgrestException catch (error) {
      throw app_auth.AuthException(code: error.code ?? 'db-error', message: error.message);
    }
  }

  Future<void> unenrollStudentFromSubject({
    required String studentProfileId,
    required String subjectOfferingId,
  }) async {
    try {
      await _client.from('subject_enrollments')
          .delete()
          .eq('student_profile_id', studentProfileId)
          .eq('subject_offering_id', subjectOfferingId);
    } on PostgrestException catch (error) {
      throw app_auth.AuthException(code: error.code ?? 'db-error', message: error.message);
    }
  }

  Future<List<String>> fetchStudentsEnrolledInSubject(String subjectOfferingId) async {
    try {
      final rows = await _selectRows(
        'subject_enrollments',
        columns: 'student_profile_id',
        equals: {'subject_offering_id': subjectOfferingId},
      );
      return rows
          .map((r) => r['student_profile_id']?.toString() ?? '')
          .where((id) => id.isNotEmpty)
          .toList();
    } on PostgrestException catch (error) {
      throw app_auth.AuthException(code: error.code ?? 'db-error', message: error.message);
    }
  }

  Future<List<String>> fetchEnrolledSubjectIds(String studentProfileId) async {
    try {
      final rows = await _selectRows(
        'subject_enrollments',
        columns: 'subject_offering_id',
        equals: {'student_profile_id': studentProfileId},
      );
      return rows
          .map((r) => r['subject_offering_id']?.toString() ?? '')
          .where((id) => id.isNotEmpty)
          .toList();
    } on PostgrestException catch (error) {
      throw app_auth.AuthException(code: error.code ?? 'db-error', message: error.message);
    }
  }

  Future<List<Map<String, dynamic>>> fetchEnrollmentCodes() async {
    try {
      final dynamic response = await _client
          .from('enrollment_codes')
          .select('id,code,course_code,year_section,max_uses,current_uses,is_active,expires_at')
          .order('created_at', ascending: false);
      if (response is! List) return [];
      return response
          .whereType<Map>()
          .map((row) => Map<String, dynamic>.from(row))
          .toList();
    } on PostgrestException catch (error) {
      throw app_auth.AuthException(code: error.code ?? 'db-error', message: error.message);
    }
  }

  Future<void> createEnrollmentCode({
    required String code,
    required String courseCode,
    required String yearSection,
    int? maxUses,
    DateTime? expiresAt,
  }) async {
    try {
      final adminUid = _client.auth.currentUser?.id;
      await _client.from('enrollment_codes').insert({
        'code': code.trim().toUpperCase(),
        'course_code': courseCode.trim(),
        'year_section': yearSection.trim(),
        if (maxUses != null) 'max_uses': maxUses,
        if (expiresAt != null) 'expires_at': expiresAt.toUtc().toIso8601String(),
        'created_by': adminUid,
      });
    } on PostgrestException catch (error) {
      throw app_auth.AuthException(code: error.code ?? 'db-error', message: error.message);
    }
  }

  Future<void> toggleEnrollmentCode(String id, bool isActive) async {
    try {
      await _client.from('enrollment_codes').update({'is_active': isActive}).eq('id', id);
    } on PostgrestException catch (error) {
      throw app_auth.AuthException(code: error.code ?? 'db-error', message: error.message);
    }
  }

  Future<void> deleteEnrollmentCode(String id) async {
    try {
      await _client.from('enrollment_codes').delete().eq('id', id);
    } on PostgrestException catch (error) {
      throw app_auth.AuthException(code: error.code ?? 'db-error', message: error.message);
    }
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
    String? professorProfileId,
  }) async {
    try {
      await _client.from('subject_offerings').insert({
        'subject_name': subjectName.trim(),
        'course_code': courseCode.trim(),
        'section': section.trim(),
        'year_level': yearLevel,
        if (semester != null) 'semester': semester,
        if (academicYear != null && academicYear.trim().isNotEmpty) 'academic_year': academicYear.trim(),
        if (room != null && room.trim().isNotEmpty) 'room': room.trim(),
        if (scheduleLabel != null && scheduleLabel.trim().isNotEmpty) 'schedule_label': scheduleLabel.trim(),
        if (professorProfileId != null && professorProfileId.isNotEmpty) 'professor_profile_id': professorProfileId,
        'status': 'active',
      });
    } on PostgrestException catch (error) {
      throw app_auth.AuthException(code: error.code ?? 'db-error', message: error.message);
    }
  }

  Future<void> updateSubject({
    required String subjectId,
    required String subjectName,
    required String courseCode,
    required String section,
    String? room,
    String? scheduleLabel,
  }) async {
    try {
      await _client.from('subject_offerings').update({
        'subject_name': subjectName.trim(),
        'course_code': courseCode.trim(),
        'section': section.trim(),
        if (room != null) 'room': room.trim(),
        if (scheduleLabel != null) 'schedule_label': scheduleLabel.trim(),
      }).eq('id', subjectId);
    } on PostgrestException catch (error) {
      throw app_auth.AuthException(code: error.code ?? 'db-error', message: error.message);
    }
  }

  Future<void> deleteSubject(String subjectId) async {
    try {
      await _client.from('subject_offerings').delete().eq('id', subjectId);
    } on PostgrestException catch (error) {
      throw app_auth.AuthException(code: error.code ?? 'db-error', message: error.message);
    }
  }

  Future<void> assignProfessorToSubject({
    required String subjectId,
    required String profileId,
  }) async {
    try {
      await _client.from('subject_offerings').update({
        'professor_profile_id': profileId,
      }).eq('id', subjectId);
    } on PostgrestException catch (error) {
      throw app_auth.AuthException(code: error.code ?? 'db-error', message: error.message);
    }
  }

  Future<Map<String, String>> _fetchProfileDisplayNames(List<String> profileIds) async {
    if (profileIds.isEmpty) return <String, String>{};

    try {
      final dynamic response = await _client
          .from('profiles')
          .select('id,display_name,first_name,last_name')
          .inFilter('id', profileIds);

      if (response is! List) return {};

      final Map<String, String> names = {};
      for (final row in response.whereType<Map>().map((r) => Map<String, dynamic>.from(r))) {
        final id = row['id']?.toString();
        if (id == null || id.isEmpty) continue;
        names[id] = _profileDisplayName(row);
      }
      return names;
    } on PostgrestException catch (error) {
      throw app_auth.AuthException(code: error.code ?? 'db-error', message: error.message);
    }
  }

  String _profileDisplayName(Map<String, dynamic> row) {
    final displayName = row['display_name']?.toString().trim() ?? '';
    if (displayName.isNotEmpty) return displayName;

    final firstName = row['first_name']?.toString().trim() ?? '';
    final lastName = row['last_name']?.toString().trim() ?? '';
    final fallback = [firstName, lastName].where((v) => v.isNotEmpty).join(' ').trim();
    return fallback.isEmpty ? 'Unknown' : fallback;
  }

  String _requestLabel(String? kind, Map<String, dynamic> metadata) {
    switch (kind) {
      case 'account_edit': return 'Account Edit Request';
      case 'class_creation': return 'Class Creation Request';
      case 'schedule_conflict': return 'Schedule Conflict Request';
      case 'student_unenroll': return 'Student Unenrollment Request';
      case 'role_assignment':
        final requestedRole = (metadata['requested_role']?.toString() ?? '').toLowerCase();
        if (requestedRole == 'student') return 'Student Registration Request';
        if (requestedRole == 'professor') return 'Professor Registration Request';
        return 'Role Assignment Request';
      case 'subject_update': return 'Subject Update Request';
      default: return 'Pending Request';
    }
  }

  String _valueOrFallback(String? value, String fallback) {
    final cleanValue = value?.trim() ?? '';
    return cleanValue.isEmpty ? fallback : cleanValue;
  }

  /// Bulk import students via Edge Function.
  /// [students] is a list of maps with keys: name, email, course, yearSection, studentNumber (optional).
  /// Returns the full response including summary and per-row results.
  Future<Map<String, dynamic>> bulkImportStudents(
    List<Map<String, String>> students,
  ) async {
    final response = await _client.functions.invoke(
      'bulk-import-students',
      body: {'students': students},
    );

    if (_functionFailed(response.status, response.data)) {
      throw app_auth.AuthException(
        code: 'function-error',
        message: _functionError(response.data, 'Bulk import failed.'),
      );
    }

    if (response.data is Map) {
      return Map<String, dynamic>.from(response.data as Map);
    }
    return {'summary': {'total': 0, 'created': 0, 'skipped': 0, 'errors': 0}, 'results': []};
  }
}
