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
make a custom file widget 15 [DONE]

get the files in the server directory and store them in a list 16 [DONE]
  - name
  - extension
  - folder?

diplay the files in a list with the file widget, the image should be 17 [DONE]
of the extension or a folder icon

when double clicking on a folder reread the files from the new location 18 [WITH BUGS]
and display them again

add a back button: cd ..

Session 3 -
order files
rename, remove, show info
extract rar/zip files
download files
upload files

Session 4 -
scene for configuring prot redirections
redirection custom widget

Session 5 -
detect nodeJS servers
detect jar files
Able to run the server, stop it, restart it

Session 6 - 7 -
Beutify

Bugs
- Server List: select the active server
- Dont show server buttons when there is no server selected
*/

