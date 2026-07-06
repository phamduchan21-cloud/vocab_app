class SeedTopicItem {
  final int lessonId;
  final String title;
  final String icon;
  final String description;
  final int count;

  SeedTopicItem({
    required this.lessonId,
    required this.title,
    required this.icon,
    required this.description,
    required this.count,
  });

  factory SeedTopicItem.fromJson(Map<String, dynamic> json) => SeedTopicItem(
        lessonId: json['lesson_id'] ?? 0,
        title: json['title'] ?? '',
        icon: json['icon'] ?? '📖',
        description: json['description'] ?? '',
        count: json['count'] ?? 0,
      );
}

class SeedVocabItem {
  final String word;
  final String meaning;
  final String? example;
  final String? pronunciation;
  final String topic;
  final int lessonId;

  SeedVocabItem({
    required this.word,
    required this.meaning,
    this.example,
    this.pronunciation,
    this.topic = 'general',
    this.lessonId = 0,
  });

  factory SeedVocabItem.fromJson(Map<String, dynamic> json) => SeedVocabItem(
        word: json['word'] ?? '',
        meaning: json['meaning'] ?? '',
        example: json['example'],
        pronunciation: json['pronunciation'],
        topic: json['topic'] ?? 'general',
        lessonId: json['lesson_id'] ?? 0,
      );
}
