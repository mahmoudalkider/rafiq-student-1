import 'package:flutter/material.dart';

import '../models/course_model.dart';
import '../data/courses_data.dart';
import '../services/local_storage_service.dart';
import 'courses_screen.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({Key? key}) : super(key: key);

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  List<Course> _favoriteCourses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    try {
      final favoriteIds = await LocalStorageService.getFavorites();

      final courses = CoursesData.allCourses.where((course) {
        return favoriteIds.contains(course.id);
      }).toList();

      if (!mounted) return;

      setState(() {
        _favoriteCourses = courses;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تعذر تحميل الدورات المفضلة'),
        ),
      );
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

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم حذف الدورة من المفضلة'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تعذر حذف الدورة، حاول مرة أخرى'),
        ),
      );
    }
  }

  void _openCourse(Course course) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CourseDetailsScreen(
          course: course,
        ),
      ),
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
              onPressed: _loadFavorites,
              icon: const Icon(Icons.refresh),
              tooltip: 'تحديث',
            ),
          ],
        ),
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : _favoriteCourses.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
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
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.favorite_border,
              size: 75,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 18),
            const Text(
              'لا توجد دورات مفضلة حتى الآن',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'أضف الدورات التي تحبها إلى المفضلة لتجدها هنا بسهولة.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
