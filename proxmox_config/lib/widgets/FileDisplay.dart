import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class FileDisplay extends StatefulWidget {
  final String fileName;
  final String assetImagePath;
  final List<String> actions;
  final Function(String)? onActionSelected;
  final VoidCallback? onDoubleClick;

  const FileDisplay({
    required this.fileName,
    required this.assetImagePath,
    required this.actions,
    this.onActionSelected,
    this.onDoubleClick,
  });

  @override
  State<FileDisplay> createState() => _FileDisplayState();
}

class _FileDisplayState extends State<FileDisplay> {
  String? selectedAction;
  ui.Image? image;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    try {
      final ImageProvider imageProvider = AssetImage(widget.assetImagePath);
      final imageStream = imageProvider.resolve(ImageConfiguration());
      final completer = Completer<ui.Image>();
      
      final listener = ImageStreamListener(
        (ImageInfo info, bool _) {
          completer.complete(info.image);
        },
        onError: (dynamic exception, StackTrace? stackTrace) {
          print('Error loading image: $exception');
          completer.completeError(exception);
        },
      );

      imageStream.addListener(listener);
      
      final loadedImage = await completer.future;
      if (mounted) {
        setState(() {
          image = loadedImage;
        });
      }
    } catch (e) {
      print('Error loading image: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: CustomPaint(
        painter: FileDisplayPainter(
          fileName: widget.fileName,
          image: image,
          actions: widget.actions,
          selectedAction: selectedAction,
        ),
        child: GestureDetector(
          onTapUp: (details) {
            final RenderBox box = context.findRenderObject() as RenderBox;
            final localPosition = details.localPosition;
            final buttonWidth = 80.0;
            final startX = box.size.width - (buttonWidth * widget.actions.length);
            
            if (localPosition.dx >= startX) {
              final buttonIndex = ((localPosition.dx - startX) ~/ buttonWidth);
              if (buttonIndex >= 0 && buttonIndex < widget.actions.length) {
                setState(() {
                  selectedAction = widget.actions[buttonIndex];
                });
                widget.onActionSelected?.call(widget.actions[buttonIndex]);
              }
            }
          },
          onDoubleTap: () {
            final RenderBox box = context.findRenderObject() as RenderBox;
            final buttonWidth = 80.0;
            final startX = box.size.width - (buttonWidth * widget.actions.length);
            
            // Get the local position of the tap
            final tapPosition = box.globalToLocal(Offset.zero);
            
            // Only trigger if not clicking in the actions area
            if (tapPosition.dx < startX) {
              widget.onDoubleClick?.call();
            }
          },
        ),
      ),
    );
  }
}

class FileDisplayPainter extends CustomPainter {
  final String fileName;
  final ui.Image? image;
  final List<String> actions;
  final String? selectedAction;

  FileDisplayPainter({
    required this.fileName,
    required this.image,
    required this.actions,
    this.selectedAction,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw background
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    // Draw image
    if (image != null) {
      final imageRect = Rect.fromLTWH(10, 10, 40, 40);
      canvas.drawImageRect(
        image!,
        Rect.fromLTWH(0, 0, image!.width.toDouble(), image!.height.toDouble()),
        imageRect,
        Paint(),
      );
    } else {
      // Draw placeholder if image is not loaded
      final placeholderPaint = Paint()..color = Colors.grey[300]!;
      canvas.drawRect(Rect.fromLTWH(10, 10, 40, 40), placeholderPaint);
    }

    // Draw file name
    final textPainter = TextPainter(
      text: TextSpan(
        text: fileName,
        style: TextStyle(fontSize: 16, color: Colors.black),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(60, (size.height - textPainter.height) / 2));

    // Draw action buttons
    final buttonWidth = 80.0;
    final buttonHeight = 40.0;
    final startX = size.width - (buttonWidth * actions.length);

    for (var i = 0; i < actions.length; i++) {
      final buttonRect = Rect.fromLTWH(
        startX + (i * buttonWidth),
        (size.height - buttonHeight) / 2,
        buttonWidth,
        buttonHeight,
      );

      final buttonPaint = Paint()
        ..color = actions[i] == selectedAction ? Colors.grey[300]! : Colors.transparent
        ..style = PaintingStyle.fill;

      canvas.drawRRect(
        RRect.fromRectAndRadius(buttonRect, Radius.circular(8)),
        buttonPaint,
      );

      final buttonText = TextPainter(
        text: TextSpan(
          text: actions[i],
          style: TextStyle(fontSize: 14, color: Colors.black),
        ),
        textDirection: TextDirection.ltr,
      );
      buttonText.layout();
      buttonText.paint(
        canvas,
        Offset(
          startX + (i * buttonWidth) + (buttonWidth - buttonText.width) / 2,
          (size.height - buttonText.height) / 2,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    if (oldDelegate is FileDisplayPainter) {
      return oldDelegate.selectedAction != selectedAction || 
             oldDelegate.image != image;
    }
    return false;
  }
}
