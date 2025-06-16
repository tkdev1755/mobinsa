import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';



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
  final List<String> choices = [
    "Choix 1",
    "Choix 2",
    "Choix 3",
  ];
  Map<String, String>? selectedStudent;

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
                          // TODO: Gérer la sélection de l'étudiant
                          setState(() {
                            selectedStudent = students[index];
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
              child: selectedStudent != null ? Column(
                children: [
                  // Section nom/prénom/promo
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${selectedStudent!['prenom']} ${selectedStudent!['nom']}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${selectedStudent!['promo']}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Section Choix (gauche)
                      Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16.0),
                        color: Colors.grey[100],
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Choix',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              height: 200, // Hauteur fixe
                              child: ListView.builder(
                                itemCount: choices.length,
                                itemBuilder: (context, index) {
                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 8.0),
                                    child: ListTile(
                                      title: Text(choices[index]),
                                      onTap: () {
                                        // TODO: Gérer la sélection du choix
                                      },
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                      
                      // Sections droite
                      Expanded(
                        child: Column(
                          children: [
                            // Section Infos perso
                            Container(
                              padding: const EdgeInsets.all(16.0),
                              color: Colors.grey[100],
                              child: const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Infos perso',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            // Section boutons
                            Container(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  ElevatedButton(
                                    onPressed: () {},
                                    child: const Text('Previous'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () {},
                                    child: const Text('Commenter'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () {},
                                    child: const Text('Next'),
                                  ),
                                ],
                              ),
                          ),
                         ],
                      ),
                     ),
                   ],
                 ),
               ],
             ) : const Center(child: Text("Sélectionnez un étudiant")),
           ),
         ],
        ),
      ),
    );
  }
}