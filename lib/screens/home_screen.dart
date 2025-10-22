import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'alarm_screen.dart';
import 'sound_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  TimeOfDay bedTime = const TimeOfDay(hour: 22, minute: 0);
  TimeOfDay wakeTime = const TimeOfDay(hour: 6, minute: 30);

  // danh sách toggle trạng thái cho từng alarm suggestion
  List<bool> toggles = [true, false, true];
  int currentIndex = 0;

  Future<void> pickTime(bool isBed) async {
    final initial = isBed ? bedTime : wakeTime;
    final result = await showTimePicker(
      context: context,
      initialTime: initial,
    );
    if (result != null) {
      setState(() {
        if (isBed) {
          bedTime = result;
        } else {
          wakeTime = result;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final today = DateFormat("dd MMM, yyyy").format(DateTime.now());

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/images/background.png"),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Welcom to Cycle Alarm",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          today,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                    // Avatar: nhấn vào sẽ mở Profile (named route '/profile')
                    GestureDetector(
                      onTap: () {
                        Navigator.pushNamed(context, '/profile');
                      },
                      child: const CircleAvatar(
                        radius: 20,
                        backgroundImage: AssetImage("assets/images/avatar.png"),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Empty box
                Container(
                  height: 100,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(51, 255, 255, 255),
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),

                const SizedBox(height: 30),

                // Time pickers
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        const Text(
                          "In-bed",
                          style: TextStyle(color: Colors.white70, fontSize: 18),
                        ),
                        const SizedBox(height: 5),
                        GestureDetector(
                          onTap: () => pickTime(true),
                          child: Row(
                            children: [
                              Text(
                                bedTime.format(context),
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Icon(Icons.edit,
                                  size: 18, color: Colors.white70),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        const Text(
                          "Wake-up",
                          style: TextStyle(color: Colors.white70, fontSize: 18),
                        ),
                        const SizedBox(height: 5),
                        GestureDetector(
                          onTap: () => pickTime(false),
                          child: Row(
                            children: [
                              Text(
                                wakeTime.format(context),
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Icon(Icons.edit,
                                  size: 18, color: Colors.white70),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 35),

                // Calculate button
                Center(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4284F5),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 28, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    onPressed: () {},
                    child: const Text(
                      "Calculate",
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // Alarm suggestions
                Expanded(
                  child: ListView(
                    children: [
                      buildAlarm("4:00 AM", "You will sleep for 3 cycles", 0),
                      buildAlarm("7:00 AM", "You will sleep for 5 cycles", 1),
                      buildAlarm("8:30 AM", "You will sleep for 6 cycles", 2),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),

      // Custom Bottom Nav
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color.fromARGB(230, 28, 16, 77),
          boxShadow: [
            BoxShadow(
              color: const Color.fromARGB(41, 55, 15, 156),
              offset: const Offset(0, -1),
              blurRadius: 4,
            ),
          ],
        ),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
            child: BottomNavigationBar(
              currentIndex: currentIndex,
              onTap: (i) {
                if (i == 0) {
                  // Alarm: giữ lại Home (nếu muốn chỉ set index)
                  setState(() => currentIndex = 0);
                } else if (i == 1) {
                  // Sound: chuyển sang màn Sound (phải có route '/sound' trong main.dart)
                  Navigator.pushReplacementNamed(context, '/sound');
                } else if (i == 2) {
                  // Settings / Profile: chuyển sang profile (hoặc route settings của bạn)
                  Navigator.pushReplacementNamed(context, '/settings');
                }
              },
              backgroundColor: const Color.fromARGB(0, 67, 33, 152),
              elevation: 0,
              selectedItemColor: Colors.white,
              unselectedItemColor: Colors.white70,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.alarm_rounded),
                  label: "Alarm",
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.bar_chart_rounded),
                  label: "Sound",
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.settings_rounded),
                  label: "Settings",
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildAlarm(String time, String desc, int index) {
    return InkWell(
      onTap: () {
        // Push AlarmScreen và truyền callback để đồng bộ toggle
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AlarmScreen(
              alarmTime: time,
              enabled: toggles[index],
              onToggle: (v) {
                // khi AlarmScreen gọi onToggle, cập nhật state ở HomeScreen
                setState(() {
                  toggles[index] = v;
                });
              },
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  time,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: toggles[index] ? Colors.greenAccent : Colors.white,
                  ),
                ),
                const SizedBox(height: 5),
                Text(desc, style: const TextStyle(color: Colors.white70)),
              ],
            ),
            // SWITCH ở Home: dùng activeThumbColor + activeTrackColor bằng Color.fromARGB
            Switch(
              value: toggles[index],
              onChanged: (v) {
                setState(() => toggles[index] = v);
              },
              activeThumbColor: Colors.greenAccent,
              activeTrackColor: const Color.fromARGB(127, 105, 240, 174),
              inactiveThumbColor: Colors.grey,
              inactiveTrackColor: Colors.grey.shade700,
            ),
          ],
        ),
      ),
    );
  }
}
