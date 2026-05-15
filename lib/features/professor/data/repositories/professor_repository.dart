import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/models/professor_subject.dart';

class ProfessorRepository {
  const ProfessorRepository();

  SupabaseClient get _client => Supabase.instance.client;

  Future<List<ProfessorSubject>> fetchMySubjects() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return [];

    final rows = await _client
        .from('subject_offerings')
        .select('id,subject_name,course_code,section,year_level,schedule_label,room')
        .eq('professor_profile_id', uid)
        .order('subject_name');

    final subjects = (rows as List).map((r) => Map<String, dynamic>.from(r as Map)).toList();

    // fetch student counts for all subject ids
    final ids = subjects.map((s) => s['id'].toString()).toList();
    final Map<String, int> counts = {};
    if (ids.isNotEmpty) {
      final enrollments = await _client
          .from('subject_enrollments')
          .select('subject_offering_id')
          .inFilter('subject_offering_id', ids);
      for (final e in (enrollments as List)) {
        final sid = e['subject_offering_id'].toString();
        counts[sid] = (counts[sid] ?? 0) + 1;
      }
    }

    return subjects.map((r) => ProfessorSubject(
      id: r['id'].toString(),
      name: r['subject_name']?.toString() ?? '',
      courseCode: r['course_code']?.toString() ?? '',
      section: r['section']?.toString() ?? '',
      yearLevel: (r['year_level'] as num?)?.toInt() ?? 0,
      scheduleLabel: r['schedule_label']?.toString(),
      room: r['room']?.toString(),
      studentCount: counts[r['id'].toString()] ?? 0,
    )).toList();
  }

  Future<List<SubjectModule>> fetchModules(String subjectId) async {
    final rows = await _client
        .from('modules')
        .select('id,title,description,order_index,file_url,file_name')
        .eq('subject_offering_id', subjectId)
        .order('order_index');
    return (rows as List).map((r) => SubjectModule(
      id: r['id'].toString(),
      title: r['title']?.toString() ?? '',
      description: r['description']?.toString(),
      orderIndex: (r['order_index'] as num?)?.toInt() ?? 0,
      fileUrl: r['file_url']?.toString(),
      fileName: r['file_name']?.toString(),
    )).toList();
  }

  Future<SubjectModule> createModule(String subjectId, String title, String? description, {String? fileUrl, String? fileName}) async {
    final row = await _client.from('modules').insert({
      'subject_offering_id': subjectId,
      'title': title.trim(),
      if (description != null && description.trim().isNotEmpty) 'description': description.trim(),
      if (fileUrl != null) 'file_url': fileUrl,
      if (fileName != null) 'file_name': fileName,
    }).select().single();
    return SubjectModule(
      id: row['id'].toString(),
      title: row['title'].toString(),
      description: row['description']?.toString(),
      orderIndex: (row['order_index'] as num?)?.toInt() ?? 0,
      fileUrl: row['file_url']?.toString(),
      fileName: row['file_name']?.toString(),
    );
  }

  Future<void> deleteModule(String moduleId) async {
    await _client.from('modules').delete().eq('id', moduleId);
  }

  Future<List<SubjectQuiz>> fetchQuizzes(String subjectId) async {
    final rows = await _client
        .from('quizzes')
        .select('id,title,description,deadline,module_id')
        .eq('subject_offering_id', subjectId)
        .order('created_at');

    final quizzes = (rows as List).map((r) => Map<String, dynamic>.from(r as Map)).toList();
    final result = <SubjectQuiz>[];

    for (final q in quizzes) {
      final qid = q['id'].toString();
      final qRows = await _client
          .from('quiz_questions')
          .select('id,question,options,correct_answer,order_index')
          .eq('quiz_id', qid)
          .order('order_index');

      final questions = (qRows as List).map((r) => QuizQuestion(
        id: r['id'].toString(),
        question: r['question']?.toString() ?? '',
        options: List<String>.from(r['options'] as List? ?? []),
        correctAnswer: r['correct_answer']?.toString() ?? '',
        orderIndex: (r['order_index'] as num?)?.toInt() ?? 0,
      )).toList();

      result.add(SubjectQuiz(
        id: qid,
        title: q['title']?.toString() ?? '',
        description: q['description']?.toString(),
        deadline: q['deadline'] != null ? DateTime.tryParse(q['deadline'].toString()) : null,
        moduleId: q['module_id']?.toString(),
        questions: questions,
      ));
    }
    return result;
  }

  Future<void> createQuiz({
    required String subjectId,
    required String title,
    String? description,
    DateTime? deadline,
    String? moduleId,
    required List<Map<String, dynamic>> questions,
  }) async {
    final quiz = await _client.from('quizzes').insert({
      'subject_offering_id': subjectId,
      'title': title.trim(),
      if (description != null && description.trim().isNotEmpty) 'description': description.trim(),
      if (deadline != null) 'deadline': deadline.toUtc().toIso8601String(),
      if (moduleId != null) 'module_id': moduleId,
    }).select().single();

    final quizId = quiz['id'].toString();
    if (questions.isNotEmpty) {
      await _client.from('quiz_questions').insert(
        questions.asMap().entries.map((e) => {
          'quiz_id': quizId,
          'question': e.value['question'],
          'options': e.value['options'],
          'correct_answer': e.value['correct_answer'],
          'order_index': e.key,
        }).toList(),
      );
    }
  }

  Future<int> fetchQuizAnswerCount(String quizId) async {
    final rows = await _client
        .from('quiz_answers')
        .select('id')
        .eq('quiz_id', quizId);
    return (rows as List).length;
  }

  Future<void> updateQuiz({
    required String quizId,
    required String title,
    String? description,
    DateTime? deadline,
    String? moduleId,
    required List<Map<String, dynamic>> questions,
  }) async {
    await _client.from('quizzes').update({
      'title': title.trim(),
      if (description != null && description.trim().isNotEmpty) 'description': description.trim(),
      if (deadline != null) 'deadline': deadline.toUtc().toIso8601String(),
      if (moduleId != null) 'module_id': moduleId,
    }).eq('id', quizId);

    await _client.from('quiz_questions').delete().eq('quiz_id', quizId);
    if (questions.isNotEmpty) {
      await _client.from('quiz_questions').insert(
        questions.asMap().entries.map((e) => {
          'quiz_id': quizId,
          'question': e.value['question'],
          'options': e.value['options'],
          'correct_answer': e.value['correct_answer'],
          'order_index': e.key,
        }).toList(),
      );
    }
  }

  Future<void> deleteQuiz(String quizId) async {
    await _client.from('quizzes').delete().eq('id', quizId);
  }

  Future<List<SubjectAssignment>> fetchAssignments(String subjectId) async {
    final rows = await _client
        .from('assignments')
        .select('id,title,description,deadline,file_url,file_name,module_id')
        .eq('subject_offering_id', subjectId)
        .order('created_at');
    return (rows as List).map((r) => SubjectAssignment(
      id: r['id'].toString(),
      title: r['title']?.toString() ?? '',
      description: r['description']?.toString(),
      deadline: r['deadline'] != null ? DateTime.tryParse(r['deadline'].toString()) : null,
      fileUrl: r['file_url']?.toString(),
      fileName: r['file_name']?.toString(),
      moduleId: r['module_id']?.toString(),
    )).toList();
  }

  Future<void> createAssignment({
    required String subjectId,
    required String title,
    String? description,
    DateTime? deadline,
    String? moduleId,
    String? fileUrl,
    String? fileName,
  }) async {
    await _client.from('assignments').insert({
      'subject_offering_id': subjectId,
      'title': title.trim(),
      if (description != null && description.trim().isNotEmpty) 'description': description.trim(),
      if (deadline != null) 'deadline': deadline.toUtc().toIso8601String(),
      if (moduleId != null) 'module_id': moduleId,
      if (fileUrl != null) 'file_url': fileUrl,
      if (fileName != null) 'file_name': fileName,
    });
  }

  Future<List<Map<String, String>>> findStudentByNumber(String studentNumber) async {
    final rows = await _client
        .from('student_profiles')
        .select('profile_id,student_number,course_code,year_section')
        .ilike('student_number', '%${studentNumber.trim()}%')
        .limit(5);

    if ((rows as List).isEmpty) return [];

    final ids = rows.map((r) => r['profile_id'].toString()).toList();
    final profileRows = await _client
        .from('profiles')
        .select('id,display_name,email')
        .inFilter('id', ids);

    final Map<String, Map<String, dynamic>> profileMap = {};
    for (final r in (profileRows as List)) {
      profileMap[r['id'].toString()] = Map<String, dynamic>.from(r as Map);
    }

    return rows.map((r) {
      final pid = r['profile_id'].toString();
      final p = profileMap[pid] ?? {};
      return <String, String>{
        'profileId': pid,
        'name': p['display_name']?.toString() ?? 'Unknown',
        'email': p['email']?.toString() ?? '',
        'studentNumber': r['student_number']?.toString() ?? '',
        'course': r['course_code']?.toString() ?? '',
        'yearSection': r['year_section']?.toString() ?? '',
      };
    }).toList().cast<Map<String, String>>();
  }

  Future<List<Map<String, String>>> searchStudents(String studentNumber) async {
    final rows = await _client
        .from('student_profiles')
        .select('profile_id,student_number,course_code,year_section')
        .ilike('student_number', '%${studentNumber.trim()}%')
        .limit(10);

    if ((rows as List).isEmpty) return [];

    final ids = rows.map((r) => r['profile_id'].toString()).toList();
    final profileRows = await _client
        .from('profiles')
        .select('id,display_name,email')
        .inFilter('id', ids);

    final Map<String, Map<String, dynamic>> profileMap = {};
    for (final r in (profileRows as List)) {
      profileMap[r['id'].toString()] = Map<String, dynamic>.from(r as Map);
    }

    return rows.map((r) {
      final pid = r['profile_id'].toString();
      final p = profileMap[pid] ?? {};
      return <String, String>{
        'profileId': pid,
        'name': p['display_name']?.toString() ?? 'Unknown',
        'email': p['email']?.toString() ?? '',
        'studentNumber': r['student_number']?.toString() ?? '',
        'course': r['course_code']?.toString() ?? '',
        'yearSection': r['year_section']?.toString() ?? '',
      };
    }).toList();
  }

  Future<void> enrollStudent(String subjectId, String studentProfileId) async {
    await _client.from('subject_enrollments').upsert({
      'subject_offering_id': subjectId,
      'student_profile_id': studentProfileId,
    }, onConflict: 'student_profile_id,subject_offering_id');
  }

  Future<void> unenrollStudent(String subjectId, String studentProfileId) async {
    await _client.from('subject_enrollments')
        .delete()
        .eq('subject_offering_id', subjectId)
        .eq('student_profile_id', studentProfileId);
  }

  Future<List<Map<String, String>>> fetchEnrolledStudents(String subjectId) async {
    // Step 1: get enrolled student profile IDs
    final enrollRows = await _client
        .from('subject_enrollments')
        .select('student_profile_id')
        .eq('subject_offering_id', subjectId);

    final ids = (enrollRows as List)
        .map((r) => r['student_profile_id']?.toString())
        .whereType<String>()
        .toList();

    if (ids.isEmpty) return [];

    // Step 2: get student_profiles
    final spRows = await _client
        .from('student_profiles')
        .select('profile_id,student_number,course_code,year_section')
        .inFilter('profile_id', ids);

    // Step 3: get display names from profiles
    final profileRows = await _client
        .from('profiles')
        .select('id,display_name,email')
        .inFilter('id', ids);

    final Map<String, Map<String, dynamic>> profileMap = {};
    for (final r in (profileRows as List)) {
      final id = r['id']?.toString();
      if (id != null) profileMap[id] = Map<String, dynamic>.from(r as Map);
    }

    return (spRows as List).map((r) {
      final pid = r['profile_id']?.toString() ?? '';
      final p = profileMap[pid] ?? {};
      return <String, String>{
        'profileId': pid,
        'name': p['display_name']?.toString() ?? 'Unknown',
        'email': p['email']?.toString() ?? '',
        'studentNumber': r['student_number']?.toString() ?? '',
        'course': r['course_code']?.toString() ?? '',
        'yearSection': r['year_section']?.toString() ?? '',
      };
    }).toList();
  }

  Future<int> fetchAssignmentSubmissionCount(String assignmentId) async {
    final rows = await _client
        .from('assignment_submissions')
        .select('id')
        .eq('assignment_id', assignmentId);
    return (rows as List).length;
  }

  Future<List<Map<String, dynamic>>> fetchAssignmentSubmissions(String assignmentId) async {
    final rows = await _client
        .from('assignment_submissions')
        .select('id,file_url,file_name,submitted_at,student_profile_id')
        .eq('assignment_id', assignmentId)
        .order('submitted_at', ascending: false);

    final ids = (rows as List).map((r) => r['student_profile_id']?.toString()).whereType<String>().toList();
    if (ids.isEmpty) return [];

    final profileRows = await _client
        .from('profiles')
        .select('id,display_name,email')
        .inFilter('id', ids);

    final Map<String, Map<String, dynamic>> profileMap = {};
    for (final r in (profileRows as List)) {
      profileMap[r['id'].toString()] = Map<String, dynamic>.from(r as Map);
    }

    return rows.map((r) {
      final pid = r['student_profile_id']?.toString() ?? '';
      final p = profileMap[pid] ?? {};
      return <String, dynamic>{
        'name': p['display_name']?.toString() ?? 'Unknown',
        'email': p['email']?.toString() ?? '',
        'file_url': r['file_url'],
        'file_name': r['file_name'],
        'submitted_at': r['submitted_at'],
      };
    }).toList();
  }

  Future<void> deleteAssignment(String assignmentId) async {
    await _client.from('assignments').delete().eq('id', assignmentId);
  }

  Future<String> uploadModuleFile(String subjectId, String fileName, Uint8List bytes) async {
    final path = 'modules/$subjectId/${DateTime.now().millisecondsSinceEpoch}_$fileName';
    await _client.storage.from('assignments').uploadBinary(path, bytes);
    return _client.storage.from('assignments').getPublicUrl(path);
  }

  Future<String> uploadAssignmentFile(String subjectId, String fileName, List<int> bytes) async {
    final path = '$subjectId/${DateTime.now().millisecondsSinceEpoch}_$fileName';
    await _client.storage.from('assignments').uploadBinary(path, bytes as Uint8List);
    return _client.storage.from('assignments').getPublicUrl(path);
  }
}
