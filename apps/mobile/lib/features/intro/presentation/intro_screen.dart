import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';

class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> _introData = [
    {
      'title': 'Track Your Spending',
      'subtitle': 'Automatically categorize your expenses and understand where your money goes. Stay in control.',
      'icon': 'insights',
    },
    {
      'title': 'Learn Financial Discipline',
      'subtitle': 'Bite-sized, gamified lessons to teach you the fundamentals of investing, saving, and wealth generation.',
      'icon': 'school',
    },
    {
      'title': 'Simulate Investments',
      'subtitle': 'Test your strategies in a risk-free environment with real-time market data before using real money.',
      'icon': 'show_chart',
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onNext() {
    if (_currentPage < _introData.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _finishIntro();
    }
  }

  Future<void> _finishIntro() async {
    final box = Hive.box('settings');
    await box.put('has_seen_intro', true);
    if (mounted) {
      context.go('/sign-in');
    }
  }

  IconData _getIconData(String name) {
    switch (name) {
      case 'insights':
        return Icons.insights_rounded;
      case 'school':
        return Icons.school_rounded;
      case 'show_chart':
        return Icons.show_chart_rounded;
      default:
        return Icons.star_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0C0E0A),
      body: Stack(
        children: [
          // Background Glow
          Positioned(
            top: -100,
            left: -100,
            right: -100,
            height: 400,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFD4FF2A).withValues(alpha: 0.15),
                    Colors.transparent,
                  ],
                  stops: const [0.1, 1.0],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() {
                        _currentPage = index;
                      });
                    },
                    itemCount: _introData.length,
                    itemBuilder: (context, index) {
                      final data = _introData[index];
                      return Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(32),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFFD4FF2A).withValues(alpha: 0.1),
                                border: Border.all(
                                  color: const Color(0xFFD4FF2A).withValues(alpha: 0.3),
                                  width: 2,
                                ),
                              ),
                              child: Icon(
                                _getIconData(data['icon']!),
                                size: 80,
                                color: const Color(0xFFD4FF2A),
                              ),
                            ).animate().scale(delay: 200.ms, duration: 600.ms, curve: Curves.easeOutBack),
                            const SizedBox(height: 64),
                            Text(
                              data['title']!,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                height: 1.2,
                              ),
                            ).animate().slideY(begin: 0.3, end: 0, duration: 500.ms).fadeIn(),
                            const SizedBox(height: 16),
                            Text(
                              data['subtitle']!,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.spaceGrotesk(
                                color: Colors.white70,
                                fontSize: 16,
                                height: 1.5,
                              ),
                            ).animate().slideY(begin: 0.3, end: 0, delay: 100.ms, duration: 500.ms).fadeIn(),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                // Bottom Controls
                Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    children: [
                      // Indicators
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          _introData.length,
                          (index) => AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: _currentPage == index ? 24 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: _currentPage == index
                                  ? const Color(0xFFD4FF2A)
                                  : Colors.white24,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      // Action Button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _onNext,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFD4FF2A),
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            _currentPage == _introData.length - 1
                                ? 'Get Started'
                                : 'Next',
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Skip Button
                      if (_currentPage < _introData.length - 1)
                        TextButton(
                          onPressed: _finishIntro,
                          child: Text(
                            'Skip',
                            style: GoogleFonts.spaceGrotesk(
                              color: Colors.white54,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        )
                      else
                        const SizedBox(height: 48), // Maintain height balance
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
