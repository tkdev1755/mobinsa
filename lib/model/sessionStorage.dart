

import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:mobinsa/model/versionManager.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart' as pp;
import 'School.dart';
import 'Student.dart';

/// Fichier traité au niveau des commentaires

class SessionStorage{
  static String jsonSchoolName = "schools";
  static String jsonStudentName = "students";
  static String saveFolder = "/mobinsa/saves";
  static String dateFormat = "dd-MM-yyyy-HH.mm";
  static Future<String> getSaveName() async{
    return "CRMob_${DateFormat(dateFormat).format(DateTime.now())}.mbsave";
  }

  static int compareSaveFiles(String filename_a, filename_b){

    List<String> splitFilename_a = filename_a.split("_").toList();
    List<String> splitFilename_b = filename_b.split("_").toList();
    if (splitFilename_a.length < 2 || splitFilename_b.length < 2){
      return -1;
    }
    String strDate_a = splitFilename_a[1];
    String strDate_b = splitFilename_b[1];
    DateTime date_a = DateFormat(SessionStorage.dateFormat).parse(strDate_a);
    DateTime date_b = DateFormat(SessionStorage.dateFormat).parse(strDate_b);
    return date_a.compareTo(date_b);
  }

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
    // Retourne le chemin du fichier de sauvegarde
    return "${(await pp.getApplicationDocumentsDirectory()).path}$saveFolder/$saveName";
  }

  static Future<List<(String,String)>> askForLoadPath() async {
    // Charge le dossier où sont stockées les sauvegarde
    final result = "${(await pp.getApplicationDocumentsDirectory()).path}$saveFolder/";

    Directory saveFolderObj = Directory(result);
    if (!saveFolderObj.existsSync()){
      saveFolderObj.createSync(recursive: true);
    }
    // Ouverture du dossier pour regarder ce qu'il y a dedans, à la manière de dirent() en C
    List<FileSystemEntity> path = saveFolderObj.listSync();

    // Liste contenant des tuples de String, la première entrée contient le chemin, et la seconde contient les
    List<(String,String)> saves = [];
    // J'extrait les noms des fichiers de la liste des éléments disponibles dans le dossier pour plus tard les affichers
    saves = path.map((e) => ((e.path,e.path.split(Platform.isWindows ?  "\\":"/").last))).toList();
    // Je filtre la liste de telle manière à n'avoir que des fichiers qui sont du type .mbsave
    saves = saves.where((e) => (e.$1.split(Platform.isWindows ?  "\\":"/").last.split(".").last == "mbsave") && (e.$2.split(".").last == "mbsave")).toList();
    // Je trie les fichiers par le fichier le plus récent à l'aide de la fonction compareSaveFiles
    saves.sort((a,b) => compareSaveFiles(b.$1, a.$2));
    // Je retourne la liste de sauvegardes
    return saves;
  }

  static Future<Map<String, dynamic>> serializeData(List<Student> students, List<School> schools) async{
    // Ajout de l'attribut version au dictionnaire
    SoftwareUpdater softwareUpdater = SoftwareUpdater(await PackageInfo.fromPlatform());
    //print("Stats about the file \n Currently ${students.where((e) => e.accepted != null).length} students have an accepted choice \n  and ${students.where((e) => e.refused.isNotEmpty).length} students have a refused choice");
    //print("We currently have ${students.length} students and ${schools.length} schools ");
    // Je prépare le dictionnaire qui contient notre structure de donnée avec les étudiants d'un côté et les écoles d'un côté
    Map<String, dynamic> finalData = {"students" : [], "schools" : [], "version" : softwareUpdater.toString()};
    // Je sérialise chaque étudiant et l'ajoute à la liste des étudiants sérialisée
    for (var student in students){
      finalData["students"]?.add(student.toJson());
    }
    // Je sérialise chaque école et l'ajoute à la liste des écoles sérialisée

    for (var school in schools){
      finalData["schools"]?.add(school.toJson());
    }
    // Je retourne le dictionnaire avec les données sérialisée
    return finalData;
  }
  static int saveData(Map<String, dynamic> data,String path){
    File saveFile = File(path);
    // Je vérifie si le fichier existe, autrement dit je le crée
    if (!saveFile.existsSync()){
      saveFile.createSync();
    }

    print("Data resemble to $data");
    // J'écrit ensuite directement le dictionnaire sous forme de chaine de caractère dans le fichier
    saveFile.writeAsStringSync(jsonEncode(data));
    return 1;
  }

  static Map<String,dynamic> loadData(String path){
    File saveFile = File(path);
    /*if (!saveFile.existsSync()){
      throw Exception("The path doesn't exist");
    }*/
    // Je lit directement le contenu du fichier en tant que chaine de caractère
    String data = saveFile.readAsStringSync();
    // Je converti la String en dictionnaire sérialisé
    Map<String, dynamic> jsonData = jsonDecode(data);
    return jsonData;
  }

  static Map<String, List<dynamic>> deserializeData(Map<String,dynamic> data){

    List<Student> students = [];
    List<School> schools = [];
    // je m'assure de l'existence des clés que je recherche pour désérialiser mes données
    if ((!data.containsKey(jsonStudentName)) || (!data.containsKey(jsonSchoolName))){
      throw Exception("404 - File doesn't have the required fields to reconstruct the data");
    }
    if (!data.containsKey("version")){
      print("Save from 1.0.0, loading it as it causes no crashes");
    }
    print(data);

    List<dynamic> jsonSchools = data[jsonSchoolName];
    List<dynamic> jsonStudents = data[jsonStudentName];
    // Je désérialise chaque école
    for (var entry in jsonSchools){
      schools.add(School.fromJson(entry));
    }
    // Je réajuste l'ID global des écoles en cas d'ajout d'une nouvelle école
    School.setGlobalID(schools.length);
    int i = 0;
    // Je refait la même chose pour les étudiants
    for (var entry in jsonStudents){
      students.add(Student.fromJson(entry,schools));
      i++;
    }
    /*print("Currently ${students.where((e) => e.accepted != null).length} Students has an acceptedChoice");
    print("Currently There is ${schools.length} schools - exact data is \n ${schools}");*/

    // Je retourne ensuite les données désérialisées
    return {
      "schools" : schools,
      "students" : students,
    };
  }

  static Future<(String,String)> loadExternalSave() async{
    // Je fait aparaitre le sélecteur de fichiers
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ["mbsave"]
    );

    // Si l'utilisateur n'as sélectionné aucun fichier, je lance une exception pour arrêter le traitement par le logiciel
    if (result?.files.first == null){
      throw Exception("The file doesn't exists");
    }
    // j'extrait le chemin du fichier sélectionné
    String path = result!.files.first.path!;

    // j'extrait les données du fichier pour les utiliser lors du chargement de la sauvegarde
    (String,String) saveInfo = (path,path.split(Platform.isWindows ?  "\\":"/").last); // (file path, name of the file to parse it afterwards)
    return saveInfo;
  }


  static Future<String> exportSave((String,String) saveInfo) async{
    // Je fais apparaitre un sélecteur de fichier avec le nom de la sauvegarde comme nom de fichier à enregistrer par défaut
    final result = await FilePicker.platform.saveFile(
      fileName: saveInfo.$2,
    );

    if (result == null){
      throw Exception("No path was specified");
    }
    // Enregistrement du fichier dans le système de fichier
    String path = result;
    File saveFile = File(saveInfo.$1);
    File exportedFile = File(path);
    saveFile.copySync(path);
    return path;
  }

  static String deleteSave((String,String) saveInfo){
    File saveFile = File(saveInfo.$1);
    if (saveFile.existsSync()){
      saveFile.deleteSync();
    }
    return saveInfo.$1;
  }
}