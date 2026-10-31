
import 'package:flutter/material.dart';

import '../models/course_model.dart';
import '../data/courses_data.dart';
import '../widgets/course_card.dart';

class CoursesScreen extends StatefulWidget {
  const CoursesScreen({Key? key}) : super(key: key);

  @override
  State<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends State<CoursesScreen> {
  late List<Course> _courses;
  String _searchText = '';
  String _selectedCategory = 'الكل';

  @override
  void initState() {
    super.initState();
    _courses = CoursesData.allCourses;
  }

  List<String> get _categories {
    final categories = _courses
        .map((course) => course.category)
        .toSet()
        .toList();

    categories.sort();
    return ['الكل', ...categories];
  }

  List<Course> get _filteredCourses {
    return _courses.where((course) {
      final matchesSearch =
          course.title.toLowerCase().contains(_searchText.toLowerCase()) ||
          course.description
              .toLowerCase()
              .contains(_searchText.toLowerCase());

      final matchesCategory = _selectedCategory == 'الكل' ||
          course.category == _selectedCategory;

      return matchesSearch && matchesCategory && course.isPublished;
    }).toList();
  }

  void _openCourse(Course course) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CourseDetailsScreen(course: course),
      ),
    ).then((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final courses = _filteredCourses;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('الدورات التعليمية'),
          centerTitle: true,
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                textDirection: TextDirection.rtl,
                onChanged: (value) {
                  setState(() {
                    _searchText = value;
                  });
                },
                decoration: InputDecoration(
                  hintText: 'ابحث عن دورة...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            SizedBox(
              height: 48,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: _categories.map((category) {
                  final selected = category == _selectedCategory;

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    child: ChoiceChip(
                      label: Text(category),
                      selected: selected,
                      onSelected: (_) {
                        setState(() {
                          _selectedCategory = category;
                        });
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            Expanded(
              child: courses.isEmpty
                  ? const Center(
                      child: Text('لا توجد دورات مطابقة للبحث.'),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.all(8),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.72,
                        crossAxisSpacing: 4,
                        mainAxisSpacing: 4,
                      ),
                      itemCount: courses.length,
                      itemBuilder: (context, index) {
                        final course = courses[index];

                        return CourseCard(
                          course: course,
                          onTap: () => _openCourse(course),
                          onFavoriteTap: () {
                            setState(() {
                              course.isFavorite = !course.isFavorite;
                            });
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class CourseDetailsScreen extends StatelessWidget {
  final Course course;

  const CourseDetailsScreen({
    Key? key,
    required this.course,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(course.title),
          centerTitle: true,
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Center(
              child: Text(
                course.imageUrl,
                style: const TextStyle(fontSize: 65),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              course.title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 10),
            Text(
              course.description,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _InfoItem(
                  icon: Icons.menu_book,
                  label: '${course.lessons.length} دروس',
                ),
                _InfoItem(
                  icon: Icons.signal_cellular_alt,
                  label: course.difficulty,
                ),
                _InfoItem(
                  icon: Icons.category,
                  label: course.category,
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'محتويات الدورة',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...course.lessons.asMap().entries.map((entry) {
              final index = entry.key;
              final lesson = entry.value;

              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text('${index + 1}'),
                  ),
                  title: Text(lesson.title),
                  subtitle: Text(
                    '${lesson.estimatedMinutes} دقيقة',
                  ),
                  trailing: Icon(
                    lesson.isCompleted
                        ? Icons.check_circle
                        : Icons.arrow_forward_ios,
                    color: lesson.isCompleted ? Colors.green : null,
                    size: 20,
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            LessonDetailsScreen(lesson: lesson),
                      ),
                    );
                  },
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class LessonDetailsScreen extends StatelessWidget {
  final Lesson lesson;

  const LessonDetailsScreen({
    Key? key,
    required this.lesson,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('شرح الدرس'),
          centerTitle: true,
        ),
        body: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            Text(
              lesson.title,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.access_time, size: 18),
                const SizedBox(width: 6),
                Text('${lesson.estimatedMinutes} دقيقة'),
              ],
            ),
            const Divider(height: 30),
            Text(
              lesson.content,
              style: const TextStyle(
                fontSize: 17,
                height: 1.9,
              ),
            ),
            if (lesson.summary.isNotEmpty) ...[
              const SizedBox(height: 24),
              const Text(
                'ملخص الدرس',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                lesson.summary,
                style: const TextStyle(fontSize: 16, height: 1.8),
              ),
            ],
            if (lesson.sections.isNotEmpty) ...[
              const SizedBox(height: 24),
              const Text(
                'محاور الدرس',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              ...lesson.sections.map(
                (section) => ListTile(
                  leading: const Icon(Icons.check_circle_outline),
                  title: Text(section),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
            if (lesson.bulletPoints.isNotEmpty) ...[
              const SizedBox(height: 20),
              const Text(
                'أهم النقاط',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              ...lesson.bulletPoints.map(
                (point) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.circle,
                        size: 8,
                        color: Colors.blue,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          point,
                          style: const TextStyle(
                            fontSize: 16,
                            height: 1.6,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            if (lesson.keyTerms.isNotEmpty) ...[
              const SizedBox(height: 20),
              const Text(
                'مصطلحات مهمة',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: lesson.keyTerms.map((term) {
                  return Chip(label: Text(term));
                }).toList(),
              ),
            ],
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                lesson.isCompleted = true;
                Navigator.pop(context);
              },
              icon: const Icon(Icons.check),
              label: const Text('إكمال الدرس'),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoItem({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 22),
        const SizedBox(height: 5),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }
}
