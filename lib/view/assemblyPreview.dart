

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

import '../model/Choice.dart';

class AssemblyPreview extends StatefulWidget {
  List<Student> students;
  List<School> schools;
  AssemblyPreview({super.key, required this.students, required this.schools});

  @override
  State<AssemblyPreview> createState() => _AssemblyPreviewState();
}

class _AssemblyPreviewState extends State<AssemblyPreview> {
  /// Fonction Affectant les voeux de manière naïve pour les étudiants
  ///
  /// Prends une liste d'étudiants et ne retourne rien
  void giveAttribution(List<Student> allStudents){
    // Ces 3 variables permettent de retenir le nombre de personnes qui ont eu leur premier voeu, second voeu etc...
    int numberOfFirstWishes = 0;
    int numberOfSecondWishes = 0;
    int numberOfThirdWishes = 0;

    // Je converti la liste d'étudiants en une liste de tuple dont le type est un entier et un choix
    // Ce tuple représente le couple numéro de voeu+ voeu
    // Cela facilite grandement le traitement car on peut ensuite simplement trier les voeux par ordre décroissant et ne pas se soucier de cas extrêmes
    // car tous les voeux qui auraient pu avoir un meilleur classement ont forcément été traités
    List<(int,Choice)> allChoices = allStudents.expand((e) => e.choices.entries.map((entry) => (entry.key, entry.value))).toList();

    // Tri de tout les voeux selon l'ordre décroissant
    allChoices.sort((a,b) => b.$2.interranking.compareTo(a.$2.interranking));

    // Itération sur chaque élément de la liste
    for ((int,Choice) choice in allChoices){
      // Si l'étudiant n'as pas de voeu d'accepté et que le voeux sur lequel j'itère n'est pas déjà dans la liste des voeux refusés, je continue le traitement
      if (choice.$2.student.accepted == null && !(choice.$2.student.refused.contains(choice.$2))){
        // Si le voeu peut être accepté, en dehors de toute considération pour l'interclassement, on le donne. Voir isChoiceValid pour les conditions
        if (choice.$2.isChoiceValid()){

          // On "donne" le voeu en utilisant la méthode accepted de la classe Choice pour actualiser tout les acteurs concernés (écoles, étudiants...)
          // Voir Choice.accepted pour plus de détails
          print("Le voeu : ${choice.$2.school.name} de ${choice.$2.student.name} a été donné");
          choice.$2.accepted(choice.$2.student);
          // On vérifie le rang du voeux qui vient d'être attribué pour mettre à jour les statistiques
          switch (choice.$1){
            case 1:
              print("Voeu 1 accepté");
              numberOfFirstWishes++;
              break;
            case 2:
              print("Voeu 2 accepté");
              numberOfSecondWishes++;
              break;
            case 3:
              print("Voeu 3 accepté");
              numberOfThirdWishes++;
              break;
          }
        }
        else{
          print("Ce voeu ne peut être accepté, refus");
          // On refuse ce voeux pour marquer la différence entre un voeu qui n'as pas été traité et celui qu'on ne pouvait pas donner
          choice.$2.refuse();
        }
      }
      // Si l'attribut accepted est initialisée (non nul), l'étudiant associé au voeu courant n'a pas besoin d'être traité
      else if (choice.$2.student.accepted != null){

        print("L'étudiant ${choice.$2.student.name} à déjà un de ses voeux");
      }
      // il est possible que ces 2 clauses peuvent être réunies en une seule
      else{
        print("None of these options are possible for this choice");
      }
    }
    // Print de débug pour s'assurer du bon fonctionnement de l'algorithme
    print("------- Résumé : Sur ${allStudents.length} étudiants, on a -------\n ${numberOfFirstWishes} ont eu leur premier voeu, \n ${numberOfSecondWishes} ont eu leur second voeu \n ${numberOfThirdWishes} ont eu leur 3ème voeu \n ${(allStudents.length-(numberOfFirstWishes+numberOfThirdWishes+numberOfSecondWishes))}  étudiants qui ont eu aucun voeu");
    // Affectation des statistiques d'attribution des voeux au anciennes variables utilisée pour l'affichage, afin de ne pas casser le code écrit par mes camarades
    stats.choice1 = numberOfFirstWishes;
    stats.choice2 = numberOfSecondWishes;
    stats.choice3 = numberOfThirdWishes;
    // On prends le nombre d'étudiants total et on y soustrait le nombre de voeux attribués au total
    stats.rejected = (allStudents.length-(numberOfFirstWishes+numberOfSecondWishes+numberOfThirdWishes));
  }

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

    // On copie les listes pour éviter que le traitement qu'on fait dessus se transmette dans les pages suivantes
    List<School> cpySchoolList = widget.schools.map((e) => e.clone()).toList();
    List<Student> cpyStudentsList = widget.students.map((e) => e.clone(cpySchoolList)).toList();

    // On exécute la fonction qui s'occupe d'affecter les voeux de manière naïvve
    giveAttribution(cpyStudentsList);

    /*print(getChoicesSummary(cpyStudentsList));*/

    // On copie la liste des voeux actualisée dans cette variable pour refléter l'affectation de voeux sur l'excel exporté
    export_list = cpyStudentsList;

    // Ancien code servant à l'affectation naïve des voeux
    /*for (var st in cpyStudentsList){
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

    //print(lst);*/
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