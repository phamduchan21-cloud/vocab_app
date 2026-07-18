class Vocabulary {
  final String id;
  final String userId;
  final String word;
  final String meaning;
  final String? example;
  final String? personalNote;
  final String? pronunciation;
  final String topic;
  final int reviewCount;
  final int reviewInterval;
  final DateTime? nextReviewDate;
  final double easeFactor;
  final int timesCorrect;
  final int timesWrong;
  final bool isBookmarked;
  final DateTime createdAt;
  final DateTime updatedAt;

  Vocabulary({
    required this.id,
    required this.userId,
    required this.word,
    required this.meaning,
    this.example,
    this.personalNote,
    this.pronunciation,
    this.topic = 'general',
    this.reviewCount = 0,
    this.reviewInterval = 0,
    this.nextReviewDate,
    this.easeFactor = 2.5,
    this.timesCorrect = 0,
    this.timesWrong = 0,
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
    personalNote: json['personal_note'],
    pronunciation: json['pronunciation'],
    topic: json['topic'] ?? 'general',
    reviewCount: json['review_count'] ?? 0,
    reviewInterval: json['review_interval'] ?? 0,
    nextReviewDate: json['next_review_date'] != null
        ? DateTime.tryParse(json['next_review_date'])
        : null,
    easeFactor: (json['ease_factor'] ?? 2.5).toDouble(),
    timesCorrect: json['times_correct'] ?? 0,
    timesWrong: json['times_wrong'] ?? 0,
    isBookmarked: json['is_bookmarked'] ?? false,
    createdAt: DateTime.parse(json['created_at']),
    updatedAt: DateTime.parse(json['updated_at']),
  );

  Map<String, dynamic> toJson() => {
    'word': word,
    'meaning': meaning,
    'example': example,
    'personal_note': personalNote,
    'pronunciation': pronunciation,
    'topic': topic,
  };

  Vocabulary copyWith({bool? isBookmarked}) => Vocabulary(
    id: id,
    userId: userId,
    word: word,
    meaning: meaning,
    example: example,
    personalNote: personalNote,
    pronunciation: pronunciation,
    topic: topic,
    reviewCount: reviewCount,
    reviewInterval: reviewInterval,
    nextReviewDate: nextReviewDate,
    easeFactor: easeFactor,
    timesCorrect: timesCorrect,
    timesWrong: timesWrong,
    isBookmarked: isBookmarked ?? this.isBookmarked,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );
}
