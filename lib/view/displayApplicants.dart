import 'package:flutter/material.dart';
import 'package:mobinsa/model/Choice.dart';
import 'package:mobinsa/model/Student.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../model/School.dart';

class DisplayApplicants extends StatefulWidget {
  final List<Student> students;
  final List<School> schools;
  
  const DisplayApplicants({Key? key, required this.students, required this.schools}) : super(key: key);

  @override
  State<DisplayApplicants> createState() => _DisplayApplicantsState();
}

class _DisplayApplicantsState extends State<DisplayApplicants> {
  Student? selectedStudent;
  Map<int, bool?> schoolChoices = {}; // null = pas de choix, true = accepté, false = refusé
  List<Choice> selectedStudentChoices = [];
  List<bool> expandedStudentsChoice = [];
  int currentStudentIndex = -1; // Add this line to track current index
  
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
                  itemCount: widget.students.length,
                  itemBuilder: (context, index) {
                    final student = widget.students[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8.0),
                      child: ListTile(
                        title: Text(
                          student.name,
                          style: const TextStyle(fontSize: 14),
                        ),
                        subtitle: Text(
                          "${student.departement} ${student.year}A",
                          style: const TextStyle(fontSize: 12),
                        ),
                        onTap: () {
                          setState(() {
                            selectedStudent = student;
                            currentStudentIndex = index; // Add this line
                            schoolChoices.clear(); // Reset des choix
                            selectedStudentChoices = student.choices.values.toList();
                            expandedStudentsChoice = List.generate(
                              selectedStudentChoices.length, 
                              (_) => false
                            );
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
                                      selectedStudent!.name,
                                      style: const TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      '${selectedStudent!.departement} ${selectedStudent!.year}A',
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
                                    ...widget.schools.asMap().entries.map((entry) {
                                      int index = entry.key;
                                      School school = entry.value;
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
                                                        school.name,
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
                                                    school.country,
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
                                    ...selectedStudentChoices.asMap().entries.map((entry) {
                                      int index = entry.key;
                                      Choice choice = entry.value;
                                      return Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          if (index == 0) 
                                            Padding(
                                              padding: const EdgeInsets.only(top: 24.0, bottom: 8.0),
                                              child: Text(
                                                "Choix de l'étudiant",
                                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                          Text(
                                            "Choix #${index+1}",
                                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                                          ),
                                          choiceCard(choice, index),
                                        ],
                                      );
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
                                        onPressed: currentStudentIndex > 0
                                          ? () => selectStudentByIndex(currentStudentIndex - 1)
                                          : null, // Disable if we're at the first student
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.grey[300],
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          disabledBackgroundColor: Colors.grey[200],
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
                                          disabledBackgroundColor: Colors.grey[200],
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
        schoolChoices.clear();
        selectedStudentChoices = widget.students[index].choices.values.toList();
        expandedStudentsChoice = List.generate(
          selectedStudentChoices.length, 
          (_) => false
        );
      });
    }
  }

  Widget choiceCard(Choice choice, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      color: Colors.grey[200],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
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
                Text(
                  "Classement: ${choice.interranking}",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              "Pays: ${choice.school.country}",
              style: TextStyle(
                fontSize: 14,
              ),
            ),
            SizedBox(height: 8),
            Text(
              "Programme: ${choice.school.program}",
              style: TextStyle(
                fontSize: 14,
              ),
            ),
            SizedBox(height: 16),
            // Adding accept/decline buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Decline button (red X)
                Container(
                  width: 40,
                  height: 40,
                  margin: EdgeInsets.only(right: 8),
                  child: ElevatedButton(
                    onPressed: () {
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
                // Accept button (green check)
                Container(
                  width: 40,
                  height: 40,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        schoolChoices[index] = true;
                        // Optionally, update the student's accepted choice
                        if (selectedStudent != null) {
                          selectedStudent!.accepted = choice;
                        }
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
      ),
    );
  }
}