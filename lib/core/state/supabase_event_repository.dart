import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseEventRepository {
  const SupabaseEventRepository();

  SupabaseClient get _client => Supabase.instance.client;

  Future<List<Map<String, dynamic>>> fetchClassEvents() async {
    try {
      final dynamic response = await _client
          .from('class_events')
          .select('*, subject_offerings(subject_name)')
          .order('created_at', ascending: false);
      if (response == null) return [];
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> fetchStudentTasks(
    String studentProfileId,
  ) async {
    try {
      final dynamic response = await _client
          .from('student_tasks')
          .select()
          .eq('student_profile_id', studentProfileId)
          .order('created_at', ascending: false);
      if (response == null) return [];
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> fetchStudentSubjects(
    String studentProfileId,
  ) async {
    try {
      final dynamic response = await _client
          .from('subject_enrollments')
          .select('subject_offerings(*)')
          .eq('student_profile_id', studentProfileId);
      if (response == null) return [];
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> fetchStudentQuizzes(
    String studentProfileId,
  ) async {
    try {
      final dynamic enrollResponse = await _client
          .from('subject_enrollments')
          .select('subject_offering_id')
          .eq('student_profile_id', studentProfileId);

      if (enrollResponse == null) return [];

      final subjectIds = (enrollResponse as List)
          .map((e) => e['subject_offering_id'])
          .whereType<String>()
          .toList();
      if (subjectIds.isEmpty) return [];
      final dynamic response = await _client
          .from('quizzes')
          .select('*, subject_offerings(subject_name)')
          .inFilter('subject_offering_id', subjectIds)
          .order('created_at', ascending: false);

      if (response == null) return [];
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> fetchStudentAssignments(
    String studentProfileId,
  ) async {
    try {
      final dynamic enrollResponse = await _client
          .from('subject_enrollments')
          .select('subject_offering_id')
          .eq('student_profile_id', studentProfileId);

      if (enrollResponse == null) return [];

      final subjectIds = (enrollResponse as List)
          .map((e) => e['subject_offering_id'])
          .whereType<String>()
          .toList();
      if (subjectIds.isEmpty) return [];
      final dynamic response = await _client
          .from('assignments')
          .select('*, subject_offerings(subject_name)')
          .inFilter('subject_offering_id', subjectIds)
          .order('created_at', ascending: false);

      if (response == null) return [];
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  Future<String?> getSubjectId(String identifier) async {
    try {
      final uid = _client.auth.currentUser?.id;
      dynamic query = _client
          .from('subject_offerings')
          .select('id')
          .or(
            'subject_name.ilike.%$identifier%,course_code.ilike.%$identifier%',
          );

      if (uid != null) {
        query = query.eq('professor_profile_id', uid);
      }

      final dynamic response = await query.limit(1).maybeSingle();
      if (response == null) return null;
      return response['id']?.toString();
    } catch (e) {
      return null;
    }
  }

  Future<void> addClassEvent({
    required String subjectOfferingId,
    required String eventType,
    required String title,
    String? description,
    DateTime? startTime,
    DateTime? endTime,
    String? createdBy,
  }) async {
    await _client.from('class_events').insert({
      'subject_offering_id': subjectOfferingId,
      'event_type': eventType,
      'title': title,
      'description': description,
      'start_time': startTime?.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'created_by': createdBy,
    });
  }

  Future<void> deleteClassEvent(String id) async {
    await _client.from('class_events').delete().eq('id', id);
  }

  Future<void> addStudentTask({
    required String studentProfileId,
    required String title,
    String? description,
    DateTime? dueDate,
  }) async {
    await _client.from('student_tasks').insert({
      'student_profile_id': studentProfileId,
      'title': title,
      'description': description,
      'due_date': dueDate?.toIso8601String(),
    });
  }

  Future<void> toggleTaskCompletion(String id, bool isCompleted) async {
    await _client
        .from('student_tasks')
        .update({'is_completed': isCompleted})
        .eq('id', id);
  }

  Future<void> deleteStudentTask(String id) async {
    await _client.from('student_tasks').delete().eq('id', id);
  }
}
