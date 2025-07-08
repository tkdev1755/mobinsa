import 'dart:io';

import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobinsa/model/School.dart';
import 'package:mobinsa/model/parser.dart';
import 'package:mobinsa/model/Student.dart';
import 'package:mobinsa/model/versionManager.dart';
import 'package:mobinsa/view/assemblyPreview.dart';
import 'package:mobinsa/view/modalPages/saveDialog.dart';
import 'package:mobinsa/view/modalPages/updaterDialog.dart';
import 'package:mobinsa/view/uiElements.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  final PackageInfo packageInfo = await PackageInfo.fromPlatform();
  runApp(MyApp(pkgInfo: packageInfo,));
}



class MyApp extends StatelessWidget {
  final PackageInfo pkgInfo;
  const MyApp({super.key, required this.pkgInfo});
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Mob'INSA",
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
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.red),
        textTheme: GoogleFonts.montserratTextTheme()
      ),
      home: MyHomePage(title: "Bienvenue sur Mob'INSA", packageInfo: pkgInfo,),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title, required this.packageInfo});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;
  final PackageInfo packageInfo;
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
  late SoftwareUpdater softwareUpdater;
  late (int,int,int) currentVersion;
  late Future<bool> isUptoDate;

  Future<String?> pickFile() async {
    final result = await FilePicker.platform.pickFiles();
    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;

      return file.path;
    } else {
      print('Aucun fichier sélectionné');
    }
    return null;
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
  @override
  void initState() {
    softwareUpdater = SoftwareUpdater(widget.packageInfo);
    currentVersion = softwareUpdater.currentVersion;
    isUptoDate = softwareUpdater.isUpToDate();
    // TODO: implement initState
    super.initState();
  }



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
        title: Text(widget.title,style: UiText(color: UiColors.white, weight: FontWeight.w600).mediumText,),
        centerTitle: true,
        actions: [
          Text("Version ${currentVersion.$1}.${currentVersion.$2}.${currentVersion.$3}", style: UiText(color: UiColors.white).smallText,),
          Padding(padding: EdgeInsets.only(right: 20)),
          FutureBuilder(future: isUptoDate, builder: (BuildContext context, AsyncSnapshot<bool> snap){
            if (snap.hasData){
              return Visibility(
                visible: !(snap.data!),
                child: InkWell(
                  splashColor: Colors.green.shade400,
                  hoverColor: Colors.green.shade600,
                  hoverDuration: Duration(milliseconds: 200),
                  customBorder: RoundedRectangleBorder(
                    side:  BorderSide(
                      color: Colors.orange,
                      width: 4,
                      strokeAlign: 20
                    )
                  ),
                  borderRadius: BorderRadius.circular(12),
                  onTap: () async {
                    await softwareUpdater.isUpToDate();
                    // Future code to try and get the update
                    if (context.mounted){
                      showDialog(context: context, builder: (BuildContext context){
                        return UpdateDialog(softwareUpdater: softwareUpdater);
                      });
                    }
                  },
                  child: Padding(
                    padding: EdgeInsets.all(8),
                    child: Text(
                      "Une mise à jour est disponible ",
                      style: UiText(color: UiColors.white).smallText,
                    ),
                  ),
                ),
              );
            }
            else if (snap.hasError){
              return Text("Impossible de récupérer la dernière version");
            }
            else{
              return CircularProgressIndicator();
            }
          }),
          Padding(padding: EdgeInsets.only(right: 40))
        ],
      ),
      body: Stack(
        children: [
          Align(
            alignment: Alignment.bottomLeft,
            child: FractionalTranslation(
              translation: const Offset(-0.3, 0.3), // -0.1 => décalage à gauche, 0.2 => vers le bas
              child: Opacity(
                opacity: 0.03,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    double width = constraints.maxWidth * 0.25; // 25% de la largeur
                    return Icon(PhosphorIcons.globe(), size: MediaQuery.sizeOf(context).height*1.2,);
                  },
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                // Logo at the top-left of the body (not centered)


                const SizedBox(height: 24),

                // Center the content that follows but keep Column's crossAxisAlignment
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: 350), // Limit width for buttons
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Importez vos fichiers', style: UiText(weight: FontWeight.w500).nText,),
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
                                    } catch (e,s) {

                                      // Error extracting schools from Excel
                                      showErrorDialog(
                                          context,
                                          "Erreur d'analyse des écoles",
                                          "Impossible de lire les données des écoles: ${e.toString()} ${e.runtimeType != ExcelParsingException ? "\nDetail : \n ${s}" : ""}"
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
                            }, child: Text("Importez les écoles", style: UiText().nsText,),
                          ),
                          Padding(padding: EdgeInsets.only(bottom: 10)),
                          Visibility(visible: selectedFilenameSchools != null,child: Text("Fichier Choisi : $selectedFilenameSchools"),),
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
                              child: Text("Importez les étudiants", style: UiText().nsText,)
                          ),
                          Padding(padding: EdgeInsets.only(bottom: 10)),
                          Visibility(visible: selectedFilenameStudents != null,child: Text("Fichier Choisi : $selectedFilenameStudents"),),
                          Padding(padding: EdgeInsets.only(bottom: 10)),
                          ElevatedButton(
                              style: customButtonStyle,
                              onPressed: (schoolsLoaded && studentsLoaded) ? () {
                                students.sort((a,b) => b.get_max_rank().compareTo(a.get_max_rank()));
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => AssemblyPreview(students: students, schools: schools)),);
                              } : null,
                              child: Text("Génerer",style: UiText().nsText,)
                          ),
                          Padding(padding: EdgeInsets.only(bottom: 10)),
                          ElevatedButton(
                              style: customButtonStyle,
                              onPressed: () {
                                showDialog(context: context, builder: (context){
                                  return SaveDialog();
                                });

                              },
                              child: Text("Générer depuis une sauvegarde",style: UiText().nsText,)
                          )
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
