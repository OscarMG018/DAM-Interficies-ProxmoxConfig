import 'package:flutter/material.dart';
import 'package:proxmox_config/models/ServerType.dart';
import 'package:provider/provider.dart';
import '../providers/ServerProvider.dart';

class ServerStatus extends StatelessWidget {
  final ServerType serverType;
  final String serverPath;
  final bool isRunning;
  final VoidCallback onStart;
  final VoidCallback onStop;
  final VoidCallback onRestart;

  const ServerStatus({
    Key? key,
    required this.serverPath,
    required this.serverType,
    required this.isRunning,
    required this.onStart,
    required this.onStop,
    required this.onRestart,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<ServerProvider>(
      builder: (context, serverProvider, child) {
        return Stack(
          children: [
            SizedBox(
              height: 80,
              width: double.infinity,
              child: GestureDetector(
                onTapUp: serverProvider.isServerOperation 
                  ? null 
                  : (details) => _handleTap(context, details.localPosition),
                child: CustomPaint(
                  painter: ServerStatusPainter(
                    serverPath: serverPath,
                    serverType: serverType,
                    isRunning: isRunning,
                    buttonLocations: _calculateButtonLocations(context),
                    isDisabled: serverProvider.isServerOperation,
                  ),
                ),
              ),
            ),
            if (serverProvider.isServerOperation)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          serverProvider.currentOperation != '' 
                            ? '${serverProvider.currentOperation}...'
                            : isRunning ? 'Stopping...' : 'Starting...',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
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
  final String serverPath;
  final bool isRunning;
  final List<Rect> buttonLocations;
  final bool isDisabled;

  ServerStatusPainter({
    required this.serverPath,
    required this.serverType,
    required this.isRunning,
    required this.buttonLocations,
    this.isDisabled = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _drawBackground(canvas, size);
    _drawText(canvas, size);
    if (!isDisabled) {
      _drawButtons(canvas);
    }
  }

  void _drawBackground(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isDisabled 
        ? Colors.grey.shade600
        : (isRunning ? Colors.green.shade600 : Colors.red.shade600)
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
          ? 'Node Server detected at $serverPath'
          : 'Java Server detected at $serverPath',
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
           oldDelegate.isRunning != isRunning ||
           oldDelegate.isDisabled != isDisabled;
  }
}