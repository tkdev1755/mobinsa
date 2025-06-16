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
      
      //students.add(Student(name,choices));
    }
    
    return students;
  }

  static void parseSchools(Excel file){
    //Données Europe et Hors-Europe
    for(int eu=0; eu<2; eu++) {
      String sheetName = file.sheets.keys.toList()[eu];
      var sheet = file.sheets[sheetName];

      if (sheet == null || sheet.maxRows < 2) {
        // Ajouter une throw indiquant que le ficher n'as pas été parsé correctement
        return;
      }
      //Afficher la première colonne
      //int MAXCOLUMN = sheet.rows[0].length - 1;
      String? colData = sheet.rows[0][0]?.value.toString();
      int MAXCOLUMN = 1;
      while (colData != "" && colData != null){
        print(colData);
        colData = sheet.rows[0][MAXCOLUMN]?.value.toString();
        MAXCOLUMN++;
      }
      MAXCOLUMN--;
      /*for (int col = 0; col < MAXCOLUMN; col++) {
        String value = sheet.rows[0][col]?.value.toString() ?? "Problème 1ere colonne" ;
        stdout.write("$value; ");
      }*/
      print("");
      // Traiter chaque ligne à partir de la ligne 2 (index 1) qui contient les données
      for (int row = 1; row < sheet.maxRows; row++) {
        // Vérifiez si la ligne contient des données
        if (sheet.rows[row].isEmpty || sheet.rows[row][0] == null) continue;
        // Offre de séjour
        //String offre = sheet.rows[row][0]?.value.toString() ?? "Problème parsing";
        //print("Offre: $offre");
        for (int col = 0; col < MAXCOLUMN; col++) { //MAXCOLUMN YEAH
          String value = sheet.rows[row][col]?.value.toString() ?? "Problème parsing";
          stdout.write("$value; ");
        }
        print("");
      }
    }
  }
}

