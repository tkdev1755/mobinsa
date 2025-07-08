

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
  /// Fonction affectant les voeux de manière naïve pour les étudiants
  ///
  /// Prends une liste d'étudiants et ne retourne rien
  ///
  void giveAttribution(List<Student> allStudents){
    // Ces 3 variables permettent de retenir le nombre de personnes qui ont eu leur premier voeu, second voeu etc...
    int numberOfFirstWishes = 0;
    int numberOfSecondWishes = 0;
    int numberOfThirdWishes = 0;

    // Je converti la liste d'étudiants en une liste de tuple dont le type est un entier et un choix
    // Ce tuple représente le couple numéro de voeu + voeu
    // Cela facilite grandement le traitement car on peut ensuite simplement trier les voeux par ordre décroissant et ne pas se soucier de cas extrêmes
    // car tous les voeux qui auraient pu avoir un meilleur classement ont forcément été traités
    List<(int,Choice)> allChoices = allStudents.expand((e) => e.choices.entries.map((entry) => (entry.key, entry.value))).toList();

    //allChoices.sort((a,b) => a.$1.compareTo(b.$1));

    // Tri de tout les voeux selon l'ordre décroissant
    allChoices.sort((a,b) => b.$2.interranking.compareTo(a.$2.interranking));

    // Itération sur chaque élément de la liste
    for ((int,Choice) choice in allChoices){
      // Si l'étudiant n'a pas de voeu d'accepté et que le voeux sur lequel j'itère n'est pas déjà dans la liste des voeux refusés, je continue le traitement
      if (choice.$2.student.accepted == null && !(choice.$2.student.refused.contains(choice.$2))){

        // Si le voeu n'est pas le premier voeu de l'étudiant, mais qu'il apparait avant un voeu préféré de celui-ci dans la liste de voeux triée

        if (choice.$1 > 1 && choice.$2.student.accepted == null){
          //print("----- VOEU DIFFERENT DE 1 -> ${choice.$1} -----");
          Student currentStudent = choice.$2.student;
          List<(int,Choice)>  betterChoices = allChoices.where((e) => e.$1 < choice.$1 && e.$2.student.id == choice.$2.student.id).toList();
          betterChoices.sort((a,b) => a.$1.compareTo(b.$1));
          betterChoices = betterChoices.where((e) => !currentStudent.refused.contains(e.$2)).toList();
          //print(betterChoices);
          if (betterChoices.isNotEmpty){
            if (betterChoices.first.$2.isChoiceValid()){
              //print("Ce voeu est possible, donc le donne");
              betterChoices.first.$2.accepted(choice.$2.student);
              betterChoices.first.$2.post_comment = "Places restantes dans cet établissement ${choice.$2.school.remaining_slots} - Voeu dont l'attribution à été forcé";
              switch (betterChoices.first.$1){
                case 1:
                //print("Voeu 1 accepté");
                  numberOfFirstWishes++;
                  break;
                case 2:
                //print("Voeu 2 accepté");
                  numberOfSecondWishes++;
                  break;
                case 3:
                //print("Voeu 3 accepté");
                  numberOfThirdWishes++;
                  break;
              }
            }
          }
        }
        // Si le voeu peut être accepté, en dehors de toute considération pour l'interclassement, on le donne. Voir isChoiceValid pour les conditions
        if (choice.$2.isChoiceValid() && choice.$2.student.accepted == null){
          // On "donne" le voeu en utilisant la méthode accepted de la classe Choice pour actualiser tout les acteurs concernés (écoles, étudiants...)
          // Voir Choice.accepted pour plus de détails
          //print("Le voeu : ${choice.$2.school.name} de ${choice.$2.student.name} a été donné");
          choice.$2.accepted(choice.$2.student);
          choice.$2.post_comment = "Places restantes dans cet établissement ${choice.$2.school.remaining_slots}";
          // On vérifie le rang du voeux qui vient d'être attribué pour mettre à jour les statistiques
          switch (choice.$1){
            case 1:
              //print("Voeu 1 accepté");
              numberOfFirstWishes++;
              break;
            case 2:
              //print("Voeu 2 accepté");
              numberOfSecondWishes++;
              break;
            case 3:
              //print("Voeu 3 accepté");
              numberOfThirdWishes++;
              break;
          }
        }
        else if (choice.$2.student.accepted == null){
          //print("Le voeu ${choice.$2.school.name} de ${choice.$2.student.name} ne peut être accepté, refus");
          choice.$2.post_comment = "Raison du refus : ${choice.$2.getRejectionInformation()} ";
          // On refuse ce voeux pour marquer la différence entre un voeu qui n'as pas été traité et celui qu'on ne pouvait pas donner
          choice.$2.refuse();
        }
      }
      // Si l'attribut accepted est initialisée (non nul), l'étudiant associé au voeu courant n'a pas besoin d'être traité
      else if (choice.$2.student.accepted != null){
        //print("L'étudiant ${choice.$2.student.name} à déjà un de ses voeux");
      }
      // il est possible que ces 2 clauses peuvent être réunies en une seule
      print("Résumé :  le voeu n°${choice.$1} de ${choice.$2.student.name} (${choice.$2.school.name}) à été "
          "${choice.$2.student.accepted == choice.$2 ? "accepté" : choice.$2.student.refused.contains(choice.$2) ? "refusé ": "non traité"} \n"
      );
    }

    // Print de débug pour s'assurer du bon fonctionnement de l'algorithme
    print("------- Résumé : Sur ${allStudents.length} étudiants, on a -------\n ${numberOfFirstWishes} étudiants ont eu leur premier voeu, \n ${numberOfSecondWishes} étudiants ont eu leur second voeu \n ${numberOfThirdWishes} étudiants ont eu leur 3ème voeu \n ${(allStudents.length-(numberOfFirstWishes+numberOfThirdWishes+numberOfSecondWishes))}  étudiants qui ont eu aucun voeu");

    Map<int, List<Choice>>  sortedChoicesBySchool = {};
    for ((int,Choice) choice in allChoices){
      if (!sortedChoicesBySchool.containsKey(choice.$2.school.id)){
        sortedChoicesBySchool[choice.$2.school.id] = [];
      }
      sortedChoicesBySchool[choice.$2.school.id]!.add(choice.$2);
    }
    schoolsStats = sortedChoicesBySchool.map((k,v) => MapEntry(k, (v.length, widget.schools.firstWhere((e) => e.id == k).available_slots)));

    // Affectation des statistiques d'attribution des voeux au anciennes variables utilisée pour l'affichage, afin de ne pas casser le code écrit par mes camarades
    stats.choice1 = numberOfFirstWishes;
    stats.choice2 = numberOfSecondWishes;
    stats.choice3 = numberOfThirdWishes;
    // On prends le nombre d'étudiants total et on y soustrait le nombre de voeux attribués au total
    stats.rejected = (allStudents.length-(numberOfFirstWishes+numberOfSecondWishes+numberOfThirdWishes));
  }

  Stats stats = Stats();
  Map<int, (int,int)> schoolsStats = {};
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

  getMostRequestedSchool(){
    List<MapEntry> schoolsInfoList = schoolsStats.entries.toList();
    schoolsInfoList.sort((a,b) => (b.value.$1/b.value.$2).compareTo(a.value.$1/a.value.$2));
    //print(schoolsInfoList);
    MapEntry mostRequestedSchool = schoolsInfoList.first;
    return (widget.schools.firstWhere((e) => e.id == mostRequestedSchool.key), mostRequestedSchool.value);
  }

  List<MapEntry<int,(int,int)>> getNumberOfOverflows(){
    List<MapEntry<int, (int,int)>> schoolsInfoList = schoolsStats.entries.toList();
    return schoolsInfoList.where((e) => e.value.$1 > e.value.$2).toList();
  }

  List<MapEntry<int,(int,int)>> getEmptyDestinations(){
    return widget.schools.where((e) => !schoolsStats.keys.contains(e.id)).map((e) => MapEntry(e.id, (0, e.available_slots))).toList();
  }
  @override


  void initState() {

    // On copie les listes pour éviter que le traitement qu'on fait dessus se transmette dans les pages suivantes
    List<School> cpySchoolList = widget.schools.map((e) => e.clone()).toList();
    List<Student> cpyStudentsList = widget.students.map((e) => e.clone(cpySchoolList)).toList();

    // On exécute la fonction qui s'occupe d'affecter les voeux de manière naïvve
    giveAttribution(cpyStudentsList);
    print("Existe-t-il des étudiants sans aucun voeu accepté et aucun voeu refusé ? : ${cpyStudentsList.where((e) => e.accepted == null && e.refused.isEmpty).isNotEmpty}");
    print("Existe-t-il des écoles où des places subsistent ? : ${cpySchoolList.where((e) => e.remaining_slots > 0).isNotEmpty}");
    List<String> incoherentChoices = [];
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
    (School, (int,int)) mostRequestedSchool = getMostRequestedSchool();
    List<MapEntry<int, (int,int)>> overflowedSchools = getNumberOfOverflows();
    List<MapEntry<int, (int,int)>> emptySchools = getEmptyDestinations();
    return MaterialApp(
      title: 'Welcome to Flutter',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.red),
        textTheme: GoogleFonts.montserratTextTheme()
      ),
      home: Scaffold(

        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Après la première passe",style: UiText().mediumText,),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("${stats.choice1}",style: UiText(weight: FontWeight.w700).vvLargeText),
                        Padding(padding: EdgeInsets.only(right: 30)),
                        Text("Étudiants ont eu leur premier voeu",style: UiText().mediumText),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children:[
                        Text("${stats.choice2 }",style: UiText(weight: FontWeight.w700).vvLargeText),
                        Padding(padding: EdgeInsets.only(right: 30)),
                        Text("Étudiants ont eu leur 2nd voeu",style: UiText().mediumText),
                        Padding(padding: EdgeInsets.only(right: 40)),
                      ]
                    ),
                    Row(
                      children: [
                        Text("${ stats.choice3}",style: UiText(weight: FontWeight.w700).vvLargeText),
                        Padding(padding: EdgeInsets.only(right: 30)),
                        Text("Étudiants ont eu leur 3eme voeu",style: UiText().mediumText),
                      ],
                    ),
                    Padding(padding: EdgeInsets.only(bottom: 20)),
                    Row(
                      children: [
                        Text("${stats.rejected}",style: UiText(color: UiColors.alertRed2,weight: FontWeight.w700).vvLargeText,),
                        Padding(padding: EdgeInsets.only(right: 30)),
                        Text("Étudiants n'ont pas eu de voeux",style: UiText().mediumText,),
                      ],
                    ),
                  ],
                ),
                Padding(padding: EdgeInsets.only(right: 40)),
                Container(
                  width: MediaQuery.sizeOf(context).width*0.3,
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: UiShapes().frameRadius
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("L'école la plus demandée est ",style: UiText().nText,),
                      UiShapes.bPadding(10),
                      SizedBox(
                        child: Row(
                          children: [
                            Expanded(child: Text(mostRequestedSchool.$1.name,style: UiText(weight: FontWeight.w600).mediumText,)),
                            IconButton(onPressed: (){
                              showDialog(context: context, builder: (BuildContext context){
                                return mostDemandedSchoolDialog(mostRequestedSchool.$1, widget.students);
                              });
                            }, icon: Icon(PhosphorIcons.info()))
                          ],
                        ),
                      ),
                      UiShapes.bPadding(5),
                      Text("Pays : ${mostRequestedSchool.$1.country} - ${mostRequestedSchool.$1.program}",style: UiText().smallText,),
                      UiShapes.bPadding(20),
                      RichText(text: TextSpan(
                        children: [
                          TextSpan(
                            style: UiText(color: Colors.red.toARGB32(), weight: FontWeight.w600).mediumText,
                            text: "${mostRequestedSchool.$2.$1} "
                          ),
                          TextSpan(
                            style: UiText(color: UiColors.black).mediumText,
                            text: "voeux pour "
                          ),
                          TextSpan(
                            style: UiText(color: UiColors.black, weight: FontWeight.w600).mediumText,
                            text: '${mostRequestedSchool.$2.$2} '
                          ),
                          TextSpan(
                            style: UiText(color: UiColors.black).mediumText,
                            text: "places disponibles"
                          )
                        ]
                      )),
                      UiShapes.bPadding(10),
                      Divider(),
                      UiShapes.bPadding(5),
                      Text("Nombre de destinations ayant plus de voeux que de places disponibles", style: UiText().nText,),
                      UiShapes.bPadding(10),
                      Row(
                        children: [
                          Expanded(
                            child: RichText(
                              text: TextSpan(
                                children:
                                  [
                                    TextSpan(
                                      style: UiText(weight: FontWeight.w700, color: Colors.red.toARGB32()).mediumText,
                                      text: "${overflowedSchools.length}"
                                    ),
                                    TextSpan(
                                        style: UiText(weight : FontWeight.w500).mediumText,
                                        text: " destinations sur ${widget.schools.length}"
                                    ),
                                  ]
                              ),
                            ),
                          ),
                          IconButton(onPressed: (){
                            showDialog(context: context, builder: (BuildContext context){
                              return overflowedSchoolDialog(overflowedSchools, widget.schools);
                            });
                          }, icon: Icon(PhosphorIcons.info()))
                        ],
                      ),
                      UiShapes.bPadding(10),
                      Divider(),
                      UiShapes.bPadding(5),
                      Text("Nombre de destinations sans aucun voeu", style: UiText().nText,),
                      UiShapes.bPadding(10),
                      Row(
                        children: [
                          Expanded(child: Text("${emptySchools.length} sur ${widget.schools.length} établissements",style: UiText(weight: FontWeight.w500).mediumText,)),
                          IconButton(onPressed: (){
                            showDialog(context: context, builder: (BuildContext context){
                              return emptySchoolsDialog(emptySchools, widget.schools);
                            });
                          }, icon: Icon(PhosphorIcons.info()))
                        ],
                      )
                    ],
                  ),
                ),
                Spacer(),
              ],
            ),
            Padding(padding: EdgeInsets.only(bottom: 20)),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                    onPressed: (){
                      Navigator.pop(context);
                    },
                    icon: Icon(PhosphorIcons.caretLeft()),
                  tooltip: "Revenir à l'accueil",
                ),
                Padding(padding: EdgeInsets.only(right: 10),),
                ElevatedButton(
                    onPressed: (){
                   Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => DisplayApplicants(schools: widget.schools, students: widget.students)),);
                }, child: Text("Continuer", style: GoogleFonts.montserrat(fontWeight: FontWeight.w500 ),)),
                Padding(padding: EdgeInsets.only(right: 10),),
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
                  tooltip: "Exporter vers excel",
                )
              ],
            ),
          ],
        )
      ),
    );
  }

  /// Méthode pour faire le traitement de la donnée nécessaire pour le Dialog mostDemandedSchoolDialog
  ///
  /// Retourne la répartition en pourcentage de chacune spécialité sur une école en particulier
  List<(String,double)> getSpecializationRepartition(School concernedSchool, List<Student> students){
    List<Student> concernedStudents = students.where((e) => e.choices.entries.where((e) => e.value.school == concernedSchool).isNotEmpty).toList();
    List<(String,double)> specializationRepartition = [];
    for (var specialization in Student.specializationList){
      double percentage = (concernedStudents.where((e) => e.specialization == specialization).length / concernedStudents.length)*100;
      if (percentage > 0){
        specializationRepartition.add((specialization,percentage));
      }
    }

    specializationRepartition.sort((a,b) => b.$2.compareTo(a.$2));
    return specializationRepartition;
  }
  Widget mostDemandedSchoolDialog(School concernedSchool, List<Student> students){
    List<(String, double)> specializationRepartition = getSpecializationRepartition(concernedSchool, students);
    return Dialog(
      child: Container(
          padding: EdgeInsets.all(20),
          constraints: BoxConstraints(
              maxWidth: 500,
              maxHeight: 350
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Informations complémentaires", style: UiText().mediumText,),
              UiShapes.bPadding(10),
              Text("Cette statistique est basée sur le rapport entre le nombre de voeu total et le nombre de places disponibles", style: UiText(alpha: 150).nsText,),
              UiShapes.bPadding(10),
              Text("Répartition par spécialité des places", style: UiText().nText,),
              UiShapes.bPadding(10),
              SizedBox(
                height: 120,
                child: ListView.builder(
                    itemCount: specializationRepartition.length,
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsets.zero,
                    itemBuilder: (BuildContext context, int index){
                      return Container(
                        padding: EdgeInsets.all(10),
                        margin: EdgeInsets.only(left: 0,right: 10),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: UiShapes().frameRadius,

                        ),
                        child: Center(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "${specializationRepartition[index].$2.toStringAsFixed(1)}% ",style: UiText().largeText,
                              ),
                              Text("de ${specializationRepartition[index].$1}", style: UiText().nText)
                            ],
                          ),
                        ),
                      );
                    }),
              ),
            ],
          )
      ),
    );
  }

  /// Méthode pour traiter la donnée à afficher dans overflowedSchoolDialog
  ///
  /// Retourne une liste triée de destinations dont le nombre de voeux est supérieur au places disponibles
  List<(School, (int,int))> getOverflowedSchoolsName(List<MapEntry<int,(int,int)>> overflowedSchools, List<School> schools){
    List<(School, (int,int))> overflowedSchoolsName  = overflowedSchools.map((e) => (schools.firstWhere((a)=>a.id == e.key),(e.value.$1,e.value.$2))).toList();
    overflowedSchoolsName.sort((a,b) => (b.$2.$1/b.$2.$2).compareTo(a.$2.$1/a.$2.$2));
    return overflowedSchoolsName;
  }
  Widget overflowedSchoolDialog(List<MapEntry<int,(int,int)>> overflowedSchools, List<School> schools){
    List<(School, (int,int))> overflowedSchoolsName = getOverflowedSchoolsName(overflowedSchools, schools);
    return Dialog(
      child: Container(
        padding: EdgeInsets.all(30),
        width: 550,
        height: 400,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Informations complémentaires",style: UiText().mediumText,),
            UiShapes.bPadding(10),
            Text("Voici toutes les destination qui ont plus de voeux que de places disponibles",style: UiText(alpha: 150).nsText,),
            Expanded(
              child: ListView.builder(
                  itemCount: overflowedSchoolsName.length,
                  scrollDirection: Axis.vertical,
                  padding: EdgeInsets.only(top: 10),
                  itemBuilder: (BuildContext context, int index){
                    double percentage = overflowedSchoolsName[index].$2.$1/overflowedSchoolsName[index].$2.$2;
                    Color displayColor = Colors.black;
                    if (percentage > 2.00){
                      displayColor = Colors.red;
                    }
                    else if (percentage > 1.50){
                      displayColor = Colors.orange;
                    }
                    return Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: UiShapes().frameRadius,
                      ),
                      padding: EdgeInsets.all(10),
                      margin: EdgeInsets.only(bottom: 10,top: 0),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment : CrossAxisAlignment.start,
                              children: [
                                Text(overflowedSchoolsName[index].$1.name, style: UiText().nText,),
                                Text("${overflowedSchoolsName[index].$1.program}", style: UiText(alpha: 150).smallText,)
                              ],
                            ),
                          ),
                          Padding(padding: EdgeInsets.only(left: 20)),
                          Text("${overflowedSchoolsName[index].$2.$1} / ${overflowedSchoolsName[index].$2.$2}",style: UiText(color: displayColor.toARGB32()).nText,)
                        ],
                      ),
                    );
                  }),
            ),

          ],
        ),
      ),
    );
  }


  List<School> getEmptySchoolsName(List<MapEntry<int,(int,int)>> emptySchools,List<School> schools){
    return schools.where((e) => !schoolsStats.keys.contains(e.id)).toList();
  }
  Widget emptySchoolsDialog(List<MapEntry<int,(int,int)>> emptySchools, List<School> schools){
    List<School> emptySchoolsName = getEmptySchoolsName(emptySchools, schools);
    return Dialog(
      child: Container(
          padding: EdgeInsets.all(20),
          constraints: BoxConstraints(
              maxWidth: 500,
              maxHeight: 400
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Informations complémentaires", style: UiText().mediumText,),
              UiShapes.bPadding(10),
              Text("Voici toutes les destination qui n'ont aucun voeu", style: UiText(alpha: 150).nsText,),
              UiShapes.bPadding(10),
              Expanded(
                child: ListView.builder(
                    itemCount: emptySchoolsName.length,
                    scrollDirection: Axis.vertical,
                    padding: EdgeInsets.zero,
                    itemBuilder: (BuildContext context, int index){
                      return Card(
                        child: Container(
                          padding: EdgeInsets.all(15),
                          child: Center(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  emptySchoolsName[index].name,style: UiText().nText,
                                ),
                                UiShapes.bPadding(10),
                                Text(emptySchoolsName[index].program, style : UiText(alpha: 100).smallText,)
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
              ),
            ],
          )
      ),
    );
  }
}

