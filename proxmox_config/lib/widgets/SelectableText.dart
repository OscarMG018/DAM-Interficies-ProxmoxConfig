import 'package:flutter/material.dart';

class SelectableText extends StatefulWidget {
  final String text;
  final Size size;
  final VoidCallback? onClick;
  final bool isSelected;

  const SelectableText({
    required this.text,
    this.size = const Size(200, 50),
    this.onClick,
    this.isSelected = false,
    Key? key,
  }) : super(key: key);

  void setSelected(bool isSelected) {
    isSelected = isSelected;
    createState();
  }

  @override
  State<SelectableText> createState() => _SelectableTextState();
}

class _SelectableTextState extends State<SelectableText> {

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (widget.onClick != null) {
          widget.onClick!();
        }
      },
      child: CustomPaint(
        painter: CustomSelectableTextPainter(isSelected: widget.isSelected),
        child: Container(
          width: widget.size.width,
          height: widget.size.height,
          padding: const EdgeInsets.all(8),
          child: Center(
            child: Text(
              widget.text,
              style: const TextStyle(
                fontSize: 16.0,
                color: Colors.black,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class CustomSelectableTextPainter extends CustomPainter {
  final bool isSelected;

  CustomSelectableTextPainter({required this.isSelected});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = isSelected ? Colors.grey.withOpacity(0.3) : Colors.transparent
      ..style = PaintingStyle.fill;

    final Rect rect = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(8)),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    if (oldDelegate is CustomSelectableTextPainter) {
      return oldDelegate.isSelected != isSelected;
    }
    return false;
  }
}