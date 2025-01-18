import 'package:flutter/material.dart';
import 'scenes/ConfigScene.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: ConfigScene(),
        ),
      ),
    );
  }
}

/* 

Session 5 -
- fix redirection
- change extract rar/zip files to require the server to have the unzip command
- UI overflow on both scenes
- server scene: change the buttons and checkbox of ServerScene to be custom
- server scene: renmame dialog to be a custom dialog

Session 6 
detect nodeJS servers
detect jar files
Able to run the server, stop it, restart it

Session 7 -
Beutify
*/

