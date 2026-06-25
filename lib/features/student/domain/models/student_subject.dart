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

  String get classLabel {
    final String cleanCode;
    final upper = courseCode.toUpperCase();
    if (upper.contains('IT') || upper.contains('ITC')) {
      cleanCode = 'BSIT';
    } else if (upper.contains('MM')) {
      cleanCode = 'BSIE';
    } else if (upper.contains('CPE')) {
      cleanCode = 'BSCPE';
    } else if (upper.contains('CS')) {
      cleanCode = 'BSCS';
    } else {
      cleanCode = courseCode;
    }
    final parts = section.split('-');
    final String secPart;
    if (parts.length > 1) {
      secPart = parts.sublist(1).join('-');
    } else {
      final match = RegExp(r'\d').firstMatch(section);
      secPart = match != null ? match.group(0)! : section.trim();
    }
    if (secPart.isEmpty) {
      return '$cleanCode $yearLevel';
    }
    return '$cleanCode $yearLevel-$secPart';
  }
}

