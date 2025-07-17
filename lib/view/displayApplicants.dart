import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobinsa/model/Choice.dart';
import 'package:mobinsa/model/Student.dart';
import 'package:mobinsa/model/parser.dart';
import 'package:mobinsa/model/sessionStorage.dart';
import 'package:mobinsa/view/uiElements.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../model/School.dart';
import 'dart:io';


/*


  16/06/2025@tahakhetib : J'ai apporté les modification suivantes
    - Ajouté les boutons accepter et refuser dans le choiceCard
    - Modifié le widget dans la liste de voeux pour le mettre à jour vers choice card
    - Ajouté l'export du fichier excel
 */
class DisplayApplicants extends StatefulWidget {
  List<School> schools;
  List<Student> students;
  (String,String)? loadedSave;
  DisplayApplicants({super.key, required this.schools, required this.students, this.loadedSave});

  @override
  State<DisplayApplicants> createState() => _DisplayApplicantsState();
}

class _DisplayApplicantsState extends State<DisplayApplicants> with TickerProviderStateMixin {

  Student? selectedStudent;
  Map<int, bool?> schoolChoices = {}; // null = pas de choix, true = accepté, false = refusé
  Map<int, bool> showCancelButton = {}; // true = afficher le bouton annuler, false = afficher les boutons accepter/refuser
  int currentStudentIndex = -1;
  List<bool> expandedStudentsChoice = [false,false,false];
  Color disabledColor = Colors.grey[100]!;
  String comment = "";
  bool hasSaved = false;
  String? currentSaveName;
  bool _showSaveMessage = false;
  Color interrankingColor(int index){
    if(index!=0){
      if(widget.students[index].get_min_rank()>widget.students[index-1].get_min_rank()){
        return Colors.red;
      }
      if(widget.students[index].get_min_rank()==widget.students[index-1].get_min_rank()){
        return Colors.orange;
      }
    }
    if(index!=widget.students.length-1){
      if(widget.students[index].get_min_rank()<widget.students[index+1].get_min_rank()){
        return Colors.red;
      }
      if(widget.students[index].get_min_rank()==widget.students[index+1].get_min_rank()){
        return Colors.orange;
      }
    }
    if(currentStudentIndex==index){
      return Colors.blue[900] ?? Colors.blue;
    }
    return Colors.black;
  }

  // Execute gtcode on startup of the page
  @override
  void initState() {
    // TODO: implement initState
    if (widget.loadedSave != null){
      hasSaved = true;
      currentSaveName = widget.loadedSave!.$2;
    }

    super.initState();
  }
  
