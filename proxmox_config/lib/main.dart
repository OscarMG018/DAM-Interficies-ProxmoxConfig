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

Session 3 -
extract rar/zip files


Session 4 -
show info
order files
scene for configuring prot redirections
redirection custom widget

Session 5 -
detect nodeJS servers
detect jar files
Able to run the server, stop it, restart it

Session 6 
BugFixes

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

