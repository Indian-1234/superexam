class Test {
  final String id;
  final String title;
  final String description;
  final String subjectId;
  final String subjectName;
  final int duration;
  final int totalMarks;
  final int passingMarks;
  final DateTime startTime;
  final DateTime endTime;
  final bool isActive;

  Test({
    required this.id,
    required this.title,
    required this.description,
    required this.subjectId,
    required this.subjectName,
    required this.duration,
    required this.totalMarks,
    required this.passingMarks,
    required this.startTime,
    required this.endTime,
    required this.isActive,
  });

  factory Test.fromJson(Map<String, dynamic> json) {
    return Test(
      id: json['_id'],
      title: json['title'],
      description: json['description'],
      subjectId: json['subjectId'],
      subjectName: json['subjectName'] ?? 'Unknown Subject',
      duration: json['duration'],
      totalMarks: json['totalMarks'],
      passingMarks: json['passingMarks'],
      startTime: DateTime.parse(json['startTime']),
      endTime: DateTime.parse(json['endTime']),
      isActive: json['isActive'],
    );
  }
}

class Question {
  final String id;
  final String question;
  final List<String> options;
  final int marks;
  final String type;

  Question({
    required this.id,
    required this.question,
    required this.options,
    required this.marks,
    required this.type,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['_id'],
      question: json['question'],
      options: List<String>.from(json['options'] ?? []),
      marks: json['marks'],
      type: json['type'],
    );
  }
}
