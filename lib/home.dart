import 'package:app/content.dart';
import 'package:app/content_.dart';
import 'package:app/twitter.dart';
import 'package:flutter/material.dart';

import 'deepseek.dart';
import 'link.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            transform: GradientRotation(3.14 / 3),
            colors: [
              Colors.orangeAccent, // Light orange (Swiggy-style top)
              Color(0xFFFFF3E0), // Soft cream-ish bottom
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: buildCustomContainer(
                        title: "Find by news content",
                        color: Colors.white,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SummaryApp(),
                            ),
                          );
                        }, imagePath: 'assets/news.png',
                      ),
                    ),
                    Expanded(
                      child: buildCustomContainer(
                        title: "Find by news link",
                        color: Colors.white,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ContentLinkApp(),
                            ),
                          );
                        }, imagePath: 'assets/link.png',
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 18,),
                Row(
                  children: [
                    Expanded(
                      child: buildCustomContainer(
                        title: "Find by X \nusername",
                        color: Colors.white,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TwitterAnalyzerApp(),
                            ),
                          );
                        }, imagePath: 'assets/twitter.png',
                      ),
                    ),
                    Expanded(
                      child: buildCustomContainer(
                        title: "Find by news link",
                        color: Colors.white,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TextAnalyzer(),
                            ),
                          );
                        }, imagePath: 'assets/twitter.png',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Widget buildCustomContainer({
  required String title,
  required Color color,
  required String imagePath,
  VoidCallback? onTap,
}) {
  return GestureDetector(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Container(
        height: 150,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 6,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Stack(
          children: [
            // Title at the top
            Align(
              alignment: Alignment.topLeft,
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            // Image at the bottom right
            Align(
              alignment: Alignment.bottomRight,
              child: Image.asset(
                imagePath,
                height: 50,
                width: 50,
                fit: BoxFit.contain,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

