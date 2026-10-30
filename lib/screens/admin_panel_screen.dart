
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({Key? key}) : super(key: key);

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  bool _loading = true;
  bool _isOwner = false;
  String _message = '';

  @override
  void initState() {
    super.initState();
    _checkOwner();
  }

  Future<void> _checkOwner() async {
    try {
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;

      if (user == null) {
        setState(() {
          _message = 'يجب تسجيل الدخول أولاً';
          _loading = false;
        });
        return;
      }

      final profile = await client
          .from('profiles')
          .select('role')
          .eq('id', user.id)
          .maybeSingle();

      final isOwner = profile != null && profile['role'] == 'owner';

      if (!mounted) return;

      setState(() {
        _isOwner = isOwner;
        _message = isOwner
            ? 'مرحباً بك في لوحة إدارة رفيق الطالب'
            : 'ليس لديك صلاحية دخول لوحة الإدارة';
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _message = 'تعذر التحقق من الصلاحيات. تحقق من اتصالك بالإنترنت.';
        _loading = false;
      });
    }
  }

  Future<void> _logout() async {
    await Supabase.instance.client.auth.signOut();

    if (!mounted) return;

    Navigator.of(context).pop();
  }

  Widget _adminItem(
    IconData icon,
    String title,
    String description,
  ) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: Colors.green),
        title: Text(title),
        subtitle: Text(description),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('لوحة إدارة رفيق الطالب'),
        actions: [
          if (_isOwner)
            IconButton(
              onPressed: _logout,
              icon: const Icon(Icons.logout),
              tooltip: 'تسجيل الخروج',
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : !_isOwner
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.lock,
                          size: 60,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _message,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _checkOwner,
                          child: const Text('إعادة المحاولة'),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text(
                      _message,
                      style: Theme.of(context).textTheme.titleLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    _adminItem(
                      Icons.menu_book,
                      'إدارة المواد والدروس',
                      'إضافة وتعديل وحذف المحتوى التعليمي',
                    ),
                    _adminItem(
                      Icons.description,
                      'إدارة الملخصات',
                      'إدارة الملخصات التعليمية الجاهزة',
                    ),
                    _adminItem(
                      Icons.workspace_premium,
                      'إدارة الاشتراكات',
                      'إدارة الباقات والأسعار',
                    ),
                    _adminItem(
                      Icons.people,
                      'إدارة الطلاب',
                      'متابعة حسابات الطلاب واشتراكاتهم',
                    ),
                    _adminItem(
                      Icons.payments,
                      'طلبات بنكك',
                      'مراجعة طلبات الدفع والتحويلات',
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'هذه واجهة أولية. سنربط أقسام الإدارة بقاعدة البيانات في الخطوات القادمة.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
    );
  }
}
