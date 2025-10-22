// lib/screens/alarm_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/sound_manager.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../../services/alarm_service.dart';

class AlarmScreen extends StatefulWidget {
  final String alarmTime;
  final bool enabled;
  final ValueChanged<bool>? onToggle;

  const AlarmScreen({
    super.key,
    required this.alarmTime,
    this.enabled = false,
    this.onToggle,
  });

  @override
  State<AlarmScreen> createState() => _AlarmScreenState();
}

class _AlarmScreenState extends State<AlarmScreen> {
  late bool enabledLocal;
  bool vibration = true;
  bool snooze = true;
  final Set<int> selectedDays = {};

  // audio / tone picker state
  final AudioPlayer _previewPlayer = AudioPlayer();
  bool _isPreviewPlaying = false;
  String? _chosenToneAsset; // e.g. 'assets/audio/drizzling.mp3'

  // available tones (assets). Keep in sync with mixes / assets folder
  final List<Map<String, String>> availableTones = [
    {'title': 'Drizzling', 'asset': 'assets/audio/drizzling.mp3'},
    {'title': 'Raindrops Drum', 'asset': 'assets/audio/raindrops_drum.mp3'},
    {'title': 'Summer Rain', 'asset': 'assets/audio/summer_rain.mp3'},
    {'title': 'Stepping Rain', 'asset': 'assets/audio/stepping_rain.mp3'},
    {'title': 'Rain in Forest', 'asset': 'assets/audio/rain_forest.mp3'},
    {'title': 'Showers on Window', 'asset': 'assets/audio/showers_window.mp3'},
    {'title': 'Gentle Stream', 'asset': 'assets/audio/gentle_stream.mp3'},
    {'title': 'Night Thunder', 'asset': 'assets/audio/night_thunder.mp3'},
  ];

  @override
  void initState() {
    super.initState();
    enabledLocal = widget.enabled;
    _loadChosenTone();
    _previewPlayer.onPlayerComplete.listen((_) {
      setState(() {
        _isPreviewPlaying = false;
      });
    });
  }

  Future<void> _loadChosenTone() async {
    final prefs = await SharedPreferences.getInstance();
    final tone = prefs.getString('chosen_tone');
    if (mounted) setState(() => _chosenToneAsset = tone);
  }

