class QuestionModel {
  final String id;
  final String question;
  final List<String> options;
  final int correctOptionIndex;

  QuestionModel({
    required this.id,
    required this.question,
    required this.options,
    required this.correctOptionIndex,
  });

  // Add toString method for debugging
  @override
  String toString() {
    return 'QuestionModel(id: $id, question: $question, options: $options, correctOptionIndex: $correctOptionIndex)';
  }
}
