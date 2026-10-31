
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({Key? key}) : super(key: key);

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;

  final TextEditingController _emailController =
      TextEditingController();

  final TextEditingController _passwordController =
      TextEditingController();

  bool _loading = false;
  bool _obscurePassword = true;
  bool _hasPermanentVipGrant = false;

  String _name = '';
  String _email = '';
  String _plan = 'مجاني';

  bool get _isLoggedIn =>
      _supabase.auth.currentUser != null;

  @override
  void initState() {
    super.initState();
    _loadAccount();
  }

  Future<void> _loadAccount() async {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      if (!mounted) return;

      setState(() {
        _name = '';
        _email = '';
        _plan = 'مجاني';
        _hasPermanentVipGrant = false;
      });

      return;
    }

    try {
      final profile = await _supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      final vipResult = await _supabase.rpc(
        'has_permanent_vip_grant',
      );

      final bool hasVip = vipResult == true;

      if (!mounted) return;

      setState(() {
        _email = user.email ?? '';

        _name = profile?['full_name'] ??
            user.userMetadata?['full_name'] ??
            'طالب رفيق الطالب';

        _hasPermanentVipGrant = hasVip;

        _plan = hasVip
            ? 'VIP دائم - منحة مجانية'
            : (profile?['subscription_plan'] ?? 'مجاني')
                .toString();
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _email = user.email ?? '';
        _name = user.userMetadata?['full_name'] ??
            'طالب رفيق الطالب';
        _plan = 'تعذر تحميل الاشتراك';
        _hasPermanentVipGrant = false;
      });

      _showMessage(
        'تعذر تحميل معلومات الاشتراك. تحقق من الاتصال.',
      );
    }
  }

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      _showMessage(
        'يرجى إدخال البريد الإلكتروني وكلمة المرور',
      );
      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      await _loadAccount();

      if (!mounted) return;

      _emailController.clear();
      _passwordController.clear();

      _showMessage('تم تسجيل الدخول بنجاح');
    } on AuthException catch (error) {
      _showMessage(error.message);
    } catch (error) {
      _showMessage('تعذر تسجيل الدخول. تحقق من الإنترنت.');
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _logout() async {
    setState(() {
      _loading = true;
    });

    try {
      await _supabase.auth.signOut();

      if (!mounted) return;

      setState(() {
        _name = '';
        _email = '';
        _plan = 'مجاني';
        _hasPermanentVipGrant = false;
      });

      _showMessage('تم تسجيل الخروج بنجاح');
    } catch (error) {
      _showMessage('تعذر تسجيل الخروج. حاول مرة أخرى.');
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
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

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('حساب الطالب'),
          centerTitle: true,
          actions: [
            if (_isLoggedIn)
              IconButton(
                onPressed: _loading ? null : _loadAccount,
                icon: const Icon(Icons.refresh),
                tooltip: 'تحديث الحساب',
              ),
          ],
        ),
        body: _loading
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : _isLoggedIn
                ? _buildAccount()
                : _buildLogin(),
      ),
    );
  }

  Widget _buildLogin() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(
              Icons.school,
              size: 85,
              color: Colors.blue,
            ),
            const SizedBox(height: 18),
            const Text(
              'مرحباً بك في رفيق الطالب',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'سجل الدخول للوصول إلى حسابك ومتابعة اشتراكك.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 30),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              textDirection: TextDirection.ltr,
              decoration: const InputDecoration(
                labelText: 'البريد الإلكتروني',
                prefixIcon: Icon(Icons.email_outlined),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: 'كلمة المرور',
                prefixIcon: const Icon(Icons.lock_outline),
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility
                        : Icons.visibility_off,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _loading ? null : _login,
                icon: const Icon(Icons.login),
                label: const Text(
                  'تسجيل الدخول',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'إذا لم يكن لديك حساب، ستحتاج إلى إنشاء حساب من خلال نظام التسجيل المعتمد في التطبيق.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccount() {
    return RefreshIndicator(
      onRefresh: _loadAccount,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 15),
          const Center(
            child: CircleAvatar(
              radius: 48,
              child: Icon(
                Icons.person,
                size: 55,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Center(
            child: Text(
              _name,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              _email,
              textDirection: TextDirection.ltr,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(height: 30),
          const Text(
            'معلومات الحساب',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('اسم الطالب'),
              subtitle: Text(_name),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.email_outlined),
              title: const Text('البريد الإلكتروني'),
              subtitle: Text(
                _email,
                textDirection: TextDirection.ltr,
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'الاشتراك',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: Icon(
                Icons.workspace_premium,
                color: _hasPermanentVipGrant
                    ? Colors.amber
                    : Colors.orange,
              ),
              title: const Text('الاشتراك الحالي'),
              subtitle: Text(_plan),
              trailing: Icon(
                _hasPermanentVipGrant
                    ? Icons.verified
                    : Icons.verified_user_outlined,
                color: _hasPermanentVipGrant
                    ? Colors.green
                    : null,
              ),
            ),
          ),
          if (_hasPermanentVipGrant)
            Card(
              child: ListTile(
                leading: const Icon(
                  Icons.card_giftcard,
                  color: Colors.green,
                ),
                title: const Text('منحة VIP الدائمة'),
                subtitle: const Text(
                  'حصلت على VIP مجاناً وبشكل دائم من إدارة التطبيق.',
                ),
              ),
            ),
          const SizedBox(height: 25),
          SizedBox(
            height: 50,
            child: OutlinedButton.icon(
              onPressed: _loading ? null : _logout,
              icon: const Icon(Icons.logout),
              label: const Text('تسجيل الخروج'),
            ),
          ),
          const SizedBox(height: 25),
          Center(
            child: Text(
              'رفيق الطالب - طريقك نحو التعلم والنجاح',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
