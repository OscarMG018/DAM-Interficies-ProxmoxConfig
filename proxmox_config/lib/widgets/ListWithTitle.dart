import 'package:flutter/material.dart';

class ListWithTitle extends StatefulWidget {
  final String title;
  final List<Widget> items;

  const ListWithTitle({
    Key? key,
    required this.title,
    required this.items,
  }) : super(key: key);

  @override
  State<ListWithTitle> createState() => _ListWithTitle();
}

class _ListWithTitle extends State<ListWithTitle> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Títol en negreta
        Text(
          widget.title,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        SizedBox(height: 10),
        // Llista d'ítems amb identació, ara és una llista de widgets
        ...widget.items.map((item) => Padding(
              padding: const EdgeInsets.only(left: 20.0),
              child: item,
            )),
      ],
    );
  }
}