  Future<void> _saveChosenTone(String asset) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('chosen_tone', asset);
    if (mounted) setState(() => _chosenToneAsset = asset);
  }

  @override
  void dispose() {
    _previewPlayer.dispose();
    super.dispose();
  }

  String get repeatSubtitle {
    if (selectedDays.isEmpty) return "Does not repeat";
    if (selectedDays.length == 7) return "Everyday";
    final names = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    final sorted = selectedDays.toList()..sort();
    return sorted.map((i) => names[i]).join(', ');
  }

  String get nextAlarmText {
    return "Next alarm will ring at ${widget.alarmTime.toLowerCase()}";
  }

  void _onSwitchChanged(bool v) async {
    setState(() => enabledLocal = v);
    widget.onToggle?.call(v);

    if (v) {
      await _setAlarmTime();
    } else {
      await AlarmService.cancelAlarm(1);
    }
  }

  // Open tone picker modal: shows available tones + marks downloaded files
  Future<void> _openTonePicker() async {
    final downloadedMap = await SoundManager.getAllDownloaded();

// Chỉ lấy những tone đã tải
    final downloadedTones = availableTones.where((t) {
      final asset = t['asset']!;
      final fileName = asset.split('/').last;
      final bool exact = downloadedMap.containsKey(asset);
      final bool rel =
          downloadedMap.containsKey(asset.replaceFirst('assets/', ''));
      final bool byFileName = downloadedMap.values.any(
        (local) => local.split('/').last == fileName,
      );
      return exact || rel || byFileName;
    }).toList();

    if (downloadedTones.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No downloaded sounds found')),
      );
      return;
    }

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          expand: false,
          builder: (_, controller) {
            return Container(
              decoration: const BoxDecoration(
                color: Color.fromRGBO(18, 18, 23, 0.95),
                borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(4)),
                  ),
                  const SizedBox(height: 12),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 18.0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Select Tone',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.builder(
                      controller: controller,
                      itemCount: downloadedTones.length,
                      itemBuilder: (context, i) {
                        final t = downloadedTones[i];
                        final asset = t['asset']!;
                        final title = t['title']!;
                        final localPath = downloadedMap[asset] ??
                            downloadedMap.values.firstWhere(
                              (v) => v.split('/').last == asset.split('/').last,
                              orElse: () => '',
                            );

                        final isSelected = _chosenToneAsset == asset;

                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 6),
                          leading: const Icon(Icons.music_note,
                              color: Colors.white70),
                          title: Text(title,
                              style: const TextStyle(color: Colors.white)),
                          subtitle: const Text('Downloaded',
                              style: TextStyle(color: Colors.white70)),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(
                                  _isPreviewPlaying
                                      ? Icons.pause_circle
                                      : Icons.play_circle,
                                  color: Colors.white,
                                ),
                                onPressed: () async {
                                  try {
                                    await _previewPlayer.stop();
                                  } catch (_) {}
                                  if (_isPreviewPlaying) {
                                    setState(() => _isPreviewPlaying = false);
                                    return;
                                  }
                                  if (localPath.isNotEmpty) {
                                    await _previewPlayer
                                        .play(DeviceFileSource(localPath));
                                    setState(() => _isPreviewPlaying = true);
                                  }
                                },
                              ),
                              IconButton(
                                icon: Icon(
                                  isSelected
                                      ? Icons.check_circle
                                      : Icons.radio_button_unchecked,
                                  color: isSelected
                                      ? Colors.greenAccent
                                      : Colors.white70,
                                ),
                                onPressed: () async {
                                  await _saveChosenTone(asset);
                                  await _previewPlayer.stop();
                                  if (mounted) {
                                    setState(() => _isPreviewPlaying = false);
                                    Navigator.pop(context);
                                  }
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    try {
      await _previewPlayer.stop();
    } catch (_) {}
    if (mounted) setState(() => _isPreviewPlaying = false);
  }

  @override
  Widget build(BuildContext context) {
    final parts = widget.alarmTime.split(' ');
    final hourPart = parts.isNotEmpty ? parts[0] : widget.alarmTime;
    final ampmPart = parts.length > 1 ? parts[1] : '';

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/images/alarmbg.png"),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Top bar
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon:
                          const Icon(Icons.close_rounded, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Text(
                      "Alarm",
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 40),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // next alarm text
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Row(
                  children: [
                    const Icon(Icons.notifications_none_rounded,
                        color: Colors.white70),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        nextAlarmText,
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Card chứa giờ và settings
              Expanded(
                child: Container(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6),
                  padding: const EdgeInsets.only(top: 18, bottom: 20),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(18, 255, 255, 255),
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(20)),
                    boxShadow: [
                      BoxShadow(
                        color: const Color.fromARGB(64, 0, 0, 0),
                        offset: const Offset(0, -6),
                        blurRadius: 20,
                      ),
                    ],
                    border: Border.all(
                      color: const Color.fromARGB(8, 255, 255, 255),
                    ),
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              hourPart,
                              style: const TextStyle(
                                fontSize: 56,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                height: 1.0,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 10.0),
                              child: Text(
                                ampmPart,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white70,
                                ),
                              ),
                            ),
                            const Spacer(),
                            // SWITCH: dùng activeThumbColor và activeTrackColor
                            Transform.scale(
                              scale: 1.05,
                              child: Switch.adaptive(
                                value: enabledLocal,
                                onChanged: _onSwitchChanged,
                                activeThumbColor:
                                    const Color.fromARGB(255, 53, 64, 168),
                                activeTrackColor:
                                    const Color.fromARGB(138, 175, 187, 224),
                                inactiveThumbColor: Colors.white70,
                                inactiveTrackColor:
                                    const Color.fromARGB(40, 255, 255, 255),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 18.0),
                        child: Divider(
                          color: Color.fromARGB(20, 255, 255, 255),
                          height: 1,
                          thickness: 0.6,
                        ),
                      ),

                      const SizedBox(height: 6),

                      // Nội dung settings
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              _buildTile(
                                icon: Icons.repeat_rounded,
                                title: "Repeat",
                                subtitle: repeatSubtitle,
                                onTap: () {},
                                showTrailing: false,
                              ),

                              // day selector
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 18.0, vertical: 12),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: List.generate(7, (i) {
                                    final letters = [
                                      'S',
                                      'M',
                                      'T',
                                      'W',
                                      'T',
                                      'F',
                                      'S'
                                    ];
                                    final selected = selectedDays.contains(i);
                                    return GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          if (selected) {
                                            selectedDays.remove(i);
                                          } else {
                                            selectedDays.add(i);
                                          }
                                        });
                                      },
                                      child: Container(
                                        width: 44,
                                        height: 44,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: selected
                                                ? Colors.white
                                                : Colors.white54,
                                            width: selected ? 1.8 : 1.0,
                                          ),
                                          color: selected
                                              ? const Color.fromARGB(
                                                  36, 255, 255, 255)
                                              : Colors.transparent,
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(
                                          letters[i],
                                          style: TextStyle(
                                            color: selected
                                                ? Colors.white
                                                : Colors.white70,
                                            fontWeight: selected
                                                ? FontWeight.w700
                                                : FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    );
                                  }),
                                ),
                              ),

                              _thinDivider(),

                              // Tone tile: open picker and show chosen title if set
                              _buildTile(
                                icon: Icons.music_note_rounded,
                                title: "Tone",
                                subtitle: _chosenToneAsset == null
                                    ? "Rise and Shine"
                                    : (availableTones.firstWhere(
                                            (t) =>
                                                t['asset'] == _chosenToneAsset,
                                            orElse: () =>
                                                {'title': 'Custom'})['title'] ??
                                        'Custom'),
                                onTap: _openTonePicker,
                              ),

                              _thinDivider(),

                              _buildTile(
                                icon: Icons.graphic_eq_rounded,
                                title: "Fade In",
                                subtitle: "30 seconds",
                                onTap: () {},
                              ),

                              _thinDivider(),

                              _buildSwitchTile(
                                icon: Icons.vibration_rounded,
                                title: "Vibration",
                                subtitle: vibration ? "Enabled" : "Disabled",
                                value: vibration,
                                onChanged: (v) => setState(() => vibration = v),
                              ),

                              _thinDivider(),

                              _buildSwitchTile(
                                icon: Icons.snooze_rounded,
                                title: "Snooze",
                                subtitle: snooze ? "Enabled" : "Disabled",
                                value: snooze,
                                onChanged: (v) => setState(() => snooze = v),
                              ),

                              const SizedBox(height: 28),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool showTrailing = true,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
      leading: Icon(icon, color: Colors.white, size: 26),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: Colors.white70, fontSize: 13),
      ),
      trailing: showTrailing
          ? const Icon(Icons.chevron_right_rounded, color: Colors.white70)
          : null,
      onTap: onTap,
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
      leading: Icon(icon, color: Colors.white, size: 26),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
      subtitle: Text(subtitle, style: const TextStyle(color: Colors.white70)),
      trailing: Transform.scale(
        scale: 1.05,
        child: Switch.adaptive(
          value: value,
          onChanged: onChanged,
          activeThumbColor: const Color.fromARGB(255, 59, 73, 200),
          activeTrackColor: const Color.fromARGB(138, 175, 187, 224),
          inactiveThumbColor: Colors.grey.shade300,
          inactiveTrackColor: const Color.fromARGB(20, 255, 255, 255),
        ),
      ),
    );
  }

  Widget _thinDivider() {
    return const Divider(
        color: Color.fromARGB(20, 255, 255, 255), height: 1, thickness: 0.6);
  }

  Future<void> _setAlarmTime() async {
    final now = DateTime.now();
    final targetTime = DateTime(
      now.year,
      now.month,
      now.day,
      6, // ví dụ báo thức 6:00 AM
      0,
    );

    await AlarmService.scheduleAlarm(
      id: 1,
      dateTime: targetTime,
      title: 'Cycle Alarm',
      body: 'Wake up now!',
    );
  }
}
