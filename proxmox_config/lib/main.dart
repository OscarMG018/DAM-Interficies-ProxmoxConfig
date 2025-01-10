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
Session 1 -
load and save configurations [x]
make a file selector custom widget []
make a custom button widget [x]
make the SSH client class and connect to server [x]

Session 2 -
make a custom file widget
get the files in the server directory
navigate in folders by clicking on them

Session 3 -
rename, remove, files
extract rar/zip files
download files
upload files

Session 4 -
detect nodeJS servers
detect jar files
Able to run the server, stop it, restart it

Session 5 -
scene for configuring prot redirections
redirection custom widget

Bugs
- Server List: select the active server
- Dont show server buttons when there is no server selected
*/

