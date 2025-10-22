// lib/screens/general_settings_screen.dart
import 'package:flutter/material.dart';

class GeneralSettingsScreen extends StatefulWidget {
  const GeneralSettingsScreen({super.key});

  @override
  State<GeneralSettingsScreen> createState() => _GeneralSettingsScreenState();
}

class _GeneralSettingsScreenState extends State<GeneralSettingsScreen> {
  bool darkMode = true;
  bool haptics = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('General settings'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        padding: const EdgeInsets.all(18),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
              colors: [Color(0xFF141328), Color(0xFF2A2140)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight),
        ),
        child: Column(
          children: [
            SwitchListTile(
              value: darkMode,
              onChanged: (v) => setState(() => darkMode = v),
              title: const Text('Dark mode',
                  style: TextStyle(color: Colors.white)),
              subtitle: const Text('Use dark theme even in system light mode',
                  style: TextStyle(color: Colors.white70)),
              activeColor: Colors.blueAccent,
            ),
            const Divider(color: Colors.white12),
            SwitchListTile(
              value: haptics,
              onChanged: (v) => setState(() => haptics = v),
              title: const Text('Haptic feedback',
                  style: TextStyle(color: Colors.white)),
              subtitle: const Text('Vibrate on interactions',
                  style: TextStyle(color: Colors.white70)),
              activeColor: Colors.blueAccent,
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Saved general settings')));
                Navigator.pop(context);
              },
              child: const Text('Save'),
            )
          ],
        ),
      ),
    );
  }
}
