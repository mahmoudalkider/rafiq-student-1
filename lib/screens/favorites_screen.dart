
import 'package:flutter/material.dart';

import '../models/course_model.dart';
import '../data/courses_data.dart';
import '../services/local_storage_service.dart';
import '../services/courses_remote_service.dart';
import 'courses_screen.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({Key? key}) : super(key: key);

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  List<Course> _favoriteCourses = [];
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });
    }

    try {
      final favoriteIds = await LocalStorageService.getFavorites();

      List<Course> courses;

      try {
        final remoteCourses = await CoursesRemoteService.getCourses();
        courses = remoteCourses.isNotEmpty
            ? remoteCourses
            : CoursesData.allCourses;
      } catch (_) {
        courses = CoursesData.allCourses;
        _hasError = true;
      }

      final favorites = courses.where((course) {
        return favoriteIds.contains(course.id) && course.isPublished;
      }).toList();

      for (final course in favorites) {
        course.isFavorite = true;
      }

      if (!mounted) return;

      setState(() {
        _favoriteCourses = favorites;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _hasError = true;
      });

      _message('تعذر تحميل الدورات المفضلة');
    }
  }

  Future<void> _removeFavorite(Course course) async {
    try {
      await LocalStorageService.removeFavorite(course.id);

      if (!mounted) return;

      setState(() {
        _favoriteCourses.removeWhere(
          (item) => item.id == course.id,
        );
        course.isFavorite = false;
      });

      _message('تم حذف الدورة من المفضلة');
    } catch (_) {
      _message('تعذر حذف الدورة. حاول مرة أخرى.');
    }
  }

  void _openCourse(Course course) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CourseDetailsScreen(course: course),
      ),
    ).then((_) {
      if (mounted) _loadFavorites();
    });
  }

  void _message(String value) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(value)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('الدورات المفضلة'),
          centerTitle: true,
          actions: [
            IconButton(
              onPressed: _isLoading ? null : _loadFavorites,
              icon: const Icon(Icons.refresh),
              tooltip: 'تحديث المفضلة',
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadFavorites,
                child: _favoriteCourses.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.25,
                          ),
                          const Icon(
                            Icons.favorite_border,
                            size: 75,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 18),
                          const Center(
                            child: Text(
                              'لا توجد دورات مفضلة حتى الآن',
                              style: TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Center(
                            child: Text(
                              'افتح الدورات واضغط على علامة القلب لإضافتها هنا.',
                              textAlign: TextAlign.center,
                            ),
                          ),
                          if (_hasError)
                            const Padding(
                              padding: EdgeInsets.all(12),
                              child: Text(
                                'تعذر الاتصال بالخادم. يتم استخدام البيانات المحلية عند توفرها.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.orange),
                              ),
                            ),
                        ],
                      )
                    : ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(12),
                        itemCount: _favoriteCourses.length,
                        itemBuilder: (context, index) {
                          final course = _favoriteCourses[index];

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(12),
                              leading: CircleAvatar(
                                radius: 27,
                                child: Text(
                                  course.imageUrl,
                                  style: const TextStyle(fontSize: 25),
                                ),
                              ),
                              title: Text(
                                course.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  course.description,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              trailing: IconButton(
                                onPressed: () => _removeFavorite(course),
                                icon: const Icon(
                                  Icons.favorite,
                                  color: Colors.red,
                                ),
                                tooltip: 'إزالة من المفضلة',
                              ),
                              onTap: () => _openCourse(course),
                            ),
                          );
                        },
                      ),
              ),
      ),
    );
  }
}
