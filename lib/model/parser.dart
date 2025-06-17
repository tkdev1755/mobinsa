import 'dart:io';

import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:mobinsa/model/Student.dart';
import 'package:mobinsa/model/Choice.dart';
import 'package:mobinsa/model/School.dart';

/*


  16/06/2025@tahakhetib : J'ai apporté les modification suivantes
    - Mis à jour la fonction de Mehdi des étudiants pour récupérer l'école à partir d'un voeu
    - Corrigé la fonction de Max des
 */
class ExcelParsingException implements Exception {
  final String message;
  
  ExcelParsingException(this.message);
  
  @override
  String toString() {
    return message;
  }
}


class SheetParser{
  // --- Constantes pour les indices de colonnes (À AJUSTER SELON VOTRE FICHIER EXCEL) ---
  // Rappel : les indices sont 0-basés pour l'accès aux données de la ligne
  static const int _colStudentName = 0;     // Colonne 1 dans Excel
  static const int _colWishOrder = 1;       // Colonne 2
  static const int _colCountry = 2;         // Colonne 3
  static const int _colSchoolName = 3;      // Colonne 4
  static const int _colSpecialization = 4;  // Colonne 5
  static const int _colInterRanking = 5;    // Colonne 6
  static const int _colRankingS1 = 6;       // Colonne 7
  static const int _colEctsNumber = 7;      // Colonne 8
  static const int _colLangLvl = 8;         // Colonne 9
  static const int _colMissedHours = 9;     // Colonne 10
  static const int _colComment = 10;        // Colonne 11


  // --- Fonctions d'aide pour l'extraction sécurisée des données de cellules ---
  static String _getStringCellData(List<Data?> row, int colIndex, {String defaultValue = ""}) {
    if (colIndex < row.length && row[colIndex]?.value != null) {
      return row[colIndex]!.value.toString().trim();
    }
    return defaultValue;
  }

  static int _getIntCellData(List<Data?> row, int colIndex, {int defaultValue = 0}) {
    if (colIndex < row.length && row[colIndex]?.value != null) {
      return int.tryParse(row[colIndex]!.value.toString().trim()) ?? defaultValue;
    }
    return defaultValue;
  }

  static double _getDoubleCellData(List<Data?> row, int colIndex, {double defaultValue = 0.0}) {
    if (colIndex < row.length && row[colIndex]?.value != null) {
      return double.tryParse(row[colIndex]!.value.toString().trim()) ?? defaultValue;
    }
    return defaultValue;
  }



  static Excel parseExcel(String path) {
  try {
    File newFile = File(path);
    
    // Check if file exists
    if (!newFile.existsSync()) {
      throw ExcelParsingException("Le fichier n'existe pas");
    }
    
    // Check file extension
    String extension = path.split('.').last.toLowerCase();
    if (extension != "xlsx" && extension != "xls") {
      throw ExcelParsingException("Le fichier doit être au format Excel (.xlsx ou .xls)");
    }
    
    Excel parsedData = Excel.decodeBytes(newFile.readAsBytesSync());
    
    // Check if the parsed data is valid
    if (parsedData.sheets.isEmpty) {
      throw ExcelParsingException("Le fichier Excel ne contient aucune feuille");
    }
    
    return parsedData;
  } catch (e) {
    if (e is ExcelParsingException) {
      rethrow;
    }
    throw ExcelParsingException("Erreur lors de la lecture du fichier: ${e.toString()}");
  }
}




  // --- Méthode principale pour extraire les étudiants ---


