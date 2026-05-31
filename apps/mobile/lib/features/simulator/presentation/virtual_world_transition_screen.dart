import 'package:flutter/material.dart';
import 'virtual_world_shell.dart';

class VirtualWorldTransitionScreen extends StatefulWidget {
  final bool isExiting;
  const VirtualWorldTransitionScreen({super.key, this.isExiting = false});

  @override
  State<VirtualWorldTransitionScreen> createState() => _VirtualWorldTransitionScreenState();
}

class _VirtualWorldTransitionScreenState extends State<VirtualWorldTransitionScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );

    _controller.forward();
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (mounted) {
          if (widget.isExiting) {
            // For exiting, we pop the transition screen which takes us back to the real world
            Navigator.of(context).pop();
          } else {
            // For entering, we push replacement to the virtual world
            Navigator.of(context).pushReplacement(
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) => const VirtualWorldShell(),
                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
                transitionDuration: const Duration(milliseconds: 600),
              ),
            );
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = widget.isExiting ? Colors.redAccent : Colors.greenAccent;

    return Scaffold(
      backgroundColor: Colors.black, // Sleek black background
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Simulated trading background (using a grid and subtle gradient)
          CustomPaint(
            painter: _GridPainter(color: primaryColor.withValues(alpha: 0.05)),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    widget.isExiting ? Icons.exit_to_app : Icons.candlestick_chart,
                    color: primaryColor,
                    size: 80,
                  ),
                  const SizedBox(height: 32),
                  Text(
                    widget.isExiting ? 'EXITING VIRTUAL WORLD' : 'ENTERING VIRTUAL WORLD',
                    style: TextStyle(
                      color: primaryColor,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.isExiting 
                        ? 'Disconnecting from the trading floor...' 
                        : 'Establishing secure connection to the trading floor...',
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),
                  AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: _controller.value,
                          minHeight: 8,
                          backgroundColor: Colors.white10,
                          valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      return Text(
                        '${(_controller.value * 100).toInt()}%',
                        style: TextStyle(
                          color: primaryColor,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  final Color color;
  _GridPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.0;

    const step = 40.0;
    
    // Draw vertical lines
    for (double i = 0; i < size.width; i += step) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    
    // Draw horizontal lines
    for (double i = 0; i < size.height; i += step) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter oldDelegate) => oldDelegate.color != color;
}
