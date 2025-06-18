

import 'package:flutter/material.dart';

import '../model/Choice.dart';
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
  /*void my_tests(){
    Student s = widget.student.first;
    Map<int,List<Choice>> diff_dict = s.diff_interrankings(widget.student);
    for(Student s in widget.student) {
      if(diff_dict.containsKey(s.id) {
        Map<(Student,int),List<Student>> ladder = s.ladder_interrankigs(widget.student);
        for(int i in ladder.keys[1]) {
          print(ladder.keys[0]+"possède un interclassement inférieur à certains élèves"+ladder.values);
        }
      }
      else continue;
    }
  }*/

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
          child: ElevatedButton(onPressed: (){/*my_tests();*/}, child: Text("Test interranking function")),
        ),
      ),
    );
  }
}