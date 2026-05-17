import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/student_subject.dart';
import '../../../professor/domain/models/professor_subject.dart'; // Reuse module/quiz/assignment models if preferred or write clean maps/classes

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
    if (uid == null) return _getMockSubjects();

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
        return _getMockSubjects();
      }

      final subjectRows = await _client
          .from('subject_offerings')
          .select('id,subject_name,course_code,section,year_level,schedule_label,room,professor_profile_id')
          .inFilter('id', subjectIds);

      final List<StudentSubject> list = [];
      for (final r in (subjectRows as List)) {
        final profId = r['professor_profile_id']?.toString();
        String profName = 'Sir Dela Cruz';
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

      if (list.isEmpty) {
        return _getMockSubjects();
      }
      return list;
    } catch (_) {
      return _getMockSubjects();
    }
  }

  List<StudentSubject> _getMockSubjects() {
    return [
      const StudentSubject(
        id: 'mock-ethics',
        name: 'Ethics',
        courseCode: 'ETHICS',
        section: 'BSIT 3-1',
        yearLevel: 3,
        scheduleLabel: 'Monday 3pm - 7pm',
        room: 'Room 302',
        professorName: 'Sir Dela Cruz',
      ),
      const StudentSubject(
        id: 'mock-programming',
        name: 'Computer Programming',
        courseCode: 'COMPPROG',
        section: 'BSIT 3-1',
        yearLevel: 3,
        scheduleLabel: 'Tuesday 1pm - 5pm',
        room: 'Lab 1',
        professorName: 'Sir Dela Cruz',
      ),
      const StudentSubject(
        id: 'mock-capstone',
        name: 'Capstone',
        courseCode: 'CAPSTONE',
        section: 'BSIT 3-1',
        yearLevel: 3,
        scheduleLabel: 'Friday 9am - 12pm',
        room: 'Lab 2',
        professorName: 'Sir Dela Cruz',
      ),
    ];
  }

  Future<List<SubjectModule>> fetchModules(String subjectId) async {
    if (subjectId.startsWith('mock-')) {
      return _getMockModules(subjectId);
    }
    try {
      final rows = await _client
          .from('modules')
          .select('id,title,description,order_index,file_url,file_name')
          .eq('subject_offering_id', subjectId)
          .order('order_index');
      
      final list = (rows as List).map((r) => SubjectModule(
        id: r['id'].toString(),
        title: r['title']?.toString() ?? '',
        description: r['description']?.toString(),
        orderIndex: (r['order_index'] as num?)?.toInt() ?? 0,
        fileUrl: r['file_url']?.toString(),
        fileName: r['file_name']?.toString(),
      )).toList();

      if (list.isEmpty) return _getMockModules(subjectId);
      return list;
    } catch (_) {
      return _getMockModules(subjectId);
    }
  }

  List<SubjectModule> _getMockModules(String subjectId) {
    if (subjectId.contains('ethics')) {
      return [
        const SubjectModule(
          id: 'mock-m1',
          title: 'Lesson 1 - Dilemma',
          description: 'Introduction to ethical dilemmas and decision making framework.',
          orderIndex: 0,
        ),
        const SubjectModule(
          id: 'mock-m2',
          title: 'Moral Standards',
          description: 'Differentiating moral standards from non-moral standards.',
          orderIndex: 1,
        ),
      ];
    }
    return [
      const SubjectModule(
        id: 'mock-m-generic-1',
        title: 'Module 1 - Introduction',
        description: 'Basic introduction to the course contents.',
        orderIndex: 0,
      ),
    ];
  }

  Future<List<SubjectAssignment>> fetchAssignments(String subjectId) async {
    if (subjectId.startsWith('mock-')) {
      return _getMockAssignments(subjectId);
    }
    try {
      final rows = await _client
          .from('assignments')
          .select('id,title,description,deadline,file_url,file_name,module_id')
          .eq('subject_offering_id', subjectId)
          .order('created_at');
      final list = (rows as List).map((r) => SubjectAssignment(
        id: r['id'].toString(),
        title: r['title']?.toString() ?? '',
        description: r['description']?.toString(),
        deadline: r['deadline'] != null ? DateTime.tryParse(r['deadline'].toString()) : null,
        fileUrl: r['file_url']?.toString(),
        fileName: r['file_name']?.toString(),
        moduleId: r['module_id']?.toString(),
      )).toList();

      if (list.isEmpty) return _getMockAssignments(subjectId);
      return list;
    } catch (_) {
      return _getMockAssignments(subjectId);
    }
  }

  List<SubjectAssignment> _getMockAssignments(String subjectId) {
    return [
      SubjectAssignment(
        id: 'mock-a1',
        title: 'Poster Making',
        description: 'Make a creative poster showing your ethical views in technology.',
        deadline: DateTime.now().add(const Duration(days: 2)),
      ),
      SubjectAssignment(
        id: 'mock-a2',
        title: 'Activity 1: PPT',
        description: 'Make a power point presentation about dilemma',
        deadline: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ];
  }

  Future<bool> checkSubmission(String assignmentId) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return false;
    if (assignmentId.startsWith('mock-')) return false;

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
    if (assignmentId.startsWith('mock-')) return;

    await _client.from('assignment_submissions').insert({
      'assignment_id': assignmentId,
      'student_profile_id': uid,
      'file_name': fileName,
      'file_url': fileUrl,
      'submitted_at': DateTime.now().toUtc().toIso8601String(),
    });
  }
}
