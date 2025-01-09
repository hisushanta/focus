import 'package:flutter/material.dart';

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
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      'FOCUS KEEPER',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.redAccent,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Flexible(
                    child: Row(
                      children: [
                        TextButton(
                          onPressed: () {},
                          child: const Text(
                            'Timer Option',
                            style: TextStyle(fontSize: 16, color: Colors.black),
                          ),
                        ),
                        TextButton(
                          onPressed: () {},
                          child: const Text(
                            'Report',
                            style: TextStyle(fontSize: 16, color: Colors.black),
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                    ),
                    child: const Text(
                      'Login',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            // Timer Display
            const Spacer(),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Text(
                  'Focus Timer',
                  style: TextStyle(fontSize: 20, color: Colors.grey),
                ),
                SizedBox(height: 10),
                Text(
                  '25:00',
                  style: TextStyle(
                    fontSize: 80,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
            const Spacer(),
            // Timer Options
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                TimerCard(
                  title: 'Focus',
                  time: '25 min',
                  color: Colors.redAccent,
                ),
                SizedBox(width: 8),
                TimerCard(
                  title: 'Short Break',
                  time: '5 min',
                  color: Colors.blueAccent,
                ),
                SizedBox(width: 8),
                TimerCard(
                  title: 'Long Break',
                  time: '30 min',
                  color: Colors.greenAccent,
                ),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey.shade800,
                padding: EdgeInsets.symmetric(horizontal: 50, vertical: 16),
              ),
              child: const Text(
                'START',
                style: TextStyle(color: Colors.white, fontSize: 20),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class TimerCard extends StatelessWidget {
  final String title;
  final String time;
  final Color color;

  const TimerCard({
    Key? key,
    required this.title,
    required this.time,
    required this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      height: 70,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            time,
            style: TextStyle(
              color: color,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
