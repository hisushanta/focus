import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

void main() {
  runApp(const FocusKeeperApp());
}

class FocusKeeperApp extends StatelessWidget {
  const FocusKeeperApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Focus Keeper',
      theme: ThemeData(
        fontFamily: 'Arial',
        primaryColor: Colors.redAccent,
      ),
      home: const FocusKeeperHomePage(),
    );
  }
}

class FocusKeeperHomePage extends StatelessWidget {
  const FocusKeeperHomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF5E6), // Light beige background
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TimerCard(
                  title: 'Focus',
                  time: '25 min',
                  icon: FontAwesomeIcons.fire,
                  color: Colors.redAccent,
                  iconColor: Colors.white,
                  hasSoundIcon: true,
                ),
                const SizedBox(width: 10),
                TimerCard(
                  title: 'Short Break',
                  time: '5 min',
                  icon: FontAwesomeIcons.mugHot,
                  color: Colors.blueAccent,
                  iconColor: Colors.blueAccent,
                ),
                const SizedBox(width: 10),
                TimerCard(
                  title: 'Long Break',
                  time: '30 min',
                  icon: FontAwesomeIcons.personMeditating,
                  color: Colors.grey.shade300,
                  iconColor: Colors.black,
                ),
                const SizedBox(width: 20),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade700,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 30,
                      vertical: 16,
                    ),
                  ),
                  child: const Text(
                    'START',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class TimerCard extends StatelessWidget {
  final String title;
  final String time;
  final IconData icon;
  final Color color;
  final Color iconColor;
  final bool hasSoundIcon;

  const TimerCard({
    Key? key,
    required this.title,
    required this.time,
    required this.icon,
    required this.color,
    required this.iconColor,
    this.hasSoundIcon = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      height: 80,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Icon(
                      icon,
                      size: 16,
                      color: iconColor,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      time,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (hasSoundIcon)
            Positioned(
              top: 8,
              right: 8,
              child: Icon(
                Icons.volume_up,
                size: 16,
                color: Colors.red.shade900,
              ),
            ),
        ],
      ),
    );
  }
}