  getAutoRejectionComment(Student currentStudent){
    Map<int, List<bool>> rejectionReasons = currentStudent.choices.map((k,v) => MapEntry(k, v.getRejectionReasons()));
    rejectionReasons.removeWhere((k,v) => currentStudent.refused.contains(currentStudent.choices[k]));
    print("rejectionReasonlength ${rejectionReasons.length}");

    // On compte le nombre de voeux refusé automatiquement pour cause d'une mauvaise spécialisation
    int numberOfBadSpecialization = 0;
    // on compte le nombre de voeux refusés automatiquement pour cause d'un manque de place sur le niveau de l'élève
    int numberOfNoMoreSlots = 0;
    for (var value in rejectionReasons.values){
      // Si la valeur de la liste à l'index 0 est vraie, l'étudiant a la spécialisation nécessaire, selon la fonction Choice().getRejectionReasons
      numberOfBadSpecialization = numberOfBadSpecialization + (value[0] ? 0:1);
      // Si la valeur de la liste à l'index 1 est vraie, l'école à encore des places
      numberOfNoMoreSlots = numberOfNoMoreSlots + (value[1] ? 0:1);
    }
    final String numberOfSlotsComment = numberOfNoMoreSlots == 0 ? "" : "- ${numberOfNoMoreSlots == rejectionReasons.length ? "Tous ses voeux restants n'ont" : "$numberOfNoMoreSlots de ses voeux restants n'ont"} plus de places";
    final String numberOfBadSpecComment = numberOfBadSpecialization == 0 ? "" : "${numberOfNoMoreSlots != 0 ? "\n" : ""}" "- ${numberOfBadSpecialization == rejectionReasons.length ? "Tous ses voeux restants" : "$numberOfBadSpecialization de ses voeux restants"} ne prennent pas de ${currentStudent.get_next_year()}";
    print("Auto generated comment -> " "${numberOfSlotsComment + numberOfBadSpecComment}");
    return numberOfSlotsComment + numberOfBadSpecComment;
  }
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.red),
        textTheme: GoogleFonts.montserratTextTheme()
      ),
      home: Scaffold(
        appBar: AppBar(
          title: RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: "Mob'",
                  style: UiText(matColor: Colors.black, weight: FontWeight.bold).mLargeText
                ),
                TextSpan(
                  text: "INSA",
                  style: UiText(matColor: Colors.red).mLargeText
                ),
              ],
            ),
          ),
          
          actions: [
            AnimatedOpacity(
              opacity: _showSaveMessage ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: UiShapes().frameRadius,
                ),
                child: Text(
                  "Fichier enregistré !",
                  style: UiText(color: UiColors.white).smallText,
                ),
              ),
            ),
            Padding(padding: EdgeInsets.only(left: 10)),
            IconButton(onPressed: () async {
              String savePath = "";
              String saveName = "";
              try {
                if (hasSaved && currentSaveName != null){
                  saveName = currentSaveName!;
                }
                else{
                  saveName = await SessionStorage.getSaveName();
                  currentSaveName = saveName;
                  hasSaved = true;
                }
                savePath = await SessionStorage.askForSavePath(saveName);
              } catch (e, s) {
                print("$s , $e -> the directory is null ");
              }
              Map<String, dynamic> serializedData = {};
              
              try {
                serializedData = await SessionStorage.serializeData(widget.students, widget.schools);
              }
              catch (e,s){
                print("$s , $e -> There was a problem while serializing the data");
              }
              
              try{
                SessionStorage.saveData(serializedData, savePath);
              }
              catch(e,s){
                print("$s , $e -> There was a problem while writing the data to disk");
              }
              setState(() {
                _showSaveMessage = true;
              });
              Future.delayed(const Duration(seconds: 2), () {
                if (mounted) {
                  setState(() {
                    _showSaveMessage = false;
                  });
                }
              });
              
            }, icon: Icon(PhosphorIcons.floppyDisk(PhosphorIconsStyle.regular)), tooltip: "Sauvegarder cette session",),
            IconButton(
              icon: Icon(
                PhosphorIcons.export(PhosphorIconsStyle.regular),
                size: 32.0,
              ),
              onPressed: () async {
                List<int> bytes = SheetParser.exportResult(widget.students, widget.schools);
                String? path = await FilePicker.platform.saveFile(
                  fileName: Platform.isMacOS ? "CR_JURY_MOBILITE_${DateTime.now().year}" : "CR_JURY_MOBILITE_${DateTime.now().year}.xlsx",
                  type: FileType.custom,
                  allowedExtensions: ["xlsx"]
                );
                if (path != null){
                  print("Now saving the excel file");
                  SheetParser.saveExcelToDisk(path, bytes);
                }
                else{
                  // TODO - Ajouter une gestion des erreurs
                }
                // TODO: Exporter en excel
              },
              tooltip: "Exporter vers excel",
            ),

            IconButton(
              icon: Icon(PhosphorIcons.house(PhosphorIconsStyle.regular), size: 32.0),
              onPressed: () => {
                widget.schools.clear(),
                widget.students.clear,
                Navigator.pop(
                  context,
                ),
                Navigator.pop(
                  context,
                )
              },
              tooltip: "Revenir à la page d'accueil",
            ),
          ],
          backgroundColor: disabledColor,
        ),
        body: Row(
          children: [
            // Sidebar (20% de la largeur)
            Container(
              width: MediaQuery.of(context).size.width * 0.2,
              decoration: BoxDecoration(
                color: const Color(0xFFf5f6fa), // Couleur douce
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withAlpha((0.15 * 255).toInt()),
                    spreadRadius: 2,
                    blurRadius: 8,
                    offset: const Offset(2, 0),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: ListView.builder(
                  itemCount: widget.students.length,
                  itemBuilder: (context, index) {
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12.0,left: 5,right: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: currentStudentIndex == index
                              ? Colors.blueAccent
                              : Colors.grey[300]!,
                          width: 2,
                        ),
                      ),
                      elevation: currentStudentIndex == index ? 8 : 2,
                      color: currentStudentIndex == index
                          ? const Color.fromARGB(255, 120, 151, 211)
                          : (widget.students[index].accepted != null
                              ? const Color.fromARGB(255, 134, 223, 137)
                              : widget.students[index].refused.length == widget.students[index].choices.length
                                  ? const Color.fromARGB(255, 213, 62, 35)
                                  : widget.students[index].hasNoChoiceLeft() ? Colors.orange.shade200: Colors.white),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: (){
                          {
                            setState(() {
                              selectedStudent = widget.students[index];
                              currentStudentIndex = index;
                              schoolChoices.clear();
                              expandedStudentsChoice = List.generate(
                                  widget.students[index].choices.values.toList().length,
                                      (_) => false
                              );
                              showCancelButton.clear();
                              widget.students[index].choices.forEach((key, choice) {
                                showCancelButton[key] = (choice.student.accepted == choice) ||
                                    choice.student.refused.contains(choice);

                                if (choice.student.accepted == choice) {
                                  schoolChoices[key] = true;
                                } else if (choice.student.refused.contains(choice)) {
                                  schoolChoices[key] = false;
                                }
                              });
                            });
                          }
                        },
                        child: ListTile(
                          title: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  widget.students[index].name,
                                  style: GoogleFonts.montserrat(textStyle : TextStyle(
                                    fontSize: 14,
                                    color: currentStudentIndex == index
                                        ? const Color.fromARGB(255, 242, 244, 246)
                                        : Colors.black,
                                    fontWeight: currentStudentIndex == index ? FontWeight.bold : FontWeight.normal,
                                  )),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Padding(padding: EdgeInsets.only(right: 10)),
                              Text(
                                widget.students[index].get_max_rank().toStringAsFixed(2),
                                style: GoogleFonts.montserrat(textStyle : TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: interrankingColor(index),
                                )),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            // Contenu principal (80% de la largeur)
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: const Color.fromARGB(255, 195, 188, 186).withAlpha((0.08 * 255).toInt()),
                      spreadRadius: 2,
                      blurRadius: 12,
                      offset: const Offset(-2, 0),
                    ),
                  ],
                ),
                width: double.infinity, // Prend tout l'espace horizontal
                child: selectedStudent != null
                    ? SingleChildScrollView(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Section nom/prénom/promo
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Nom et promo à gauche
                                Expanded(
                                  flex: 2,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${selectedStudent?.name}',
                                        style:  GoogleFonts.montserrat(textStyle: TextStyle(
                                          fontSize: 28,
                                          fontWeight: FontWeight.bold,
                                        )),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        '${selectedStudent?.year}A ${selectedStudent?.departement}',
                                        style: GoogleFonts.montserrat(textStyle : TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w500,
                                        )),
                                      ),
                                      UiShapes.bPadding(20),
                                      Visibility(
                                        child: notificationCard(selectedStudent!),
                                        visible : selectedStudent?.refused.length != selectedStudent?.choices.length && (selectedStudent?.accepted == null) &&(selectedStudent?.hasNoChoiceLeft() ?? false) ,
                                      )

                                    ],
                                  ),
                                ),
                                const SizedBox(width: 20),
                                // Informations sur l'élève à droite
                                Expanded(
                                  flex: 1,
                                  child: Container(
                                    padding: const EdgeInsets.all(16.0),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[300],
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Column(
                                      children: [
                                        Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text("Classement S1", style: UiText().smallText,),
                                                  Text("${selectedStudent!.ranking_s1}",
                                                    style:  GoogleFonts.montserrat(textStyle: TextStyle(
                                                      fontSize: 18,
                                                      fontWeight: FontWeight.w500,
                                                    )),
                                                  )
                                                ],
                                              ),
                                            ),
                                            Padding(padding: EdgeInsets.only(right: 20)),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  const Text("Crédits ECTS",),
                                                  Text("${selectedStudent!.ects_number}",
                                                    style: GoogleFonts.montserrat(textStyle: TextStyle(
                                                      fontSize: 18,
                                                      fontWeight: FontWeight.w500,
                                                      color : (selectedStudent!.ects_number < 30 ?
                                                      Colors.orange :
                                                      Colors.black),
                                                    )),
                                                  )
                                                ],
                                              ),
                                            ),
                                            Padding(padding: EdgeInsets.only(right: 20)),
                                          ],
                                        ),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text("Niveau d'anglais",style: UiText().smallText,),
                                                  Text(selectedStudent!.lang_lvl,
                                                    style:  GoogleFonts.montserrat(textStyle: TextStyle(
                                                      fontSize: 18,
                                                      fontWeight: FontWeight.w500,
                                                    )),
                                                  )
                                                ],
                                              ),
                                            ),
                                            Padding(padding: EdgeInsets.only(right: 20)),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text("Heures d'absences", style : UiText().smallText),
                                                  Text("${selectedStudent!.missed_hours}",
                                                    style: GoogleFonts.montserrat(textStyle: TextStyle(
                                                      fontSize: 18,
                                                      fontWeight: FontWeight.w500,
                                                      color : (selectedStudent!.missed_hours >= 5 ?
                                                      (selectedStudent!.missed_hours >= 10 ? Colors.red : Colors. orange) :
                                                      Colors.black),
                                                    )),
                                                  )
                                                ],
                                              ),
                                            ),
                                          ],
                                        )
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 30),

                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Section Écoles (gauche)
                                Expanded(
                                  flex: 2,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Liste des écoles
                                      ...selectedStudent!.choices.entries.map((entry) {
                                        int index = entry.key;
                                        //Map<String, String> school = entry.value;
                                        return choiceCard(entry.value, index);
                                      }),
                                    ],
                                  ),
                                ),

                                const SizedBox(width: 20),

                                // Section Boutons d'action (droite)
                                Expanded(
                                  flex: 1,
                                  child: Column(
                                    children: [
                                      // Bouton Laisser un commentaire
                                      Container(
                                        width: double.infinity,
                                        height: 60,
                                        margin: const EdgeInsets.only(bottom: 16),
                                        child: ElevatedButton(
                                          onPressed: () {
                                            showDialog(
                                              context: context,
                                              builder: (BuildContext dialogContext) => CommentModal(student: selectedStudent!, choice: null),
                                            );
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.red,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                          ),
                                          child: Text(
                                            'Laissez un commentaire',
                                            style: GoogleFonts.montserrat( textStyle: TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            )),
                                          ),
                                        ),
                                      ),

                                      // Bouton Revenir à l'étudiant précédent
                                      Container(
                                        width: double.infinity,
                                        height: 50,
                                        margin: const EdgeInsets.only(bottom: 16),
                                        child: ElevatedButton(
                                          onPressed: currentStudentIndex > 0
                                              ? () => selectStudentByIndex(currentStudentIndex - 1)
                                              : null, // Disable if we're at the first student
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.grey[300],
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                          ),
                                          child: Text(
                                            'Revenir à l\'étudiant précédent',
                                            style: GoogleFonts.montserrat(textStyle: TextStyle(
                                              color: Colors.black,
                                              fontSize: 14,
                                            )),
                                          ),
                                        ),
                                      ),

                                      // Bouton Passer à l'étudiant suivant
                                      SizedBox(
                                        width: double.infinity,
                                        height: 50,
                                        child: ElevatedButton(
                                          onPressed: currentStudentIndex < widget.students.length - 1
                                              ? () => selectStudentByIndex(currentStudentIndex + 1)
                                              : null, // Disable if we're at the last student
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.grey[300],
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                          ),
                                          child: Text(
                                            'Passer à l\'étudiant Suivant',
                                            style: GoogleFonts.montserrat(textStyle: const TextStyle(
                                              color: Colors.black,
                                              fontSize: 14,
                                            )),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      )
                    :  Center(child: Text("Sélectionnez un étudiant",style: UiText().mediumText,)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void selectStudentByIndex(int index) {
    if (index >= 0 && index < widget.students.length) {
      setState(() {
        selectedStudent = widget.students[index];
        currentStudentIndex = index;
        expandedStudentsChoice = List.generate(
            widget.students[index].choices.values.toList().length,
                (_) => false
        );
        // Initialiser showCancelButton pour chaque choix en fonction de l'état actuel
        showCancelButton.clear();
        widget.students[index].choices.forEach((key, choice) {
          // Afficher le bouton annuler si le choix est accepté ou refusé
          showCancelButton[key] = (choice.student.accepted == choice) || 
                                  choice.student.refused.contains(choice);
          // Initialiser schoolChoices en fonction de l'état
          if (choice.student.accepted == choice) {
            schoolChoices[key] = true;
          } else if (choice.student.refused.contains(choice)) {
            schoolChoices[key] = false;
          }
        });
      });
    }
  }

  bool disbaleChoice(Choice choice){
    int availableplaces = choice.student.get_graduation_level() == "master" ? choice.school.m_slots : choice.school.b_slots;
    return (choice.student.accepted != null &&  choice.student.accepted != choice) ||
           (availableplaces == 0 && choice.student.accepted == null);
  }

  bool disableChoiceByRanking(Student student_f,int choiceNumber){
    Map<int, List<Student>> ladder = student_f.ladder_interranking(widget.students);
    bool atLeastOneNotAccepted = false; 
    print("meilleur: ${ladder}");
    print("-----------------------------------------------------------------");
    for (var entry in ladder.entries){
      for (var student in entry.value){
        print("student: ${student.name}");
        print("accepted: ${student.accepted}");
        print("refused: ${student.refused}");
        print("choice_f: ${student_f.choices[choiceNumber]}");
      }
    }
    print("-----------------------------------------------------------------");
    //pour s'il y a au moins un étudiant mieux classé qui n'est pas accepté.
    for (var entry in ladder.entries){
      if (entry.value.any((student) => student.accepted == null && !student.refused.contains(student_f.choices[choiceNumber]))){
        atLeastOneNotAccepted = true;
        break;
      }
    }
    return  atLeastOneNotAccepted && ladder.containsKey(choiceNumber);
  }


  Widget choiceCard(Choice choice, int index) {
    int availableplaces = choice.student.get_graduation_level() == "master" ? choice.school.m_slots : choice.school.b_slots;

    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      color: disbaleChoice(choice) ? disabledColor : Colors.grey[300],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),

      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: AnimatedSize(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOut,
          alignment: Alignment.topCenter,
          // vsync: this,
          child: expandedStudentsChoice[index-1]
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            choice.school.name,
                            style:  GoogleFonts.montserrat(textStyle: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            )),
                          ),
                        ),
                        Column(
                          children: [
                            IconButton(
                                onPressed: (){
                                  setState(() {
                                    expandedStudentsChoice[index-1] = false;
                                  });
                                },
                                icon: Icon(PhosphorIcons.arrowUp()),
                            ),
                          ],
                        )
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      choice.school.country,
                      style: GoogleFonts.montserrat(textStyle: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      )),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Niveau académique requis",style: UiText().smallText,),
                                SizedBox(
                                  width: MediaQuery.sizeOf(context).width*0.5*0.4,
                                  child: Text(choice.school.academic_level,
                                    style:  GoogleFonts.montserrat(textStyle: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w500,
                                    )),
                                  ),
                                ),
                                Padding(padding: EdgeInsets.only(bottom: 5)),
                                Text("Langue d'enseignement", style: UiText().smallText,
                                ),
                                SizedBox(
                                  width: MediaQuery.sizeOf(context).width*0.5*0.4,
                                  child: Text(choice.school.use_langage,
                                    maxLines: 3,
                                    style: GoogleFonts.montserrat(textStyle: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w500,
                                    )),
                                  ),
                                ),
                                Padding(padding: EdgeInsets.only(bottom: 5)),
                                Text("Niveau de langue",style: UiText().smallText,),
                                SizedBox(
                                  width: MediaQuery.sizeOf(context).width*0.5*0.4,
                                  child: Text("${choice.school.req_lang_level}",
                                    style: GoogleFonts.montserrat(textStyle: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 18,
                                    )),
                                      maxLines: 4,
                                  ),
                                ),
                              ],
                            ),
                            Padding(padding: EdgeInsets.only(right: 20)),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Nombre de places",style: UiText().smallText,),
                                Text("${choice.school.remaining_slots} | ${choice.school.b_slots} Bachelor, ${choice.school.m_slots} Master",
                                  style: GoogleFonts.montserrat(textStyle: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                  )),
                                ),
                                Padding(padding: EdgeInsets.only(bottom: 5)),
                                Text("Discipline",style: UiText().smallText,),
                                SizedBox(
                                  width : MediaQuery.sizeOf(context).width*0.5*0.3,
                                  child: Text("${choice.school.specialization.toString().replaceAll("[", "").replaceAll("]", "")}",
                                    style: GoogleFonts.montserrat(textStyle: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w500,
                                      color : (choice.is_incoherent() ?
                                          Colors.orange :
                                          Colors.black),

                                    )),
                                  ),
                                ),
                                Padding(padding: EdgeInsets.only(bottom: 5)),
                                Text("Interclassement"),
                                Text("${choice.interranking}",
                                  style:  GoogleFonts.montserrat(textStyle: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                  )),
                                ),  
                              ],
                            ),
                          ],
                        ),
                        Spacer(),
                        // Afficher le bouton annuler ou les boutons accepter/refuser
                        if (showCancelButton[index] == true)
                          SizedBox(
                            width: 80,
                            height: 40,
                            child: Tooltip(
                              message: "Annuler l'action précédente",
                              child: ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    showCancelButton[index] = false;
                                    schoolChoices[index] = null;
                                    // Annuler l'action précédente
                                    if (choice.student.accepted == choice) {
                                      choice.remove_choice();
                                    }
                                    // Restaurer le choix si il avait été refusé
                                    if (choice.student.refused.contains(choice)) {
                                      choice.student.restoreRefusedChoice(choice, index);
                                    }
                                  });
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange,
                                  padding: EdgeInsets.zero,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ),
                                child: Text(
                                  "Annuler",
                                  style: GoogleFonts.montserrat(textStyle: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  )),
                                ),
                              ),
                            ),
                          )
                        else
                          Row(
                            children: [
                              // Bouton Refuser (X)
                              SizedBox(
                                width: 40,
                                height: 40,
                                child: Tooltip(
                                  message: "Refuser ce choix",
                                  child: ElevatedButton(
                                    onPressed: choice.student.accepted != null && choice.student.accepted != choice ? null : () async {
                                      // Ouvrir le modal de commentaire pour le refus
                                      await showDialog(
                                        context: context,
                                        builder: (BuildContext dialogContext) => CommentModal(student: choice.student, choice: choice),
                                      );
                                      
                                      setState(() {
                                        schoolChoices[index] = false;
                                        choice.refuse();
                                        showCancelButton[index] = true;
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text("Choix refusé"),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      });
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: schoolChoices[index] == false
                                          ? Colors.red[700]
                                          : Colors.red,
                                      padding: EdgeInsets.zero,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.close,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Bouton Accepter (✓)
                              SizedBox(
                                width: 40,
                                height: 40,
                                child: Tooltip(
                                  message: availableplaces == 0 ? "Plus de places disponibles" : disableChoiceByRanking(selectedStudent!, index) ? "Il y un étudiant avec un meilleur interclassement" : "Accepter ce choix",
                                  child: ElevatedButton(
                                    onPressed: disableChoiceByRanking(selectedStudent!, index)  || choice.student.accepted != null || availableplaces == 0 ? null : () {
                                      setState(() {
                                        schoolChoices[index] = true;
                                        choice.accepted(choice.student);
                                        showCancelButton[index] = true;
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text("Choix accepté"),
                                            backgroundColor: Colors.green,
                                          ),
                                        );
                                      });
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: schoolChoices[index] == true
                                          ? Colors.green[700]
                                          : Colors.green,
                                      padding: EdgeInsets.zero,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.check,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ],
                )
              : Container(
                  width: MediaQuery.sizeOf(context).width * 0.4,
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.sizeOf(context).width * 0.5,
                    minWidth: MediaQuery.sizeOf(context).width * 0.5,
                  ),
                  child: Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: MediaQuery.sizeOf(context).width*0.35,
                            child: Text(
                              choice.school.name,
                              style: GoogleFonts.montserrat(textStyle: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              )),
                            ),
                          ),
                          Text(
                            choice.school.country,
                            style: GoogleFonts.montserrat(textStyle: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            )),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          IconButton(
                            onPressed: () {
                              setState(() {
                                expandedStudentsChoice[index-1] = true;
                              });
                            },
                            icon: Icon(PhosphorIcons.arrowDown()),
                          ),
                          Padding(padding: EdgeInsets.only(bottom: 10)),
                          Row(
                            children: [
                              // Afficher le bouton annuler ou les boutons accepter/refuser
                              if (showCancelButton[index] == true)
                                SizedBox(
                                  width: 80,
                                  height: 40,
                                  child: Tooltip(
                                    message: "Annuler l'action précédente",
                                    child: ElevatedButton(
                                      onPressed: () {
                                        setState(() {
                                          showCancelButton[index] = false;
                                          schoolChoices[index] = null;
                                          // Annuler l'action précédente
                                          if (choice.student.accepted == choice) {
                                            choice.remove_choice();
                                          }
                                          // Restaurer le choix si il avait été refusé
                                          if (choice.student.refused.contains(choice)) {
                                            choice.student.restoreRefusedChoice(choice, index);
                                          }
                                        });
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.orange,
                                        padding: EdgeInsets.zero,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                      ),
                                      child: Text(
                                        "Annuler",
                                        style: GoogleFonts.montserrat(textStyle: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        )),
                                      ),
                                    ),
                                  ),
                                )
                              else
                                Row(
                                  children: [
                                    // Bouton Refuser (X)
                                    SizedBox(
                                      width: 40,
                                      height: 40,
                                      child: Tooltip(
                                        message: "Refuser ce choix",
                                        child: ElevatedButton(
                                          onPressed: choice.student.accepted != null && choice.student.accepted != choice ? null : () async {
                                            // Ouvrir le modal de commentaire pour le refus
                                            await showDialog(
                                              context: context,
                                              builder: (BuildContext dialogContext) => CommentModal(student: choice.student, choice: choice),
                                            );
                                            
                                            setState(() {
                                              schoolChoices[index] = false;
                                              choice.refuse();
                                              showCancelButton[index] = true;
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text("Choix refusé"),
                                                  backgroundColor: Colors.red,
                                                ),
                                              );
                                            });
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: schoolChoices[index] == false
                                                ? Colors.red[700]
                                                : Colors.red,
                                            padding: EdgeInsets.zero,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.close,
                                            color: Colors.white,
                                            size: 20,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    // Bouton Accepter (✓)
                                    SizedBox(
                                      width: 40,
                                      height: 40,
                                      child: Tooltip(
                                        message: availableplaces == 0 ? "Plus de places disponibles" : disableChoiceByRanking(selectedStudent!, index) ? "Il y un étudiant avec un meilleur interclassement" : "Accepter ce choix",
                                        child: ElevatedButton(
                                          onPressed: disableChoiceByRanking(selectedStudent!, index)  || choice.student.accepted != null || availableplaces == 0 ? null : () {
                                            setState(() {
                                              schoolChoices[index] = true;
                                              choice.accepted(choice.student);
                                              showCancelButton[index] = true;
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text("Choix accepté"),
                                                  backgroundColor: Colors.green,
                                                ),
                                              );
                                            });
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: schoolChoices[index] == true
                                                ? Colors.green[700]
                                                : Colors.green,
                                            padding: EdgeInsets.zero,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.check,
                                            color: Colors.white,
                                            size: 20,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
              ),
        ),
      ),
    );
  }

  Widget notificationCard(Student currentStudent){
    return Container(
      decoration: BoxDecoration(
        color: Colors.orange.shade100,
        borderRadius: UiShapes().frameRadius,
      ),
      padding: EdgeInsets.all(10),
      child: Row(
        children: [
          Icon(PhosphorIcons.info(),size: 50,),
          Padding(padding: EdgeInsets.only(right: 10)),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Cet étudiant n'as plus de voeux admissibles à cause des raisons suivantes :", style: UiText().nsText,),
              Text("${getAutoRejectionComment(currentStudent)}", style: UiText(weight: FontWeight.w500).nText,),
            ],
          ))
        ],
      ),
    );
  }
}

// Widget modal pour les commentaires
class CommentModal extends StatefulWidget {
  final Student student;
  final Choice? choice; // null pour commentaire général, non-null pour commentaire sur un choix spécifique

  const CommentModal({super.key, required this.student, this.choice});

  @override
  State<CommentModal> createState() => _CommentModalState();
}

class _CommentModalState extends State<CommentModal> {
  int selectedChoice = 1;
  String comment = "";

  @override
  void initState() {
    super.initState();
    // Si un choix est spécifié, utiliser son index
    if (widget.choice != null) {
      widget.student.choices.forEach((key, value) {
        if (value == widget.choice) {
          selectedChoice = key;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.choice != null ? "Commentaire sur le refus" : "Laisser un commentaire"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.choice == null) // Afficher le dropdown seulement pour les commentaires généraux
            DropdownButton<int>(
              value: selectedChoice,
              items: [1, 2, 3].map((int value) {
                return DropdownMenuItem<int>(
                  value: value,
                  child: Text("Choix $value"),
                );
              }).toList(),
              onChanged: (int? newValue) {
                setState(() {
                  selectedChoice = newValue!;
                });
              },
            ),
          if (widget.choice == null) SizedBox(height: 16),
          TextField(
            onChanged: (value) {
              comment = value;
            },
            decoration: InputDecoration(
              hintText: widget.choice != null ? "Expliquez pourquoi ce choix a été refusé" : "Entrez votre commentaire",
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: Text("Annuler"),
        ),
        TextButton(
          onPressed: () {
            if (widget.choice != null) {
              // Ajouter le commentaire au choix refusé
              widget.choice!.post_comment = comment;
            } else {
              // Ajouter le commentaire général
              widget.student.add_post_comment(selectedChoice, comment);
            }
            Navigator.pop(context);
          },
          child: Text("Valider"),
        ),
      ],
    );
  }
}