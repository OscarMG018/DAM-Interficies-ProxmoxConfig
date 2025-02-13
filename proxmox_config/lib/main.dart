import 'package:flutter/material.dart';
import 'scenes/ConfigScene.dart';
import 'package:provider/provider.dart';
import 'providers/FileProvider.dart';
import 'providers/ServerProvider.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => FileProvider()),
        ChangeNotifierProvider(create: (_) => ServerProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(
            child: ConfigScene(),
          ),
        ),
      ),
    );
  }
}