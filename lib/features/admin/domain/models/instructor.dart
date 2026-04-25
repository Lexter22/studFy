class Instructor {
  final String profileId;
  final String name;
  final String course;
  final String subject;

  const Instructor({
    required this.profileId,
    required this.name,
    required this.course,
    required this.subject,
  });

  factory Instructor.fromMap(Map<String, String> map) {
    return Instructor(
      profileId: map['profileId'] ?? '',
      name: map['name'] ?? '',
      course: map['course'] ?? '',
      subject: map['subject'] ?? '',
    );
  }

  Map<String, String> toMap() {
    return {
      'profileId': profileId,
      'name': name,
      'course': course,
      'subject': subject,
    };
  }
}
