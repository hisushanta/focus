import 'dart:async';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Add this import

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize window manager
  await windowManager.ensureInitialized();

  // Set window properties for transparency
  WindowOptions windowOptions = const WindowOptions(
    size: Size(420, 710), // Set your desired window size
    center: true,
    backgroundColor: Colors.transparent, // Make the window background transparent
    titleBarStyle: TitleBarStyle.hidden, // Hide the title bar
    alwaysOnTop: true,
  );

  // Wait for the window to be ready
  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show(); // Show the window
    await windowManager.focus(); // Focus the window
  });

  doWhenWindowReady(() {
    final win = appWindow;
    const initialSize = Size(420, 710);
    win.minSize = initialSize;
    win.size = initialSize;
    win.alignment = Alignment.center;
    win.show();
  });

  runApp(const FocusKeeperApp());
}

class FocusKeeperApp extends StatelessWidget {
  const FocusKeeperApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Focus',
      theme: ThemeData(
        fontFamily: 'Arial',
        primaryColor: Colors.redAccent,
      ),
      home: const FocusKeeperHomePage(),
    );
  }
}

class FocusKeeperHomePage extends StatefulWidget {
  const FocusKeeperHomePage({Key? key}) : super(key: key);

  @override
  _FocusKeeperHomePageState createState() => _FocusKeeperHomePageState();
}

class _FocusKeeperHomePageState extends State<FocusKeeperHomePage> {
  String focusTime = '25:00';
  String shortBreakTime = '5:00';
  String longBreakTime = '15:00';
  String currentTimer = '1:00'; // This will reflect the current timer value
  String currentPhase = 'Focus'; // Tracks the current phase (Focus, Short Break, Long Break)
  String snoozNote = "";
  String breakNote = "";
  bool isEditingFocus = false;
  bool isEditingShortBreak = false;
  bool isEditingLongBreak = false;

  final TextEditingController _focusTimeController = TextEditingController();
  final TextEditingController _shortBreakTimeController = TextEditingController();
  final TextEditingController _longBreakTimeController = TextEditingController();

  bool isTimerRunning = false;
  int focusCyclesCompleted = 0;
  Timer? _timer;
  final AudioPlayer _audioPlayer = AudioPlayer();

  Future<void> _playSound() async {
    await _audioPlayer.play(AssetSource('school-bell.mp3')); // Play sound from assets
  }

  Future<void> _stopSound() async {
    await _audioPlayer.stop(); // Stop the sound
  }

  @override
  void initState() {
    super.initState();
    _loadPreferences(); // Load saved preferences when the app starts
  }

