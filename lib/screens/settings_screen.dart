// lib/screens/settings_screen.dart
import 'package:flutter/material.dart';
import '../screens/profile_screen.dart';

class SettingsScreen extends StatefulWidget {
  final ThemeMode themeMode;
  final bool pushEnabled;
  final ValueChanged<bool> onPushToggle;
  final VoidCallback onThemeToggle;
  final String nickname;
  final VoidCallback onLogout;

  const SettingsScreen({
    super.key,
    required this.themeMode,
    required this.pushEnabled,
    required this.onPushToggle,
    required this.onThemeToggle,
    required this.nickname,
    required this.onLogout,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Настройки'),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ЛИЧНЫЙ КАБИНЕТ (СЕРВЕР)
          Card(
            child: ListTile(
              leading: const Icon(Icons.account_circle, color: Colors.redAccent),
              title: const Text('Личный кабинет (сервер)', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Данные из Firestore: email, токен, никнейм'),
              trailing: const Icon(Icons.arrow_forward_ios, color: Colors.redAccent),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProfileScreen(onLogout: widget.onLogout),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ТЁМНАЯ ТЕМА
          Card(
            child: SwitchListTile(
              value: widget.themeMode == ThemeMode.dark,
              title: const Text('Тёмная тема'),
              secondary: const Icon(Icons.brightness_6, color: Colors.redAccent),
              activeColor: Colors.redAccent,
              onChanged: (_) => widget.onThemeToggle(),
            ),
          ),
          const SizedBox(height: 16),

          // ПУШ-УВЕДОМЛЕНИЯ
          Card(
            child: SwitchListTile(
              value: widget.pushEnabled,
              title: const Text('Пуш-уведомления'),
              subtitle: const Text('О новых фильмах'),
              secondary: const Icon(Icons.notifications_active, color: Colors.redAccent),
              activeColor: Colors.redAccent,
              onChanged: widget.onPushToggle,
            ),
          ),
          const SizedBox(height: 24),

          // ВЫХОД
          Card(
            color: Colors.red.withOpacity(0.1),
            child: ListTile(
              leading: const Icon(Icons.logout, color: Colors.redAccent),
              title: const Text('Выйти из аккаунта', style: TextStyle(color: Colors.redAccent)),
              trailing: const Icon(Icons.arrow_forward_ios, color: Colors.redAccent, size: 16),
              onTap: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Выйти?'),
                    content: const Text('Вы уверены?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Отмена')),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Выйти', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                );
                if (confirm == true) widget.onLogout();
              },
            ),
          ),
        ],
      ),
    );
  }
}