class SecurityQuestion {
  final String id;
  final String question;

  const SecurityQuestion({required this.id, required this.question});
}

class SecurityAnswer {
  final String questionId;
  final String answer;

  const SecurityAnswer({required this.questionId, required this.answer});
}
