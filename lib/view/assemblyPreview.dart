

import 'package:flutter/material.dart';
import 'package:mobinsa/model/Stats.dart';
import 'package:mobinsa/model/Student.dart';
import 'package:mobinsa/model/School.dart';
import 'package:mobinsa/view/uiElements.dart';
import 'package:mobinsa/view/displayApplicants.dart';

class AssemblyPreview extends StatefulWidget {
  List<Student> students;
  List<School> schools;
  AssemblyPreview({Key? key, required this.students, required this.schools}) : super(key: key);

  @override
  State<AssemblyPreview> createState() => _AssemblyPreviewState();
}

class _AssemblyPreviewState extends State<AssemblyPreview> {

  Stats stats = Stats();
  @override
  List<(double, Student)> sort_student(List<Student> lst_student) {
    List<(double, Student)> my_list = [];
    for (var el in lst_student) {
      double ranking = el.choices[1]!.interranking;
      my_list.add((ranking, el));
    }
    my_list.sort((a, b) => b.$1.compareTo(a.$1));
    return my_list;
  }

  Map<School,List<int>> concerned_school = {};
  void initState() {
    List<Student> cpy_students_list = widget.students;
    for (var st in cpy_students_list){
      for(var c in st.choices.values){
        if (!(concerned_school.containsKey(c.school))) {
          concerned_school[c.school] = [c.school.b_slots, c.school.m_slots];
        }
      }
    }

    print(concerned_school);
    List<(double, Student)> lst = sort_student(cpy_students_list);
    for (var element in lst) {
      Student student = element.$2;
      print(student.choices);
      int nb_voeux_student = student.choices.keys.reduce((a, b) => a > b ? a : b);
      print(nb_voeux_student);
      print("\n");
      print(concerned_school[student.choices[1]!.school]);
      if (student.year == 2) {

        if (concerned_school[student.choices[1]!.school]![0] > 0) {
          concerned_school[student.choices[1]!.school]?[0] --;
          stats.add_c1();
        }
        else if (nb_voeux_student >= 2 &&
            concerned_school[student.choices[2]!.school]![0] > 0) {
          concerned_school[student.choices[2]!.school]?[0] --;
          stats.add_c2();
        }
        else if (nb_voeux_student == 3 &&
            concerned_school[student.choices[3]!.school]![0] > 0) {
          concerned_school[student.choices[3]!.school]?[0] --;
          stats.add_c3();
        }
        else {
          stats.add_r();
        }
      }
      else if (student.year > 2) {
        if (concerned_school[student.choices[1]!.school]![1] > 0) {
          concerned_school[student.choices[1]!.school]?[1] --;
          stats.add_c1();
        }
        else if (nb_voeux_student >= 2 &&
            concerned_school[student.choices[2]!.school]![0] > 0) {
          concerned_school[student.choices[2]!.school]?[1] --;
          stats.add_c2();
        }
        else if (nb_voeux_student == 3 &&
            concerned_school[student.choices[3]!.school]![0] > 0) {
          concerned_school[student.choices[3]!.school]?[1] --;
          stats.add_c3();
        }
        else {
          stats.add_r();
        }
      }
    }

    print(stats);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Welcome to Flutter',
      home: Scaffold(
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Après la première passe",style: UiText().mediumText,),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Column(
                  children: [
                    Text("${stats.choice1}",style: UiText(weight: FontWeight.w700).vvLargeText),
                    SizedBox(
                        child: Text("Etudiants ont eu leur premier voeu",style: UiText().mediumText)),
                  ],
                ),
                Padding(padding: EdgeInsets.only(right: 40)),


              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children:[
                Column(
                  children: [
                    Text("${stats.choice2 }",style: UiText(weight: FontWeight.w700).vvLargeText),
                    Text("Etudiants ont eu leur 2nd voeu",style: UiText().mediumText),
                  ],
                ),
                Padding(padding: EdgeInsets.only(right: 40)),
                Column(
                  children: [
                    Text("${ stats.choice3}",style: UiText(weight: FontWeight.w700).vvLargeText),
                    Text("Etudiants ont eu leur 3eme voeu",style: UiText().mediumText),
                  ],
                )
              ]
            ),
            Padding(padding: EdgeInsets.only(bottom: 20)),
            Column(
              children: [
                Text("${stats.rejected}",style: UiText(color: UiColors.alertRed2,weight: FontWeight.w700).vvLargeText,),
                Text("Étudiants n'ont pas eu de voeux",style: UiText().mediumText,),
              ],
            ),
            Padding(padding: EdgeInsets.only(bottom: 20)),
            ElevatedButton(onPressed: (){
               Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => DisplayApplicants(schools: widget.schools, students: widget.students)),);
            }, child: Text("Continuer")),
          ],
        )
      ),
    );
  }
}