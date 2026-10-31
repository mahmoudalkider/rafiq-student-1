import 'package:flutter/material.dart';

import '../models/course_model.dart';
import '../data/courses_data.dart';
import '../services/local_storage_service.dart';
import '../widgets/course_card.dart';
import '../widgets/search_bar.dart';
import 'courses_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController =
      TextEditingController();

  late List<Course> _allCourses;
  late List<Course> _displayedCourses;

  String _selectedCategory = 'الكل';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    _allCourses = CoursesData.allCourses;
    _displayedCourses = List.from(_allCourses);

    _loadFavoritesAndProgress();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFavoritesAndProgress() async {
    if (_isLoading) return;

    _isLoading = true;

    try {
      final favorites =
          await LocalStorageService.getFavorites();

      for (final course in _allCourses) {
        course.isFavorite = favorites.contains(course.id);

        final progress =
            await LocalStorageService.getProgress(course.id);

        if (progress != null) {
          course.progressPercentage =
              (progress['progressPercentage'] as num)
                  .toDouble();
        }
      }

      _filterCourses(_searchController.text);

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      debugPrint('خطأ في تحميل بيانات الطالب: $e');
    } finally {
      _isLoading = false;
    }
  }

  List<String> get _categories {
    final categories = _allCourses
        .map((course) => course.category)
        .toSet()
        .toList();

    categories.sort();

    return ['الكل', ...categories];
  }

  void _filterCourses(String query) {
    final searchText = query.trim().toLowerCase();

    final results = _allCourses.where((course) {
      final matchesSearch =
          course.title.toLowerCase().contains(searchText) ||
          course.description.toLowerCase().contains(searchText) ||
          course.category.toLowerCase().contains(searchText);

      final matchesCategory =
          _selectedCategory == 'الكل' ||
          course.category == _selectedCategory;

      return matchesSearch &&
          matchesCategory &&
          course.isPublished;
    }).toList();

    if (!mounted) return;

    setState(() {
      _displayedCourses = results;
    });
  }

  void _selectCategory(String category) {
    setState(() {
      _selectedCategory = category;
    });

    _filterCourses(_searchController.text);
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
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final publishedCourses = _allCourses
        .where((course) => course.isPublished)
        .length;

    final favoritesCount = _allCourses
        .where((course) => course.isFavorite)
        .length;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'رفيق الطالب',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              tooltip: 'تحديث',
              icon: const Icon(Icons.refresh),
              onPressed: _loadFavoritesAndProgress,
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: _loadFavoritesAndProgress,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildWelcomeSection(),
                _buildSearchSection(),
                _buildStatistics(
                  publishedCourses,
                  favoritesCount,
                ),
                _buildCategoriesSection(),
                _buildCoursesSection(),
                _buildLearningSection(),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF123B70),
            Color(0xFF1976D2),
            Color(0xFF42A5F5),
          ],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'مرحباً بك في رفيق الطالب 👋',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 12),
          Text(
            'منصتك التعليمية لتعلم الحاسوب والبرمجة والشبكات والأمن السيبراني والكهرباء.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              height: 1.8,
            ),
          ),
          SizedBox(height: 15),
          Text(
            'ابدأ التعلم اليوم وطور مهاراتك خطوة بخطوة.',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: CustomSearchBar(
        controller: _searchController,
        onChanged: _filterCourses,
        onClear: () {
          _searchController.clear();
          _filterCourses('');
        },
      ),
    );
  }

  Widget _buildStatistics(
    int courseCount,
    int favoritesCount,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              Icons.menu_book,
              'الدورات',
              '$courseCount',
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _buildStatCard(
              Icons.favorite,
              'المفضلة',
              '$favoritesCount',
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _buildStatCard(
              Icons.school,
              'التعلم',
              'مستمر',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    IconData icon,
    String title,
    String value,
  ) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 5,
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: const Color(0xFF1976D2),
              size: 27,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoriesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'استكشف المجالات التعليمية',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 48,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
            ),
            children: _categories.map((category) {
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 4,
                ),
                child: ChoiceChip(
                  label: Text(category),
                  selected: _selectedCategory == category,
                  onSelected: (_) {
                    _selectCategory(category);
                  },
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildCoursesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 24, 16, 12),
          child: Text(
            'الدورات التعليمية',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        if (_displayedCourses.isEmpty)
          const Padding(
            padding: EdgeInsets.all(30),
            child: Center(
              child: Text(
                'لا توجد دورات مطابقة للبحث.',
              ),
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics:
                const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
            ),
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.72,
              crossAxisSpacing: 4,
              mainAxisSpacing: 4,
            ),
            itemCount: _displayedCourses.length,
            itemBuilder: (context, index) {
              final course = _displayedCourses[index];

              return CourseCard(
                course: course,
                onTap: () => _openCourse(course),
                onFavoriteTap: () =>
                    _toggleFavorite(course),
              );
            },
          ),
      ],
    );
  }

  Widget _buildLearningSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withOpacity(0.5),
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                color: Color(0xFF1976D2),
              ),
              SizedBox(width: 8),
              Text(
                'نصيحة تعليمية',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          Text(
            'خصص وقتاً يومياً للتعلم والتطبيق العملي. '
            'لا تكتفِ بقراءة الدروس، بل جرّب كتابة الأكواد '
            'وتنفيذ التمارين بنفسك.',
            style: TextStyle(
              height: 1.8,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
