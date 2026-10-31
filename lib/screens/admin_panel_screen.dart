
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
  bool _grantsLoading = false;
  bool _granting = false;

  String _message = '';

  List<Map<String, dynamic>> _grants = [];

  final TextEditingController _emailController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    _checkOwner();
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _checkOwner() async {
    if (mounted) {
      setState(() {
        _loading = true;
      });
    }

    try {
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;

      if (user == null) {
        if (!mounted) return;

        setState(() {
          _message = 'يجب تسجيل الدخول أولاً';
          _isOwner = false;
          _loading = false;
        });
        return;
      }

      final profile = await client
          .from('profiles')
          .select('role')
          .eq('id', user.id)
          .maybeSingle();

      final isOwner =
          profile != null && profile['role'] == 'owner';

      if (!mounted) return;

      setState(() {
        _isOwner = isOwner;
        _message = isOwner
            ? 'مرحباً بك في لوحة إدارة رفيق الطالب'
            : 'ليس لديك صلاحية دخول لوحة الإدارة';
        _loading = false;
      });

      if (isOwner) {
        await _loadGrants();
      }
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isOwner = false;
        _message = 'تعذر التحقق من الصلاحيات. تحقق من الاتصال.';
        _loading = false;
      });
    }
  }

  Future<void> _loadGrants() async {
    if (!mounted) return;

    setState(() {
      _grantsLoading = true;
    });

    try {
      final result = await Supabase.instance.client
          .from('permanent_student_grants')
          .select(
            'id, student_email, is_active, granted_at, revoked_at',
          )
          .order('granted_at', ascending: false);

      if (!mounted) return;

      setState(() {
        _grants = List<Map<String, dynamic>>.from(result);
        _grantsLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _grantsLoading = false;
      });

      _showMessage('تعذر تحميل سجل المنح. تحقق من صلاحيات قاعدة البيانات.');
    }
  }

  Future<void> _grantVip() async {
    final email = _emailController.text.trim().toLowerCase();

    if (email.isEmpty ||
        !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      _showMessage('يرجى إدخال بريد إلكتروني صحيح');
      return;
    }

    if (_granting) return;

    setState(() {
      _granting = true;
    });

    try {
      final result = await Supabase.instance.client.rpc(
        'grant_permanent_vip',
        params: {'p_email': email},
      );

      if (!mounted) return;

      _emailController.clear();

      _showMessage(
        result == null || result.toString().isEmpty
            ? 'تم إرسال طلب منح الاشتراك'
            : result.toString(),
      );

      await _loadGrants();
    } catch (error) {
      if (!mounted) return;

      _showMessage('تعذر منح الاشتراك. تحقق من البريد والصلاحيات.');
    } finally {
      if (mounted) {
        setState(() {
          _granting = false;
        });
      }
    }
  }

  Future<void> _revokeGrant(
    Map<String, dynamic> grant,
  ) async {
    final email = grant['student_email']?.toString() ?? '';

    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('إلغاء منحة VIP'),
          content: Text(
            'هل تريد إلغاء المنحة الدائمة للطالب:\n$email؟',
            textDirection: TextDirection.ltr,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('تراجع'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('إلغاء المنحة'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    try {
      await Supabase.instance.client
          .from('permanent_student_grants')
          .update({
            'is_active': false,
            'revoked_at':
                DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', grant['id']);

      if (!mounted) return;

      _showMessage('تم تحديث حالة المنحة');
      await _loadGrants();
    } catch (error) {
      if (!mounted) return;

      _showMessage('تعذر إلغاء المنحة. تحقق من صلاحيات قاعدة البيانات.');
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
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
        leading: Icon(icon, color: Colors.blue),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(description),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 16,
        ),
      ),
    );
  }

  Widget _permanentVipSection() {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.workspace_premium,
                  color: Colors.amber,
                  size: 28,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'منح VIP الدائم',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'امنح طالباً تختاره اشتراك VIP مجانياً ودائماً باستخدام بريده الإلكتروني المسجل في التطبيق.',
              style: TextStyle(height: 1.6),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              textDirection: TextDirection.ltr,
              decoration: const InputDecoration(
                labelText: 'البريد الإلكتروني للطالب',
                hintText: 'student@example.com',
                prefixIcon: Icon(Icons.email),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _granting ? null : _grantVip,
              icon: _granting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.card_giftcard),
              label: Text(
                _granting
                    ? 'جارٍ تنفيذ الطلب...'
                    : 'منح VIP الدائم',
              ),
            ),
            const Divider(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'سجل المنح',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: _loadGrants,
                  icon: const Icon(Icons.refresh),
                  tooltip: 'تحديث القائمة',
                ),
              ],
            ),
            if (_grantsLoading)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_grants.isEmpty)
              const Padding(
                padding: EdgeInsets.all(12),
                child: Text(
                  'لا توجد منح مسجلة حتى الآن',
                  textAlign: TextAlign.center,
                ),
              )
            else
              ..._grants.map((grant) {
                final active = grant['is_active'] == true;

                return Card(
                  color: active
                      ? Colors.green.withOpacity(0.08)
                      : Colors.grey.withOpacity(0.08),
                  child: ListTile(
                    leading: Icon(
                      active
                          ? Icons.verified
                          : Icons.cancel_outlined,
                      color: active ? Colors.green : Colors.grey,
                    ),
                    title: Text(
                      grant['student_email']?.toString() ?? '',
                      textDirection: TextDirection.ltr,
                    ),
                    subtitle: Text(
                      active
                          ? 'VIP دائم - نشط'
                          : 'تم إلغاء المنحة',
                    ),
                    trailing: active
                        ? IconButton(
                            onPressed: () => _revokeGrant(grant),
                            icon: const Icon(
                              Icons.remove_circle_outline,
                              color: Colors.red,
                            ),
                            tooltip: 'إلغاء المنحة',
                          )
                        : const Icon(Icons.history),
                  ),
                );
              }),
          ],
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
            ? const Center(
                child: CircularProgressIndicator(),
              )
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
                      _permanentVipSection(),
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
                        'بعض أقسام الإدارة ما زالت واجهات أولية، وسيتم ربطها بقاعدة البيانات في الخطوات القادمة.',
                        textAlign: TextAlign.center,
                        style: TextStyle(height: 1.6),
                      ),
                    ],
                  ),
      ),
    );
  }
}
