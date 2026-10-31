
class Course {
  final String id;
  final String title;
  final String description;
  final String category;
  final String difficulty;
  final String imageUrl;
  final int totalLessons;
  final List<Lesson> lessons;

  // مستوى الوصول إلى الدورة
  final String accessLevel; // public, normal, vip

  // حالة نشر الدورة من لوحة المالك
  bool isPublished;

  bool isFavorite;
  double progressPercentage;

  Course({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.difficulty,
    required this.imageUrl,
    required this.totalLessons,
    required this.lessons,
    this.accessLevel = 'public',
    this.isPublished = true,
    this.isFavorite = false,
    this.progressPercentage = 0.0,
  });
}

class Lesson {
  final String id;
  final String title;
  final String content;

  // ملخص الدرس
  final String summary;

  // الكلمات والمصطلحات المهمة
  final List<String> keyTerms;

  final List<String> sections;
  final List<String> bulletPoints;
  final String? imageUrl;

  // الزمن التقريبي للدرس بالدقائق
  final int estimatedMinutes;

  bool isCompleted;
  Quiz? quiz;

  Lesson({
    required this.id,
    required this.title,
    required this.content,
    this.summary = '',
    this.keyTerms = const [],
    required this.sections,
    required this.bulletPoints,
    this.imageUrl,
    this.estimatedMinutes = 10,
    this.isCompleted = false,
    this.quiz,
  });
}

class Quiz {
  final String id;
  final String title;
  final List<QuizQuestion> questions;

  int? userScore;
  bool? isCompleted;

  Quiz({
    required this.id,
    required this.title,
    required this.questions,
    this.userScore,
    this.isCompleted = false,
  });
}

class QuizQuestion {
  final String id;
  final String question;
  final List<String> options;
  final int correctAnswerIndex;

  int? userAnswerIndex;

  QuizQuestion({
    required this.id,
    required this.question,
    required this.options,
    required this.correctAnswerIndex,
    this.userAnswerIndex,
  });
}