  // Load saved preferences
  Future<void> _loadPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      focusTime = prefs.getString('focusTime') ?? '1:00';
      shortBreakTime = prefs.getString('shortBreakTime') ?? '1:00';
      longBreakTime = prefs.getString('longBreakTime') ?? '1:00';
      snoozNote = prefs.getString('snoozNote') ?? "";
      breakNote = prefs.getString('breakNote') ?? "";
      currentTimer = focusTime;
      _focusTimeController.text = focusTime;
      _shortBreakTimeController.text = shortBreakTime;
      _longBreakTimeController.text = longBreakTime;
    });
  }

  // Save preferences
  Future<void> _savePreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('focusTime', focusTime);
    await prefs.setString('shortBreakTime', shortBreakTime);
    await prefs.setString('longBreakTime', longBreakTime);
    await prefs.setString('snoozNote', snoozNote);
    await prefs.setString('breakNote', breakNote);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _updateTimer(String newTime, String timerType) {
    setState(() {
      if (timerType == 'Focus') {
        focusTime = newTime;
        if (currentPhase == 'Focus') {
          currentTimer = newTime;
        }
        _focusTimeController.text = newTime;
        isEditingFocus = false;
      } else if (timerType == 'Short Break') {
        shortBreakTime = newTime;
        if (currentPhase == 'Short Break') {
          currentTimer = newTime;
        }
        _shortBreakTimeController.text = newTime;
        isEditingShortBreak = false;
      } else if (timerType == 'Long Break') {
        longBreakTime = newTime;
        if (currentPhase == 'Long Break') {
          currentTimer = newTime;
        }
        _longBreakTimeController.text = newTime;
        isEditingLongBreak = false;
      }
    });
    _savePreferences(); // Save the updated preferences
  }

  bool _validateTimeFormat(String time) {
    // Validate time format (MMM:SS)
    final RegExp timeRegex = RegExp(r'^\d{1,3}:\d{2}$');
    return timeRegex.hasMatch(time);
  }

  String _formatTime(String time) {
    // Automatically convert "M:SS" to "MM:SS" or "MMM:SS"
    final parts = time.split(':');
    if (parts.length == 2) {
      // Format minutes and seconds
      final minutes = parts[0].padLeft(1, '0'); // Allow 1-3 digits for minutes
      final seconds = parts[1].padLeft(2, '0'); // Always 2 digits for seconds

      // Cap minutes at 999
      final minutesInt = int.tryParse(minutes) ?? 0;
      final cappedMinutes = minutesInt > 999 ? '999' : minutesInt.toString();

      return '$cappedMinutes:$seconds';
    }
    return time; // Return as-is if invalid
  }

  void _toggleTimer() {
    if (isTimerRunning) {
      // Stop the timer and reset to focus time
      _stopTimer();
      _resetTimer();
    } else {
      // Start the timer
      _startTimer();
    }
  }

  void _startTimer() {
    setState(() {
      isTimerRunning = true;
    });
    _runTimer();
  }

  void _runTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        final parts = currentTimer.split(':');
        int minutes = int.parse(parts[0]);
        int seconds = int.parse(parts[1]);

        if (seconds > 0) {
          seconds--;
        } else {
          if (minutes > 0) {
            minutes--;
            seconds = 59;
          } else {
            // Timer ended, switch to the next phase
            _switchPhase();
            return;
          }
        }

        currentTimer = '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
      });
    });
  }

  void _isTimeEnd() async {
    await windowManager.setMaximumSize(Size(410, 710));
    await windowManager.restore();
    await windowManager.minimize();
    _switchPhase();
  }

  void _closeButton() async {
    await windowManager.setMaximumSize(Size(410, 710));
    await windowManager.setAlwaysOnTop(true);
    await windowManager.restore();
    _resetTimer();
  }

  void _switchPhase() {
    _stopTimer(); // Stop the current timer before switching phases

    if (currentPhase == 'Focus') {
      if (focusCyclesCompleted < 4) {
        // Move to Short Break
        setState(() {
          currentPhase = 'Short Break';
          currentTimer = shortBreakTime;
          focusCyclesCompleted++;
        });
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BreakScreen(
              breakType: "Short Break",
              breakDurationMinutes: int.parse(currentTimer.split(":")[0]),
              snoozNote: snoozNote.isEmpty ? "Time For A Short Break" : snoozNote,
              breakNote: breakNote.isEmpty ? "Enjoy Your Short Break" : breakNote,
              onProceed: _isTimeEnd,
              onClose: _closeButton,
              playSound: _playSound,
              stopSound: _stopSound,
            ),
          ),
        );
      } else {
        // Move to Long Break
        setState(() {
          currentPhase = 'Long Break';
          currentTimer = longBreakTime;
          focusCyclesCompleted = 0;
        });
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BreakScreen(
              breakType: "Long Break",
              breakDurationMinutes: int.parse(currentTimer.split(":")[0]),
              snoozNote: snoozNote.isEmpty ? "Time For A Long Break" : snoozNote,
              breakNote: breakNote.isEmpty ? "Enjoy Your Long Break" : breakNote,
              onProceed: _isTimeEnd,
              onClose: _closeButton,
              playSound: _playSound,
              stopSound: _stopSound,
            ),
          ),
        );
      }
    } else if (currentPhase == 'Short Break') {
      // Move back to Focus Time
      setState(() {
        currentPhase = 'Focus';
        currentTimer = focusTime;
      });
      _startTimer();
    } else if (currentPhase == 'Long Break') {
      // Move back to Focus Time after Long Break
      setState(() {
        currentPhase = 'Focus';
        currentTimer = focusTime;
      });
      _startTimer();
    }
  }

  void _stopTimer() {
    _timer?.cancel();
    setState(() {
      isTimerRunning = false;
    });
  }

  void _resetTimer() {
    _stopTimer(); // Ensure the timer is stopped before resetting
    setState(() {
      currentPhase = 'Focus'; // Reset phase to Focus
      currentTimer = focusTime; // Reset timer to focus time
      focusCyclesCompleted = 0; // Reset focus cycles
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF5E6), // Light beige background
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Header
                    Container(
                      color: Color(0xFFFDF5E6), // Set the background color here
                      height: 50, // Title bar height
                      child: Row(
                        children: [
                          Expanded(
                            child: MoveWindow(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                                child: Text(
                                  'FOCUS',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.redAccent,
                                    fontStyle: FontStyle.italic,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ),
                          WindowButtons(),
                        ],
                      ),
                    ),

                    // Timer Display
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '$currentPhase Timer', // Display the current phase
                          style:  TextStyle(fontSize: 20, color: Colors.grey, fontStyle: FontStyle.italic),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          currentTimer, // Display the current timer value
                          style: const TextStyle(
                            fontSize: 80,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),

                    // Timer Options
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            TimerCard(
                              title: 'Focus',
                              time: focusTime,
                              color: Colors.redAccent,
                              isEditing: isEditingFocus,
                              onTap: () {
                                setState(() {
                                  isEditingFocus = true;
                                  isEditingShortBreak = false;
                                  isEditingLongBreak = false;
                                });
                              },
                              onSubmitted: (value) {
                                final formattedTime = _formatTime(value);
                                if (_validateTimeFormat(formattedTime)) {
                                  _updateTimer(formattedTime, 'Focus');
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Invalid time format. Use MMM:SS.'),
                                    ),
                                  );
                                }
                              },
                              controller: _focusTimeController,
                            ),
                            const SizedBox(width: 8),
                            TimerCard(
                              title: 'Short Break',
                              time: shortBreakTime,
                              color: Colors.blueAccent,
                              isEditing: isEditingShortBreak,
                              onTap: () {
                                setState(() {
                                  isEditingShortBreak = true;
                                  isEditingFocus = false;
                                  isEditingLongBreak = false;
                                });
                              },
                              onSubmitted: (value) {
                                final formattedTime = _formatTime(value);
                                if (_validateTimeFormat(formattedTime)) {
                                  _updateTimer(formattedTime, 'Short Break');
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Invalid time format. Use MMM:SS.'),
                                    ),
                                  );
                                }
                              },
                              controller: _shortBreakTimeController,
                            ),
                            const SizedBox(width: 8),
                            TimerCard(
                              title: 'Long Break',
                              time: longBreakTime,
                              color: Colors.green,
                              isEditing: isEditingLongBreak,
                              onTap: () {
                                setState(() {
                                  isEditingLongBreak = true;
                                  isEditingFocus = false;
                                  isEditingShortBreak = false;
                                });
                              },
                              onSubmitted: (value) {
                                final formattedTime = _formatTime(value);
                                if (_validateTimeFormat(formattedTime)) {
                                  _updateTimer(formattedTime, 'Long Break');
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Invalid time format. Use MMM:SS.'),
                                    ),
                                  );
                                }
                              },
                              controller: _longBreakTimeController,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Start/Close Button
                    ElevatedButton(
                      onPressed: _toggleTimer,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isTimerRunning ? Colors.redAccent : Colors.grey.shade800,
                        padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 16),
                      ),
                      child: Text(
                        isTimerRunning ? 'CLOSE' : 'START',
                        style: const TextStyle(color: Colors.white, fontSize: 20),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),

            // Settings Icon in the bottom left corner
            Positioned(
              left: 16,
              bottom: 16,
              child: IconButton(
                icon: Icon(Icons.settings, color: Colors.grey[600], size: 30),
                onPressed: () async {
                  final result = await showDialog(
                    context: context,
                    builder: (context) => SettingsDialog(
                      pomodoroTime: int.parse(focusTime.split(':')[0]),
                      shortBreakTime: int.parse(shortBreakTime.split(':')[0]),
                      longBreakTime: int.parse(longBreakTime.split(':')[0]),
                      snoozNote: snoozNote,
                      breakNote: breakNote,
                    ),
                  );

                  if (result != null) {
                    setState(() {
                      focusTime = '${result['pomodoroTime']}:00';
                      shortBreakTime = '${result['shortBreakTime']}:00';
                      longBreakTime = '${result['longBreakTime']}:00';
                      snoozNote = result['snoozNote'];
                      breakNote = result['breakNote'];
                      currentTimer = focusTime;
                    });
                    _savePreferences(); // Save the updated preferences
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SettingsDialog extends StatefulWidget {
  final int pomodoroTime;
  final int shortBreakTime;
  final int longBreakTime;
  final String snoozNote;
  final String breakNote;

  const SettingsDialog({
    Key? key,
    required this.pomodoroTime,
    required this.shortBreakTime,
    required this.longBreakTime,
    required this.snoozNote,
    required this.breakNote,
  }) : super(key: key);

  @override
  _SettingsDialogState createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog> {
  late int _pomodoroTime;
  late int _shortBreakTime;
  late int _longBreakTime;
  late String tempSnoozNote;
  late String tempBreakNote;

  @override
  void initState() {
    super.initState();
    _pomodoroTime = widget.pomodoroTime;
    _shortBreakTime = widget.shortBreakTime;
    _longBreakTime = widget.longBreakTime;
    tempSnoozNote = widget.snoozNote;
    tempBreakNote = widget.breakNote;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Color(0xFFFDF5E6),
      title: const Text(
        'SETTINGS',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.redAccent,
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTimeField('Pomodoro', _pomodoroTime, Icons.timer, (value) {
              setState(() {
                _pomodoroTime = value;
              });
            }),
            const SizedBox(height: 16),
            _buildTimeField('Short Break', _shortBreakTime, Icons.coffee, (value) {
              setState(() {
                _shortBreakTime = value;
              });
            }),
            const SizedBox(height: 16),
            _buildTimeField('Long Break', _longBreakTime, Icons.self_improvement, (value) {
              setState(() {
                _longBreakTime = value;
              });
            }),
            const SizedBox(height: 16),
            _buildNoteField('Snooz Note', widget.snoozNote, Icons.note_add, (value) {
              setState(() {
                tempSnoozNote = value;
              });
            }),
            const SizedBox(height: 16),
            _buildNoteField('Break Note', widget.breakNote, Icons.note_add, (value) {
              setState(() {
                tempBreakNote = value;
              });
            }),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text(
            'Cancel',
            style: TextStyle(color: Colors.grey),
          ),
        ),
        TextButton(
          onPressed: () {
            if (_shortBreakTime == 0) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Short Break Minimum 1 minute'),
                  duration: Duration(seconds: 2),
                ),
              );
            } else if (_longBreakTime == 0) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Long Break Minimum 1 minute'),
                  duration: Duration(seconds: 2),
                ),
              );
            } else {
              Navigator.of(context).pop({
                'pomodoroTime': _pomodoroTime,
                'shortBreakTime': _shortBreakTime,
                'longBreakTime': _longBreakTime,
                'snoozNote': tempSnoozNote.trim().isEmpty ? "" : tempSnoozNote,
                'breakNote': tempBreakNote.trim().isEmpty ? "" : tempBreakNote,
              });
            }
          },
          child: const Text(
            'Save',
            style: TextStyle(color: Colors.redAccent),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeField(String label, int value, IconData icon, Function(int) onChanged) {
    return TextFormField(
      initialValue: value.toString(),
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey),
        prefixIcon: Icon(icon, color: Colors.redAccent),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
      ),
      onChanged: (text) {
        final newValue = int.tryParse(text) ?? value;
        onChanged(newValue);
      },
    );
  }

  Widget _buildNoteField(String label, String value, IconData icon, Function(String) onChanged) {
    return TextFormField(
      initialValue: value.toString(),
      keyboardType: TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey),
        prefixIcon: Icon(icon, color: Colors.redAccent),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
      ),
      onChanged: (text) {
        final newValue = text;
        onChanged(newValue);
      },
    );
  }
}

