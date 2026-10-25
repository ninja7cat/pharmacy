import 'package:flutter/material.dart';

/// A WhatsApp-style logo (speech bubble with a phone inside), drawn in code
/// so no extra package is needed. It takes any colour, so it works on both
/// light and dark buttons.
class WhatsAppIcon extends StatelessWidget {
  final double size;
  final Color color;

  const WhatsAppIcon({super.key, this.size = 24, this.color = Colors.white});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _WhatsAppBubblePainter(color),
        child: Center(
          child: Icon(Icons.phone_rounded, size: size * 0.5, color: color),
        ),
      ),
    );
  }
}

class _WhatsAppBubblePainter extends CustomPainter {
  final Color color;

  const _WhatsAppBubblePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    // Round bubble outline.
    canvas.drawCircle(
      Offset(w * 0.5, h * 0.5),
      w * 0.41,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.09,
    );

    // Little tail at the bottom-left.
    final Path tail = Path()
      ..moveTo(w * 0.04, h * 0.96)
      ..lineTo(w * 0.15, h * 0.64)
      ..lineTo(w * 0.37, h * 0.88)
      ..close();

    canvas.drawPath(tail, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _WhatsAppBubblePainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
