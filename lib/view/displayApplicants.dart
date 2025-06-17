import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:mobinsa/model/Choice.dart';
import 'package:mobinsa/model/Student.dart';
import 'package:mobinsa/model/parser.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../model/School.dart';


/*


  16/06/2025@tahakhetib : J'ai apporté les modification suivantes
    - Ajouté les boutons accepter et refuser dans le choiceCard
    - Modifié le widget dans la liste de voeux pour le mettre à jour vers choice card
    - Ajouté l'export du fichier excel
 */
class DisplayApplicants extends StatefulWidget {
  List<School> schools;
  List<Student> students;
  DisplayApplicants({Key? key, required this.schools, required this.students}) : super(key: key);

  @override
  State<DisplayApplicants> createState() => _DisplayApplicantsState();
}

class _DisplayApplicantsState extends State<DisplayApplicants> {

  Student? selectedStudent;
  Map<int, bool?> schoolChoices = {}; // null = pas de choix, true = accepté, false = refusé
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
              onPressed: null,
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
                      color: currentStudentIndex == index ? Colors.blue[100] : (widget.students[index].accepted != null ? Colors.green[700] : Colors.grey[300]),
                      child: ListTile(
                        title: Text(
                          widget.students[index].name,
                          style: TextStyle(
                            fontSize: 14,
                            color: currentStudentIndex == index ? Colors.blue[900] : Colors.black,
                          ),
                        ),
                        onTap: () {
                          setState(() {
                            selectedStudent = widget.students[index];
                            currentStudentIndex = index;
                            schoolChoices.clear();
                          });
                        },
                      ),
                    );
                  },
                ),
              ),
            ),
            // Contenu principal (80% de la largeur)
            Container(
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
                                    const Text("Niveau d'anglais",),
                                    Text("${selectedStudent!.lang_lvl}",
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
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w500,
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
                                print(index);
                                //Map<String, String> school = entry.value;
                                return choiceCard(entry.value, index);
                              }).toList(),
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
                                    int selectedChoice = 1;
                                    String comment = "";
                                    showDialog(
                                      context: context,
                                      builder: (BuildContext dialogContext) => StatefulBuilder(
                                        builder: (BuildContext context, StateSetter setDialogState) {
                                          return AlertDialog(
                                            title: Text("Laisser un commentaire"),
                                            content: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                DropdownButton<int>(
                                                  value: selectedChoice,
                                                  items: [1, 2, 3].map((int value) {
                                                    return DropdownMenuItem<int>(
                                                      value: value,
                                                      child: Text("Choix $value"),
                                                    );
                                                  }).toList(),
                                                  onChanged: (int? newValue) {
                                                    setDialogState(() {
                                                      selectedChoice = newValue!;
                                                    });
                                                  },
                                                ),
                                                SizedBox(height: 16),
                                                TextField(
                                                  onChanged: (value) {
                                                    comment = value;
                                                  },
                                                  decoration: InputDecoration(
                                                    hintText: "Entrez votre commentaire",
                                                    border: OutlineInputBorder(),
                                                  ),
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
                                                  setState(() {
                                                    selectedStudent?.add_post_comment(selectedChoice, comment);
                                                    print("selectedChoice: $selectedChoice");
                                                    print("comment: $comment");
                                                  });
                                                  Navigator.pop(context);
                                                },
                                                child: Text("Valider"),
                                              ),
                                            ],
                                          );
                                        },
                                      ),
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
                              Container(
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
      });
    }
  }

  bool disbaleChoice(Choice choice){
    //TODO: check if the student rank is the best
    return (choice.student.accepted != null && choice.student.accepted != choice) || 
           (choice.school.remaining_slots == 0 && choice.student.accepted != choice);
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
                          Text("${choice.school.academic_level}",
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text("Langue d'enseignement",

                          ),
                          Text("${choice.school.use_langage}",
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text("Nombre de places"),
                          Text("${choice.school.remaining_slots} | ",
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
                  Container(
                    width: 40,
                    height: 40,
                    child: ElevatedButton(
                      onPressed: choice.student.accepted != null && choice.student.accepted != choice ? null : () {
                        setState(() {
                          schoolChoices[index] = false;
                            choice.remove_choice();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("Choix retiré"),
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
                  const SizedBox(width: 8),
                  // Bouton Accepter (✓)
                  Container(
                    width: 40,
                    height: 40,
                    child: ElevatedButton(
                      onPressed: choice.student.accepted != null ? null : () {
                        setState(() {
                          schoolChoices[index] = true;
                          choice.accepted(choice.student);
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
                    Container(
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
                        // Bouton Refuser (X)
                        Container(
                          width: 40,
                          height: 40,
                          child: ElevatedButton(
                            onPressed: choice.student.accepted != null && choice.student.accepted != choice ? null : () {
                              setState(() {
                                schoolChoices[index] = false;
                                choice.remove_choice();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text("Choix retiré"),
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
                        const SizedBox(width: 8),
                        // Bouton Accepter (✓)
                        Container(
                          width: 40,
                          height: 40,
                          child: ElevatedButton(
                            onPressed: choice.student.accepted != null ? null : () {
                              setState(() {
                                schoolChoices[index] = true;
                                choice.accepted(choice.student);
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