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
  String? _soundName;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final arg = ModalRoute.of(context)?.settings.arguments;
      if (arg is String && arg.isNotEmpty) {
        // payload có thể là tên sound hoặc json -> tùy cách bạn gửi từ scheduleAlarm
        _soundName = arg;
      }
      _startAlarm();
    });
  }

  Future<void> _startAlarm() async {
    try {
      await _player.setReleaseMode(ReleaseMode.loop);

      String sourcePath;
      if (_soundName != null && _soundName!.isNotEmpty) {
        sourcePath = _soundName!;
      } else {
        sourcePath = 'assets/audio/drizzling.mp3';
      }

      // Nếu là asset (trong assets/audio)
      if (sourcePath.startsWith('assets/') || sourcePath.startsWith('audio/')) {
        await _player.play(AssetSource(sourcePath.replaceFirst('assets/', '')));
      } else if (sourcePath.startsWith('/')) {
        // Nếu là file local (file user import từ raw hoặc storage)
        await _player.play(DeviceFileSource(sourcePath));
      } else {
        // Nếu chỉ có tên (raw)
        await _player.play(AssetSource('audio/$sourcePath.mp3'));
      }

      setState(() => _isPlaying = true);
      print('🔊 Playing sound: $sourcePath');
    } catch (e) {
      print('❌ Error starting alarm audio: $e');
    }
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
            const Icon(Icons.alarm_rounded, color: Colors.redAccent, size: 100),
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
