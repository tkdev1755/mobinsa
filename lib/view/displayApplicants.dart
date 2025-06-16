import 'package:flutter/material.dart';


class DisplayApplicants extends StatefulWidget {
  const DisplayApplicants({Key? key}) : super(key: key);

  @override
  State<DisplayApplicants> createState() => _DisplayApplicantsState();
}

class _DisplayApplicantsState extends State<DisplayApplicants> {
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