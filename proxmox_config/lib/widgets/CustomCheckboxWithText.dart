import 'package:flutter/material.dart';

class CustomCheckboxWithText extends StatelessWidget {
  final bool isChecked;
  final String text;
  final Function(bool?) onChanged;
  final double size;
  final Color checkColor;
  final Color borderColor;

  const CustomCheckboxWithText({
    Key? key,
    required this.isChecked,
    required this.text,
    required this.onChanged,
    this.size = 24.0,
    this.checkColor = Colors.blue,
    this.borderColor = Colors.grey,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!isChecked),
      child: Row(
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: CheckboxPainter(
              isChecked: isChecked,
              checkColor: checkColor,
              borderColor: borderColor,
            ),
          ),
          SizedBox(width: 8),
          Text(text),
        ],
      ),
    );
  }
}

class CheckboxPainter extends CustomPainter {
  final bool isChecked;
  final Color checkColor;
  final Color borderColor;

  CheckboxPainter({
    required this.isChecked,
    required this.checkColor,
    required this.borderColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    // Draw the checkbox border
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Radius.circular(4),
      ),
      paint,
    );

    if (isChecked) {
      // Draw the check mark
      paint
        ..color = checkColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5;

      final path = Path();
      path.moveTo(size.width * 0.2, size.height * 0.5);
      path.lineTo(size.width * 0.45, size.height * 0.75);
      path.lineTo(size.width * 0.8, size.height * 0.25);

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(CheckboxPainter oldDelegate) {
    return isChecked != oldDelegate.isChecked ||
        checkColor != oldDelegate.checkColor ||
        borderColor != oldDelegate.borderColor;
  }
}