

import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart' as pp;
import 'School.dart';
import 'Student.dart';


/// Classe utilitaire pour la sérialisation et la désérialisation
/// des données liées aux `Student` et `School`.
/// Elle gère également la sauvegarde et le chargement de fichiers `.mbsave`.
class SessionStorage{
  /// Clé utilisée pour accéder à la liste des écoles dans la structure JSON.
  static String jsonSchoolName = "schools";

  /// Clé utilisée pour accéder à la liste des étudiants dans la structure JSON.
  static String jsonStudentName = "students";

  /// Nom du dossier dans lequel les sauvegardes sont enregistrées.
  static String saveFolder = "saves";

  /// Format de date utilisé pour nommer les fichiers de sauvegarde.
  static String dateFormat = "dd-MM-yyyy-HH.mm";

  /// Génère un nom de fichier de sauvegarde basé sur la date et l'heure actuelles.
  ///
  /// Retourne un `Future<String>` avec un nom comme `CRMob_19-06-2025-14.32.mbsave`.
  static Future<String> getSaveName() async{
    return "CRMob_${DateFormat(dateFormat).format(DateTime.now())}.mbsave";
  }

  /// Renvoie un chemin complet où sauvegarder le fichier avec le nom donné.
  ///
  /// Affiche l'emplacement choisi dans la console.
  ///
  /// [saveName] : Le nom du fichier à sauvegarder.
  ///
  /// Retourne un `Future<String>` avec le chemin complet.
  static Future<String> askForSavePath(String saveName) async {
    /*final result = await FilePicker.platform.saveFile(
      type: FileType.custom,
      allowedExtensions: ["mbsave"]
    );*/
    /*String result = await getSaveName();

    if (result == null){
      throw Exception("No path was specified");
    }
    String path = result;*/
    print("Fichier sauvegardé dans ${((await pp.getApplicationDocumentsDirectory()).path)}/$saveName");
    return "${(await pp.getApplicationDocumentsDirectory()).path}/$saveName";
  }

  /// Récupère les fichiers `.mbsave` présents dans le répertoire de sauvegarde.
  ///
  /// Retourne une liste de tuples `(chemin complet, nom du fichier)`
  static Future<List<(String,String)>> askForLoadPath() async {
    final result = (await pp.getApplicationDocumentsDirectory()).path;
    Directory saveFolder = Directory(result);
    List<FileSystemEntity> path = saveFolder.listSync();
    List<(String,String)> saves = [];
    saves = path.map((e) => ((e.path,e.path.split(Platform.isWindows ?  "\\":"/").last))).toList();
    saves = saves.where((e) => (e.$1.split(Platform.isWindows ?  "\\":"/").last.split(".").last == "mbsave") && (e.$2.split(".").last == "mbsave")).toList();
    return saves;
  }

  /// Sérialise les listes d’étudiants et d’écoles dans une structure JSON.
  ///
  /// Affiche des statistiques sur les étudiants acceptés ou refusés dans la console.
  ///
  /// [students] : Liste des objets `Student`.
  /// [schools] : Liste des objets `School`.
  ///
  /// Retourne une `Map<String, dynamic>` représentant les données prêtes à être sauvegardées.
  static Map<String, dynamic> serializeData(List<Student> students, List<School> schools){
    print("Stats about the file \n Currently ${students.where((e) => e.accepted != null).length} students have an accepted choice \n  and ${students.where((e) => e.refused.isNotEmpty).length} students have a refused choice");
    print("We currently have ${students.length} students and ${schools.length} schools ");
    Map<String, List<dynamic>> finalData = {"students" : [], "schools" : []};
    for (var student in students){
      finalData["students"]?.add(student.toJson());
    }
    for (var school in schools){
      finalData["schools"]?.add(school.toJson());
    }
    return finalData;

  }

  /// Enregistre les données sérialisées dans un fichier à l'emplacement donné.
  ///
  /// [data] : Données à enregistrer sous forme de `Map<String, dynamic>`.
  /// [path] : Chemin du fichier de sauvegarde.
  ///
  /// Retourne `1` si la sauvegarde a réussi.
  static int saveData(Map<String, dynamic> data,String path){
    File saveFile = File(path);
    if (!saveFile.existsSync()){
      saveFile.createSync();
    }
    print("Data resemble to $data");
    saveFile.writeAsStringSync(jsonEncode(data));
    return 1;
  }

  /// Charge les données d'un fichier de sauvegarde JSON.
  ///
  /// [path] : Chemin du fichier à charger.
  ///
  /// Retourne une `Map<String, dynamic>` contenant les données chargées.
  static Map<String,dynamic> loadData(String path){
    File saveFile = File(path);
    /*if (!saveFile.existsSync()){
      throw Exception("The path doesn't exist");
    }*/
    String data = saveFile.readAsStringSync();
    Map<String, dynamic> jsonData = jsonDecode(data);
    return jsonData;
  }

  /// Désérialise les données JSON en objets `Student` et `School`.
  ///
  /// [data] : Données JSON lues depuis un fichier.
  ///
  /// Retourne une `Map<String, List<dynamic>>` contenant les listes d’objets `students` et `schools`.
  ///
  /// Lance une exception si les clés requises sont absentes.
  static Map<String, List<dynamic>> deserializeData(Map<String,dynamic> data){
    List<Student> students = [];
    List<School> schools = [];
    if ((!data.containsKey(jsonStudentName)) || (!data.containsKey(jsonSchoolName)) ){
      throw Exception("404 - File doesn't have the required field to reconstruct the data");
    }
    print(data);
    List<dynamic> jsonSchools = data[jsonSchoolName];
    List<dynamic> jsonStudents = data[jsonStudentName];
    for (var entry in jsonSchools){
      schools.add(School.fromJson(entry));
    }
    School.setGlobalID(schools.length);
    int i = 0;
    for (var entry in jsonStudents){
      students.add(Student.fromJson(entry));
      print("Does this student have the accepted field : ${students[i].accepted}");
      i++;
    }
    print("Currently ${students.where((e) => e.accepted != null).length} Students has an acceptedChoice");
    print("Currently There is ${schools.length} schools - exact data is \n ${schools}");
    return {
      "schools" : schools,
      "students" : students,
    };
  }

}