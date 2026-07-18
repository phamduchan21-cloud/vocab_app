class QuizTopic {
  final String key;
  final String label;

  const QuizTopic({required this.key, required this.label});

  factory QuizTopic.fromJson(Map<String, dynamic> json) =>
      QuizTopic(key: json['key'] as String, label: json['label'] as String);

  Map<String, dynamic> toJson() => {'key': key, 'label': label};
}
