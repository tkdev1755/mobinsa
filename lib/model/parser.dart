import 'dart:io';

import 'package:excel/excel.dart';
import 'package:mobinsa/model/Student.dart';

class SheetParser{


  static Excel parseExcel(String path){

    File newFile = File(path);
    if (newFile.existsSync()){
      Excel parsedData = Excel.decodeBytes(newFile.readAsBytesSync());
      Excel createdFile= Excel.createExcel();
      String? test;
      String test2 = test ?? "DUMN";
      print(parsedData.sheets.values.firstOrNull?.rows[1]);
      print("Decoded File sheets : ${parsedData.sheets}, $parsedData");
      print("Decoded File  : ${parsedData.tables}");
      return parsedData;
    }
    else{
      throw Exception();
    }
  }

  static List<Student> extractStudents(String path) {
    List<Student> students = [];
    Excel excel = parseExcel(path);
    
    // Supposons que les données sont dans la première feuille
    String sheetName = excel.sheets.keys.first;
    var sheet = excel.sheets[sheetName];
    
    if (sheet == null || sheet.maxRows < 2) {
      return students;
    }
    
    // Traiter chaque ligne à partir de la ligne 2 (index 1) qui contient les données
    for (int row = 1; row < sheet.maxRows; row++) {
      // Vérifiez si la ligne contient des données
      if (sheet.rows[row].isEmpty || sheet.rows[row][0] == null) continue;
      
      // Le nom de l'étudiant 
      String name = sheet.rows[row][0]?.value.toString() ?? "Inconnu";
      
    //voeux 
      List<String> choices = [];
      for (int col = 2; col < 4; col++) {
        if (sheet.rows[row].length > col && sheet.rows[row][col] != null) {
          var choice = sheet.rows[row][col]?.value.toString();
          if (choice != null && choice.isNotEmpty) {
            choices.add(choice);
          }
        }
      }
      
      students.add(Student(name,choices));
    }
    
    return students;
  }
}

