class QuizCategory {
  final String id;
  final String title;
  final String? description;
  final String? icon;

  QuizCategory({
    required this.id,
    required this.title,
    this.description,
    this.icon,
  });

  factory QuizCategory.fromJson(Map<String, dynamic> json) => QuizCategory(
        id: json['id'],
        title: json['title'],
        description: json['description'],
        icon: json['icon'],
      );
}
