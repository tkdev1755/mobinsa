

import 'package:flutter/material.dart';

import '../model/School.dart';
import '../model/Student.dart';


class DebugPage extends StatefulWidget {
  List<Student> student;
  List<School> schools;
   DebugPage({Key? key, required this.student, required this.schools}) : super(key: key);

  @override
  State<DebugPage> createState() => _DebugPageState();
}


class _DebugPageState extends State<DebugPage> {

  /// ECRIT TON CODE ICI AMAURY
  void my_tests(){

  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Welcome to Flutter',
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Welcome to Flutter'),
        ),
        body: Center(
          child: ElevatedButton(onPressed: (){my_tests();}, child: Text("Test interranking function")),
        ),
      ),
    );
  }
}