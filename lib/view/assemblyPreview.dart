

import 'package:flutter/material.dart';
import 'package:mobinsa/model/Student.dart';
import 'package:mobinsa/model/School.dart';
import 'package:mobinsa/view/UiElements.dart';
import 'package:mobinsa/view/displayApplicants.dart';

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