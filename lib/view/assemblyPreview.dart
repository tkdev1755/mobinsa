

import 'package:flutter/material.dart';
import 'package:mobinsa/model/Stats.dart';
import 'package:mobinsa/model/Student.dart';
import 'package:mobinsa/model/School.dart';
import 'package:mobinsa/view/uiElements.dart';
import 'package:mobinsa/view/displayApplicants.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:mobinsa/model/parser.dart';
import 'package:file_picker/file_picker.dart';

import 'dart:io';

class AssemblyPreview extends StatefulWidget {
  List<Student> students;
  List<School> schools;
  AssemblyPreview({super.key, required this.students, required this.schools});

  @override
  State<AssemblyPreview> createState() => _AssemblyPreviewState();
}

class _AssemblyPreviewState extends State<AssemblyPreview> {

  Stats stats = Stats();
  @override
  List<(double, Student)> sort_student(List<Student> lstStudent) {
    List<(double, Student)> myList = [];
    for (var el in lstStudent) {
      double ranking = el.get_max_rank();
      myList.add((ranking, el));
    }
    myList.sort((a, b) => b.$1.compareTo(a.$1));
    return myList;
  }
  List<Student> export_list = [];
  Map<School,List<int>> concerned_school = {};
  @override
  void initState() {
    List<Student> cpyStudentsList = widget.students.map((e) => e.clone()).toList();
    for (var st in cpyStudentsList){
      for(var c in st.choices.values){
        if (!(concerned_school.containsKey(c.school))) {
          concerned_school[c.school] = [c.school.b_slots, c.school.m_slots];
        }
      }
    }


    //print(concerned_school);
    List<(double, Student)> lst = sort_student(cpyStudentsList);

    print (lst);
    for (var element in lst) {
      Student student = element.$2;
      //print(student.choices);
      int nbVoeuxStudent = student.choices.keys.reduce((a, b) => a > b ? a : b);
      //print(nb_voeux_student);
      //print(concerned_school[student.choices[1]!.school]);
      if (student.year == 2) {

        if (concerned_school[student.choices[1]!.school]![0] > 0 && student.choices[1]!.school.specialization.contains(student.get_next_year())) {
          concerned_school[student.choices[1]!.school]?[0] --;
          student.accepted = student.choices[1];
          export_list.add(student);
          stats.add_c1();
        }
        else if (nbVoeuxStudent >= 2
            && student.choices[2]!.school.specialization.contains(student.get_next_year())
            && concerned_school[student.choices[2]!.school]![0] > 0) {
          concerned_school[student.choices[2]!.school]?[0] --;
          student.accepted = student.choices[2];
          student.refused.add(student.choices[1]!);
          export_list.add(student);
          stats.add_c2();
        }
        else if (nbVoeuxStudent == 3
            && student.choices[3]!.school.specialization.contains(student.get_next_year())
            && concerned_school[student.choices[3]!.school]![0] > 0) {
          concerned_school[student.choices[3]!.school]?[0] --;
          student.accepted = student.choices[3];
          student.refused.add(student.choices[1]!);
          student.refused.add(student.choices[2]!);
          export_list.add(student);
          stats.add_c3();
        }
        else {
          stats.add_r();
          student.refused.add(student.choices[1]!);
          if (nbVoeuxStudent >= 2){
            student.refused.add(student.choices[2]!);}
          if (nbVoeuxStudent == 3 ){
            student.refused.add(student.choices[3]!);
          }
          export_list.add(student);
        }
      }
      else if (student.year > 2) {
        if (concerned_school[student.choices[1]!.school]![1] > 0
            && student.choices[1]!.school.specialization.contains(student.get_next_year())
        ) {
          concerned_school[student.choices[1]!.school]?[1] --;
          student.accepted = student.choices[1];
          export_list.add(student);
          stats.add_c1();
        }
        else if (nbVoeuxStudent >= 2
            && student.choices[2]!.school.specialization.contains(student.get_next_year())
            && concerned_school[student.choices[2]!.school]![1] > 0) {
          concerned_school[student.choices[2]!.school]?[1] --;
          student.accepted = student.choices[2];
          student.refused.add(student.choices[1]!);
          export_list.add(student);
          stats.add_c2();
        }
        else if (nbVoeuxStudent == 3
            && student.choices[3]!.school.specialization.contains(student.get_next_year())
            && concerned_school[student.choices[3]!.school]![1] > 0) {
          concerned_school[student.choices[3]!.school]?[1] --;
          student.accepted = student.choices[3];
          student.refused.add(student.choices[1]!);
          student.refused.add(student.choices[2]!);
          export_list.add(student);
          stats.add_c3();
        }
        else {
          stats.add_r();
          student.refused.add(student.choices[1]!);
          if (nbVoeuxStudent >= 2){
            student.refused.add(student.choices[2]!);}
          if (nbVoeuxStudent == 3 ) {
            student.refused.add(student.choices[3]!);
          }
          export_list.add(student);
        }
      }
    }

    //print(stats);

    //print(lst);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Welcome to Flutter',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.red),
      ),
      home: Scaffold(
        appBar: AppBar(
          actions: [
            IconButton(
              icon: Icon(
                PhosphorIcons.export(PhosphorIconsStyle.regular),
                size: 32.0,
                ),
              onPressed: () async {
                List<int> bytes = SheetParser.exportResult(export_list, widget.schools);
                String? path = await FilePicker.platform.saveFile(
                    fileName: Platform.isMacOS ? "Preview_JURY_MOBILITE_${DateTime.now().year}" : "Preview_JURY_MOBILITE_${DateTime.now().year}.xlsx",
                    type: FileType.custom,
                    allowedExtensions: ["xlsx"]
                );
                if (path != null){
                  print("Now saving the excel file");
                  SheetParser.saveExcelToDisk(path, bytes);
                }
              },
              tooltip: "Exporter vers excel",)
                  ],
                ),
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