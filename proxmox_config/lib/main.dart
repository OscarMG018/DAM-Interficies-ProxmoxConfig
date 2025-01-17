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
Session 4 -
show info [DONE]
order files [DONE]
redirection custom dialog [PLANED]

Session 5 -
fix extract rar/zip files bugs
BugFixes

Session 6 
detect nodeJS servers
detect jar files
Able to run the server, stop it, restart it

Session 7 -
Beutify

Bugs
- Server List: select the active server
- Dont show server buttons when there is no server selected
- .. and . show in the file list as folders
- UI overflow on both scenes

Other
- change the buttons and checkbox of ServerScene to be custom
*/

