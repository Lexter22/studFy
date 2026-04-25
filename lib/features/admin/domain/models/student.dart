class StudentData {
  final String profileId;
  final String name;
  final String course;
  final String yearSection;
  final List<String> subjects;

  const StudentData({
    required this.profileId,
    required this.name,
    required this.course,
    required this.yearSection,
    this.subjects = const [],
  });
}
