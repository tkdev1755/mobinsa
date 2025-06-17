import 'package:flutter/material.dart';
import 'package:mobinsa/model/Choice.dart';
import 'package:mobinsa/model/Student.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../model/School.dart';



class DisplayApplicants extends StatefulWidget {
  const DisplayApplicants({Key? key}) : super(key: key);

  @override
  State<DisplayApplicants> createState() => _DisplayApplicantsState();
}

class _DisplayApplicantsState extends State<DisplayApplicants> {
  final List<Map<String, String>> students = [
    {'nom': 'Dupont', 'prenom': 'Jean', 'promo': "3A STI"},
    {'nom': 'Martin', 'prenom': 'Sophie', 'promo': "3A STI"},
    {'nom': 'Bernard', 'prenom': 'Lucas', 'promo': "3A STI"},
    {'nom': 'Petit', 'prenom': 'Emma', 'promo': "3A STI"},
    {'nom': 'Robert', 'prenom': 'Thomas', 'promo': "3A STI"},
  ];

  final List<Map<String, String>> schools = [
    {'nom': 'Ecole 1', 'pays': 'Pays X'},
    {'nom': 'Ecole 2', 'pays': 'Pays Y'},
    {'nom': 'Ecole 3', 'pays': 'Pays Z'},
  ];

  Map<String, String>? selectedStudent;
  Map<int, bool?> schoolChoices = {}; // null = pas de choix, true = accepté, false = refusé
  List<Choice> selectedStudentChoices = [
    Choice(
        School("Ecole 1","Pays X","",0,0,0,[],"","","","",""),10,Student(0,"",{},"",0,0,"",0.0,"")
    )
  ];
  List<bool> expandedStudentsChoice = [false];
  @override
  Widget build(BuildContext context) {
    print(expandedStudentsChoice);

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
              onPressed: () {
                // TODO: Exporter en excel
              },
              tooltip: "Exporter en excel",
            ),
            IconButton(
              icon: Icon(PhosphorIcons.gear(PhosphorIconsStyle.regular), size: 32.0),
              onPressed: null,
              tooltip: "Cette fonctionnalité n'est pas encore disponible",
            ),
          ],
          backgroundColor: Colors.grey[100],
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
                  itemCount: students.length,
                  itemBuilder: (context, index) {
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8.0),
                      child: ListTile(
                        title: Text(
                          '${students[index]['prenom']} ${students[index]['nom']}',
                          style: const TextStyle(fontSize: 14),
                        ),
                        onTap: () {
                          setState(() {
                            selectedStudent = students[index];
                            schoolChoices.clear(); // Reset des choix
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
                                flex: 1,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${selectedStudent!['prenom']} ${selectedStudent!['nom']}',
                                      style: const TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      '${selectedStudent!['promo']}',
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
                                flex: 1,
                                child: Container(
                                  padding: const EdgeInsets.all(16.0),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[300],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Informations sur l\'élève (niveau de langue, niveau académique,...)',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                        ),
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
                                flex: 1,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Liste des écoles
                                    ...schools.asMap().entries.map((entry) {
                                      int index = entry.key;
                                      Map<String, String> school = entry.value;
                                      return Container(
                                        margin: const EdgeInsets.only(bottom: 16.0),
                                        padding: const EdgeInsets.all(16.0),
                                        decoration: BoxDecoration(
                                          color: Colors.grey[300],
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          children: [
                                            // Informations école
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                    children: [
                                                      Text(
                                                        school['nom']!,
                                                        style: const TextStyle(
                                                          fontSize: 18,
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                      Icon(
                                                        Icons.keyboard_arrow_down,
                                                        color: Colors.grey[600],
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    school['pays']!,
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      color: Colors.grey[600],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 16),
                                            // Boutons Accepter/Refuser
                                            Row(
                                              children: [
                                                // Bouton Refuser (X)
                                                Container(
                                                  width: 40,
                                                  height: 40,
                                                  child: ElevatedButton(
                                                    onPressed: () {
                                                      // TODO: Marquer l'école comme refusée
                                                      setState(() {
                                                        schoolChoices[index] = false;
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
                                                    onPressed: () {
                                                      // TODO: Marquer l'école comme acceptée
                                                      setState(() {
                                                        schoolChoices[index] = true;
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
                                      );
                                    }).toList(),
                                    choiceCard(selectedStudentChoices[0],0)
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
                                          // TODO: Implémenter la fonctionnalité de commentaire
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
                                        onPressed: () {
                                          // TODO: Implémenter la navigation vers l'étudiant précédent
                                        },
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
                                        onPressed: () {
                                          // TODO: Implémenter la navigation vers l'étudiant suivant
                                        },
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

  Widget choiceCard(Choice choice, int index) {
    // TODO: Ajouter les bouttons pour accepter et refuser dans un row de la column du iconbutton
    print("expanded ? ${expandedStudentsChoice[index]}");
    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      color: Colors.grey[300],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Visibility(
          visible: !expandedStudentsChoice[index],
          replacement: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    choice.school.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Column(
                    children: [
                      IconButton(
                        onPressed: (){
                          setState(() {
                            expandedStudentsChoice[index] = false;
                          });
                          print(expandedStudentsChoice);
                        },
                        icon: Icon(PhosphorIcons.arrowUp()),
                        color: Colors.black,
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.grey[300],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            onPressed: () {
                              // TODO: Gérer le refus
                            },
                            icon: Icon(PhosphorIcons.x(PhosphorIconsStyle.bold)),
                            color: Colors.white,
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.red[700],
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: () {
                              // TODO: Gérer la validation
                            },
                            icon: Icon(PhosphorIcons.check(PhosphorIconsStyle.bold)),
                            color: Colors.white,
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.green[700],
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                          ),
                        ],
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Niveau académique requis"),
                  Text("${choice.school.academic_level}"),
                  Text("Langue d'enseignement"),
                  Text("${choice.school.use_langage}"),
                  Text("Nombre de place"),
                ],
              ),
            ],
          ),
          child: Row(
            children: [
              Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        choice.school.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
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
                  const SizedBox(width: 16),
                  choice.student.accepted_school == null ?
                  Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          choice.school.accepted(choice.student);
                        },
                        icon: Icon(PhosphorIcons.x(PhosphorIconsStyle.bold)),
                        color: Colors.white,
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.red[700],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () {
                          choice.school.accepted(choice.student);
                        },
                        icon: Icon(PhosphorIcons.check(PhosphorIconsStyle.bold)),
                        color: Colors.white,
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.green[700],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ),
                    ],
                  )
                  :
                  choice.student.accepted_school == choice.school ?
                  Row(
                    children: [
                      Text("École acceptée"),
                    ],
                  )
                  :
                  Row(
                    children: [
                      Text("Un autre choix à été validé"),
                    ],
                  ),
                ],
              ),
              const Spacer(),
              IconButton(
                onPressed: () {
                  setState(() {
                    expandedStudentsChoice[index] = true;
                  });
                },
                icon: Icon(PhosphorIcons.arrowDown()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}