import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/student_subject.dart';
import '../../../professor/domain/models/professor_subject.dart';

class StudentRepository {
  const StudentRepository();

  SupabaseClient get _client => Supabase.instance.client;

  Future<Map<String, dynamic>?> fetchStudentProfile() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return null;
    try {
      final row = await _client
          .from('student_profiles')
          .select('student_number,course_code,year_section')
          .eq('profile_id', uid)
          .maybeSingle();
      return row;
    } catch (_) {
      return null;
    }
  }

  Future<List<StudentSubject>> fetchEnrolledSubjects() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return [];

    try {
      final enrollRows = await _client
          .from('subject_enrollments')
          .select('subject_offering_id')
          .eq('student_profile_id', uid);

      final subjectIds = (enrollRows as List)
          .map((r) => r['subject_offering_id']?.toString())
          .whereType<String>()
          .toList();

      if (subjectIds.isEmpty) {
        return [];
      }

      final subjectRows = await _client
          .from('subject_offerings')
          .select('id,subject_name,course_code,section,year_level,schedule_label,room,professor_profile_id')
          .inFilter('id', subjectIds);

      final List<StudentSubject> list = [];
      for (final r in (subjectRows as List)) {
        final profId = r['professor_profile_id']?.toString();
        String profName = 'Unknown';
        if (profId != null) {
          try {
            final profRow = await _client
                .from('profiles')
                .select('display_name,first_name,last_name')
                .eq('id', profId)
                .maybeSingle();
            if (profRow != null) {
              final dispName = profRow['display_name']?.toString().trim() ?? '';
              if (dispName.isNotEmpty) {
                profName = dispName;
              } else {
                final firstName = profRow['first_name']?.toString().trim() ?? '';
                final lastName = profRow['last_name']?.toString().trim() ?? '';
                final fallback = [firstName, lastName].where((v) => v.isNotEmpty).join(' ').trim();
                if (fallback.isNotEmpty) {
                  profName = fallback;
                }
              }
            }
          } catch (_) {}
        }

        list.add(StudentSubject(
          id: r['id'].toString(),
          name: r['subject_name']?.toString() ?? '',
          courseCode: r['course_code']?.toString() ?? '',
          section: r['section']?.toString() ?? '',
          yearLevel: (r['year_level'] as num?)?.toInt() ?? 0,
          scheduleLabel: r['schedule_label']?.toString(),
          room: r['room']?.toString(),
          professorName: profName,
        ));
      }

      return list;
    } catch (_) {
      return [];
    }
  }

  Future<List<SubjectModule>> fetchModules(String subjectId) async {
    try {
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
    } catch (_) {
      return [];
    }
  }

  Future<List<SubjectAssignment>> fetchAssignments(String subjectId) async {
    try {
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
    } catch (_) {
      return [];
    }
  }

  Future<List<SubjectQuiz>> fetchQuizzes(String subjectId) async {
    try {
      final rows = await _client
          .from('quizzes')
          .select('id,title,description,deadline,module_id')
          .eq('subject_offering_id', subjectId)
          .order('created_at');

      final quizzes = (rows as List).map((r) => Map<String, dynamic>.from(r as Map)).toList();

      // Note: questions are NOT loaded here. quiz_questions is restricted to
      // professors/admins; students fetch questions (without answers) via the
      // get_quiz_questions_for_taking RPC only when actually taking the quiz.
      return quizzes.map((q) => SubjectQuiz(
        id: q['id'].toString(),
        title: q['title']?.toString() ?? '',
        description: q['description']?.toString(),
        deadline: q['deadline'] != null ? DateTime.tryParse(q['deadline'].toString()) : null,
        moduleId: q['module_id']?.toString(),
        questions: const [],
      )).toList();
    } catch (_) {
      return [];
    }
  }

  Future<bool> checkSubmission(String assignmentId) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return false;

    try {
      final rows = await _client
          .from('assignment_submissions')
          .select('id')
          .eq('assignment_id', assignmentId)
          .eq('student_profile_id', uid)
          .limit(1);
      return (rows as List).isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<void> submitAssignment(String assignmentId, String fileName, String fileUrl) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return;

    await _client.from('assignment_submissions').insert({
      'assignment_id': assignmentId,
      'student_profile_id': uid,
      'file_name': fileName,
      'file_url': fileUrl,
      'submitted_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  Future<String> uploadSubmissionFile(String assignmentId, String fileName, Uint8List bytes) async {
    final uid = _client.auth.currentUser?.id ?? 'unknown';
    final path = 'submissions/$assignmentId/${uid}_${DateTime.now().millisecondsSinceEpoch}_$fileName';
    await _client.storage.from('assignments').uploadBinary(path, bytes);
    return _client.storage.from('assignments').getPublicUrl(path);
  }

  // ── Quiz Answers ──────────────────────────────────────────────────────────

  /// Check if the student has already answered a quiz
  Future<bool> hasAnsweredQuiz(String quizId) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return false;
    try {
      final rows = await _client
          .from('quiz_answers')
          .select('id')
          .eq('quiz_id', quizId)
          .eq('student_profile_id', uid)
          .limit(1);
      return (rows as List).isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Get the student's previous quiz answer (score)
  Future<Map<String, dynamic>?> fetchQuizAnswer(String quizId) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return null;
    try {
      final row = await _client
          .from('quiz_answers')
          .select('id,answers,score,max_score,submitted_at')
          .eq('quiz_id', quizId)
          .eq('student_profile_id', uid)
          .maybeSingle();
      return row;
    } catch (_) {
      return null;
    }
  }

  /// Submit quiz answers and calculate score
  /// Scores SERVER-SIDE via the submit_quiz RPC. Correct answers never reach
  /// the client. [answers] is the list of selected option strings, ordered to
  /// match the questions' order.
  Future<Map<String, dynamic>> submitQuizAnswers({
    required String quizId,
    required List<String> answers,
    List<String>? correctAnswers, // ignored; kept for backward compatibility
  }) async {
    final result = await _client.rpc('submit_quiz', params: {
      'p_quiz_id': quizId,
      'p_answers': answers,
    });
    final row = (result is List && result.isNotEmpty) ? result.first : result;
    final score = (row is Map ? (row['score'] as num?) : null)?.toInt() ?? 0;
    final maxScore = (row is Map ? (row['max_score'] as num?) : null)?.toInt() ?? answers.length;
    return {'score': score, 'maxScore': maxScore};
  }

  /// Fetch quiz questions for taking — WITHOUT correct answers (server-stripped).
  Future<List<QuizQuestion>> fetchQuizQuestionsForTaking(String quizId) async {
    final rows = await _client.rpc('get_quiz_questions_for_taking', params: {'p_quiz_id': quizId});
    if (rows is! List) return [];
    return rows.map((r) => QuizQuestion(
      id: r['id'].toString(),
      question: r['question']?.toString() ?? '',
      options: List<String>.from(r['options'] as List? ?? []),
      correctAnswer: '', // not provided during taking
      orderIndex: (r['order_index'] as num?)?.toInt() ?? 0,
    )).toList();
  }

  /// Fetch quiz questions WITH correct answers for review — only works after the
  /// student has submitted (enforced server-side).
  Future<List<QuizQuestion>> fetchQuizReview(String quizId) async {
    final rows = await _client.rpc('get_quiz_review', params: {'p_quiz_id': quizId});
    if (rows is! List) return [];
    return rows.map((r) => QuizQuestion(
      id: r['id'].toString(),
      question: r['question']?.toString() ?? '',
      options: List<String>.from(r['options'] as List? ?? []),
      correctAnswer: r['correct_answer']?.toString() ?? '',
      orderIndex: (r['order_index'] as num?)?.toInt() ?? 0,
    )).toList();
  }

  // ── Grades ────────────────────────────────────────────────────────────────

  /// Fetch all grades for the current student across all enrolled subjects
  Future<List<Map<String, dynamic>>> fetchMyGrades() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return [];

    try {
      final rows = await _client
          .from('student_grades')
          .select('id,subject_offering_id,category,title,score,max_score,remarks,graded_at')
          .eq('student_profile_id', uid)
          .order('graded_at', ascending: false);

      if ((rows as List).isEmpty) return [];

      final subjectIds = rows.map((r) => r['subject_offering_id']?.toString()).whereType<String>().toSet().toList();
      final subjectRows = await _client
          .from('subject_offerings')
          .select('id,subject_name')
          .inFilter('id', subjectIds);

      final Map<String, String> subjectNameMap = {};
      for (final r in (subjectRows as List)) {
        subjectNameMap[r['id'].toString()] = r['subject_name']?.toString() ?? '';
      }

      return rows.map((r) {
        final subjectId = r['subject_offering_id']?.toString() ?? '';
        return <String, dynamic>{
          'id': r['id']?.toString() ?? '',
          'subjectName': subjectNameMap[subjectId] ?? '',
          'subjectId': subjectId,
          'category': r['category']?.toString() ?? 'general',
          'title': r['title']?.toString() ?? '',
          'score': (r['score'] as num?)?.toDouble() ?? 0,
          'maxScore': (r['max_score'] as num?)?.toDouble() ?? 100,
          'remarks': r['remarks']?.toString(),
          'gradedAt': r['graded_at']?.toString() ?? '',
        };
      }).toList();
    } catch (_) {
      return [];
    }
  }

  /// Fetch grades for the current student in a specific subject
  Future<List<Map<String, dynamic>>> fetchMyGradesForSubject(String subjectId) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return [];

    try {
      final rows = await _client
          .from('student_grades')
          .select('id,category,title,score,max_score,remarks,graded_at')
          .eq('student_profile_id', uid)
          .eq('subject_offering_id', subjectId)
          .order('graded_at', ascending: false);

      return (rows as List).map((r) => <String, dynamic>{
        'id': r['id']?.toString() ?? '',
        'category': r['category']?.toString() ?? 'general',
        'title': r['title']?.toString() ?? '',
        'score': (r['score'] as num?)?.toDouble() ?? 0,
        'maxScore': (r['max_score'] as num?)?.toDouble() ?? 100,
        'remarks': r['remarks']?.toString(),
        'gradedAt': r['graded_at']?.toString() ?? '',
      }).toList();
    } catch (_) {
      return [];
    }
  }

  // ── Attendance ────────────────────────────────────────────────────────────

  /// Fetch attendance records for the current student across all subjects
  Future<List<Map<String, dynamic>>> fetchMyAttendance() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return [];

    try {
      final rows = await _client
          .from('attendance_records')
          .select('id,subject_offering_id,date,status,remarks')
          .eq('student_profile_id', uid)
          .order('date', ascending: false);

      if ((rows as List).isEmpty) return [];

      final subjectIds = rows.map((r) => r['subject_offering_id']?.toString()).whereType<String>().toSet().toList();
      final subjectRows = await _client
          .from('subject_offerings')
          .select('id,subject_name')
          .inFilter('id', subjectIds);

      final Map<String, String> subjectNameMap = {};
      for (final r in (subjectRows as List)) {
        subjectNameMap[r['id'].toString()] = r['subject_name']?.toString() ?? '';
      }

      return rows.map((r) {
        final subjectId = r['subject_offering_id']?.toString() ?? '';
        return <String, dynamic>{
          'id': r['id']?.toString() ?? '',
          'subjectName': subjectNameMap[subjectId] ?? '',
          'subjectId': subjectId,
          'date': r['date']?.toString() ?? '',
          'status': r['status']?.toString() ?? 'present',
          'remarks': r['remarks']?.toString(),
        };
      }).toList();
    } catch (_) {
      return [];
    }
  }

  /// Fetch attendance summary for the current student per subject
  Future<Map<String, Map<String, int>>> fetchMyAttendanceSummary() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return {};

    try {
      final rows = await _client
          .from('attendance_records')
          .select('subject_offering_id,status')
          .eq('student_profile_id', uid);

      final Map<String, Map<String, int>> summary = {};
      for (final r in (rows as List)) {
        final subjectId = r['subject_offering_id']?.toString() ?? '';
        final status = r['status']?.toString() ?? 'present';
        summary.putIfAbsent(subjectId, () => {'present': 0, 'late': 0, 'absent': 0, 'total': 0});
        summary[subjectId]![status] = (summary[subjectId]![status] ?? 0) + 1;
        summary[subjectId]!['total'] = (summary[subjectId]!['total'] ?? 0) + 1;
      }
      return summary;
    } catch (_) {
      return {};
    }
  }

  // ── Announcements (filtered to enrolled subjects) ─────────────────────────

  /// Fetch announcements only for subjects the student is enrolled in
  Future<List<Map<String, String>>> fetchMyAnnouncements() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return [];

    try {
      // Get enrolled subject IDs
      final enrollRows = await _client
          .from('subject_enrollments')
          .select('subject_offering_id')
          .eq('student_profile_id', uid);

      final subjectIds = (enrollRows as List)
          .map((r) => r['subject_offering_id']?.toString())
          .whereType<String>()
          .toList();

      if (subjectIds.isEmpty) return [];

      final rows = await _client
          .from('announcements')
          .select('id,subject_offering_id,content,created_at')
          .inFilter('subject_offering_id', subjectIds)
          .order('created_at', ascending: false)
          .limit(30);

      if ((rows as List).isEmpty) return [];

      // Get subject names
      final subjectRows = await _client
          .from('subject_offerings')
          .select('id,subject_name')
          .inFilter('id', subjectIds);
      final Map<String, String> subjectNameMap = {};
      for (final r in (subjectRows as List)) {
        subjectNameMap[r['id'].toString()] = r['subject_name']?.toString() ?? '';
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
          'body': snippet,
          'fullText': content,
          'date': dateStr,
        };
      }).toList();
    } catch (_) {
      return [];
    }
  }

  // ── Meetings (for enrolled subjects) ──────────────────────────────────────

  /// Fetch upcoming meetings for subjects the student is enrolled in
  Future<List<Map<String, dynamic>>> fetchMyMeetings() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return [];

    try {
      final enrollRows = await _client
          .from('subject_enrollments')
          .select('subject_offering_id')
          .eq('student_profile_id', uid);

      final subjectIds = (enrollRows as List)
          .map((r) => r['subject_offering_id']?.toString())
          .whereType<String>()
          .toList();

      if (subjectIds.isEmpty) return [];

      final rows = await _client
          .from('meetings')
          .select('id,subject_offering_id,title,platform,link,meeting_date,meeting_time')
          .inFilter('subject_offering_id', subjectIds)
          .order('meeting_date', ascending: true);

      if ((rows as List).isEmpty) return [];

      final subjectRows = await _client
          .from('subject_offerings')
          .select('id,subject_name')
          .inFilter('id', subjectIds);
      final Map<String, String> subjectNameMap = {};
      for (final r in (subjectRows as List)) {
        subjectNameMap[r['id'].toString()] = r['subject_name']?.toString() ?? '';
      }

      return rows.map((r) {
        final subjectId = r['subject_offering_id']?.toString() ?? '';
        return <String, dynamic>{
          'id': r['id']?.toString() ?? '',
          'subject': subjectNameMap[subjectId] ?? '',
          'title': r['title']?.toString() ?? '',
          'platform': r['platform']?.toString() ?? '',
          'link': r['link']?.toString() ?? '',
          'date': r['meeting_date']?.toString() ?? '',
          'time': r['meeting_time']?.toString() ?? '',
        };
      }).toList();
    } catch (_) {
      return [];
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  // ── Join a class by code (Google Classroom-style) ─────────────────────────

  /// Join a class using its professor-shared code. Returns a status string:
  /// 'ok' | 'already' | 'invalid' | 'not_student'. On ok/already also returns
  /// the subject name.
  Future<Map<String, String>> joinClassByCode(String code) async {
    final result = await _client.rpc('join_class_by_code', params: {'p_code': code.trim()});
    final row = (result is List && result.isNotEmpty) ? result.first : result;
    if (row is Map) {
      return {
        'status': row['status']?.toString() ?? 'invalid',
        'subjectId': row['subject_id']?.toString() ?? '',
        'subjectName': row['subject_name']?.toString() ?? '',
      };
    }
    return {'status': 'invalid', 'subjectId': '', 'subjectName': ''};
  }

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