class BreakScreen extends StatefulWidget {
  final String breakType;
  final int breakDurationMinutes;
  final String snoozNote;
  final String breakNote;
  final VoidCallback onProceed;
  final VoidCallback onClose;
  final VoidCallback playSound;
  final VoidCallback stopSound;
  BreakScreen({
    Key? key,
    required this.breakType,
    required this.breakDurationMinutes,
    required this.snoozNote,
    required this.breakNote,
    required this.onProceed,
    required this.onClose,
    required this.playSound,
    required this.stopSound
  }) : super(key: key);

  @override
  _BreakScreenState createState() => _BreakScreenState();
}

class _BreakScreenState extends State<BreakScreen> with SingleTickerProviderStateMixin {
  late Timer _snoozeTimer;
  late Timer _breakTimer;
  int _snoozeCountdown = 10; // Snooze timer countdown in seconds
  int _breakCountdown = 0; // Break timer countdown in seconds
  bool _isSnoozePhase = true;
  
  @override
  void initState() {
    super.initState();

    // Initialize the break timer duration in seconds
    _breakCountdown = widget.breakDurationMinutes * 60;

    // Start the snooze countdown
    _startSnoozeCountdown();
  }

  void _startSnoozeCountdown() async {
    await windowManager.maximize();
    await windowManager.show();
    await windowManager.focus();
    widget.playSound();

    _snoozeTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_snoozeCountdown > 0) {
          _snoozeCountdown--;
        } else {
          // Snooze phase ends, start the break timer
          widget.stopSound();
          widget.playSound();
          _snoozeTimer.cancel();
          _startBreakTimer();
        }
      });
    });
  }

  Future<void> _startSnooze() async {
    setState(() {
      _snoozeTimer.cancel();
    });

    // Minimize the window
    await windowManager.minimize();

    // Wait for 30 seconds, then restore the window and restart the snooze countdown
    Future.delayed(const Duration(seconds: 30), () async {
      if (mounted) {
        widget.stopSound();
        widget.playSound();
        await windowManager.maximize();
        await windowManager.show();
        await windowManager.focus();
        setState(() {
          _snoozeCountdown = 10; // Reset snooze countdown
          _startSnoozeCountdown(); // Restart snooze countdown
        });
      }
    });
  }

  void _startBreakTimer() {
    setState(() {
      _isSnoozePhase = false;
    });

    _breakTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_breakCountdown > 0) {
          _breakCountdown--;
        } else {
          // Break time ends
          
          _breakTimer.cancel();
          widget.stopSound();
          widget.playSound();
          widget.onProceed();
          Navigator.pop(context);
        }
      });
    });
  }

  void _closeScreen() {
    _breakTimer.cancel();
    widget.stopSound();
    widget.onClose();
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _snoozeTimer.cancel();
    _breakTimer.cancel();
    super.dispose();
  }

  @override
