class Vocabulary {
  final String id;
  final String userId;
  final String word;
  final String meaning;
  final String? example;
  final String topic;
  final DateTime createdAt;
  final DateTime updatedAt;

  Vocabulary({
    required this.id,
    required this.userId,
    required this.word,
    required this.meaning,
    this.example,
    this.topic = 'general',
    required this.createdAt,
    required this.updatedAt,
  });

  factory Vocabulary.fromJson(Map<String, dynamic> json) => Vocabulary(
        id: json['id'],
        userId: json['user_id'],
        word: json['word'],
        meaning: json['meaning'],
        example: json['example'],
        topic: json['topic'] ?? 'general',
        createdAt: DateTime.parse(json['created_at']),
        updatedAt: DateTime.parse(json['updated_at']),
      );

  Map<String, dynamic> toJson() => {
        'word': word,
        'meaning': meaning,
        'example': example,
        'topic': topic,
      };
}
