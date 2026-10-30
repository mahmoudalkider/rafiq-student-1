
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({Key? key}) : super(key: key);

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final _supabase = Supabase.instance.client;

  bool _loading = false;
  bool _showLogin = false;
  String _name = '';
  String _email = '';
  String _plan = 'مجاني';

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadAccount();
  }

  Future<void> _loadAccount() async {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      setState(() {
        _name = '';
        _email = '';
        _plan = 'مجاني';
      });
      return;
    }

    try {
      final profile = await _supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (!mounted) return;

      setState(() {
        _email = user.email ?? '';
        _name = profile?['full_name'] ??
            user.userMetadata?['full_name'] ??
            'طالب رفيق الطالب';
        _plan = profile?['subscription_plan'] ?? 'مجاني';
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _email = user.email ?? '';
        _name = 'طالب رفيق الطالب';
        _plan = 'مجاني';
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

    setState(() => _loading = true);

    try {
      await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      await _loadAccount();

      if (!mounted) return;

      setState(() => _showLogin = false);
      _emailController.clear();
      _passwordController.clear();
      _showMessage('تم تسجيل الدخول بنجاح');
    } on AuthException catch (error) {
      _showMessage(error.message);
    } catch (_) {
      _showMessage('تعذر تسجيل الدخول. تحقق من الإنترنت.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _logout() async {
    setState(() => _loading = true);

    try {
      await _supabase.auth.signOut();

      if (!mounted) return;

      setState(() {
        _name = '';
        _email = '';
        _plan = 'مجاني';
        _showLogin = false;
      });

      _showMessage('تم تسجيل الخروج');
    } catch (_) {
      _showMessage('تعذر تسجيل الخروج');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
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
    final user = _supabase.auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('حساب الطالب'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : user == null
              ? _buildLogin()
              : _buildAccount(),
    );
  }

  Widget _buildLogin() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(Icons.school, size: 70, color: Colors.green),
            const SizedBox(height: 16),
            const Text(
              'مرحباً بك في رفيق الطالب',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'البريد الإلكتروني',
                prefixIcon: Icon(Icons.email),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'كلمة المرور',
                prefixIcon: Icon(Icons.lock),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _login,
                child: const Text('تسجيل الدخول'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccount() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const CircleAvatar(
          radius: 40,
          child: Icon(Icons.person, size: 45),
        ),
        const SizedBox(height: 16),
        Center(
          child: Text(
            _name,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Center(child: Text(_email)),
        const SizedBox(height: 24),
        Card(
          child: ListTile(
            leading: const Icon(Icons.person),
            title: const Text('بيانات الطالب'),
            subtitle: Text(_name),
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.workspace_premium),
            title: const Text('الاشتراك الحالي'),
            subtitle: Text(_plan),
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _loading ? null : _logout,
            icon: const Icon(Icons.logout),
            label: const Text('تسجيل الخروج'),
          ),
        ),
      ],
    );
  }
}
