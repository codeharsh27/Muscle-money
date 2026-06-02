import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class GeneratingPlanScreen extends StatefulWidget {
  const GeneratingPlanScreen({super.key});

  @override
  State<GeneratingPlanScreen> createState() => _GeneratingPlanScreenState();
}

class _GeneratingPlanScreenState extends State<GeneratingPlanScreen> {
  int _currentTextIndex = 0;
  Timer? _textTimer;
  Timer? _completionTimer;

  final List<String> _loadingTexts = [
    "Nova is analyzing your financial goals...",
    "Calculating optimal savings ratios...",
    "Structuring your personalized learning modules...",
    "Finalizing your virtual simulator portfolio...",
    "Ready to build wealth."
  ];

  @override
  void initState() {
    super.initState();
    
    // Change text every 2.5 seconds
    _textTimer = Timer.periodic(const Duration(milliseconds: 2500), (timer) {
      if (_currentTextIndex < _loadingTexts.length - 1) {
        setState(() {
          _currentTextIndex++;
        });
      }
    });

    // Complete after 12.5 seconds
    _completionTimer = Timer(const Duration(milliseconds: 12500), () {
      if (mounted) {
        context.go('/learning');
      }
    });
  }

  @override
  void dispose() {
    _textTimer?.cancel();
    _completionTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F111A),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Glowing AI Core Animation
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const RadialGradient(
                  colors: [Color(0xFF00FFA3), Color(0xFF00B8FF), Colors.transparent],
                  stops: [0.2, 0.6, 1.0],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00FFA3).withValues(alpha: 0.5),
                    blurRadius: 40,
                    spreadRadius: 10,
                  ),
                  BoxShadow(
                    color: const Color(0xFF00B8FF).withValues(alpha: 0.3),
                    blurRadius: 80,
                    spreadRadius: 30,
                  ),
                ],
              ),
              child: const Center(
                child: Icon(Icons.auto_awesome, color: Colors.white, size: 48),
              ),
            )
            .animate(onPlay: (controller) => controller.repeat())
            .scale(duration: 1500.ms, begin: const Offset(0.9, 0.9), end: const Offset(1.1, 1.1), curve: Curves.easeInOutSine)
            .then()
            .scale(duration: 1500.ms, begin: const Offset(1.1, 1.1), end: const Offset(0.9, 0.9), curve: Curves.easeInOutSine),

            const SizedBox(height: 64),

            // Dynamic Text Sequence
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(begin: const Offset(0.0, 0.2), end: Offset.zero).animate(animation),
                    child: child,
                  ),
                );
              },
              child: Text(
                _loadingTexts[_currentTextIndex],
                key: ValueKey<int>(_currentTextIndex),
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
            ),

            const SizedBox(height: 16),
            const CircularProgressIndicator(
              color: Color(0xFF00FFA3),
              strokeWidth: 2,
            ).animate().fadeIn(delay: 500.ms),
          ],
        ),
      ),
    );
  }
}
