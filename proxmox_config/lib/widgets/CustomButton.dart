import 'package:flutter/material.dart';



class CustomButton extends StatefulWidget {
  final String text;
  final Color color;
  final VoidCallback? onPressed;
  final double width;
  final double height;
  final TextStyle textStyle;

  CustomButton({
    required this.text,
    required this.color,
    this.onPressed,
    double? width,
    this.height = 40,
    this.textStyle = const TextStyle(
      color: Colors.white,
      fontSize: 16,
    ),
  }) : width = width ?? _calculateTextWidth(text, textStyle);

  static double _calculateTextWidth(String text, TextStyle style) {
    final textPainter = TextPainter(
      text: TextSpan(text: text, style: style),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout();
    return textPainter.width + 32; // Adding 32 for padding
  }

  @override
  State<StatefulWidget> createState() => _CustomButtonState();
}

class _CustomButtonState extends State<CustomButton> {
  bool pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => pressed = true),
      onTapUp: (_) {
        setState(() => pressed = false);
        widget.onPressed?.call();
      },
      onTapCancel: () => setState(() => pressed = false),
      child: CustomPaint(
        size: Size(widget.width, widget.height),
        painter: CustomButtonPainter(
          color: pressed ? widget.color.withOpacity(0.8) : widget.color,
          text: widget.text,
          radius: 8,
          pressed: pressed,
          textStyle: widget.textStyle
        ),
      ),
    );
  }
}

class CustomButtonPainter extends CustomPainter {
  final Color color;
  final String text;
  final int radius;
  final bool pressed;
  final TextStyle textStyle;

  CustomButtonPainter({
    required this.color,
    required this.text, 
    required this.radius,
    required this.pressed,
    required this.textStyle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    
    // Create rounded rectangle path
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final rrect = RRect.fromRectAndRadius(
      rect,
      Radius.circular(radius.toDouble()),
    );
    
    // Draw the button background
    canvas.drawRRect(rrect, paint);
    
    // Setup text painter
    final textSpan = TextSpan(
      text: text,
      style: textStyle
    );
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );
    
    // Layout and paint text in center
    textPainter.layout();
    final textX = (size.width - textPainter.width) / 2;
    final textY = (size.height - textPainter.height) / 2;
    textPainter.paint(canvas, Offset(textX, textY));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    if (oldDelegate is CustomButtonPainter) {
      return oldDelegate.pressed != pressed || 
             oldDelegate.color != color ||
             oldDelegate.text != text ||
             oldDelegate.radius != radius;
    }
    return false;
  }
}