  static List<Student> extractStudents(Excel excel, List<School> schools) {
  // Check if schools list is empty
  if (schools.isEmpty) {
    throw ExcelParsingException("La liste des écoles est vide. Importez d'abord les écoles.");
  }
  
  Map<String, Student> tempStudentMap = {};
    int nextStudentId=1;

    if (excel.sheets.isEmpty) {
      print("Information: Le fichier Excel ne contient aucune feuille.");

      return [];
    }
    String sheetName = excel.sheets.keys.first; // Prend la première feuille par défaut
    var sheet = excel.tables[sheetName]; // Utilisez .tables pour la nouvelle version de la lib excel

    if (sheet == null) {
      print("Erreur: La feuille '$sheetName' n'a pas pu être chargée ou n'existe pas dans les tables.");
      return [];
    }

    if (sheet.maxRows < 2) {
      print("Information: La feuille '$sheetName' contient moins de 2 lignes (pas de données ou juste l'en-tête).");
      return [];
    }
    // Itérer sur les lignes, en commençant par la deuxième (index 1) pour sauter l'en-tête
    for (int rowIndex = 1; rowIndex < sheet.maxRows; rowIndex++) {
      var rowData = sheet.row(rowIndex); // Récupère les données de la ligne actuelle

      // Vérification minimale : le nom de l'étudiant doit être présent
      String studentName = _getStringCellData(rowData, _colStudentName);
      if (studentName.isEmpty) {
        // print("Ligne ${rowIndex + 1}: Nom de l'étudiant manquant, ligne ignorée.");
        continue; // Passer à la ligne suivante
      }

      // --- Récupération/Création de l'objet Student ---
      Student currentStudent;
      if (!tempStudentMap.containsKey(studentName)) {
        // Nouvel étudiant : lire ses informations spécifiques et le créer
        String specialization = _getStringCellData(rowData, _colSpecialization, defaultValue: "Non spécifiée");
        int rankingS1 = _getIntCellData(rowData, _colRankingS1);
        int ectsNumber = _getIntCellData(rowData, _colEctsNumber);
        String langLvl = _getStringCellData(rowData, _colLangLvl, defaultValue: "N/A");
        double missedHours = _getDoubleCellData(rowData, _colMissedHours);
        String comment = _getStringCellData(rowData, _colComment);
        // Lire d'autres champs de Student si nécessaire (post_comment, etc.)
        // String? postComment = _getStringCellData(rowData, _colPostComment, defaultValue: null); // Exemple

        currentStudent = Student(
            nextStudentId,
            studentName,
            {}, // Initialiser avec une Map de choix vide
            specialization,
            rankingS1,
            ectsNumber,
            langLvl,
            missedHours,
            comment
          // post_comment: postComment, // Si vous avez ce champ et l'avez lu
        );
        tempStudentMap[studentName] = currentStudent;
        nextStudentId++;
      } else {
        // Étudiant existant : le récupérer
        currentStudent = tempStudentMap[studentName]!;
        // Optionnel : mettre à jour des informations de l'étudiant si elles sont plus complètes
        // sur cette ligne, mais attention à ne pas écraser des données valides.
        // Exemple : si la spécialisation était "Non spécifiée" et qu'on en trouve une :
        if (currentStudent.specialization == "Non spécifiée") {
          String newSpecialization = _getStringCellData(rowData, _colSpecialization, defaultValue: "Non spécifiée");
          if (newSpecialization != "Non spécifiée") {
            currentStudent.specialization = newSpecialization;
            currentStudent.year_departement(newSpecialization); // Mettre à jour année/département
          }
        }
      }

      // --- Traitement du Vœu pour l'étudiant actuel ---
      String rawWishOrder = _getStringCellData(rowData, _colWishOrder);
      String country = _getStringCellData(rowData, _colCountry);
      String schoolName = _getStringCellData(rowData, _colSchoolName);
      String rawInterRanking = _getStringCellData(rowData, _colInterRanking);

      // Un vœu nécessite au moins un ordre, un nom d'école et un pays
      if (rawWishOrder.isEmpty || schoolName.isEmpty || country.isEmpty || rawInterRanking.isEmpty) {
        // print("Ligne ${rowIndex + 1} pour ${studentName}: Données de vœu incomplètes, vœu ignoré.");
        continue; // Passer si les informations essentielles du vœu sont manquantes
      }

      int? wishOrder = int.tryParse(rawWishOrder);
      double? interRanking = double.tryParse(rawInterRanking); // Votre Choice utilise double

      if (wishOrder == null || interRanking == null) {
        // print("Ligne ${rowIndex + 1} pour ${studentName}: Format numérique invalide pour l'ordre du vœu ou interRanking, vœu ignoré.");
        continue;
      }

      // Création de l'objet School
      School? school = schools.where((e) => e.name == schoolName).firstOrNull;
      if (school == null){
        print("The schools doesn't appear in the list of parsed school");
        return [];
      }
      // Création de l'objet Choice (en passant l'instance de Student, comme défini dans votre classe Choice)
      Choice choice = Choice(school, interRanking, currentStudent);

      // Ajout du choix à la map de choix de l'étudiant
      currentStudent.choices[wishOrder] = choice;
    }
    // Conversion de la map des étudiants en une liste triée par ID
    List<Student> finalStudentList = tempStudentMap.values.toList();
    finalStudentList.sort((a, b) => a.id.compareTo(b.id));

    // Add verification at specific points, for example:
    if (tempStudentMap.isEmpty) {
      throw ExcelParsingException("Aucun étudiant n'a été trouvé dans le fichier");
    }
    
    // Check if any student has no choices
    for (var student in tempStudentMap.values) {
      if (student.choices.isEmpty) {
        throw ExcelParsingException("L'étudiant ${student.name} n'a aucun choix d'école");
      }
    }
    
    return finalStudentList;
  }

