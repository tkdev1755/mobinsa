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
  bool studentsLoaded = false;

  Future<String?> pickFile() async {
    final result = await FilePicker.platform.pickFiles();

    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;

      return file.path;
    } else {
      print('Aucun fichier sélectionné');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(

        child: Column(

          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('Importez vos fichiers'),
            Padding(padding: EdgeInsets.only(bottom: 10)),
            /// BOUTON POUR LES ECOLES
            ElevatedButton(onPressed: () async {
              String? filePath = await pickFile();
              if (filePath != null){
                setState(() {
                  if(Platform.isWindows){
                    selectedFilenameSchools = filePath.split('\\').last;
                  }else{
                    selectedFilenameSchools = filePath.split("/").last;
                  }
                  
                });
                //Afficher les écoles dans la console
                Excel schoolResult = SheetParser.parseExcel(filePath);
                schools = SheetParser.parseSchools(schoolResult);
                schoolsLoaded = schools.isNotEmpty;
                setState(() {

                });
              }
              }, child: Text("Importez les écoles"),
            ),
            Padding(padding: EdgeInsets.only(bottom: 10)),
            Visibility(child: Text("Fichier Choisi : $selectedFilenameSchools"), visible: selectedFilenameSchools != null,),
            Padding(padding: EdgeInsets.only(bottom: 10)),
            /// BOUTON POUR LES ETUDIANTS
            ElevatedButton(
              onPressed: schoolsLoaded ? () async {
                String? filePath = await pickFile();
                if (filePath != null){
                  if(Platform.isWindows){
                    selectedFilenameStudents = filePath.split('\\').last;
                  }else{
                    selectedFilenameStudents = filePath.split("/").last;
                  }
                  
                  Excel studentsResult = SheetParser.parseExcel(filePath);
                  if (!schoolsLoaded){
                    return;
                  }
                  try {
                    students = SheetParser.extractStudents(studentsResult,schools);
                    studentsLoaded = students.isNotEmpty;
                    for (var student in students) {
                      print(student);
                    }
                    setState(() {

                    });
                  } catch (e, s) {
                    print(s);
                  }
                  // Afficher les étudiants dans la console

                }
                else{
                  print("Aucun fichier sélectionné");
                }
              } : null,
              child: Text("Importez les étudiants")
            ),
            Padding(padding: EdgeInsets.only(bottom: 10)),
            Visibility(child: Text("Fichier Choisi : $selectedFilenameStudents"), visible: selectedFilenameStudents != null,),
            Padding(padding: EdgeInsets.only(bottom: 10)),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => DisplayApplicants(schools: schools,students: students,)),
                );
              },
              child: Text("Page d'affichage"),
            ),
            Padding(padding: EdgeInsets.only(bottom: 10)),
            ElevatedButton(
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
    );
  }
}
