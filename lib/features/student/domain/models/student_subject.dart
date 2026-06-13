class StudentSubject {
  final String id;
  final String name;
  final String courseCode;
  final String section;
  final int yearLevel;
  final String? scheduleLabel;
  final String? room;
  final String professorName;

  const StudentSubject({
    required this.id,
    required this.name,
    required this.courseCode,
    required this.section,
    required this.yearLevel,
    this.scheduleLabel,
    this.room,
    required this.professorName,
  });
}
