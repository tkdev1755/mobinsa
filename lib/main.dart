import 'dart:io';

import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:mobinsa/model/School.dart';
import 'package:mobinsa/model/parser.dart';
import 'package:mobinsa/model/Student.dart';
import 'package:mobinsa/view/displayApplicants.dart';
import 'package:mobinsa/view/assemblyPreview.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<Student> students = [];
  List<School> schools = [];
  String? selectedFilenameSchools;
  String? selectedFilenameStudents;
  bool schoolsLoaded = false;
  bool studentsLoaded = false;  // Changed to false

  Future<String?> pickFile() async {
    final result = await FilePicker.platform.pickFiles();

    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;

      return file.path;
    } else {
      print('Aucun fichier sélectionné');
    }
  }

  void showErrorDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Keep your existing button style definition
    final ButtonStyle customButtonStyle = ElevatedButton.styleFrom(
      backgroundColor: Colors.grey[300],
      foregroundColor: Colors.black,
      minimumSize: const Size.fromHeight(60), // Just define height, not width
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 1,
    );

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        title: Text(widget.title),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Logo at the top-left of the body (not centered)
            Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                height: 100,
                child: Image.asset(
                  'assets/images/logo.jpg', // Correct file extension
                  fit: BoxFit.contain,
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Center the content that follows but keep Column's crossAxisAlignment
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: 350), // Limit width for buttons
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text('Importez vos fichiers'),
                      const SizedBox(height: 16),
                      
                      /// BOUTON POUR LES ECOLES
                      ElevatedButton(
                        style: customButtonStyle,
                        onPressed: () async {
                          String? filePath = await pickFile();
                          if (filePath != null) {
                            try {
                              setState(() {
                                if(Platform.isWindows){
                                  selectedFilenameSchools = filePath.split('\\').last;
                                } else {
                                  selectedFilenameSchools = filePath.split("/").last;
                                }
                              });
                              
                              // Try to parse Excel
                              try {
                                Excel schoolResult = SheetParser.parseExcel(filePath);
                                
                                // Try to extract schools
                                try {
                                  List<School> parsedSchools = SheetParser.parseSchools(schoolResult);
                                  setState(() {
                                    schools = parsedSchools;
                                    schoolsLoaded = schools.isNotEmpty;
                                  });
                                  
                                  // Show success message
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('${schools.length} écoles importées avec succès'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                } catch (e) {
                                  // Error extracting schools from Excel
                                  showErrorDialog(
                                    context, 
                                    "Erreur d'analyse des écoles", 
                                    "Impossible de lire les données des écoles: ${e.toString()}"
                                  );
                                }
                              } catch (e) {
                                // Error parsing Excel file
                                showErrorDialog(
                                  context, 
                                  "Erreur de format", 
                                  "Le fichier n'est pas un fichier Excel valide: ${e.toString()}"
                                );
                              }
                            } catch (e) {
                              // General error
                              showErrorDialog(context, "Erreur", e.toString());
                            }
                          }
                        }, child: Text("Importez les écoles"),
                      ),
                      Padding(padding: EdgeInsets.only(bottom: 10)),
                      Visibility(child: Text("Fichier Choisi : $selectedFilenameSchools"), visible: selectedFilenameSchools != null,),
                      Padding(padding: EdgeInsets.only(bottom: 10)),
                      /// BOUTON POUR LES ETUDIANTS
                      ElevatedButton(
                        style: customButtonStyle,
                        onPressed: schoolsLoaded ? () async {
                          String? filePath = await pickFile();
                          if (filePath != null) {
                            try {
                              setState(() {
                                if(Platform.isWindows){
                                  selectedFilenameStudents = filePath.split('\\').last;
                                } else {
                                  selectedFilenameStudents = filePath.split("/").last;
                                }
                              });
                              
                              // Try to parse Excel
                              try {
                                Excel studentsResult = SheetParser.parseExcel(filePath);
                                
                                // Try to extract students
                                try {
                                  List<Student> parsedStudents = SheetParser.extractStudents(studentsResult, schools);
                                  setState(() {
                                    students = parsedStudents;
                                    studentsLoaded = students.isNotEmpty;
                                  });
                                  
                                  // Show success message
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('${students.length} étudiants importés avec succès'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                } catch (e) {
                                  // Error extracting students from Excel
                                  showErrorDialog(
                                    context, 
                                    "Erreur d'analyse des étudiants", 
                                    "Impossible de lire les données des étudiants: ${e.toString()}"
                                  );
                                }
                              } catch (e) {
                                // Error parsing Excel file
                                showErrorDialog(
                                  context, 
                                  "Erreur de format", 
                                  "Le fichier n'est pas un fichier Excel valide: ${e.toString()}"
                                );
                              }
                            } catch (e) {
                              // General error
                              showErrorDialog(context, "Erreur", e.toString());
                            }
                          }
                        } : null,
                        child: Text("Importez les étudiants")
                      ),
                      Padding(padding: EdgeInsets.only(bottom: 10)),
                      Visibility(child: Text("Fichier Choisi : $selectedFilenameStudents"), visible: selectedFilenameStudents != null,),
                      Padding(padding: EdgeInsets.only(bottom: 10)),
                      ElevatedButton(
                        style: customButtonStyle,
                        onPressed: studentsLoaded ? () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => DisplayApplicants(
                              students: students,
                              schools: schools,  // Pass the schools list
                            )),
                          );
                        } : null,
                        child: Text("Page d'affichage"),
                      ),
                      Padding(padding: EdgeInsets.only(bottom: 10)),
                      ElevatedButton(
                        style: customButtonStyle,
                        onPressed: (schoolsLoaded && studentsLoaded) ? () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => AssemblyPreview(students: students, schools: schools)),);
                        } : null,
                        child: Text("Génerer")
                      )
                    ],
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
