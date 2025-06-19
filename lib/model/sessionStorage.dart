

import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart' as pp;
import 'School.dart';
import 'Student.dart';



class SessionStorage{
  static String jsonSchoolName = "schools";
  static String jsonStudentName = "students";
  static String saveFolder = "saves";

  static String dateFormat = "dd-MM-yyyy-HH.mm";
  static Future<String> getSaveName() async{
    return "CRMob_${DateFormat(dateFormat).format(DateTime.now())}.mbsave";
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
    print("Fichier sauvegardé dans ${((await pp.getApplicationDocumentsDirectory()).path)}/$saveName");
    return "${(await pp.getApplicationDocumentsDirectory()).path}/$saveName";
  }

  static Future<List<(String,String)>> askForLoadPath() async {
    final result = (await pp.getApplicationDocumentsDirectory()).path;
    Directory saveFolder = Directory(result);
    List<FileSystemEntity> path = saveFolder.listSync();
    List<(String,String)> saves = [];
    saves = path.map((e) => ((e.path,e.path.split(Platform.isWindows ?  "\\":"/").last))).toList();
    saves = saves.where((e) => (e.$1.split(Platform.isWindows ?  "\\":"/").last.split(".").last == "mbsave") && (e.$2.split(".").last == "mbsave")).toList();
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

}