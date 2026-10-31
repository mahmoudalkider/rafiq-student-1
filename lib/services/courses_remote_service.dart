
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/course_model.dart';

class CoursesRemoteService {
  static Future<List<Course>> getCourses() async {
    final response = await Supabase.instance.client
        .from('courses')
        .select()
        .eq('is_published', true)
        .order('course_order', ascending: true);

    final rows = response as List<dynamic>;

    return rows.map((item) {
      final json = Map<String, dynamic>.from(item as Map);
      return _courseFromJson(json);
    }).toList();
  }

  static Course _courseFromJson(Map<String, dynamic> json) {
    final rawLessons = json['lessons'];

    final lessons = rawLessons is List
        ? rawLessons
            .whereType<Map>()
            .map((item) => _lessonFromJson(
                  Map<String, dynamic>.from(item),
                ))
            .toList()
        : <Lesson>[];

    return Course(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'دورة بدون عنوان',
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

  static Lesson _lessonFromJson(Map<String, dynamic> json) {
    return Lesson(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'درس بدون عنوان',
      content: json['content']?.toString() ?? '',
      summary: json['summary']?.toString() ?? '',
      sections: _stringList(json['sections']),
      bulletPoints: _stringList(json['bulletPoints']),
      keyTerms: _stringList(json['keyTerms']),
      estimatedMinutes:
          (json['estimatedMinutes'] as num?)?.toInt() ?? 10,
    );
  }

  static List<String> _stringList(dynamic value) {
    if (value is! List) return [];

    return value
        .map((item) => item.toString())
        .toList();
  }
}
