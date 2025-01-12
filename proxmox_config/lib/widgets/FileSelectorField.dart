import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'CustomButton.dart';

class FileSelectorController extends ChangeNotifier {
  String? _selectedFilePath;
  
  String? get selectedFilePath => _selectedFilePath;
  
  FileSelectorController();

  set selectedFilePath(String? value) {
    if (_selectedFilePath != value) {
      _selectedFilePath = value;
      notifyListeners();
    }
  }

  void clear() {
    selectedFilePath = null;
  }

  bool get hasFile => _selectedFilePath != null;
}

class FileSelectorField extends StatefulWidget {
  final String label;
  final Function(String)? onFileSelected;
  final Color color;
  final FileSelectorController? controller;

  const FileSelectorField({
    Key? key,
    required this.label,
    this.onFileSelected,
    this.color = Colors.blue,
    this.controller,
  }) : super(key: key);

  @override
  State<FileSelectorField> createState() => _FileSelectorFieldState();
}

class _FileSelectorFieldState extends State<FileSelectorField> {
  late final FileSelectorController _controller;
  static final _defaultController = FileSelectorController();
  bool isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? _defaultController;
    _controller.addListener(_handleControllerChange);
  }

  @override
  void dispose() {
    if (widget.controller == null && _controller != _defaultController) {
      _controller.dispose();
    }
    _controller.removeListener(_handleControllerChange);
    super.dispose();
  }

  void _handleControllerChange() {
    setState(() {});
  }

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    
    if (result != null) {
      _controller.selectedFilePath = result.files.single.path;
      
      if (widget.onFileSelected != null && _controller.selectedFilePath != null) {
        widget.onFileSelected!(_controller.selectedFilePath!);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: MouseRegion(
                  onEnter: (_) => setState(() => isHovered = true),
                  onExit: (_) => setState(() => isHovered = false),
                  child: CustomPaint(
                    size: const Size(double.infinity, 36),
                    painter: TextFieldPainter(
                      text: _controller.selectedFilePath ?? 'No file selected',
                      isHovered: isHovered,
                      color: widget.color,
                      hasValue: _controller.hasFile,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              CustomButton(
                text: 'Choose File',
                color: widget.color,
                onPressed: _pickFile,
                width: 100,
                height: 36,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class TextFieldPainter extends CustomPainter {
  final String text;
  final bool isHovered;
  final Color color;
  final bool hasValue;

  TextFieldPainter({
    required this.text,
    required this.isHovered,
    required this.color,
    required this.hasValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw the background
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = isHovered ? color : Colors.grey
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(4),
    );

    canvas.drawRRect(rrect, paint);
    canvas.drawRRect(rrect, borderPaint);

    final textSpan = TextSpan(
      text: text,
      style: TextStyle(
        color: hasValue ? Colors.black : Colors.grey[600],
        fontSize: 14,
      ),
    );

    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '...',
    );

    textPainter.layout(maxWidth: size.width - 24);
    textPainter.paint(
      canvas,
      Offset(12, (size.height - textPainter.height) / 2),
    );
  }

  @override
  bool shouldRepaint(covariant TextFieldPainter oldDelegate) {
    return oldDelegate.text != text ||
           oldDelegate.isHovered != isHovered ||
           oldDelegate.color != color ||
           oldDelegate.hasValue != hasValue;
  }
}