  static List<School> parseSchools(Excel file) {
    List<School> schools = [];
    
    // Basic validation for file structure
    if (file.sheets.length < 2) {
      throw ExcelParsingException("Le fichier des écoles doit contenir au moins deux feuilles (Europe et Hors-Europe)");
    }
    
    //Données Europe et Hors-Europe
    for(int eu=0; eu<2; eu++) {
      String sheetName = file.sheets.keys.toList()[eu];
      var sheet = file.sheets[sheetName];

      if (sheet == null || sheet.maxRows < 2) {
        // Ajouter une throw indiquant que le ficher n'as pas été parsé correctement
        return [];
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
        //VERSION DU TABLEUR
        int version = 2;
        if(version==2) {
          String name = sheet.rows[row][0]?.value.toString() ?? "PROBLEM NAME";
          String country = sheet.rows[row][1]?.value.toString() ??
              "PROBLEM COUNTRY";
          String contract = sheet.rows[row][2]?.value.toString() ??
              "PROBLEM CONTRACT_TYPE";
          int slots = int.parse(sheet.rows[row][3]?.value.toString() ?? "-1");
          int b_slots = int.parse(sheet.rows[row][4]?.value.toString() ?? "-1");
          int m_slots = int.parse(sheet.rows[row][5]?.value.toString() ?? "-1");
          List<String> specialization = specializationStringToList(
              sheet.rows[row][6]?.value.toString() ?? "PROBLEM SPECIALIZATION");
          String graduation_level = sheet.rows[row][7]?.value.toString() ??
              "PROBLEM GRADUATION_LEVEL";
          String program = sheet.rows[row][8]?.value.toString() ??
              "PROBLEM PROGRAM";
          String use_language = sheet.rows[row][9]?.value.toString() ??
              "PROBLEM USE_LANGUAGE";
          String req_lang_level = sheet.rows[row][10]?.value.toString() ??
              "PROBLEM REQ_LANG_LEVEL";
          String academic_level = sheet.rows[row][11]?.value.toString() ??
              "PROBLEM ACADEMIC_LEVEL";
          School school = School(
              name,
              country,
              contract,
              slots,
              b_slots,
              m_slots,
              specialization,
              graduation_level,
              program,
              use_language,
              req_lang_level,
              academic_level
          );
          schools.add(school);
        }
        if(version==1) {
          String name = sheet.rows[row][0]?.value.toString() ?? "PROBLEM NAME";
          String country = sheet.rows[row][1]?.value.toString() ??
              "PROBLEM COUNTRY";
          String contract = sheet.rows[row][2]?.value.toString() ??
              "PROBLEM CONTRACT_TYPE";
          int slots = int.parse(sheet.rows[row][3]?.value.toString() ?? "-1");
          int b_slots = slots;
          int m_slots = slots;
          List<String> specialization = specializationStringToList(
              sheet.rows[row][5]?.value.toString() ?? "PROBLEM SPECIALIZATION");
          String graduation_level = sheet.rows[row][6]?.value.toString() ??
              "PROBLEM GRADUATION_LEVEL";
          String program = sheet.rows[row][7]?.value.toString() ??
              "PROBLEM PROGRAM";
          String use_language = sheet.rows[row][8]?.value.toString() ??
              "PROBLEM USE_LANGUAGE";
          String req_lang_level = sheet.rows[row][9]?.value.toString() ??
              "PROBLEM REQ_LANG_LEVEL";
          String academic_level = sheet.rows[row][10]?.value.toString() ??
              "PROBLEM ACADEMIC_LEVEL";
          School school = School(
              name,
              country,
              contract,
              slots,
              b_slots,
              m_slots,
              specialization,
              graduation_level,
              program,
              use_language,
              req_lang_level,
              academic_level
          );
          schools.add(school);
        }
        print("");
      }
    }
    print("LES SCHOOLS: $schools");
    print("Normalemennt MONS:");
    print(schools[5].name);print(schools[5].country);print(schools[5].content_type);print(schools[5].specialization);
    
    if (schools.isEmpty) {
      throw ExcelParsingException("Aucune école n'a été trouvée dans le fichier");
    }
    
    return schools;
  }

