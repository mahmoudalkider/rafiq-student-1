
import 'package:flutter/material.dart';

import '../data/courses_data.dart';
import '../models/course_model.dart';
import '../services/local_storage_service.dart';
import '../services/courses_remote_service.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({Key? key}) : super(key: key);

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  bool _isLoading = true;
  int _completedLessons = 0;
  int _totalLessons = 0;
  List<_CourseProgress> _courseProgress = [];

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    if (mounted) {
      setState(() => _isLoading = true);
    }

    try {
      List<Course> courses;

      try {
        final remote = await CoursesRemoteService.getCourses();
        courses = remote.isNotEmpty ? remote : CoursesData.allCourses;
      } catch (_) {
        courses = CoursesData.allCourses;
      }

      int completedTotal = 0;
      int lessonsTotal = 0;
      final results = <_CourseProgress>[];

      for (final course in courses.where((c) => c.isPublished)) {
        final completedIds =
            await LocalStorageService.getCompletedLessons(course.id);

        final completed = completedIds.toSet().length;
        final total = course.lessons.length;

        completedTotal += completed;
        lessonsTotal += total;

        results.add(
          _CourseProgress(
            course: course,
            completed: completed.clamp(0, total),
            total: total,
          ),
        );
      }

      if (!mounted) return;

      setState(() {
        _completedLessons = completedTotal;
        _totalLessons = lessonsTotal;
        _courseProgress = results;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('خطأ في تحميل التقدم: $e');

      if (!mounted) return;

      setState(() => _isLoading = false);
      _message('تعذر تحميل تقدمك الدراسي');
    }
  }

  double get _overallProgress {
    if (_totalLessons == 0) return 0;
    return (_completedLessons / _totalLessons).clamp(0.0, 1.0);
  }

  void _message(String value) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(value)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final percentage = (_overallProgress * 100).round();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('تقدمي الدراسي'),
          centerTitle: true,
          actions: [
            IconButton(
              onPressed: _isLoading ? null : _loadProgress,
              icon: const Icon(Icons.refresh),
              tooltip: 'تحديث التقدم',
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadProgress,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildSummaryCard(percentage),
                    const SizedBox(height: 24),
                    const Text(
                      'تقدمك في كل دورة',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_courseProgress.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(
                          child: Text('لا توجد دورات متاحة حالياً.'),
                        ),
                      )
                    else
                      ..._courseProgress.map(_buildCourseCard),
                    const SizedBox(height: 24),
                    _buildMotivationCard(),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildSummaryCard(int percentage) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(
              Icons.trending_up,
              size: 55,
              color: Colors.blue,
            ),
            const SizedBox(height: 12),
            const Text(
              'ملخص تقدمك الدراسي',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNumber(
                  '$_completedLessons',
                  'دروس مكتملة',
                  Colors.green,
                ),
                _buildNumber(
                  '$_totalLessons',
                  'إجمالي الدروس',
                  Colors.blue,
                ),
              ],
            ),
            const SizedBox(height: 24),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: LinearProgressIndicator(
                value: _overallProgress,
                minHeight: 12,
                backgroundColor: Colors.grey.shade300,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '$percentage% من إجمالي الدروس',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNumber(String number, String label, Color color) {
    return Column(
      children: [
        Text(
          number,
          style: TextStyle(
            fontSize: 27,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 5),
        Text(label),
      ],
    );
  }

  Widget _buildCourseCard(_CourseProgress item) {
    final progress = item.total == 0
        ? 0.0
        : (item.completed / item.total).clamp(0.0, 1.0);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.course.title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${item.completed} من ${item.total} درس'),
                Text('${(progress * 100).round()}%'),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 9,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMotivationCard() {
    String message;
    IconData icon;

    if (_completedLessons == 0) {
      message = 'ابدأ أول درس لك اليوم، وكل خطوة تقربك من هدفك.';
      icon = Icons.flag;
    } else if (_overallProgress >= 1) {
      message = 'رائع! لقد أكملت جميع الدروس المتاحة. استمر في التعلم!';
      icon = Icons.emoji_events;
    } else {
      message = 'أحسنت! واصل التعلم، فأنت تتقدم نحو هدفك.';
      icon = Icons.star;
    }

    return Card(
      color: Colors.blue.withOpacity(0.08),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Icon(icon, color: Colors.blue, size: 32),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.6,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CourseProgress {
  final Course course;
  final int completed;
  final int total;

  _CourseProgress({
    required this.course,
    required this.completed,
    required this.total,
  });
}
