import 'package:flutter/material.dart';
import 'package:cuttinglist/screens/3d_design.dart';
import 'package:cuttinglist/screens/drawingboard_screen.dart';
import 'package:cuttinglist/screens/folder_screen.dart';
import 'package:cuttinglist/screens/vanish_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Folder & File App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: VanishScreen(), // Start with the Vanish screen
    );
  }
}
