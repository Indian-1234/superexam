class QuestionModel {
  final String id;
  final String question;
  final List<String> options;
  final int? correctOptionIndex; // Make it nullable

  QuestionModel({
    required this.id,
    required this.question,
    required this.options,
    required this.correctOptionIndex,
  });

  factory QuestionModel.fromJson(Map<String, dynamic> json) {
    return QuestionModel(
      id: json['questionId'] ?? '', // or use 'id' if your backend returns it like that
      question: json['questionText'],
      options: List<String>.from(json['options']),
      correctOptionIndex: json['correctOptionIndex'] ?? -1, // fallback if missing
    );
  }
}
