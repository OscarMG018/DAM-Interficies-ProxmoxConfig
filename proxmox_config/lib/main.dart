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
Session 2 -
server name as title
Close connection button
Reconnect button
make a custom file widget
get the files in the server directory
navigate in folders by clicking on them

Session 3 -
order files
rename, remove, show info
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

Session 6 - 7 -
Beutify


Bugs
- Server List: select the active server
- Dont show server buttons when there is no server selected
*/

