import 'package:flutter/material.dart';

class LabeledTextField extends StatefulWidget {
  final String label;
  final String initialText;
  
  LabeledTextField({
    Key? key,
    required this.label,
    this.initialText = '',
  }) : super(key: key);

  final GlobalKey<_LabeledTextFieldState> _key = GlobalKey<_LabeledTextFieldState>();
  
  String get text => (_key.currentState as _LabeledTextFieldState).text;
  set text(String value) => (_key.currentState as _LabeledTextFieldState).text = value;

  @override
  State<LabeledTextField> createState() => _LabeledTextFieldState();
}

class _LabeledTextFieldState extends State<LabeledTextField> {
  final TextEditingController _controller = TextEditingController();
  bool _isFocused = false;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller.text = widget.initialText;
    _focusNode = FocusNode();
    _focusNode.addListener(() {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  String get text => _controller.text;
  set text(String newText) {
    _controller.text = newText;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,  
      height: 80,
      child: CustomPaint(
        painter: CustomTextFieldPainter(isFocused: _isFocused),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey,
                ),
              ),
              const SizedBox(height: 4),
              Expanded(
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CustomTextFieldPainter extends CustomPainter {
  final bool isFocused;
  
  CustomTextFieldPainter({required this.isFocused});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = isFocused ? Colors.blue : Colors.grey
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
      
    final Rect rect = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(8)),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    if (oldDelegate is CustomTextFieldPainter) {
      return oldDelegate.isFocused != isFocused;
    }
    return false;
  }
}