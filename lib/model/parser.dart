import 'dart:io';

import 'package:excel/excel.dart';
import 'package:mobinsa/model/Student.dart';
import 'package:mobinsa/model/Choice.dart';
import 'package:mobinsa/model/School.dart';


class ExcelParsingException implements Exception {
  final String message;
  ExcelParsingException(this.message);
  @override
  String toString() => "ExcelParsingException: $message";
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



  static Excel parseExcel(String path){

    File newFile = File(path);
    if (newFile.existsSync()){
      Excel parsedData = Excel.decodeBytes(newFile.readAsBytesSync());
      Excel createdFile= Excel.createExcel();
      String? test;
      String test2 = test ?? "DUMN";
      // print(parsedData.sheets.values.firstOrNull?.rows[1]);
      // print("Decoded File sheets : ${parsedData.sheets}, $parsedData");
      // print("Decoded File  : ${parsedData.tables}");
      return parsedData;
    }
    else{
      throw Exception();
    }
  }


  // --- Méthode principale pour extraire les étudiants ---


  static List<Student> extractStudents(Excel excel) {
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
      School school = School(schoolName,"ds","",0,0,0,[],"","","","","");

      // Création de l'objet Choice (en passant l'instance de Student, comme défini dans votre classe Choice)
      Choice choice = Choice(school, interRanking, currentStudent);

      // Ajout du choix à la map de choix de l'étudiant
      currentStudent.choices[wishOrder] = choice;
    }
    // Conversion de la map des étudiants en une liste triée par ID
    List<Student> finalStudentList = tempStudentMap.values.toList();
    finalStudentList.sort((a, b) => a.id.compareTo(b.id));

    return finalStudentList;
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
        /*String name = sheet.rows[row][0]?.value.toString() ?? "PROBLEM NAME";
        String country = sheet.rows[row][1]?.value.toString() ?? "PROBLEM COUNTRY";
        String contract = sheet.rows[row][2]?.value.toString() ?? "PROBLEM CONTRACT_TYPE";
        int slots = int.parse(sheet.rows[row][3]?.value.toString() ?? "-1");
        int b_slots = int.parse(sheet.rows[row][4]?.value.toString() ?? "-1");
        int m_slots = int.parse(sheet.rows[row][5]?.value.toString() ?? "-1");
        String spez = sheet.rows[row][6]?.value.toString() ?? "PROBLEM SPECIALIZATION";
        List<String> specialization = specializationStringToList(spez);
        String graduation_level = sheet.rows[row][7]?.value.toString() ?? "PROBLEM GRADUATION_LEVEL";
        String program = sheet.rows[row][8]?.value.toString() ?? "PROBLEM PROGRAM";
        String use_language = sheet.rows[row][9]?.value.toString() ?? "PROBLEM USE_LANGUAGE";
        String req_lang_level = sheet.rows[row][10]?.value.toString() ?? "PROBLEM REQ_LANG_LEVEL";
        String academic_level = sheet.rows[row][11]?.value.toString() ?? "PROBLEM ACADEMIC_LEVEL";*/
        /*School school = School(
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
        ); */

        print("");
      }
    }
  }

  //transforme la colonne DISCIPLINE en une liste de STI 3A, STI 4A, MRI 3A, MRI 4A
  static List<String> specializationStringToList(String specialization){
    List<String> program = []; List<String> spez = [];
    for(String prog in ["ENP","ENR","GSI","MRI","STI","Paysagiste"]){
      if(specialization.contains(prog)) {
        program.add(prog);
      }
    }
    for(String yea in ["2A","3A","4A","5A"]){
      if(specialization.contains(yea)) {
        for(String prog in program){
          spez.add("$prog $yea"); //used interpolation, avoids concatenation (prog+" "+yea)
        }
      }
    }
    return spez;
  }
}







