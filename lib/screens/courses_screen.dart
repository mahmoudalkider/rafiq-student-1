import 'package:flutter/material.dart';

import '../models/course_model.dart';
import '../data/courses_data.dart';
import '../widgets/course_card.dart';
import '../services/local_storage_service.dart';
import '../services/courses_remote_service.dart';

class CoursesScreen extends StatefulWidget {
  const CoursesScreen({Key? key}) : super(key: key);

  @override
  State<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends State<CoursesScreen> {
  late List<Course> _courses;
  String _searchText = '';
  String _selectedCategory = 'الكل';

  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _courses = CoursesData.allCourses;
    _loadCourses();
  }

  Future<void> _loadCourses() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final remoteCourses =
          await CoursesRemoteService.getCourses();

      if (!mounted) return;

      if (remoteCourses.isNotEmpty) {
        _courses = remoteCourses;
      }

      await _loadFavorites();

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      await _loadFavorites();

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  Future<void> _loadFavorites() async {
    final favorites = await LocalStorageService.getFavorites();

    for (final course in _courses) {
      course.isFavorite = favorites.contains(course.id);
    }
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
          course.title.toLowerCase().contains(
                _searchText.toLowerCase(),
              ) ||
              course.description.toLowerCase().contains(
                    _searchText.toLowerCase(),
                  );

      final matchesCategory =
          _selectedCategory == 'الكل' ||
              course.category == _selectedCategory;

      return matchesSearch &&
          matchesCategory &&
          course.isPublished;
    }).toList();
  }

  Future<void> _toggleFavorite(Course course) async {
    final oldValue = course.isFavorite;

    setState(() {
      course.isFavorite = !oldValue;
    });

    try {
      if (course.isFavorite) {
        await LocalStorageService.addFavorite(course.id);
      } else {
        await LocalStorageService.removeFavorite(course.id);
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        course.isFavorite = oldValue;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تعذر حفظ المفضلة'),
        ),
      );
    }
  }

  void _openCourse(Course course) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            CourseDetailsScreen(course: course),
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
          actions: [
            IconButton(
              onPressed: _loadCourses,
              icon: const Icon(Icons.refresh),
              tooltip: 'تحديث الدورات',
            ),
          ],
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
                  final selected =
                      category == _selectedCategory;

                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                    ),
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
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(),
                    )
                  : Column(
                      children: [
                        if (_hasError)
                          const Padding(
                            padding: EdgeInsets.all(8),
                            child: Text(
                              'تعذر الاتصال بقاعدة البيانات. '
                              'نعرض الدورات المحفوظة محلياً.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.orange),
                            ),
                          ),
                        Expanded(
                          child: courses.isEmpty
                              ? const Center(
                                  child: Text(
                                    'لا توجد دورات مطابقة للبحث.',
                                  ),
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
                                      onTap: () =>
                                          _openCourse(course),
                                      onFavoriteTap: () =>
                                          _toggleFavorite(course),
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class CourseDetailsScreen extends StatefulWidget {
  final Course course;

  const CourseDetailsScreen({
    Key? key,
    required this.course,
  }) : super(key: key);

  @override
  State<CourseDetailsScreen> createState() =>
      _CourseDetailsScreenState();
}

class _CourseDetailsScreenState
    extends State<CourseDetailsScreen> {
  @override
  Widget build(BuildContext context) {
    final course = widget.course;

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
                    color: lesson.isCompleted
                        ? Colors.green
                        : null,
                    size: 20,
                  ),
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            LessonDetailsScreen(
                          lesson: lesson,
                          course: course,
                        ),
                      ),
                    );

                    if (mounted) setState(() {});
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

class LessonDetailsScreen extends StatefulWidget {
  final Lesson lesson;
  final Course course;

  const LessonDetailsScreen({
    Key? key,
    required this.lesson,
    required this.course,
  }) : super(key: key);

  @override
  State<LessonDetailsScreen> createState() =>
      _LessonDetailsScreenState();
}

class _LessonDetailsScreenState
    extends State<LessonDetailsScreen> {
  bool _isSaving = false;

  Future<void> _completeLesson() async {
    if (_isSaving || widget.lesson.isCompleted) {
      Navigator.pop(context);
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await LocalStorageService.markLessonCompleted(
        widget.lesson.id,
        widget.course.id,
      );

      final completedIds =
          await LocalStorageService.getCompletedLessons(
        widget.course.id,
      );

      await LocalStorageService.saveProgress(
        widget.course.id,
        completedIds.toSet().length,
        widget.course.lessons.length,
      );

      widget.lesson.isCompleted = true;

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم حفظ إكمال الدرس بنجاح'),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'حدث خطأ أثناء حفظ تقدمك. حاول مرة أخرى.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final lesson = widget.lesson;

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
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.8,
                ),
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
                  leading:
                      const Icon(Icons.check_circle_outline),
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
                  padding: const EdgeInsets.symmetric(
                    vertical: 6,
                  ),
                  child: Row(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
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
            if (lesson.isCompleted)
              const Card(
                child: ListTile(
                  leading: Icon(
                    Icons.check_circle,
                    color: Colors.green,
                  ),
                  title: Text(
                    'لقد أكملت هذا الدرس سابقاً',
                  ),
                ),
              )
            else
              ElevatedButton.icon(
                onPressed:
                    _isSaving ? null : _completeLesson,
                icon: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.check),
                label: Text(
                  _isSaving
                      ? 'جارٍ الحفظ...'
                      : 'إكمال الدرس',
                ),
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
