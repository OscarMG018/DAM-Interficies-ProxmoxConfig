import 'package:flutter/material.dart';
import 'package:proxmox_config/models/FileData.dart';
import 'dart:math';

class FileInfo extends StatelessWidget {
  final FileData file;

  const FileInfo({super.key, required this.file});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 600,
          maxHeight: 400,
        ),
        child: CustomPaint(
          painter: FileInfoPainter(file: file),
          size: const Size(600, 400),
        ),
      ),
    );
  }
}

class FileInfoPainter extends CustomPainter {
  final FileData file;

  FileInfoPainter({required this.file});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint backgroundPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final Paint shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.1)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    final Paint accentPaint = Paint()
      ..color = _getFileTypeColor()
      ..style = PaintingStyle.fill;

    final Paint borderPaint = Paint()
      ..color = Colors.grey.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // Draw shadow
    final shadowPath = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(4, 4, size.width - 8, size.height - 8),
        const Radius.circular(16),
      ));
    canvas.drawPath(shadowPath, shadowPaint);

    // Draw main background
    final backgroundPath = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        const Radius.circular(16),
      ));
    canvas.drawPath(backgroundPath, backgroundPaint);

    // Draw accent header
    final headerPath = Path()
      ..addRRect(RRect.fromRectAndCorners(
        Rect.fromLTWH(0, 0, size.width, 50),
        topLeft: const Radius.circular(16),
        topRight: const Radius.circular(16),
      ));
    canvas.drawPath(headerPath, accentPaint);

    // Draw border
    canvas.drawPath(backgroundPath, borderPaint);

    // Text Painting
    _drawTitle(canvas, size);
    _drawFileInfo(canvas, size);
  }

  void _drawTitle(Canvas canvas, Size size) {
    final titleStyle = TextStyle(
      color: Colors.white,
      fontSize: 20,
      fontWeight: FontWeight.bold,
    );

    final titleSpan = TextSpan(
      text: file.name,
      style: titleStyle,
    );

    final titlePainter = TextPainter(
      text: titleSpan,
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '...',
    );

    titlePainter.layout(maxWidth: size.width - 32);
    titlePainter.paint(
      canvas,
      Offset(16, 15),
    );
  }

  void _drawFileInfo(Canvas canvas, Size size) {
    const labelStyle = TextStyle(
      color: Colors.black87,
      fontSize: 20,
      fontWeight: FontWeight.bold,
    );

    const valueStyle = TextStyle(
      color: Colors.black87,
      fontSize: 20,
    );

    final infoItems = [
      {'label': 'Type', 'value': file.isFolder ? 'Folder' : file.extension},
      {'label': 'Size', 'value': file.getFormattedSize()},
      {'label': 'Modified', 'value': file.getFormatedDate()},
      {'label': 'Owner', 'value': file.owner},
      {'label': 'Permissions', 'value': file.getFormattedPermissions()},
    ];

    var yOffset = 80.0;
    const padding = 16.0;
    const lineHeight = 40.0;

    for (var item in infoItems) {
      
      final labelSpan = TextSpan(
        text: '${item['label']}: ',
        style: labelStyle,
      );

      final labelPainter = TextPainter(
        text: labelSpan,
        textDirection: TextDirection.ltr,
      );

      labelPainter.layout();
      labelPainter.paint(canvas, Offset(padding, yOffset));

      // Draw value with wrapping
      final valueSpan = TextSpan(
        text: item['value'],
        style: valueStyle,
      );

      final valuePainter = TextPainter(
        text: valueSpan,
        textDirection: TextDirection.ltr,
        maxLines: 10,
        textAlign: TextAlign.left,
      );

      final maxValueWidth = size.width - labelPainter.width - (padding * 2);
      valuePainter.layout(maxWidth: maxValueWidth);
      
      valuePainter.paint(
        canvas,
        Offset(padding + labelPainter.width, yOffset),
      );

      yOffset += valuePainter.height > lineHeight ? valuePainter.height : lineHeight;
    }
  }

  Color _getFileTypeColor() {
    if (file.isFolder) {
      return Colors.blue;
    }
    switch (file.extension.toLowerCase()) {
      case 'pdf':
        return Colors.red;
      case 'doc':
      case 'docx':
        return Colors.blue;
      case 'xls':
      case 'xlsx':
        return Colors.green;
      case 'jpg':
      case 'jpeg':
      case 'png':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}