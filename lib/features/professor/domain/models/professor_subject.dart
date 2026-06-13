class ProfessorSubject {
  final String id;
  final String name;
  final String courseCode;
  final String section;
  final int yearLevel;
  final String? scheduleLabel;
  final String? room;
  final int studentCount;

  const ProfessorSubject({
    required this.id,
    required this.name,
    required this.courseCode,
    required this.section,
    required this.yearLevel,
    this.scheduleLabel,
    this.room,
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
