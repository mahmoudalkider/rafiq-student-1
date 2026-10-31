
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'theme/app_theme.dart';
import 'screens/home_screen.dart';
import 'screens/courses_screen.dart';
import 'screens/favorites_screen.dart';
import 'screens/progress_screen.dart';
import 'screens/account_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  bool supabaseReady = false;

  try {
    await Supabase.initialize(
      url: 'https://fvkyprjvoxwsevaqaluw.supabase.co',
      publishableKey: 'sb_publishable_zcdOiO6nTY5XzWpHlhvZuQ_G4pDSJR',
    );

    supabaseReady = true;
  } catch (error) {
    debugPrint('Supabase initialization failed: $error');
  }

  runApp(RafiqStudentApp(
    supabaseReady: supabaseReady,
  ));
}

class RafiqStudentApp extends StatelessWidget {
  final bool supabaseReady;

  const RafiqStudentApp({
    Key? key,
    required this.supabaseReady,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'رفيق الطالب',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: MainApp(
        supabaseReady: supabaseReady,
      ),
    );
  }
}

class MainApp extends StatefulWidget {
  final bool supabaseReady;

  const MainApp({
    Key? key,
    required this.supabaseReady,
  }) : super(key: key);

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  int _selectedIndex = 0;

  late final List<Widget> _screens = [
    const HomeScreen(),
    const CoursesScreen(),
    const FavoritesScreen(),
    const ProgressScreen(),
    const AccountScreen(),
  ];

  void _changePage(int index) {
    if (index < 0 || index >= _screens.length) return;

    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          if (!widget.supabaseReady)
            Material(
              color: Colors.orange.shade100,
              child: const Padding(
                padding: EdgeInsets.all(10),
                child: Row(
                  children: [
                    Icon(Icons.wifi_off, color: Colors.deepOrange),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'تعذر الاتصال بالخادم. بعض الخدمات قد لا تعمل.',
                        style: TextStyle(color: Colors.black87),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Expanded(
            child: IndexedStack(
              index: _selectedIndex,
              children: _screens,
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        type: BottomNavigationBarType.fixed,
        onTap: _changePage,
        selectedFontSize: 12,
        unselectedFontSize: 11,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'الرئيسية',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book_outlined),
            activeIcon: Icon(Icons.menu_book),
            label: 'الدورات',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite_border),
            activeIcon: Icon(Icons.favorite),
            label: 'المفضلة',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.trending_up),
            activeIcon: Icon(Icons.show_chart),
            label: 'تقدمي',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'حسابي',
          ),
        ],
      ),
    );
  }
}
