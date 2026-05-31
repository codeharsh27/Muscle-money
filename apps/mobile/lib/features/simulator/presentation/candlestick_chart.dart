import 'dart:math';
import 'package:flutter/material.dart';
import '../data/yahoo_finance_api.dart';

class CandlestickChart extends StatefulWidget {
  final List<YahooOhlc> data;

  const CandlestickChart({super.key, required this.data});

  @override
  State<CandlestickChart> createState() => _CandlestickChartState();
}

class _CandlestickChartState extends State<CandlestickChart> {
  Offset? _crosshairOffset;
  YahooOhlc? _selectedCandle;

  void _updateCrosshair(Offset localPosition, Size size) {
    if (widget.data.isEmpty) return;

    final candleWidth = size.width / widget.data.length;
    int index = (localPosition.dx / candleWidth).floor();
    index = index.clamp(0, widget.data.length - 1);

    setState(() {
      _crosshairOffset = localPosition;
      _selectedCandle = widget.data[index];
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.data.isEmpty) return const Center(child: Text('No chart data available'));
    
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        
        return Stack(
          children: [
            InteractiveViewer(
              minScale: 1.0,
              maxScale: 10.0,
              boundaryMargin: const EdgeInsets.all(20),
              child: GestureDetector(
                onLongPressStart: (details) => _updateCrosshair(details.localPosition, size),
                onLongPressMoveUpdate: (details) => _updateCrosshair(details.localPosition, size),
                onLongPressEnd: (_) => setState(() {
                  _crosshairOffset = null;
                  _selectedCandle = null;
                }),
                onTapDown: (details) => _updateCrosshair(details.localPosition, size),
                onTapUp: (_) => setState(() {
                  _crosshairOffset = null;
                  _selectedCandle = null;
                }),
                onPanUpdate: (details) => _updateCrosshair(details.localPosition, size),
                onPanEnd: (_) => setState(() {
                  _crosshairOffset = null;
                  _selectedCandle = null;
                }),
                child: CustomPaint(
                  size: size,
                  painter: _CandlestickPainter(
                    data: widget.data,
                    upColor: Colors.green,
                    downColor: Colors.red,
                    crosshairOffset: _crosshairOffset,
                  ),
                ),
              ),
            ),
            
            // Value display overlay (Top left)
            if (_selectedCandle != null)
              Positioned(
                top: 0,
                left: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  color: Colors.black54,
                  child: Row(
                    children: [
                      _buildInfoText('O', _selectedCandle!.open),
                      _buildInfoText('H', _selectedCandle!.high),
                      _buildInfoText('L', _selectedCandle!.low),
                      _buildInfoText('C', _selectedCandle!.close),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
  
  Widget _buildInfoText(String label, double val) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: Text(
        '$label: ${val.toStringAsFixed(2)}',
        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _CandlestickPainter extends CustomPainter {
  final List<YahooOhlc> data;
  final Color upColor;
  final Color downColor;
  final Offset? crosshairOffset;

  _CandlestickPainter({
    required this.data,
    required this.upColor,
    required this.downColor,
    this.crosshairOffset,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    double maxPrice = data.map((e) => e.high).reduce(max);
    double minPrice = data.map((e) => e.low).reduce(min);
    
    // Add 2% padding top and bottom
    final range = maxPrice - minPrice;
    maxPrice += range * 0.05;
    minPrice -= range * 0.05;
    
    if (maxPrice == minPrice) {
      maxPrice += 1;
      minPrice -= 1;
    }

    final candleWidth = size.width / data.length;
    final maxWickWidth = 1.5;
    final maxBodyWidth = (candleWidth * 0.7).clamp(1.0, 20.0);
    
    final paint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < data.length; i++) {
      final candle = data[i];
      final isUp = candle.close >= candle.open;
      paint.color = isUp ? upColor : downColor;

      final x = i * candleWidth + (candleWidth / 2);

      double getY(double price) {
        return size.height - ((price - minPrice) / (maxPrice - minPrice) * size.height);
      }

      final highY = getY(candle.high);
      final lowY = getY(candle.low);
      final openY = getY(candle.open);
      final closeY = getY(candle.close);

      // Draw wick
      canvas.drawRect(Rect.fromLTRB(x - maxWickWidth / 2, highY, x + maxWickWidth / 2, lowY), paint);

      // Draw body
      final topBody = min(openY, closeY);
      var bottomBody = max(openY, closeY);
      
      if (bottomBody - topBody < 1) {
        bottomBody = topBody + 1;
      }

      canvas.drawRect(Rect.fromLTRB(x - maxBodyWidth / 2, topBody, x + maxBodyWidth / 2, bottomBody), paint);
    }
    
    // Draw crosshair
    if (crosshairOffset != null) {
      final linePaint = Paint()
        ..color = Colors.white54
        ..strokeWidth = 1.0
        ..style = PaintingStyle.stroke;
        
      // Render dashed line logic can be complex, so we'll just draw solid faint lines
      canvas.drawLine(Offset(crosshairOffset!.dx, 0), Offset(crosshairOffset!.dx, size.height), linePaint);
      canvas.drawLine(Offset(0, crosshairOffset!.dy), Offset(size.width, crosshairOffset!.dy), linePaint);
      
      // We also draw a dot at the intersection
      canvas.drawCircle(crosshairOffset!, 4, linePaint..style = PaintingStyle.fill..color = Colors.white);
    }
  }

  @override
  bool shouldRepaint(covariant _CandlestickPainter oldDelegate) {
    return oldDelegate.data != data ||
           oldDelegate.crosshairOffset != crosshairOffset ||
           oldDelegate.upColor != upColor ||
           oldDelegate.downColor != downColor;
  }
}
