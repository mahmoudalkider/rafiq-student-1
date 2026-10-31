import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/course_model.dart';

class CoursesRemoteService {
  static Future<List<Course>> getCourses() async {
    final response = await Supabase.instance.client
        .from('courses')
        .select()
        .eq('is_published', true);

    return (response as List)
        .map((item) => _courseFromJson(
              Map<String, dynamic>.from(item),
            ))
        .toList();
  }

  static Course _courseFromJson(Map<String, dynamic> json) {
    final lessonsData = json['lessons'] as List? ?? [];

    final lessons = lessonsData.map((item) {
      final lesson = Map<String, dynamic>.from(item);

      return Lesson(
        id: lesson['id']?.toString() ?? '',
        title: lesson['title']?.toString() ?? '',
        content: lesson['content']?.toString() ?? '',
        summary: lesson['summary']?.toString() ?? '',
        sections: List<String>.from(lesson['sections'] ?? []),
        bulletPoints:
            List<String>.from(lesson['bulletPoints'] ?? []),
        keyTerms: List<String>.from(lesson['keyTerms'] ?? []),
        estimatedMinutes:
            (lesson['estimatedMinutes'] as num?)?.toInt() ?? 10,
      );
    }).toList();

    return Course(
      id: json['id'].toString(),
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      category: json['category']?.toString() ?? 'عام',
      difficulty: json['difficulty']?.toString() ?? 'مبتدئ',
      imageUrl: json['image_url']?.toString() ?? '📚',
      totalLessons: lessons.length,
      lessons: lessons,
      accessLevel: json['access_level']?.toString() ?? 'public',
      isPublished: json['is_published'] == true,
    );
  }
}