  //transforme la colonne DISCIPLINE en une liste de STI 3A, STI 4A, MRI 3A, MRI 4A
  static List<String> specializationStringToList(String specialization){
    List<String> spez = [];
    List<String> substrings = specialization.split("+");
    for(String substring in substrings) {
      List<String> program = [];
      for (String prog in ["ENP", "ENR", "GSI", "MRI", "STI"]) {
        if (substring.contains(prog)) {
          program.add(prog);
          print(prog + " DETECTÉ");
        }
      }
      for (String yea in ["2A", "3A", "4A", "5A"]) {
        if (substring.contains(yea)) {
          print(yea + " DETECTÉ");
          for (String prog in program) {
            spez.add(
                "$prog $yea"); //used interpolation, avoids concatenation (prog+" "+yea)
          }
        }
      }
    }
    return spez;
  }
  static List<int> exportResult(List<Student> students, List<School> schools){
    Map<int,String> indexes = {
      0 : "Nom",
      1 : "Voeu",
      2 : "Pays",
      3 : "Etablissement",
      4 : "Département",
      5 : "Interclassement",
      6 : "Nb ECTS",
      7 : "Niveau Anglais",
      8 : "Absences",
      9 : "Nbre de Places",
      10 : "Commentaires",
      11 : "Commentaires post-jury"
    };
    const studentNameColumn = (0,"Nom");
    const studentWishColumn = (1,"Voeu");
    const studentCountryColumn = (2,"Pays");
    const studentSchoolColumn = (3,"Etablissement");
    const studentDepartmentColumn = (4,"Département");
    const studentInterRankingColumn = (5,"Interclassement");
    const studentCreditsColumn = (6,"Nb ECTS");
    const studentEngLVLColumn = (7,"Niveau Anglais");
    const studentMissedHoursColumn = (8,"Absences");
    const studentPlacesColumn = (9,"Nbre de Places");
    const studentCommentColumn = (10,"Commentaire");
    const studentAfterCommentColumn = (11,"Commentaire post-jury");

    List<(int,int,Choice)> allChoices = [];
    for (var s in students){
      for (var c in s.choices.entries){
       allChoices.add((s.id, c.key,c.value));
      }
    }
    allChoices.sort((a,b) => b.$3.interranking.compareTo(a.$3.interranking));
    Excel exportedExcel = Excel.createExcel();
    Sheet resultSheet = exportedExcel.sheets["Sheet1"]!;
    // Colonne N°1 : Ajoute le nom des étudiants
    List<CellValue?> test = [];
    for (int i = 0; i < 12; i++){
      resultSheet.insertColumn(i);
      CellValue value = TextCellValue(indexes[i]!);
      test.add(value);
    }
    resultSheet.appendRow(test);
    int i = 0;
    for (var c in allChoices){
      List<CellValue?> studentValues = [];
      Choice currentChoice = c.$3;
      Student? currentStudent = students.where((e) => e.id == c.$1).firstOrNull;
      if (currentStudent == null){
        throw Exception("The current student doesn't exist ????");
      }
      int choiceNumber = c.$2;
      TextCellValue studentName = TextCellValue(currentStudent.name);
      IntCellValue studentWish = IntCellValue(choiceNumber);
      TextCellValue studentCountry = TextCellValue(currentChoice.school.country);
      TextCellValue studentSchool = TextCellValue(currentChoice.school.name);;
      TextCellValue studentDepartment = TextCellValue(currentChoice.student.departement);
      DoubleCellValue studentInterRanking = DoubleCellValue(currentChoice.interranking);;
      IntCellValue studentCredits = IntCellValue(currentChoice.student.ects_number);
      TextCellValue studentEngLVL = TextCellValue(currentChoice.student.lang_lvl);
      DoubleCellValue studentMissedHours = DoubleCellValue(currentChoice.student.missed_hours);
      IntCellValue studentPlaces = IntCellValue(currentChoice.school.available_slots);
      TextCellValue studentComment = TextCellValue(currentChoice.student.comment);
      TextCellValue studentAfterComment = TextCellValue(currentChoice.student.post_comment ?? " - ");
      studentValues = [
        studentName,
        studentWish,
        studentCountry,
        studentSchool,
        studentDepartment,
        studentInterRanking,
        studentCredits,
        studentEngLVL, studentMissedHours,studentPlaces, studentComment,studentAfterComment];
      resultSheet.appendRow(studentValues);
      List<Data?> currentRow = resultSheet.row(i+1);
      print("Right now student has the following wish accepted ${currentStudent.accepted_school}");
      if ( currentStudent.accepted != null &&  currentStudent.accepted!.school.id == c.$3.school.id
      ){
        print("The voeux was accepted ! Painting it in green");
        for (var data in currentRow){
          data!.cellStyle = CellStyle(
            backgroundColorHex: ExcelColor.green200
          );
        }
      }
      i++;
    }
    return exportedExcel.save() ?? [];



    return [];
  }

  static int saveExcelToDisk(String path, List<int> bytes){
    File excelFile = File("$path");
    excelFile.createSync();
    excelFile.writeAsBytes(bytes);
    return 1;
  }
}







