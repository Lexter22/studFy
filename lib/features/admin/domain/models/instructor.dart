class Instructor {
  final String name;
  final String course;
  final String subject;

  const Instructor({
    required this.name,
    required this.course,
    required this.subject,
  });

  factory Instructor.fromMap(Map<String, String> map) {
    return Instructor(
      name: map['name'] ?? '',
      course: map['course'] ?? '',
      subject: map['subject'] ?? '',
    );
  }

  Map<String, String> toMap() {
    return {'name': name, 'course': course, 'subject': subject};
  }
}
