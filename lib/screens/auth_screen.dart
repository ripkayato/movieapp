// lib/screens/auth_screen.dart
import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class AuthScreen extends StatefulWidget {
  final void Function(String) onAuthorized;
  const AuthScreen({super.key, required this.onAuthorized});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _nicknameCtrl = TextEditingController();
  bool _isRegisterMode = false;
  String? _statusMessage;

  final AuthService _auth = AuthService(); // ← один экземпляр

  void _toggleMode() {
    setState(() {
      _isRegisterMode = !_isRegisterMode;
      _statusMessage = null;
      _emailCtrl.clear();
      _passwordCtrl.clear();
      _nicknameCtrl.clear();
    });
  }

  void _signIn() async {
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;

    if (email.isEmpty || password.isEmpty) {
      _showError('Заполните email и пароль');
      return;
    }

    setState(() => _statusMessage = 'Вход...');
    final result = await _auth.signInWithEmail(email: email, password: password);

    if (result == 'success') {
      final nick = await _auth.getUserNickname() ?? 'Пользователь';
      widget.onAuthorized(nick);
      if (mounted) Navigator.pushReplacementNamed(context, '/home');
    } else if (result == 'email_not_verified') {
      if (mounted) Navigator.pushReplacementNamed(context, '/verify');
    } else {
      _showError(result ?? 'Ошибка входа');
    }
  }

  void _register() async {
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;
    final nickname = _nicknameCtrl.text.trim();

    if (email.isEmpty || password.isEmpty || nickname.isEmpty) {
      _showError('Заполните все поля');
      return;
    }

    setState(() => _statusMessage = 'Регистрация...');
    final result = await _auth.registerWithEmail(
      email: email,
      password: password,
      nickname: nickname,
    );

    if (result == 'success') {
      if (mounted) Navigator.pushReplacementNamed(context, '/verify');
    } else {
      _showError(result ?? 'Ошибка регистрации');
    }
  }

  void _showError(String msg) {
    setState(() => _statusMessage = msg);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Icon(Icons.movie, size: 80, color: Colors.redAccent),
              const SizedBox(height: 16),
              Text(
                _isRegisterMode ? 'Регистрация' : 'Вход',
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.redAccent),
              ),
              const SizedBox(height: 32),

              TextField(
                controller: _emailCtrl,
                decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email)),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordCtrl,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Пароль', prefixIcon: Icon(Icons.lock)),
              ),
              const SizedBox(height: 16),
              if (_isRegisterMode)
                TextField(
                  controller: _nicknameCtrl,
                  decoration: const InputDecoration(labelText: 'Никнейм', prefixIcon: Icon(Icons.person)),
                ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                  onPressed: _isRegisterMode ? _register : _signIn,
                  child: Text(_isRegisterMode ? 'Зарегистрироваться' : 'Войти', style: const TextStyle(color: Colors.white)),
                ),
              ),
              const SizedBox(height: 16),

              TextButton(
                onPressed: _toggleMode,
                child: Text(
                  _isRegisterMode ? 'Уже есть аккаунт? Войти' : 'Нет аккаунта? Регистрация',
                  style: const TextStyle(color: Colors.redAccent),
                ),
              ),

              if (_statusMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(_statusMessage!, style: const TextStyle(color: Colors.red)),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _nicknameCtrl.dispose();
    super.dispose();
  }
}