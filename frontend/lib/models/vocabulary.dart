class Vocabulary {
  final String id;
  final String userId;
  final String word;
  final String meaning;
  final String? example;
  final String? pronunciation;
  final String topic;
  final int reviewCount;
  final bool isBookmarked;
  final DateTime createdAt;
  final DateTime updatedAt;

  Vocabulary({
    required this.id,
    required this.userId,
    required this.word,
    required this.meaning,
    this.example,
    this.pronunciation,
    this.topic = 'general',
    this.reviewCount = 0,
    this.isBookmarked = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Vocabulary.fromJson(Map<String, dynamic> json) => Vocabulary(
        id: json['id'],
        userId: json['user_id'],
        word: json['word'],
        meaning: json['meaning'],
        example: json['example'],
        pronunciation: json['pronunciation'],
        topic: json['topic'] ?? 'general',
        reviewCount: json['review_count'] ?? 0,
        isBookmarked: json['is_bookmarked'] ?? false,
        createdAt: DateTime.parse(json['created_at']),
        updatedAt: DateTime.parse(json['updated_at']),
      );

  Map<String, dynamic> toJson() => {
        'word': word,
        'meaning': meaning,
        'example': example,
        'pronunciation': pronunciation,
        'topic': topic,
      };

  Vocabulary copyWith({bool? isBookmarked}) => Vocabulary(
        id: id,
        userId: userId,
        word: word,
        meaning: meaning,
        example: example,
        pronunciation: pronunciation,
        topic: topic,
        reviewCount: reviewCount,
        isBookmarked: isBookmarked ?? this.isBookmarked,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}
