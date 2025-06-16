

import 'package:flutter/material.dart';


class AssemblyPreview extends StatefulWidget {
  const AssemblyPreview({Key? key}) : super(key: key);

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