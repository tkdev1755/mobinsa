

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

  List<(double, Student)> sort_student(List<Student> lst_student) {
    List<(double, Student)> my_list = [];
    for (var el in lst_student) {
      double ranking = el.choices[1]!.interranking;
      my_list.add((ranking, el));
    }
    my_list.sort((a, b) => b.$1.compareTo(a.$1));
    return my_list;
  }

// Je vais prendre interranking max comme interranking de l'élève au global

  void attribution(List<(double, Student)> lst_student, Stats mes_stats) {
    // Create a copy to iterate over, as we'll be modifying the original list.
    List<(double, Student)> lst_student_copy = List.from(lst_student);

    for (var el in lst_student_copy) {
      Student student = el.$2;
      if (student.year == 2) {
          if (student.choices.containsKey(1) &&
              student.choices[1]!.school.b_slots > 0) {
            student.choices[1]!.school.reduce_slots(student);
            lst_student.removeWhere((e) => e.$2.id == student.id);
            mes_stats.add_c1();
          } else if (student.choices.containsKey(2) &&
              student.choices[1]!.school.b_slots > 0) {
            student.choices[2]!.school.reduce_slots(student);
            lst_student.removeWhere((e) => e.$2.id == student.id);
            mes_stats.add_c2();
          } else if (student.choices.containsKey(3) &&
              student.choices[1]!.school.b_slots > 0) {
            student.choices[3]!.school.reduce_slots(student);
            lst_student.removeWhere((e) => e.$2.id == student.id);
            mes_stats.add_c3();
          } else {
            lst_student.removeWhere((e) => e.$2.id == student.id);
            mes_stats.add_r();
          }
      }
      else {
          if (student.choices.containsKey(1) &&
              student.choices[1]!.school.m_slots > 0) {
            student.choices[1]!.school.reduce_slots(student);
            lst_student.removeWhere((e) => e.$2.id == student.id);
            mes_stats.add_c1();
          } else if (student.choices.containsKey(2) &&
              student.choices[1]!.school.m_slots > 0) {
            student.choices[2]!.school.reduce_slots(student);
            lst_student.removeWhere((e) => e.$2.id == student.id);
            mes_stats.add_c2();
          } else if (student.choices.containsKey(3) &&
              student.choices[1]!.school.m_slots > 0) {
            student.choices[3]!.school.reduce_slots(student);
            lst_student.removeWhere((e) => e.$2.id == student.id);
            mes_stats.add_c3();
          } else {
            lst_student.removeWhere((e) => e.$2.id == student.id);
            mes_stats.add_r();
          }
      }
    }
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
                    Text("20",style: UiText(weight: FontWeight.w700).vvLargeText),
                    SizedBox(
                        child: Text("Etudiants ont eu leur premier voeu",style: UiText().mediumText)),
                  ],
                ),
                Padding(padding: EdgeInsets.only(right: 40)),
                Column(
                  children: [
                    Text("20",style: UiText(weight: FontWeight.w700).vvLargeText),
                    Text("Etudiants ont eu leur 2nd/3eme voeu",style: UiText().mediumText),
                  ],
                )

              ],
            ),
            Padding(padding: EdgeInsets.only(bottom: 20)),
            Column(
              children: [
                Text("5",style: UiText(color: UiColors.alertRed2,weight: FontWeight.w700).vvLargeText,),
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