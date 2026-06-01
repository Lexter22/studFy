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
                .select('display_name')
                .eq('id', profId)
                .maybeSingle();
            if (profRow != null && profRow['display_name'] != null) {
              profName = profRow['display_name'].toString();
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
}
