import 'package:flutter/material.dart';
import 'package:proxmox_config/models/RedirectionData.dart';

class PortRedirectionDisplay extends StatefulWidget {
  final Function(RedirectionData) onChanged;
  final RedirectionData initialData;

  const PortRedirectionDisplay({
    Key? key,
    required this.onChanged,
    required this.initialData,
  }) : super(key: key);

  @override
  State<PortRedirectionDisplay> createState() => _PortRedirectionDisplayState();
}

class _PortRedirectionDisplayState extends State<PortRedirectionDisplay> {
  late TextEditingController sourceController;
  late TextEditingController targetController;

  @override
  void initState() {
    super.initState();
    sourceController = TextEditingController(text: widget.initialData.dport?.toString());
    targetController = TextEditingController(text: widget.initialData.tport?.toString());
  }

  @override
  void dispose() {
    sourceController.dispose();
    targetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Source Port TextField
          SizedBox(
            width: 120,
            child: TextField(
              controller: sourceController,
              decoration: const InputDecoration(
                labelText: 'Source Port',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                widget.onChanged(RedirectionData(
                  dport: int.tryParse(value),
                  tport: int.tryParse(targetController.text),
                ));
              },
            ),
          ),
          // Custom Arrow
          CustomPaint(
            size: const Size(80, 40),
            painter: ArrowPainter(),
          ),
          // Target Port TextField
          SizedBox(
            width: 120,
            child: TextField(
              controller: targetController,
              decoration: const InputDecoration(
                labelText: 'Target Port',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              onChanged: (value) {
                widget.onChanged(RedirectionData(
                  dport: int.tryParse(sourceController.text) ?? 0,
                  tport: int.tryParse(value),
                ));
              },
            ),
          ),
        ],
      ),
    );
  }
}

class ArrowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.shade600
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    // Draw main line
    final path = Path()
      ..moveTo(0, size.height / 2)
      ..lineTo(size.width - 15, size.height / 2);

    // Draw arrow head
    path
      ..moveTo(size.width - 15, size.height / 2)
      ..lineTo(size.width - 25, size.height / 2 - 10)
      ..moveTo(size.width - 15, size.height / 2)
      ..lineTo(size.width - 25, size.height / 2 + 10);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}