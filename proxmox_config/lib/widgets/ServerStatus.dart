import 'package:flutter/material.dart';
import 'package:proxmox_config/models/ServerType.dart';

class ServerStatus extends StatelessWidget {
  final ServerType serverType;
  final bool isRunning;
  final VoidCallback onStart;
  final VoidCallback onStop;
  final VoidCallback onRestart;

  const ServerStatus({
    Key? key,
    required this.serverType,
    required this.isRunning,
    required this.onStart,
    required this.onStop,
    required this.onRestart,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 80,
      width: double.infinity,
      child: GestureDetector(
        onTapUp: (details) => _handleTap(context, details.localPosition),
        child: CustomPaint(
          painter: ServerStatusPainter(
            serverType: serverType,
            isRunning: isRunning,
            buttonLocations: _calculateButtonLocations(context),
          ),
        ),
      ),
    );
  }

  List<Rect> _calculateButtonLocations(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    const buttonWidth = 80.0;
    const buttonHeight = 36.0;
    const buttonSpacing = 8.0;
    const rightPadding = 16.0;
    const borderPadding = 32.0;

    if (isRunning) {
      return [
        // Stop button
        Rect.fromLTWH(
          width - 2 * buttonWidth - buttonSpacing - rightPadding - borderPadding,
          22,
          buttonWidth,
          buttonHeight,
        ),
        // Restart button
        Rect.fromLTWH(
          width - buttonWidth - rightPadding - borderPadding,
          22,
          buttonWidth,
          buttonHeight,
        ),
      ];
    } else {
      return [
        // Start button
        Rect.fromLTWH(
          width - buttonWidth - rightPadding - borderPadding,
          22,
          buttonWidth,
          buttonHeight,
        ),
      ];
    }
  }

  void _handleTap(BuildContext context, Offset tapPosition) {
    final buttons = _calculateButtonLocations(context);
    
    for (int i = 0; i < buttons.length; i++) {
      if (buttons[i].contains(tapPosition)) {
        if (isRunning) {
          if (i == 0) onStop();
          if (i == 1) onRestart();
        } else {
          onStart();
        }
        break;
      }
    }
  }
}

class ServerStatusPainter extends CustomPainter {
  final ServerType serverType;
  final bool isRunning;
  final List<Rect> buttonLocations;

  ServerStatusPainter({
    required this.serverType,
    required this.isRunning,
    required this.buttonLocations,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _drawBackground(canvas, size);
    _drawText(canvas, size);
    _drawButtons(canvas);
  }

  void _drawBackground(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isRunning ? Colors.green.shade600 : Colors.red.shade600
      ..style = PaintingStyle.fill;

    final RRect rRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(12),
    );
    canvas.drawRRect(rRect, paint);
  }

  void _drawText(Canvas canvas, Size size) {
    final textSpan = TextSpan(
      text: serverType == ServerType.node 
          ? 'Node Server detected'
          : 'Java Server detected',
      style: const TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );

    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(16, (size.height - textPainter.height) / 2),
    );
  }

  void _drawButtons(Canvas canvas) {
    final buttonPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final buttonTextStyle = const TextStyle(
      color: Colors.black,
      fontSize: 14,
      fontWeight: FontWeight.w500,
    );

    for (int i = 0; i < buttonLocations.length; i++) {
      final rect = buttonLocations[i];
      
      // Draw button background
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(8)),
        buttonPaint,
      );

      // Draw button text
      final String buttonText;
      if (isRunning) {
        buttonText = i == 0 ? 'Stop' : 'Restart';
      } else {
        buttonText = 'Start';
      }

      final textSpan = TextSpan(
        text: buttonText,
        style: buttonTextStyle,
      );

      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );

      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          rect.left + (rect.width - textPainter.width) / 2,
          rect.top + (rect.height - textPainter.height) / 2,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(ServerStatusPainter oldDelegate) {
    return oldDelegate.serverType != serverType || 
           oldDelegate.isRunning != isRunning;
  }
}