Widget build(BuildContext context) {
  // Fixed circle size
  final double fixedCircleDiameter = 400.0; // Adjust this value as needed

  // Calculate progress for the progress bar
  double progress = _isSnoozePhase
      ? 1 - (_snoozeCountdown / 10)
      : 1 - (_breakCountdown / (widget.breakDurationMinutes * 60));

  return Scaffold(
    backgroundColor: Colors.black.withOpacity(0.7),
    body: Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Circular Progress Indicator
          SizedBox(
            width: fixedCircleDiameter,
            height: fixedCircleDiameter,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 16,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                _isSnoozePhase ? Colors.yellowAccent : Colors.yellowAccent,
              ),
            ),
          ),
          // Circle Container
          Container(
            width: fixedCircleDiameter,
            height: fixedCircleDiameter,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.lightGreen,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Wrapping text inside the circle
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 20.0), // Add horizontal padding
                  child: Text(
                    _isSnoozePhase ? widget.snoozNote : widget.breakNote,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    maxLines: 4, // Limit to a maximum of 4 lines
                    overflow: TextOverflow.ellipsis, // Add ellipsis for overflow
                    softWrap: true, // Enable wrapping
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  _isSnoozePhase
                      ? '$_snoozeCountdown'
                      : '${_breakCountdown ~/ 60}:${(_breakCountdown % 60).toString().padLeft(2, '0')}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),
                if (_isSnoozePhase)
                  ElevatedButton(
                    onPressed: _startSnooze,
                    style: ElevatedButton.styleFrom(
                      shape: const CircleBorder(),
                      padding: const EdgeInsets.all(20),
                      backgroundColor: Colors.orange,
                    ),
                    child: const Icon(Icons.snooze, color: Colors.white),
                  ),
                if (!_isSnoozePhase)
                  ElevatedButton(
                    onPressed: _closeScreen,
                    style: ElevatedButton.styleFrom(
                      shape: const CircleBorder(),
                      padding: const EdgeInsets.all(20),
                      backgroundColor: Colors.red,
                    ),
                    child: const Icon(Icons.close, color: Colors.white),
                  ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

}




// Define Button Colors
final buttonColors = WindowButtonColors(
  iconNormal: Colors.black,
  mouseOver: Colors.blue[200]!,
  mouseDown: Colors.blue[300]!,
  iconMouseOver: Colors.white,
  iconMouseDown: Colors.white,
);

final closeButtonColors = WindowButtonColors(
  mouseOver: Colors.red[300]!,
  mouseDown: Colors.red[400]!,
  iconNormal: Colors.black,
  iconMouseOver: Colors.white,
);

// Window Buttons Widget
class WindowButtons extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        MinimizeWindowButton(colors: buttonColors),
        MaximizeWindowButton(colors: buttonColors),
        CloseWindowButton(colors: closeButtonColors),
      ],
    );
  }
}

