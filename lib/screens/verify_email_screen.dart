import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class VerifyEmailScreen extends StatefulWidget {
  final String nickname;
  final VoidCallback onVerified;
  const VerifyEmailScreen({
    super.key, 
    required this.nickname, 
    required this.onVerified,
  });

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  final AuthService _authService = AuthService();
  bool _isVerifying = false;

  void _checkVerification() async {
    if (_isVerifying) return;
    
    setState(() => _isVerifying = true);
    
    // Reload без задержки
    await _authService.currentUser?.reload();
    final verified = _authService.currentUser?.emailVerified ?? false;
    
    setState(() => _isVerifying = false);
    
    if (verified) {
      await _authService.verifyEmail();
      widget.onVerified();
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email не подтвержден. Проверьте почту!'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void _resendEmail() async {
    await _authService.currentUser?.sendEmailVerification();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Письмо отправлено повторно!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.email, size: 80, color: Colors.redAccent),
              const SizedBox(height: 16),
              const Text(
                'Проверьте почту',
                style: TextStyle(
                  fontSize: 28, 
                  fontWeight: FontWeight.bold, 
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'На ${_authService.currentUser?.email ?? ''} отправлено письмо.\nКликните по ссылке для подтверждения.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[400]),
              ),
              const SizedBox(height: 32),
              
              // КНОПКА "Отправить повторно"
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _resendEmail,
                  icon: const Icon(Icons.email_outlined, color: Colors.white),
                  label: const Text(
                    'Отправить повторно', 
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // КНОПКА "Я подтвердил" (ЕДИНСТВЕННАЯ ПРОВЕРКА)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isVerifying ? null : _checkVerification,
                  icon: _isVerifying 
                      ? const SizedBox(
                          width: 20, 
                          height: 20, 
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh, color: Colors.white),
                  label: Text(
                    _isVerifying ? 'Проверка...' : 'Я подтвердил email',
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}