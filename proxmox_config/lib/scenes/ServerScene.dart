import 'package:dartssh2/dartssh2.dart';
import 'package:flutter/material.dart';

class ServerScene extends StatefulWidget {
  final SSHClient client;

  const ServerScene({
    Key? key,
    required this.client,
  }) : super(key: key);
  
  @override
  _ServerSceneState createState() => _ServerSceneState();
}

class _ServerSceneState extends State<ServerScene> {

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Center(
        child: Text("Server Scene"),
      ),
    );
  }
  
}