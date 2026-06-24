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
        .select('id,subject_name,course_code,section,year_level,schedule_label,room,join_code')
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
      joinCode: r['join_code']?.toString(),
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

  Future<void> updateModule({
    required String moduleId,
    required String title,
    String? description,
  }) async {
    await _client.from('modules').update({
      'title': title.trim(),
      'description': description?.trim(),
    }).eq('id', moduleId);
  }

  Future<void> deleteModule(String moduleId) async {
    await _client.from('modules').delete().eq('id', moduleId);
  }

  Future<void> deleteModuleAttachment(String moduleId) async {
    await _client.from('modules').update({
      'file_url': null,
      'file_name': null,
    }).eq('id', moduleId);
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

  Future<List<Map<String, String>>> fetchAllStudents() async {
    final rows = await _client
        .from('student_profiles')
        .select('profile_id,student_number,course_code,year_section');

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

  // ── Class join code ─────────────────────────────────────────────────────

  /// Regenerate the Google Classroom-style join code for a subject.
  /// Returns the new code. Only the owning professor or an admin may call this.
  Future<String> regenerateClassCode(String subjectId) async {
    final result = await _client.rpc('regenerate_class_code', params: {'p_subject_id': subjectId});
    return result.toString();
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

  Future<void> requestUnenrollStudent({
    required String subjectId,
    required String studentProfileId,
    required String studentName,
    required String subjectName,
    required String classLabel,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    await _client.from('requests').insert({
      'kind': 'student_unenroll',
      'title': studentName,
      'details': 'Request to unenroll $studentName from $subjectName ($classLabel)',
      'status': 'pending',
      'requester_profile_id': user.id,
      'metadata': {
        'student_id': studentProfileId,
        'subject_id': subjectId,
        'student_name': studentName,
        'subject_name': subjectName,
        'class_label': classLabel,
      },
    });
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

  // ── Attendance ────────────────────────────────────────────────────────────

  /// Save attendance for a list of students on a given date.
  /// [attendance] is a map of studentProfileId -> status ('present', 'late', 'absent')
  Future<void> saveAttendance({
    required String subjectId,
    required DateTime date,
    required Map<String, String> attendance,
  }) async {
    final uid = _client.auth.currentUser?.id;
    final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    final rows = attendance.entries.map((e) => {
      'subject_offering_id': subjectId,
      'student_profile_id': e.key,
      'date': dateStr,
      'status': e.value,
      'recorded_by': uid,
    }).toList();

    await _client.from('attendance_records').upsert(
      rows,
      onConflict: 'subject_offering_id,student_profile_id,date',
    );
  }

  /// Fetch attendance records for a subject on a specific date
  Future<List<AttendanceRecord>> fetchAttendanceByDate(String subjectId, DateTime date) async {
    final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    final rows = await _client
        .from('attendance_records')
        .select('id,subject_offering_id,student_profile_id,date,status,remarks')
        .eq('subject_offering_id', subjectId)
        .eq('date', dateStr);

    if ((rows as List).isEmpty) return [];

    final ids = rows.map((r) => r['student_profile_id']?.toString()).whereType<String>().toList();
    final profileRows = await _client
        .from('profiles')
        .select('id,display_name')
        .inFilter('id', ids);

    final Map<String, String> nameMap = {};
    for (final r in (profileRows as List)) {
      nameMap[r['id'].toString()] = r['display_name']?.toString() ?? 'Unknown';
    }

    return rows.map((r) {
      final pid = r['student_profile_id']?.toString() ?? '';
      return AttendanceRecord(
        id: r['id'].toString(),
        subjectOfferingId: r['subject_offering_id'].toString(),
        studentProfileId: pid,
        date: DateTime.parse(r['date'].toString()),
        status: r['status']?.toString() ?? 'present',
        remarks: r['remarks']?.toString(),
        studentName: nameMap[pid],
      );
    }).toList();
  }

  /// Fetch attendance history (summary per date) for a subject
  Future<List<AttendanceSummary>> fetchAttendanceHistory(String subjectId) async {
    final rows = await _client
        .from('attendance_records')
        .select('date,status')
        .eq('subject_offering_id', subjectId)
        .order('date', ascending: false);

    final Map<String, Map<String, int>> grouped = {};
    for (final r in (rows as List)) {
      final dateStr = r['date'].toString();
      final status = r['status']?.toString() ?? 'present';
      grouped.putIfAbsent(dateStr, () => {'present': 0, 'late': 0, 'absent': 0});
      grouped[dateStr]![status] = (grouped[dateStr]![status] ?? 0) + 1;
    }

    return grouped.entries.map((e) => AttendanceSummary(
      date: DateTime.parse(e.key),
      presentCount: e.value['present'] ?? 0,
      lateCount: e.value['late'] ?? 0,
      absentCount: e.value['absent'] ?? 0,
    )).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  /// Fetch per-student attendance summary for a subject
  Future<List<StudentAttendanceSummary>> fetchStudentAttendanceSummaries(String subjectId) async {
    final rows = await _client
        .from('attendance_records')
        .select('student_profile_id,status')
        .eq('subject_offering_id', subjectId);

    if ((rows as List).isEmpty) return [];

    final Map<String, Map<String, int>> grouped = {};
    for (final r in rows) {
      final pid = r['student_profile_id'].toString();
      final status = r['status']?.toString() ?? 'present';
      grouped.putIfAbsent(pid, () => {'present': 0, 'late': 0, 'absent': 0});
      grouped[pid]![status] = (grouped[pid]![status] ?? 0) + 1;
    }

    final ids = grouped.keys.toList();
    final profileRows = await _client
        .from('profiles')
        .select('id,display_name')
        .inFilter('id', ids);

    final Map<String, String> nameMap = {};
    for (final r in (profileRows as List)) {
      nameMap[r['id'].toString()] = r['display_name']?.toString() ?? 'Unknown';
    }

    return grouped.entries.map((e) => StudentAttendanceSummary(
      studentProfileId: e.key,
      studentName: nameMap[e.key] ?? 'Unknown',
      totalPresent: e.value['present'] ?? 0,
      totalLate: e.value['late'] ?? 0,
      totalAbsent: e.value['absent'] ?? 0,
    )).toList();
  }

  // ── Grades ────────────────────────────────────────────────────────────────

  /// Add or update a grade for a student
  Future<void> saveGrade({
    required String subjectId,
    required String studentProfileId,
    required String category,
    required String title,
    required double score,
    required double maxScore,
    String? remarks,
  }) async {
    await _client.from('student_grades').insert({
      'subject_offering_id': subjectId,
      'student_profile_id': studentProfileId,
      'category': category,
      'title': title,
      'score': score,
      'max_score': maxScore,
      if (remarks != null && remarks.isNotEmpty) 'remarks': remarks,
    });
  }

  /// Update an existing grade
  Future<void> updateGrade({
    required String gradeId,
    required double score,
    required double maxScore,
    String? remarks,
  }) async {
    await _client.from('student_grades').update({
      'score': score,
      'max_score': maxScore,
      if (remarks != null) 'remarks': remarks,
    }).eq('id', gradeId);
  }

  /// Delete a grade record
  Future<void> deleteGrade(String gradeId) async {
    await _client.from('student_grades').delete().eq('id', gradeId);
  }

  /// Fetch all grades for a subject
  Future<List<StudentGrade>> fetchGrades(String subjectId) async {
    final rows = await _client
        .from('student_grades')
        .select('id,subject_offering_id,student_profile_id,category,title,score,max_score,remarks,graded_at')
        .eq('subject_offering_id', subjectId)
        .order('graded_at', ascending: false);

    if ((rows as List).isEmpty) return [];

    final ids = rows.map((r) => r['student_profile_id']?.toString()).whereType<String>().toSet().toList();
    final profileRows = await _client
        .from('profiles')
        .select('id,display_name')
        .inFilter('id', ids);

    final Map<String, String> nameMap = {};
    for (final r in (profileRows as List)) {
      nameMap[r['id'].toString()] = r['display_name']?.toString() ?? 'Unknown';
    }

    return rows.map((r) {
      final pid = r['student_profile_id']?.toString() ?? '';
      return StudentGrade(
        id: r['id'].toString(),
        subjectOfferingId: r['subject_offering_id'].toString(),
        studentProfileId: pid,
        category: r['category']?.toString() ?? 'general',
        title: r['title']?.toString() ?? '',
        score: (r['score'] as num?)?.toDouble() ?? 0,
        maxScore: (r['max_score'] as num?)?.toDouble() ?? 100,
        remarks: r['remarks']?.toString(),
        gradedAt: DateTime.tryParse(r['graded_at']?.toString() ?? '') ?? DateTime.now(),
        studentName: nameMap[pid],
      );
    }).toList();
  }

  /// Fetch grades for a specific student in a subject
  Future<List<StudentGrade>> fetchStudentGrades(String subjectId, String studentProfileId) async {
    final rows = await _client
        .from('student_grades')
        .select('id,subject_offering_id,student_profile_id,category,title,score,max_score,remarks,graded_at')
        .eq('subject_offering_id', subjectId)
        .eq('student_profile_id', studentProfileId)
        .order('graded_at', ascending: false);

    return (rows as List).map((r) => StudentGrade(
      id: r['id'].toString(),
      subjectOfferingId: r['subject_offering_id'].toString(),
      studentProfileId: r['student_profile_id'].toString(),
      category: r['category']?.toString() ?? 'general',
      title: r['title']?.toString() ?? '',
      score: (r['score'] as num?)?.toDouble() ?? 0,
      maxScore: (r['max_score'] as num?)?.toDouble() ?? 100,
      remarks: r['remarks']?.toString(),
      gradedAt: DateTime.tryParse(r['graded_at']?.toString() ?? '') ?? DateTime.now(),
    )).toList();
  }

  /// Fetch grade summaries per student for a subject
  Future<List<StudentGradeSummary>> fetchGradeSummaries(String subjectId) async {
    final rows = await _client
        .from('student_grades')
        .select('student_profile_id,score,max_score')
        .eq('subject_offering_id', subjectId);

    if ((rows as List).isEmpty) return [];

    final Map<String, List<Map<String, double>>> grouped = {};
    for (final r in rows) {
      final pid = r['student_profile_id'].toString();
      grouped.putIfAbsent(pid, () => []);
      grouped[pid]!.add({
        'score': (r['score'] as num?)?.toDouble() ?? 0,
        'maxScore': (r['max_score'] as num?)?.toDouble() ?? 100,
      });
    }

    final ids = grouped.keys.toList();
    final profileRows = await _client
        .from('profiles')
        .select('id,display_name')
        .inFilter('id', ids);

    final Map<String, String> nameMap = {};
    for (final r in (profileRows as List)) {
      nameMap[r['id'].toString()] = r['display_name']?.toString() ?? 'Unknown';
    }

    return grouped.entries.map((e) {
      final grades = e.value;
      final totalScore = grades.fold<double>(0, (sum, g) => sum + g['score']!);
      final totalMax = grades.fold<double>(0, (sum, g) => sum + g['maxScore']!);
      final avgPct = totalMax > 0 ? (totalScore / totalMax) * 100 : 0.0;
      return StudentGradeSummary(
        studentProfileId: e.key,
        studentName: nameMap[e.key] ?? 'Unknown',
        averagePercentage: avgPct,
        totalItems: grades.length,
        totalScore: totalScore,
        totalMaxScore: totalMax,
      );
    }).toList();
  }

  /// Save a batch of grades for multiple students (e.g., for an assignment or quiz)
  Future<void> saveBatchGrades({
    required String subjectId,
    required String category,
    required String title,
    required double maxScore,
    required Map<String, double> studentScores, // studentProfileId -> score
  }) async {
    final rows = studentScores.entries.map((e) => {
      'subject_offering_id': subjectId,
      'student_profile_id': e.key,
      'category': category,
      'title': title,
      'score': e.value,
      'max_score': maxScore,
    }).toList();

    await _client.from('student_grades').insert(rows);
  }

  Future<void> updateBatchGrades({
    required String subjectId,
    required String oldTitle,
    required String oldCategory,
    required String newTitle,
    required String newCategory,
    required double newMaxScore,
    required Map<String, double> studentScores, // studentProfileId -> score
  }) async {
    final existingRows = await _client
        .from('student_grades')
        .select('id, student_profile_id')
        .eq('subject_offering_id', subjectId)
        .eq('title', oldTitle)
        .eq('category', oldCategory);

    final Map<String, String> existingMap = {};
    for (final r in (existingRows as List)) {
      existingMap[r['student_profile_id'].toString()] = r['id'].toString();
    }

    final List<Future<void>> updates = [];
    final List<Map<String, dynamic>> inserts = [];

    for (final entry in studentScores.entries) {
      final pid = entry.key;
      final score = entry.value;
      final gradeId = existingMap[pid];

      if (gradeId != null) {
        updates.add(
          _client.from('student_grades').update({
            'title': newTitle,
            'category': newCategory,
            'max_score': newMaxScore,
            'score': score,
          }).eq('id', gradeId)
        );
      } else {
        inserts.add({
          'subject_offering_id': subjectId,
          'student_profile_id': pid,
          'category': newCategory,
          'title': newTitle,
          'score': score,
          'max_score': newMaxScore,
        });
      }
    }

    if (updates.isNotEmpty) {
      await Future.wait(updates);
    }
    if (inserts.isNotEmpty) {
      await _client.from('student_grades').insert(inserts);
    }
  }

  // ── Announcements ─────────────────────────────────────────────────────────

  /// Fetch announcements for a specific subject
  Future<List<Map<String, String>>> fetchAnnouncements(String subjectId) async {
    final rows = await _client
        .from('announcements')
        .select('id,subject_offering_id,content,posted_by,created_at')
        .eq('subject_offering_id', subjectId)
        .order('created_at', ascending: false);

    if ((rows as List).isEmpty) return [];

    final ids = rows.map((r) => r['posted_by']?.toString()).whereType<String>().toSet().toList();
    final profileRows = await _client
        .from('profiles')
        .select('id,display_name')
        .inFilter('id', ids);

    final Map<String, String> nameMap = {};
    for (final r in (profileRows as List)) {
      nameMap[r['id'].toString()] = r['display_name']?.toString() ?? 'Unknown';
    }

    return rows.map((r) {
      final createdAt = DateTime.tryParse(r['created_at']?.toString() ?? '');
      final dateStr = createdAt != null ? _formatDate(createdAt) : '';
      final content = r['content']?.toString() ?? '';
      final snippet = content.length > 80 ? '${content.substring(0, 80)}...' : content;
      return <String, String>{
        'id': r['id']?.toString() ?? '',
        'subject_offering_id': r['subject_offering_id']?.toString() ?? '',
        'body': snippet,
        'fullText': content,
        'date': dateStr,
        'postedBy': nameMap[r['posted_by']?.toString()] ?? 'Unknown',
      };
    }).toList();
  }

  /// Fetch announcements for all subjects taught by the current professor
  Future<List<Map<String, String>>> fetchAllMyAnnouncements() async {
    final subjects = await fetchMySubjects();
    if (subjects.isEmpty) return [];
    final ids = subjects.map((s) => s.id).toList();

    final rows = await _client
        .from('announcements')
        .select('id,subject_offering_id,content,posted_by,created_at')
        .inFilter('subject_offering_id', ids)
        .order('created_at', ascending: false);

    if ((rows as List).isEmpty) return [];

    // Build subject name map
    final Map<String, String> subjectNameMap = {};
    for (final s in subjects) {
      subjectNameMap[s.id] = s.name;
    }

    return rows.map((r) {
      final createdAt = DateTime.tryParse(r['created_at']?.toString() ?? '');
      final dateStr = createdAt != null ? _formatDate(createdAt) : '';
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
  }

  /// Create a new announcement for a subject
  Future<void> createAnnouncement(String subjectId, String content) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) throw Exception('Not authenticated');
    await _client.from('announcements').insert({
      'subject_offering_id': subjectId,
      'content': content.trim(),
      'posted_by': uid,
    });
  }

  /// Delete an announcement
  Future<void> deleteAnnouncement(String announcementId) async {
    await _client.from('announcements').delete().eq('id', announcementId);
  }

  // ── Meetings ──────────────────────────────────────────────────────────────

  /// Fetch meetings for a specific subject
  Future<List<Map<String, dynamic>>> fetchMeetings(String subjectId) async {
    final rows = await _client
        .from('meetings')
        .select('id,subject_offering_id,title,platform,link,meeting_date,meeting_time,created_by,created_at')
        .eq('subject_offering_id', subjectId)
        .order('meeting_date', ascending: false);

    if ((rows as List).isEmpty) return [];

    // Get subject name
    final subjectRows = await _client
        .from('subject_offerings')
        .select('id,subject_name')
        .eq('id', subjectId)
        .limit(1);
    final subjectName = (subjectRows as List).isNotEmpty
        ? subjectRows.first['subject_name']?.toString() ?? ''
        : '';

    return rows.map((r) => <String, dynamic>{
      'id': r['id']?.toString() ?? '',
      'subject': subjectName,
      'subject_offering_id': r['subject_offering_id']?.toString() ?? '',
      'title': r['title']?.toString() ?? '',
      'platform': r['platform']?.toString() ?? '',
      'link': r['link']?.toString() ?? '',
      'date': r['meeting_date']?.toString() ?? '',
      'time': r['meeting_time']?.toString() ?? '',
    }).toList();
  }

  /// Fetch all meetings across all subjects for the current professor
  Future<List<Map<String, dynamic>>> fetchAllMyMeetings() async {
    final subjects = await fetchMySubjects();
    if (subjects.isEmpty) return [];
    final ids = subjects.map((s) => s.id).toList();

    final rows = await _client
        .from('meetings')
        .select('id,subject_offering_id,title,platform,link,meeting_date,meeting_time')
        .inFilter('subject_offering_id', ids)
        .order('meeting_date', ascending: false);

    if ((rows as List).isEmpty) return [];

    final Map<String, String> subjectNameMap = {};
    for (final s in subjects) {
      subjectNameMap[s.id] = s.name;
    }

    return rows.map((r) {
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
  }

  /// Create a new meeting for a subject
  Future<void> createMeeting({
    required String subjectId,
    required String title,
    required String platform,
    String? link,
    required DateTime date,
    required String time,
  }) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) throw Exception('Not authenticated');
    final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    await _client.from('meetings').insert({
      'subject_offering_id': subjectId,
      'title': title.trim(),
      'platform': platform.trim(),
      if (link != null && link.trim().isNotEmpty) 'link': link.trim(),
      'meeting_date': dateStr,
      'meeting_time': time.trim(),
      'created_by': uid,
    });
  }

  /// Delete a meeting
  Future<void> deleteMeeting(String meetingId) async {
    await _client.from('meetings').delete().eq('id', meetingId);
  }

  // ── Reminders ─────────────────────────────────────────────────────────────

  /// Fetch all reminders for the current user
  Future<List<Map<String, String>>> fetchReminders() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return [];

    final rows = await _client
        .from('reminders')
        .select('id,title,description,reminder_date,reminder_time')
        .eq('profile_id', uid)
        .order('reminder_date', ascending: true);

    return (rows as List).map((r) => <String, String>{
      'id': r['id']?.toString() ?? '',
      'title': r['title']?.toString() ?? '',
      'description': r['description']?.toString() ?? '',
      'date': r['reminder_date']?.toString() ?? '',
      'time': r['reminder_time']?.toString() ?? '',
    }).toList();
  }

  /// Create a new reminder
  Future<void> createReminder({
    required String title,
    String? description,
    required DateTime date,
    required String time,
  }) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) throw Exception('Not authenticated');
    final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    await _client.from('reminders').insert({
      'profile_id': uid,
      'title': title.trim(),
      if (description != null && description.trim().isNotEmpty) 'description': description.trim(),
      'reminder_date': dateStr,
      'reminder_time': time.trim(),
    });
  }

  /// Delete a reminder
  Future<void> deleteReminder(String reminderId) async {
    await _client.from('reminders').delete().eq('id', reminderId);
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final isToday = dt.year == now.year && dt.month == now.month && dt.day == now.day;
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
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
}
