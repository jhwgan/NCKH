import 'package:flutter/material.dart';
import 'screens/logo_screen.dart';
import 'screens/question_screen.dart';
import 'screens/question_age_screen.dart';
import 'screens/home_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/alarm_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cycle Alarm',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true),
      initialRoute: '/logo',
      routes: {
        '/logo': (_) => const LogoScreen(),
        '/question': (_) => const QuestionScreen(),
        '/question_age': (_) => const QuestionAgeScreen(),
        '/home': (_) => const HomeScreen(),
        '/profile': (_) => const ProfileScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/alarm') {
          final String alarmTime = (settings.arguments is String &&
                  (settings.arguments as String).isNotEmpty)
              ? settings.arguments as String
              : '08:00 AM';
          return MaterialPageRoute(
            builder: (_) => AlarmScreen(
              alarmTime: alarmTime,
              enabled: false,
              onToggle: (bool v) {},
            ),
            settings: settings,
          );
        }
        return null;
      },
    );
  }
}
