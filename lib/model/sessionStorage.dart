

import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart' as pp;
import 'School.dart';
import 'Student.dart';



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
    print("Fichier sauvegardé dans ${((await pp.getApplicationDocumentsDirectory()).path)}$saveFolder/$saveName");
    return "${(await pp.getApplicationDocumentsDirectory()).path}$saveFolder/$saveName";
  }

  static Future<List<(String,String)>> askForLoadPath() async {
    final result = "${(await pp.getApplicationDocumentsDirectory()).path}$saveFolder/";
    Directory saveFolderObj = Directory(result);
    if (!saveFolderObj.existsSync()){
      saveFolderObj.createSync(recursive: true);
    }
    List<FileSystemEntity> path = saveFolderObj.listSync();
    List<(String,String)> saves = [];
    saves = path.map((e) => ((e.path,e.path.split(Platform.isWindows ?  "\\":"/").last))).toList();
    saves = saves.where((e) => (e.$1.split(Platform.isWindows ?  "\\":"/").last.split(".").last == "mbsave") && (e.$2.split(".").last == "mbsave")).toList();
    saves.sort((a,b) => compareSaveFiles(b.$1, a.$2));
    return saves;
  }

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
  static int saveData(Map<String, dynamic> data,String path){
    File saveFile = File(path);
    if (!saveFile.existsSync()){
      saveFile.createSync();
    }
    print("Data resemble to $data");
    saveFile.writeAsStringSync(jsonEncode(data));
    return 1;
  }

  static Map<String,dynamic> loadData(String path){
    File saveFile = File(path);
    /*if (!saveFile.existsSync()){
      throw Exception("The path doesn't exist");
    }*/
    String data = saveFile.readAsStringSync();
    Map<String, dynamic> jsonData = jsonDecode(data);
    return jsonData;
  }

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

  static Future<(String,String)> loadExternalSave() async{
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ["mbsave"]
    );
    if (result?.files.first == null){
      throw Exception("The file doesn't exists");
    }
    String path = result!.files.first.path!;

    (String,String) saveInfo = (path,path.split(Platform.isWindows ?  "\\":"/").last); // (file path, name of the file for parsing it afterwards)
    return saveInfo;
  }


  static Future<String> exportSave((String,String) saveInfo) async{
    final result = await FilePicker.platform.saveFile(
      fileName: saveInfo.$2,

    );


    if (result == null){
      throw Exception("No path was specified");
    }
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