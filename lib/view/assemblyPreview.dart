

import 'package:flutter/material.dart';
import 'package:mobinsa/model/Student.dart';
import 'package:mobinsa/model/School.dart';

class AssemblyPreview extends StatefulWidget {
  List<Student> students;
  List<School> schools;
  AssemblyPreview({Key? key, required this.students, required this.schools}) : super(key: key);

  @override
  State<AssemblyPreview> createState() => _AssemblyPreviewState();
}

class _AssemblyPreviewState extends State<AssemblyPreview> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Welcome to Flutter',
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Welcome to Flutter'),
        ),
        body: const Center(
          child: Text('Hello World'),
        ),
      ),
    );
  }
}