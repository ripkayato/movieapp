// lib/screens/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';

class ProfileScreen extends StatefulWidget {
  final VoidCallback onLogout;
  const ProfileScreen({super.key, required this.onLogout});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _auth = AuthService();
  late final TextEditingController _nickCtrl = TextEditingController(); // ← ИНИЦИАЛИЗАЦИЯ СРАЗУ!
  
  String _email = 'Загрузка...';
  bool _verified = false;
  String _fcmToken = 'Загрузка...';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    if (!mounted) return; // ← КЛЮЧЕВАЯ ПРОВЕРКА!

    try {
      final user = FirebaseAuth.instance.currentUser!;
      final nick = await _auth.getUserNickname() ?? '';
      final snap = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final data = snap.data() ?? {};

      if (!mounted) return; // ← ЕЩЁ РАЗ!

      setState(() {
        _email = user.email ?? 'Нет email';
        _verified = user.emailVerified;
        _nickCtrl.text = nick;
        _fcmToken = kIsWeb 
            ? 'Web: токен недоступен' 
            : (data['fcmToken']?.toString().substring(0, 30) ?? 'Нет токена');
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Личный кабинет'),
        backgroundColor: Colors.redAccent,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.redAccent),
            )
          : Padding(
              padding: const EdgeInsets.all(20),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.redAccent,
                      child: Text(
                        _nickCtrl.text.isEmpty ? '?' : _nickCtrl.text[0].toUpperCase(),
                        style: const TextStyle(fontSize: 40, color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 24),

                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.email, color: Colors.redAccent),
                        title: const Text('Email'),
                        subtitle: Text(_email),
                      ),
                    ),
                    Card(
                      child: ListTile(
                        leading: Icon(_verified ? Icons.verified : Icons.warning,
                            color: _verified ? Colors.green : Colors.orange),
                        title: const Text('Email подтверждён'),
                        subtitle: Text(_verified ? 'Да' : 'Нет'),
                      ),
                    ),
                    Card(
                      child: ListTile(
                        leading: Icon(kIsWeb ? Icons.web : Icons.token,
                            color: kIsWeb ? Colors.grey : Colors.purple),
                        title: Text(kIsWeb ? 'FCM Токен (Web)' : 'FCM Токен'),
                        subtitle: Text(kIsWeb
                            ? 'Токен доступен только на Android/iOS'
                            : '$_fcmToken...'),
                      ),
                    ),

                    const SizedBox(height: 24),
                    TextField(
                      controller: _nickCtrl,
                      decoration: InputDecoration(
                        labelText: 'Никнейм',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        prefixIcon: const Icon(Icons.person),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                        onPressed: () async {
                          await _auth.updateNickname(_nickCtrl.text.trim());
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Никнейм обновлён!')),
                          );
                        },
                        child: const Text('Сохранить', style: TextStyle(color: Colors.white)),
                      ),
                    ),

                    const SizedBox(height: 40),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                        onPressed: widget.onLogout,
                        child: const Text('Выйти из аккаунта', style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  @override
  void dispose() {
    _nickCtrl.dispose();
    super.dispose();
  }
}