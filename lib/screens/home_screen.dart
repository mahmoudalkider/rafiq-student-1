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

  @override
  void initState() {
    super.initState();

    _allCourses = CoursesData.allCourses;
    _displayedCourses = _allCourses;

    _loadFavoritesAndProgress();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // تحميل المفضلة ونسبة التقدم
  Future<void> _loadFavoritesAndProgress() async {
    try {
      final favorites = await LocalStorageService.getFavorites();

      for (final course in _allCourses) {
        course.isFavorite = favorites.contains(course.id);

        final progress =
            await LocalStorageService.getProgress(course.id);

        if (progress != null) {
          course.progressPercentage =
              (progress['progressPercentage'] as num).toDouble();
        }
      }

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      debugPrint('خطأ في تحميل بيانات الطالب: $e');
    }
  }

  // تصنيفات الدورات
  List<String> get _categories {
    final categories = _allCourses
        .map((course) => course.category)
        .toSet()
        .toList();

    categories.sort();

    return ['الكل', ...categories];
  }

  // البحث والتصفية
  void _handleSearch(String query) {
    final searchText = query.trim().toLowerCase();

    setState(() {
      _displayedCourses = _allCourses.where((course) {
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
    });
  }

  void _selectCategory(String category) {
    setState(() {
      _selectedCategory = category;
    });

    _handleSearch(_searchController.text);
  }

  // إضافة دورة إلى المفضلة أو إزالتها
  Future<void> _toggleFavorite(Course course) async {
    setState(() {
      course.isFavorite = !course.isFavorite;
    });

    try {
      if (course.isFavorite) {
        await LocalStorageService.addFavorite(course.id);
      } else {
        await LocalStorageService.removeFavorite(course.id);
      }
    } catch (e) {
      debugPrint('خطأ في حفظ المفضلة: $e');
    }
  }

  // فتح تفاصيل الدورة
  void _openCourse(Course course) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CourseDetailsScreen(course: course),
      ),
    ).then((_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  // رسالة للميزات التي لم يتم ربطها بعد
  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature: هذه الميزة قيد التجهيز'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final publishedCourses =
        _allCourses.where((course) => course.isPublished).length;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'رفيق الطالب',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
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

                _buildStatistics(publishedCourses),

                _buildCategoriesSection(),

                _buildCoursesSection(),

                _buildToolsSection(),

                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // قسم الترحيب
  Widget _buildWelcomeSection() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF1565C0),
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
              fontSize: 21,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 12),
          Text(
            'تعلم البرمجة والحاسوب والشبكات والأمن السيبراني والكهرباء، وابدأ رحلتك التعليمية من هنا.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              height: 1.8,
            ),
          ),
        ],
      ),
    );
  }

  // قسم البحث
  Widget _buildSearchSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: CustomSearchBar(
        controller: _searchController,
        onChanged: _handleSearch,
        onClear: () {
          _searchController.clear();
          _handleSearch('');
        },
      ),
    );
  }

  // الإحصائيات
  Widget _buildStatistics(int courseCount) {
    final favoritesCount =
        _allCourses.where((course) => course.isFavorite).length;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              icon: Icons.menu_book,
              title: 'الدورات',
              value: '$courseCount',
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _buildStatCard(
              icon: Icons.favorite,
              title: 'المفضلة',
              value: '$favoritesCount',
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _buildStatCard(
              icon: Icons.school,
              title: 'التعلم',
              value: 'ابدأ الآن',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: 15,
          horizontal: 5,
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.blue, size: 26),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
              textAlign: TextAlign.center,
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

  // تصنيفات المواد
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
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: _categories.map((category) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
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

  // الدورات التعليمية
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
              child: Text('لا توجد دورات مطابقة للبحث.'),
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 8),
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
                onFavoriteTap: () => _toggleFavorite(course),
              );
            },
          ),
      ],
    );
  }

  // أدوات الطالب
  Widget _buildToolsSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'أدوات تساعدك على التعلم',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 14),

          _buildToolCard(
            icon: Icons.smart_toy,
            title: 'اسأل رفيق الطالب',
            description: 'احصل على المساعدة في فهم دروسك.',
            color: Colors.blue,
            onTap: () {
              _showComingSoon('المساعد الذكي');
            },
          ),

          const SizedBox(height: 12),

          _buildToolCard(
            icon: Icons.summarize,
            title: 'تلخيص درس',
            description: 'جهز درسك للتلخيص والمراجعة.',
            color: Colors.deepPurple,
            onTap: () {
              _showComingSoon('تلخيص الدروس');
            },
          ),

          const SizedBox(height: 12),

          _buildToolCard(
            icon: Icons.quiz,
            title: 'إنشاء اختبار',
            description: 'اختبر معلوماتك واستعد للامتحانات.',
            color: Colors.orange,
            onTap: () {
              _showComingSoon('إنشاء الاختبارات');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildToolCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: CircleAvatar(
          radius: 25,
          backgroundColor: color.withOpacity(0.12),
          child: Icon(icon, color: color),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Text(description),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 17),
        onTap: onTap,
      ),
    );
  }
}
