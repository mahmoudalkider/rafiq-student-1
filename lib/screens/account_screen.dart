
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
  bool _hasVipGrant = false;

  String _name = 'طالب رفيق الطالب';
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
        _name = 'طالب رفيق الطالب';
        _email = '';
        _plan = 'مجاني';
        _hasVipGrant = false;
      });
      return;
    }

    try {
      final profile = await _supabase
          .from('profiles')
          .select('email, role')
          .eq('id', user.id)
          .maybeSingle();

      final vipResult =
          await _supabase.rpc('has_permanent_vip_grant');

      final hasVip = vipResult == true;

      final metadata = user.userMetadata ?? {};

      final name = (metadata['full_name'] ??
              metadata['name'] ??
              'طالب رفيق الطالب')
          .toString();

      if (!mounted) return;

      setState(() {
        _email = profile?['email']?.toString() ??
            user.email ??
            '';

        _name = name;
        _hasVipGrant = hasVip;
        _plan = hasVip
            ? 'VIP دائم - منحة مجانية'
            : 'مجاني';
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _email = user.email ?? '';
        _name = (user.userMetadata?['full_name'] ??
                'طالب رفيق الطالب')
            .toString();

        _hasVipGrant = false;
        _plan = 'تعذر تحميل حالة الاشتراك';
      });
    }
  }

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      _showMessage('أدخل البريد الإلكتروني وكلمة المرور');
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
      _showMessage('تعذر تسجيل الدخول. تحقق من اتصال الإنترنت.');
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
        _name = 'طالب رفيق الطالب';
        _email = '';
        _plan = 'مجاني';
        _hasVipGrant = false;
      });

      _showMessage('تم تسجيل الخروج');
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

  void _showMessage(String value) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(value),
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
                ? _accountView()
                : _loginView(),
      ),
    );
  }

  Widget _loginView() {
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
            const Text(
              'سجل الدخول لمتابعة حسابك وتقدمك الدراسي.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
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
                label: const Text('تسجيل الدخول'),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'إنشاء الحساب يحتاج إلى تفعيل التسجيل في نظام المصادقة.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _accountView() {
    return RefreshIndicator(
      onRefresh: _loadAccount,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 15),
          Center(
            child: CircleAvatar(
              radius: 48,
              backgroundColor: Colors.blue.withOpacity(0.1),
              child: const Icon(
                Icons.person,
                size: 55,
                color: Colors.blue,
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
              style: const TextStyle(color: Colors.grey),
            ),
          ),
          const SizedBox(height: 28),
          const Text(
            'معلومات الحساب',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),
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
          Card(
            child: ListTile(
              leading: Icon(
                Icons.workspace_premium,
                color: _hasVipGrant
                    ? Colors.amber
                    : Colors.orange,
              ),
              title: const Text('الاشتراك الحالي'),
              subtitle: Text(_plan),
              trailing: Icon(
                _hasVipGrant
                    ? Icons.verified
                    : Icons.verified_user_outlined,
                color: _hasVipGrant ? Colors.green : null,
              ),
            ),
          ),
          if (_hasVipGrant)
            const Card(
              child: ListTile(
                leading: Icon(
                  Icons.card_giftcard,
                  color: Colors.green,
                ),
                title: Text('منحة VIP الدائمة'),
                subtitle: Text(
                  'منحتك الإدارة اشتراك VIP بشكل دائم.',
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
          const Center(
            child: Text(
              'رفيق الطالب - طريقك نحو التعلم والنجاح',
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
