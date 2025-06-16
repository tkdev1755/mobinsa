import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';



class DisplayApplicants extends StatefulWidget {
  const DisplayApplicants({Key? key}) : super(key: key);

  @override
  State<DisplayApplicants> createState() => _DisplayApplicantsState();
}

class _DisplayApplicantsState extends State<DisplayApplicants> {
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
              child: const Padding(
                padding: EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    // Contenu de la sidebar
                  ],
                ),
              ),
            ),
            // Contenu principal (80% de la largeur)
            Container(
              width: MediaQuery.of(context).size.width * 0.8,
              child: const Center(
                child: Text(
                  'Sélectionner un élève',
                  style: TextStyle(
                    fontSize: 24,
                    color: Colors.grey,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}