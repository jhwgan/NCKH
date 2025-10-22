// lib/screens/permissions_assistant_screen.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PermissionsAssistantScreen extends StatefulWidget {
  const PermissionsAssistantScreen({super.key});

  @override
  State<PermissionsAssistantScreen> createState() =>
      _PermissionsAssistantScreenState();
}

class _PermissionsAssistantScreenState
    extends State<PermissionsAssistantScreen> {
  bool permissionLocation = false;
  bool permissionSensors = true;
  bool permissionNotifications = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      permissionLocation = prefs.getBool('perm_location') ?? false;
      permissionSensors = prefs.getBool('perm_sensors') ?? true;
      permissionNotifications = prefs.getBool('perm_notifications') ?? true;
    });
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('perm_location', permissionLocation);
    await prefs.setBool('perm_sensors', permissionSensors);
    await prefs.setBool('perm_notifications', permissionNotifications);
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Permissions saved (simulated)')));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Permissions Assistant'),
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
            Card(
              color: Colors.white10,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: [
                  SwitchListTile(
                    value: permissionSensors,
                    onChanged: (v) => setState(() => permissionSensors = v),
                    title: const Text('Motion & Sensor access',
                        style: TextStyle(color: Colors.white)),
                    subtitle: const Text('Needed to detect sleep movements',
                        style: TextStyle(color: Colors.white70)),
                    activeColor: Colors.blueAccent,
                  ),
                  const Divider(color: Colors.white12),
                  SwitchListTile(
                    value: permissionNotifications,
                    onChanged: (v) =>
                        setState(() => permissionNotifications = v),
                    title: const Text('Notifications',
                        style: TextStyle(color: Colors.white)),
                    subtitle: const Text('Allow alarm and reminders',
                        style: TextStyle(color: Colors.white70)),
                    activeColor: Colors.blueAccent,
                  ),
                  const Divider(color: Colors.white12),
                  SwitchListTile(
                    value: permissionLocation,
                    onChanged: (v) => setState(() => permissionLocation = v),
                    title: const Text('Location (optional)',
                        style: TextStyle(color: Colors.white)),
                    subtitle: const Text(
                        'Used for timezone or light exposure features',
                        style: TextStyle(color: Colors.white70)),
                    activeColor: Colors.blueAccent,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
                'Note: toggles here are simulated — to change real OS permissions go to system settings.',
                style: TextStyle(color: Colors.white70)),
            const Spacer(),
            ElevatedButton(
              onPressed: _save,
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
