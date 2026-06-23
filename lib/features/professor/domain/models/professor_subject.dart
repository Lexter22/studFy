class ProfessorSubject {
  final String id;
  final String name;
  final String courseCode;
  final String section;
  final int yearLevel;
  final String? scheduleLabel;
  final String? room;
  String? joinCode;
  int studentCount;

  ProfessorSubject({
    required this.id,
    required this.name,
    required this.courseCode,
    required this.section,
    required this.yearLevel,
    this.scheduleLabel,
    this.room,
    this.joinCode,
    required this.studentCount,
  });
}

class SubjectModule {
  final String id;
  final String title;
  final String? description;
  final int orderIndex;
  final String? fileUrl;
  final String? fileName;

  const SubjectModule({
    required this.id,
    required this.title,
    this.description,
    required this.orderIndex,
    this.fileUrl,
    this.fileName,
  });
}

class SubjectQuiz {
  final String id;
  final String title;
  final String? description;
  final DateTime? deadline;
  final String? moduleId;
  final List<QuizQuestion> questions;

  const SubjectQuiz({
    required this.id,
    required this.title,
    this.description,
    this.deadline,
    this.moduleId,
    this.questions = const [],
  });
}

class QuizQuestion {
  final String id;
  final String question;
  final List<String> options;
  final String correctAnswer;
  final int orderIndex;

  const QuizQuestion({
    required this.id,
    required this.question,
    required this.options,
    required this.correctAnswer,
    required this.orderIndex,
  });
}

class SubjectAssignment {
  final String id;
  final String title;
  final String? description;
  final DateTime? deadline;
  final String? fileUrl;
  final String? fileName;
  final String? moduleId;

  const SubjectAssignment({
    required this.id,
    required this.title,
    this.description,
    this.deadline,
    this.fileUrl,
    this.fileName,
    this.moduleId,
  });
}

class AttendanceRecord {
  final String id;
  final String subjectOfferingId;
  final String studentProfileId;
  final DateTime date;
  final String status; // 'present', 'late', 'absent'
  final String? remarks;
  final String? studentName;

  const AttendanceRecord({
    required this.id,
    required this.subjectOfferingId,
    required this.studentProfileId,
    required this.date,
    required this.status,
    this.remarks,
    this.studentName,
  });
}

class AttendanceSummary {
  final DateTime date;
  final int presentCount;
  final int lateCount;
  final int absentCount;

  const AttendanceSummary({
    required this.date,
    required this.presentCount,
    required this.lateCount,
    required this.absentCount,
  });

  int get total => presentCount + lateCount + absentCount;
}

class StudentAttendanceSummary {
  final String studentProfileId;
  final String studentName;
  final int totalPresent;
  final int totalLate;
  final int totalAbsent;

  const StudentAttendanceSummary({
    required this.studentProfileId,
    required this.studentName,
    required this.totalPresent,
    required this.totalLate,
    required this.totalAbsent,
  });

  int get totalSessions => totalPresent + totalLate + totalAbsent;
  double get attendanceRate =>
      totalSessions > 0 ? (totalPresent + totalLate) / totalSessions * 100 : 0;
}

class StudentGrade {
  final String id;
  final String subjectOfferingId;
  final String studentProfileId;
  final String category; // 'quiz', 'assignment', 'exam', 'project', 'general'
  final String title;
  final double score;
  final double maxScore;
  final String? remarks;
  final DateTime gradedAt;
  final String? studentName;

  const StudentGrade({
    required this.id,
    required this.subjectOfferingId,
    required this.studentProfileId,
    required this.category,
    required this.title,
    required this.score,
    required this.maxScore,
    this.remarks,
    required this.gradedAt,
    this.studentName,
  });

  double get percentage => maxScore > 0 ? (score / maxScore) * 100 : 0;
}

class StudentGradeSummary {
  final String studentProfileId;
  final String studentName;
  final double averagePercentage;
  final int totalItems;
  final double totalScore;
  final double totalMaxScore;

  const StudentGradeSummary({
    required this.studentProfileId,
    required this.studentName,
    required this.averagePercentage,
    required this.totalItems,
    required this.totalScore,
    required this.totalMaxScore,
  });

  bool get isPassing => averagePercentage >= 75;
}
