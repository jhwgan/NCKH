// lib/screens/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final List<String> _genders = ['Male', 'Female'];

  String _selectedGender = 'Female';
  DateTime? _birthday;
  int _age = 18;

  final FlutterLocalNotificationsPlugin _localNotifPlugin =
      FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _initNotifications();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final savedGender = prefs.getString('profile_gender');
    final savedBirthday = prefs.getString('profile_birthday');
    final savedAge = prefs.getInt('profile_age');

    if (!mounted) return;

    setState(() {
      if (savedGender != null) _selectedGender = savedGender;
      if (savedBirthday != null) {
        _birthday = DateTime.tryParse(savedBirthday);
      }
      if (savedAge != null) _age = savedAge;
    });
  }

  Future<void> _saveGender(String gender) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('profile_gender', gender);
  }

  Future<void> _saveBirthday(DateTime birth, int age) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('profile_birthday', birth.toIso8601String());
    await prefs.setInt('profile_age', age);
  }

  Future<void> _initNotifications() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings();
    final initSettings =
        InitializationSettings(android: androidSettings, iOS: iosSettings);
    await _localNotifPlugin.initialize(initSettings);
  }

  Future<void> _showSavedNotification(String title, String body) async {
    const androidDetails = AndroidNotificationDetails(
      'profile_channel',
      'Profile updates',
      channelDescription: 'Notifications for profile changes',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );
    const iosDetails = DarwinNotificationDetails();
    const platformDetails =
        NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _localNotifPlugin.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      platformDetails,
    );
  }

  int _computeAge(DateTime birthDate) {
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  void _openGenderBottomSheet() {
    String tempSelected = _selectedGender;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1F1F1F),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx2, setStateSheet) {
          return SizedBox(
            height: 320,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Padding(
                  padding:
                      EdgeInsets.only(left: 20, top: 22, right: 20, bottom: 10),
                  child: Text(
                    'Gender',
                    style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                ),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: _genders.map((g) {
                      final bool isSelected = g == tempSelected;
                      return GestureDetector(
                        onTap: () {
                          setStateSheet(() {
                            tempSelected = g;
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 6.0, horizontal: 20),
                          child: Column(
                            children: [
                              Text(
                                g,
                                style: TextStyle(
                                  fontSize: isSelected ? 20 : 18,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.w400,
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.white70,
                                ),
                              ),
                              const SizedBox(height: 6),
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                height: 3,
                                width: isSelected ? 120 : 0,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(4),
                                  color: isSelected
                                      ? const Color(0xFF3B82F6)
                                      : Colors.transparent,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 18.0, vertical: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            backgroundColor: const Color(0xFF2A2A2A),
                            side: const BorderSide(color: Colors.transparent),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                          onPressed: () {
                            Navigator.pop(ctx);
                          },
                          child: const Text(
                            'Cancel',
                            style:
                                TextStyle(color: Colors.white70, fontSize: 16),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF3B82F6),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                          onPressed: () async {
                            setState(() {
                              _selectedGender = tempSelected;
                            });
                            await _saveGender(_selectedGender);

                            if (!mounted) return;

                            final messenger = ScaffoldMessenger.of(context);
                            final navigator = Navigator.of(context);

                            final body = 'Gender set to $_selectedGender';
                            messenger.showSnackBar(SnackBar(
                              content: Text(body),
                              duration: const Duration(seconds: 2),
                            ));
                            await _showSavedNotification(
                                'Profile updated', body);

                            if (!mounted) return;
                            navigator.pop();
                          },
                          child: const Text(
                            'Save',
                            style: TextStyle(fontSize: 16, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        });
      },
    );
  }

  Future<void> _pickBirthday() async {
    final now = DateTime.now();
    final firstDate = DateTime(now.year - 100, now.month, now.day);
    final lastDate = now;
    final initialDate =
        _birthday ?? DateTime(now.year - 18, now.month, now.day);

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      helpText: 'Select your birthday',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF3B82F6),
              onPrimary: Colors.white,
              surface: Color(0xFF222222),
              onSurface: Colors.white,
            ),
            dialogTheme: const DialogThemeData(
              backgroundColor: Color(0xFF111111),
            ),
          ),
          child: child ?? const SizedBox(),
        );
      },
    );

    if (!mounted) return;

    if (picked != null) {
      final computedAge = _computeAge(picked);
      setState(() {
        _birthday = picked;
        _age = computedAge;
      });

      await _saveBirthday(picked, computedAge);

      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);

      final body = 'Birthday saved — age $_age';
      messenger.showSnackBar(SnackBar(
        content: Text(body),
        duration: const Duration(seconds: 2),
      ));
      await _showSavedNotification('Profile updated', body);
    }
  }

  String get _birthdayText {
    if (_birthday == null) return '-';
    return DateFormat('yyyy-M-d').format(_birthday!);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/images/bg.png"),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new,
                          color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'My Profile',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(59, 97, 92, 92),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    children: [
                      InkWell(
                        onTap: _openGenderBottomSheet,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 18.0, vertical: 18),
                          child: Row(
                            children: [
                              const Text(
                                'Gender',
                                style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500),
                              ),
                              const Spacer(),
                              Text(
                                _selectedGender,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.chevron_right,
                                  color: Colors.white70),
                            ],
                          ),
                        ),
                      ),
                      Container(height: 1, color: Colors.white10),
                      InkWell(
                        onTap: _pickBirthday,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 18.0, vertical: 18),
                          child: Row(
                            children: [
                              const Text(
                                'Age',
                                style: TextStyle(
                                    color: Color.fromARGB(198, 255, 255, 255),
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500),
                              ),
                              const Spacer(),
                              Text(
                                _birthday == null ? '-' : '$_age',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.chevron_right,
                                  color: Colors.white70),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_birthday != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Birthday: $_birthdayText',
                    style: const TextStyle(color: Colors.white54),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
