import 'dart:io';

import 'package:excel/excel.dart';
import 'package:mobinsa/model/Student.dart';
import 'package:mobinsa/model/Choice.dart';
import 'package:mobinsa/model/School.dart';

/*


  16/06/2025@tahakhetib : J'ai apporté les modification suivantes
    - Mis à jour la fonction de Mehdi des étudiants pour récupérer l'école à partir d'un voeu
 */
class ExcelParsingException implements Exception {
  final String message;
  final String? stackTrace;
  ExcelParsingException(this.message, {this.stackTrace});
  
  @override
  String toString() {
    return message;
  }
}


class SheetParser{
  // --- Constantes pour les indices de colonnes du Excel des étudiants (À AJUSTER SELON VOTRE FICHIER EXCEL) ---
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

  // --- Constantes pour les indices des colonnes du Excel des écoles (A adapter si le fichier Ecoles venait à changer) ---
  // Ici un S à été ajouté avant le "nom" de la colonne pour éviter des conflits avec les constantes définies précédemment
  // Si une colonne à changé d'emplacement
  static const int _colSOfferName = 0;      // Colonne 1 dans Excel -> Colonne "OFFRE DE SEJOUR"
  static const int _colSCountry = 1;        // Colonne 2 -> Colonne "PAYS"
  static const int _colSContentType = 2;    // Colonne 3 -> Colonne "CADRE"
  static const int _colSSlots = 3;          // Colonne 4 -> Colonne "Places en 20**/20**"
  static const int _colSBachelorSlots = 4;  // Colonne 5 -> Colonne "Places Bachelor"
  static const int _colSMasterSlots = 5;    // Colonne 6 -> Colonne "Places Master"
  static const int _colSSpecialization= 6;  // Colonne 7 -> Colonne "DISCIPLINE"
  static const int _colSGraduation = 7;     // Colonne 8 -> Colonne "Niveau"
  static const int _colSProgram = 8;        // Colonne 9 -> Colonne "FORMATION"
  static const int _colSLangage = 9;        // Colonne 10 -> Colonne "Langue d'enseignement"
  static const int _colSLangLvl = 10;       // Colonne 11 -> Colonne "Niveau langue"
  static const int _colSAcademicLvl = 10;   // Colonne 11 -> Colonne "Niveau Académique"


  // --- Fonctions d'aide pour l'extraction sécurisée des données de cellules ---
  static String _getStringCellData(List<Data?> row, int colIndex, {String defaultValue = ""}) {
    if (colIndex < row.length && row[colIndex]?.value != null) {
      return row[colIndex]!.value.toString().trim();
    }
    return defaultValue;
  }

