class StudentData {
  final String name;
  final String course;
  final String yearSection;
  final List<String> subjects;

  const StudentData({
    required this.name,
    required this.course,
    required this.yearSection,
    this.subjects = const [],
  });
}
