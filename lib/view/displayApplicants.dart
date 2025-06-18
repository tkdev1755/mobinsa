import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:mobinsa/model/Choice.dart';
import 'package:mobinsa/model/Student.dart';
import 'package:mobinsa/model/parser.dart';
import 'package:mobinsa/view/debugPage.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../model/School.dart';

//TODO: faire en sorte que le bouton retirer marcher pour retirer et pour refuser un choix

/*


  16/06/2025@tahakhetib : J'ai apporté les modification suivantes
    - Ajouté les boutons accepter et refuser dans le choiceCard
    - Modifié le widget dans la liste de voeux pour le mettre à jour vers choice card
    - Ajouté l'export du fichier excel
 */
class DisplayApplicants extends StatefulWidget {
  List<School> schools;
  List<Student> students;
  DisplayApplicants({super.key, required this.schools, required this.students});

  @override
  State<DisplayApplicants> createState() => _DisplayApplicantsState();
}

class _DisplayApplicantsState extends State<DisplayApplicants> {

  Student? selectedStudent;
  Map<int, bool?> schoolChoices = {}; // null = pas de choix, true = accepté, false = refusé
  Map<int, bool> showCancelButton = {}; // true = afficher le bouton annuler, false = afficher les boutons accepter/refuser
  int currentStudentIndex = -1;
  List<bool> expandedStudentsChoice = [false,false,false];
  Color disabledColor = Colors.grey[100]!;
  String comment = "";
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text(
            "Mob'INSA",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, ),
          ),
          actions: [
            IconButton(
              icon: Icon(
                PhosphorIcons.export(PhosphorIconsStyle.regular),
                size: 32.0,
              ),
              onPressed: () async {
                List<int> bytes = SheetParser.exportResult(widget.students, widget.schools);
                String? path = await FilePicker.platform.saveFile(
                  fileName: "CR_JURY_MOBILITE_${DateTime.now().year}",
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
              icon: Icon(PhosphorIcons.gear(PhosphorIconsStyle.regular), size: 32.0),
              onPressed: (){
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => DebugPage(student: widget.students, schools: widget.schools)),);
              },
              tooltip: "Cette fonctionnalité n'est pas encore disponible",
            ),
            IconButton(
              icon: Icon(PhosphorIcons.house(PhosphorIconsStyle.regular), size: 32.0),
              onPressed: () => {
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
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: ListView.builder(
                  itemCount: widget.students.length,
                  itemBuilder: (context, index) {
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8.0),
                      color: currentStudentIndex == index
                          ? Colors.blue[100]
                          : (widget.students[index].accepted != null
                          ? Colors.green[700]
                          : Colors.grey[300]),
                      child: ListTile(
                        title: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              widget.students[index].name,
                              style: TextStyle(
                                fontSize: 14,
                                color: currentStudentIndex == index
                                    ? Colors.blue[900]
                                    : Colors.black,
                              ),
                            ),
                            Text(
                              widget.students[index].get_max_rank().toString() ?? "Err",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: currentStudentIndex == index
                                    ? Colors.blue[900]
                                    : Colors.black,
                              ),
                            ),
                          ],
                        ),
                        onTap: () {
                          setState(() {
                            selectedStudent = widget.students[index];
                            currentStudentIndex = index;
                            schoolChoices.clear();

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
                        },
                      ),
                    );
                  },
                ),
              ),
            ),// Contenu principal (80% de la largeur)
            SizedBox(
              width: MediaQuery.of(context).size.width * 0.8,
              child: selectedStudent != null
                  ? SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
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
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${selectedStudent?.year}A ${selectedStudent?.departement}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 20),
                        // Informations sur l'élève à droite
                        Expanded(
                          flex: 2,
                          child: Container(
                            padding: const EdgeInsets.all(16.0),
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text("Classement S1",),
                                    Text("${selectedStudent!.ranking_s1}",
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    )
                                  ],
                                ),
                                Padding(padding: EdgeInsets.only(right: 20)),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text("Crédits ECTS",),
                                    Text("${selectedStudent!.ects_number}",
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w500,
                                        color : (selectedStudent!.ects_number < 30 ?
                                        Colors.orange :
                                        Colors.black),
                                      ),
                                    )
                                  ],
                                ),
                                Padding(padding: EdgeInsets.only(right: 20)),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text("Niveau d'anglais",),
                                    Text(selectedStudent!.lang_lvl,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    )
                                  ],
                                ),
                                Padding(padding: EdgeInsets.only(right: 20)),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text("Heures d'absences",),
                                    Text("${selectedStudent!.missed_hours}",
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w500,
                                        color : (selectedStudent!.missed_hours >= 5 ?
                                        (selectedStudent!.missed_hours >= 10 ? Colors.red : Colors. orange) :
                                        Colors.black),
                                      ),
                                    )
                                  ],
                                ),
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
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: const Text(
                                    'Laissez un commentaire',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
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
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: const Text(
                                    'Revenir à l\'étudiant précédent',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 14,
                                    ),
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
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: const Text(
                                    'Passer à l\'étudiant Suivant',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 14,
                                    ),
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
                  : const Center(child: Text("Sélectionnez un étudiant")),
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
    //TODO: check if the student rank is the best
    return (choice.student.accepted != null && choice.student.accepted != choice) || 
           (choice.school.remaining_slots == 0 && choice.student.accepted == null);
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
    print(" is the output disabled ? ${disbaleChoice(choice)}");
    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      color: disbaleChoice(choice) ? disabledColor : Colors.grey[300],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Visibility(
          visible: !expandedStudentsChoice[index-1],
          replacement: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      choice.school.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
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
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
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
                          Text("Niveau académique requis"),
                          SizedBox(
                            width: MediaQuery.sizeOf(context).width*0.5*0.4,
                            child: Text(choice.school.academic_level,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Text("Langue d'enseignement",
                          ),
                          SizedBox(
                            width: MediaQuery.sizeOf(context).width*0.5*0.4,
                            child: Text(choice.school.use_langage,
                              maxLines: 3,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Text("Niveau de langue"),
                          Text("${choice.school.req_lang_level} | ",
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      Padding(padding: EdgeInsets.only(right: 20)),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Nombre de places"),
                          Text("${choice.school.remaining_slots} | ${choice.school.b_slots} Bachelor, ${choice.school.m_slots} Master",
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text("Discipline"),
                          SizedBox(
                            width : MediaQuery.sizeOf(context).width*0.5*0.3,
                            child: Text("${choice.school.specialization.toString().replaceAll("[", "").replaceAll("]", "")}",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                color : (choice.is_incoherent() ?
                                    Colors.orange :
                                    Colors.black),

                              ),
                            ),
                          ),
                          Text("Interclassement"),
                          Text("${choice.interranking}",
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                            ),
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
                          child: const Text(
                            "Annuler",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
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
                            message: choice.school.remaining_slots == 0 ? "Plus de places disponibles" : disableChoiceByRanking(selectedStudent!, index) ? "Il y un étudiant avec un meilleur interclassement" : "Accepter ce choix",
                            child: ElevatedButton(
                              onPressed: disableChoiceByRanking(selectedStudent!, index) || choice.student.accepted != null || choice.school.remaining_slots == 0 ? null : () {
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
          child: Container(
            width: MediaQuery.sizeOf(context).width*0.4,
            constraints: BoxConstraints(
              maxWidth: MediaQuery.sizeOf(context).width*0.5,
              minWidth: MediaQuery.sizeOf(context).width*0.5,
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
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Text(
                      choice.school.country,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
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
                                child: const Text(
                                  "Annuler",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
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
                                  message: choice.school.remaining_slots == 0 ? "Plus de places disponibles" : disableChoiceByRanking(selectedStudent!, index) ? "Il y un étudiant avec un meilleur interclassement" : "Accepter ce choix",
                                  child: ElevatedButton(
                                    onPressed: disableChoiceByRanking(selectedStudent!, index)  || choice.student.accepted != null || choice.school.remaining_slots == 0 ? null : () {
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