  static int _getIntCellData(List<Data?> row, int colIndex, {int defaultValue = 0}) {
    if (colIndex < row.length && row[colIndex]?.value != null) {
      if (row[colIndex]!.value.runtimeType == FormulaCellValue){
        //FormulaCellValue? value = row[colIndex]!.value as FormulaCellValue;
        throw Exception("Formulaes aren't supported rn");
        //print(value.formula);
      }
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
      }
      else {
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
      School? school = schools.where((e) => e.name.contains(schoolName)).firstOrNull;
      if (school == null){
        // On jette un exception si l'école n'est pas repertoriée dans le fichier excel
        throw ExcelParsingException("L'école ${schoolName} ne semble pas être répertoriée au sein du fichier école \nDétail : Ligne ${rowIndex+1} du fichier étudiants, Etudiant : ${studentName}");
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
    for (var student in finalStudentList){
      student.sortChoices();
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
        throw ExcelParsingException("Il semble que le fichier passé n'est pas lisible");
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
        /*for (int col = 0; col < MAXCOLUMN; col++) { //MAXCOLUMN YEAH
          String value = sheet.rows[row][col]?.value.toString() ?? "Problème parsing";
          stdout.write("$value; ");
        }*/
        //VERSION DU TABLEUR
        int version = 2;
        if(version==2) {
          List<String> readInfo = ["Offre de séjour", "Pays", "Cadre"];
          String? name = sheet.rows[row][_colSOfferName]?.value?.toString();

          if (name != null){
            print("Name is ${name}");
            readInfo.remove("Offre de séjour");
          }

          String? country = sheet.rows[row][_colSCountry]?.value?.toString();
          if (country != null){
            readInfo.remove("Pays");
          }
          String? contract = sheet.rows[row][_colSContentType]?.value?.toString();
          if (contract != null){
            readInfo.remove("Cadre");
          }
          if (readInfo.length != 0){
            throw ExcelParsingException("Les valeurs ${readInfo} pour l'école ${name} à la ligne ${row+1} semblent être incorrecte ");
          }

          int slots = -1;
          int bSlots = -1;
          int mSlots = -1;
          List<String> readSlots = ["Places", "Places Bachelor","Places Master"];
          try{
            slots = int.parse(sheet.rows[row][_colSSlots]?.value.toString() ?? "-1");
            readSlots.remove("Places");
            bSlots = int.parse(sheet.rows[row][_colSBachelorSlots]?.value.toString() ?? "-1");
            readSlots.remove("Places Bachelor");
            mSlots = int.parse(sheet.rows[row][_colSMasterSlots]?.value.toString() ?? "-1");
            readSlots.remove("Places Master");
          }
          catch (e,s){
            throw ExcelParsingException("Les valeurs ${readSlots.toString()} pour l'école ${name} à la ligne ${row+1} sont incorrectes ");
          }
          List<String> readDetails = ["Discipline","Niveau", "Formation","Langue d'enseignement", "Niveau langue", "Niveau Académique"];
          List<String>? specialization = specializationStringToList(
              sheet.rows[row][_colSSpecialization]?.value.toString() ?? "PROBLEM SPECIALIZATION");
          if (specialization != null){
            readDetails.remove("Discipline");
          }
          String? graduationLevel = sheet.rows[row][_colSGraduation]?.value?.toString();

          if (graduationLevel != null){
            readDetails.remove("Niveau");
          }

          String? program = sheet.rows[row][_colSProgram]?.value?.toString();
          if (program != null){
            readDetails.remove("Formation");
          }
          String? useLanguage = sheet.rows[row][_colSLangage]?.value.toString();
          if (useLanguage != null){
            readDetails.remove("Langue d'enseignement");
          }
          String? reqLangLevel = sheet.rows[row][_colSLangLvl]?.value?.toString();
          if (reqLangLevel != null){
            readDetails.remove("Niveau langue");
          }
          String? academicLevel = sheet.rows[row][_colSAcademicLvl]?.value?.toString();
          if (academicLevel != null){
            readDetails.remove("Niveau Académique");
          }
          
          if (readDetails.isNotEmpty){
            throw ExcelParsingException("Les valeurs ${readDetails.toString()} pour l'école $name à la ligne ${row+1}  sont incorrectes");
          }
          //
          School school = School(
              name!,
              country!,
              contract!,
              slots,
              bSlots,
              mSlots,
              specialization!,
              graduationLevel!,
              program!,
              useLanguage!,
              reqLangLevel!,
              academicLevel!
          );
          schools.add(school);
        }
        /*if(version==1) {
          String name = sheet.rows[row][0]?.value.toString() ?? "PROBLEM NAME";
          String country = sheet.rows[row][1]?.value.toString() ??
              "PROBLEM COUNTRY";
          String contract = sheet.rows[row][2]?.value.toString() ??
              "PROBLEM CONTRACT_TYPE";
          int slots = int.parse(sheet.rows[row][3]?.value.toString() ?? "-1");
          int bSlots = slots;
          int mSlots = slots;
          List<String> specialization = specializationStringToList(
              sheet.rows[row][5]?.value.toString() ?? "PROBLEM SPECIALIZATION");
          String graduationLevel = sheet.rows[row][6]?.value.toString() ??
              "PROBLEM GRADUATION_LEVEL";
          String program = sheet.rows[row][7]?.value.toString() ??
              "PROBLEM PROGRAM";
          String useLanguage = sheet.rows[row][8]?.value.toString() ??
              "PROBLEM USE_LANGUAGE";
          String reqLangLevel = sheet.rows[row][9]?.value.toString() ??
              "PROBLEM REQ_LANG_LEVEL";
          String academicLevel = sheet.rows[row][10]?.value.toString() ??
              "PROBLEM ACADEMIC_LEVEL";
          School school = School(
              name,
              country,
              contract,
              slots,
              bSlots,
              mSlots,
              specialization,
              graduationLevel,
              program,
              useLanguage,
              reqLangLevel,
              academicLevel
          );
          schools.add(school);
        }*/
        print("");
      }
    }

    // muted prints to clean the debug output
    //print("LES SCHOOLS: $schools");
    //print("Normalemennt MONS:");
    //print(schools[5].name);print(schools[5].country);print(schools[5].content_type);print(schools[5].specialization);
    
    if (schools.isEmpty) {
      throw ExcelParsingException("Aucune école n'a été trouvée dans le fichier");
    }
    
    return schools;
  }

  //transforme la colonne DISCIPLINE en une liste de STI 3A, STI 4A, MRI 3A, MRI 4A
  static List<String>? specializationStringToList(String specialization){
    List<String> spez = [];
    List<String> substrings = specialization.split("+");
    for(String substring in substrings) {
      List<String> program = [];
      for (String prog in ["ENP", "ENR", "GSI", "MRI", "STI"]) {
        if (substring.contains(prog)) {
          program.add(prog);
          print("$prog DETECTÉ");
        }
      }
      for (String yea in ["2A", "3A", "4A", "5A"]) {
        if (substring.contains(yea)) {
          print("$yea DETECTÉ");
          for (String prog in program) {
            spez.add(
                "$prog $yea"); //used interpolation, avoids concatenation (prog+" "+yea)
          }
        }
      }
    }
    if (spez.length == 0){
      return null;
    }
    return spez;
  }

  static List<int> exportResult(List<Student> students, List<School> schools) {
    Map<int, String> indexes = {
      0: "Nom",
      1: "Voeu",
      2: "Pays",
      3: "Etablissement",
      4: "Département",
      5: "Interclassement",
      6: "Nb ECTS",
      7: "Niveau Anglais",
      8: "Absences",
      9: "Nbre de Places",
      10: "Commentaires",
      11: "Commentaires post-jury"
    };

    // Create separate lists for different sheets
    List<(int, int, Choice)> allChoices = [];
    List<(int, int, Choice)> acceptedChoices = [];
    List<(int, int, Choice)> rejectedChoices = [];
    List<(int, int, Choice)> noResponseChoices = [];
    
    // First pass - identify students with responses and collect all choices
    Map<int, bool> studentHasResponse = {};
    Map<int, bool> studentAllChoicesRejected = {}; // New map to track fully rejected students

    for (var s in students) {
      // Initialize tracking variables
      studentHasResponse[s.id] = false;
      studentAllChoicesRejected[s.id] = true; // Assume all choices rejected until proven otherwise
      
      for (var c in s.choices.entries) {
        // Add to all choices list
        allChoices.add((s.id, c.key, c.value));
        
        // Check acceptance status
        if (s.accepted != null && s.accepted!.school.id == c.value.school.id) {
          acceptedChoices.add((s.id, c.key, c.value));
          studentHasResponse[s.id] = true;
          studentAllChoicesRejected[s.id] = false; // At least one choice is accepted
        }
        // Check rejection status
        else if (s.refused.any((choice) => choice.school.id == c.value.school.id)) {
          rejectedChoices.add((s.id, c.key, c.value));
          studentHasResponse[s.id] = true;
          // Note: We don't set studentAllChoicesRejected to false here
          // because we're checking if ALL choices are rejected
        } else {
          studentAllChoicesRejected[s.id] = false; // Found a choice that's not rejected
        }
      }
      
      // If the student has all choices rejected but has choices,
      // confirm it by checking the get_second_tour() method
      if ((studentAllChoicesRejected[s.id] ?? false) && s.choices.isNotEmpty) {
        studentAllChoicesRejected[s.id] = s.get_second_tour();
      }
    }
    
    // Second pass - add students to noResponseChoices (now includes second tour students)
    for (var s in students) {
      if ((studentHasResponse[s.id] == false && s.choices.isNotEmpty) || 
          (studentAllChoicesRejected[s.id] == true && s.choices.isNotEmpty)) {
        // This student has NO responses OR all choices rejected - add ALL their choices
        for (var c in s.choices.entries) {
          noResponseChoices.add((s.id, c.key, c.value));
        }
      }
    }

    // Sort all lists by interranking
    allChoices.sort((a, b) => b.$3.interranking.compareTo(a.$3.interranking));
    acceptedChoices.sort((a, b) => b.$3.interranking.compareTo(a.$3.interranking));
    rejectedChoices.sort((a, b) => b.$3.interranking.compareTo(a.$3.interranking));
    noResponseChoices.sort((a, b) => b.$3.interranking.compareTo(a.$3.interranking));

    // Create Excel workbook
    Excel exportedExcel = Excel.createExcel();
    
    // Get default sheet name
    String defaultSheetName = exportedExcel.getDefaultSheet() ?? "Sheet1";
    
    // Create additional sheets by copying the default one
    exportedExcel.copy(defaultSheetName, "Choix acceptés");
    exportedExcel.copy(defaultSheetName, "Choix refusés");
    exportedExcel.copy(defaultSheetName, "Second Tour"); // Changed name
    
    // Rename default sheet and get sheet references
    exportedExcel.rename(defaultSheetName, "Tous les choix");
    Sheet allSheet = exportedExcel.sheets["Tous les choix"]!;
    Sheet acceptedSheet = exportedExcel.sheets["Choix acceptés"]!;
    Sheet rejectedSheet = exportedExcel.sheets["Choix refusés"]!;
    Sheet secondTourSheet = exportedExcel.sheets["Second Tour"]!; // Reference to new sheet
    
    // Clear copied content
    //acceptedSheet.clear();
    //rejectedSheet.clear();
    //noResponseSheet.clear();
    
    // Add headers to each sheet
    setupSheetHeaders(allSheet, indexes);
    setupSheetHeaders(acceptedSheet, indexes);
    setupSheetHeaders(rejectedSheet, indexes);
    setupSheetHeaders(secondTourSheet, indexes); // Add headers to new sheet
    
    // Fill each sheet with data
    fillSheetWithChoices(allSheet, allChoices, students, true);
    fillSheetWithChoices(acceptedSheet, acceptedChoices, students, false);
    fillSheetWithChoices(rejectedSheet, rejectedChoices, students, false);
    fillSheetWithChoices(secondTourSheet, noResponseChoices, students, false); // Fill new sheet
    
    return exportedExcel.save() ?? [];
  }

  // Helper method to set up sheet headers
  static void setupSheetHeaders(Sheet sheet, Map<int, String> indexes) {
    List<CellValue?> headerRow = [];
    for (int i = 0; i < indexes.length; i++) {
      sheet.insertColumn(i);
      headerRow.add(TextCellValue(indexes[i]!));
    }
    sheet.appendRow(headerRow);
  }

  // Helper method to fill a sheet with choice data
  static void fillSheetWithChoices(Sheet sheet, List<(int, int, Choice)> choices, List<Student> students, bool applyColors) {
    int rowIndex = 1; // Start after header
    
    for (var c in choices) {
      Student? currentStudent = students.where((e) => e.id == c.$1).firstOrNull;
      if (currentStudent == null) continue;
      
      Choice currentChoice = c.$3;
      int choiceNumber = c.$2;
      
      // Create cell values for this row
      List<CellValue?> studentValues = [
        TextCellValue(currentStudent.name),
        IntCellValue(choiceNumber),
        TextCellValue(currentChoice.school.country),
        TextCellValue(currentChoice.school.name),
        TextCellValue(currentStudent.departement),
        DoubleCellValue(currentChoice.interranking),
        IntCellValue(currentStudent.ects_number),
        TextCellValue(currentStudent.lang_lvl),
        DoubleCellValue(currentStudent.missed_hours),
        IntCellValue(currentChoice.school.available_slots),
        TextCellValue(currentStudent.comment),
        TextCellValue(currentChoice.post_comment ?? " - ")
      ];
      
      sheet.appendRow(studentValues);
      
      // Apply color coding if needed (only for the main sheet)
      if (applyColors) {
        List<Data?> currentRow = sheet.row(rowIndex);
        
        // Green for accepted choices
        if (currentStudent.accepted != null && currentStudent.accepted!.school.id == currentChoice.school.id) {
          for (var data in currentRow) {
            data?.cellStyle = CellStyle(backgroundColorHex: ExcelColor.green200);
          }
        }
        // Red for rejected choices
        else if (currentStudent.refused.any((choice) => choice.school.id == currentChoice.school.id)) {
          for (var data in currentRow) {
            data?.cellStyle = CellStyle(backgroundColorHex: ExcelColor.red200);
          }
        }
      }
      
      rowIndex++;
    }
  }

  static int saveExcelToDisk(String path, List<int> bytes){
    // On crée un objet Fichier qui contient le descripteur, le chemin etc...
    File excelFile = File(path);
    // Ici étant qu'on est forcément dans un cas où on enregistre le fichier sur le disque, on le crée dans le système de fichier
    excelFile.createSync();
    // On écrit ensuite les octets qui composent le fichier excel initial
    excelFile.writeAsBytes(bytes);
    return 1;
  }
}