class TimerCard extends StatefulWidget {
  final String title;
  final String time;
  final Color color;
  final bool isEditing;
  final VoidCallback onTap;
  final Function(String) onSubmitted;
  final TextEditingController controller;

  const TimerCard({
    Key? key,
    required this.title,
    required this.time,
    required this.color,
    required this.isEditing,
    required this.onTap,
    required this.onSubmitted,
    required this.controller,
  }) : super(key: key);

  @override
  _TimerCardState createState() => _TimerCardState();
}

class _TimerCardState extends State<TimerCard> {
  bool _isHovered = false;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    if (!_focusNode.hasFocus) {
      // When the TextFormField loses focus, call the onSubmitted callback
      widget.onSubmitted(widget.controller.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: () {
          widget.onTap(); // Call the onTap callback
          _focusNode.requestFocus(); // Request focus for the TextFormField
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 120, // Increased width to accommodate MMM:SS
          height: 90, // Increased height to accommodate the TextFormField
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: widget.color),
            boxShadow: _isHovered
                ? [
                    BoxShadow(
                      color: widget.color.withOpacity(0.5),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ]
                : [],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                widget.title,
                style: TextStyle(
                  color: widget.color,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
             
              Text(
                      '${widget.time} min', // Always display "min" suffix
                      style: TextStyle(
                        color: widget.color,
                        fontSize: 14,
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

