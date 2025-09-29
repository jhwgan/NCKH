import 'package:flutter/material.dart';

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

  @override
  void initState() {
    super.initState();
    enabledLocal = widget.enabled;
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

  void _onSwitchChanged(bool v) {
    setState(() => enabledLocal = v);
    if (widget.onToggle != null) widget.onToggle!(v);
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

                              _buildTile(
                                icon: Icons.music_note_rounded,
                                title: "Tone",
                                subtitle: "Rise and Shine",
                                onTap: () {},
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
}
