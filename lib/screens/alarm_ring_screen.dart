// lib/screens/alarm_ring_screen.dart
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

class AlarmRingScreen extends StatefulWidget {
  const AlarmRingScreen({super.key});

  @override
  State<AlarmRingScreen> createState() => _AlarmRingScreenState();
}

class _AlarmRingScreenState extends State<AlarmRingScreen> {
  final AudioPlayer _player = AudioPlayer();
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _startAlarm();
  }

  Future<void> _startAlarm() async {
    await _player
        .play(AssetSource('audio/drizzling.mp3')); // hoặc tone bạn chọn
    setState(() => _isPlaying = true);
  }

  Future<void> _stopAlarm() async {
    await _player.stop();
    if (mounted) Navigator.pop(context);
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.9),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "⏰ Alarm Ringing",
              style: TextStyle(color: Colors.white, fontSize: 32),
            ),
            const SizedBox(height: 40),
            Icon(
              Icons.alarm_rounded,
              color: Colors.redAccent,
              size: 100,
            ),
            const SizedBox(height: 60),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                padding:
                    const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
              ),
              onPressed: _stopAlarm,
              child: const Text(
                "Stop Alarm",
                style: TextStyle(fontSize: 20, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
