
import 'package:mobinsa/model/Choice.dart';
import 'package:mobinsa/model/School.dart';

class Student {
  int id;

  String name;
  Map <int, Choice> choices;
  Choice? accepted;
  List<Choice> refused = [];
  School? accepted_school;
  String specialization;
  int ranking_s1;

  int ects_number;
  String lang_lvl;
  double missed_hours;
  String comment;
  

  late int year;
  late String departement;


  Student(this.id, this.name, this.choices, this.specialization,
      this.ranking_s1, this.ects_number, this.lang_lvl, this.missed_hours,
      this.comment) {
    year_departement(specialization);
  }

  void add_student(id, name, choices, specialization, rankingS1, ectsNumber,
      langLvl, missedHours, comment) {
    this.id = id;
    this.name = name;
    for (int i = 0; i < choices.length; i++) {
      this.choices = choices[i];
    }

    this.specialization = specialization;
    this.ranking_s1 = rankingS1;
    this.ects_number = ectsNumber;
    this.lang_lvl = langLvl;
    this.missed_hours = missedHours;
    this.comment = comment;
    year_departement(specialization);
    accepted_school = null;
  }

  void year_departement(String specialization) {
    if (specialization.contains("2")) {
      year = 2;
    }
    else if (specialization.contains("3")) {
      year = 3;
    }
    else if (specialization.contains("4")) {
      year = 4;
    }
    else {
      year = 5;
    }

    if (specialization.contains("MRI")) {
      departement = "MRI";
    }
    else if (specialization.contains("STI")) {
      departement = "STI";
    }
    else if (specialization.contains("ENP")) {
      this.departement = "ENP";
    }
    else {
      departement = "GSI";
    }
  }

  void addRefusedChoice(Choice choice) {
    refused.add(choice);
  }

  void removeRefusedChoice(Choice choice) {
    refused.remove(choice);
  }

  void restoreRefusedChoice(Choice choice, int choiceKey) {
    // Restaurer un choix refusé dans la liste des choix actifs
    
    if (refused.contains(choice)) {
      refused.remove(choice);
      choices[choiceKey] = choice;
      print("CHOICE RESTORED");
    }
    print(refused);
  }

  void add_post_comment(int selectedChoice , String newComment ) {
    if (choices.containsKey(selectedChoice)){
      choices[selectedChoice]!.post_comment =  newComment;
    }
    else {
      throw Exception("The selected choice doesn't exists");
    }
  }

  String get_next_year() {
    return "$departement ${year + 1}A";
  }

  Student clone(){
    return Student(id, name,choices,specialization,ranking_s1,ects_number,lang_lvl,missed_hours,comment);
  }

  @override
  String toString() {
    String choicesString = choices.entries.map((entry) => '\n    Vœu ${entry.key}: ${entry.value}').join('');
    String refusedChoicesString = refused.isNotEmpty ? refused.map((choice) => '\n    Refusé: $choice').join('') : '\n    Aucun refus';
    // return this.name;
    return 'Étudiant {\n'
        '  ID: $id,\n'
        '  Nom: $name,\n'
        '  Spécialisation: $specialization (Année: $year, Département: $departement),\n'
        '  Classement S1: $ranking_s1,\n'
        '  Crédits ECTS: $ects_number,\n'
        '  Niveau Langue: $lang_lvl,\n'
        '  Heures Manquées: $missed_hours,\n'
        '  Commentaire: "$comment",\n'
        '  Post-Commentaire: "${'N/A'}",\n'
        '  Vœux: $choicesString\n'
        '  Vœu Accepté: ${accepted ?? 'Aucun'}\n'
        '  Vœux Refusés: $refusedChoicesString\n'
        '}';
  }

  Map<int, Choice> diff_interrankings() {
    Map<int, Choice> diff_dict = {};
    if (choices.isEmpty) return {};
    // Compter la fréquence de chaque interclassement
    Map<double, int> interrankFrequencies = {};
    for (var choice in choices.values) {
      interrankFrequencies.update(
        choice.interranking,
            (count) => count + 1,
        ifAbsent: () => 1,
      );
    }
    // Trouver l'interclassement le plus fréquent
    double reference_Rank;
    List<double> mostCommonRanks = interrankFrequencies.entries
        .where((e) => e.value > 1)
        .map((e) => e.key)
        .toList();
    if (mostCommonRanks.isNotEmpty) {
      // Si des interclassements sont communs, choisir le plus fréquent
      reference_Rank = mostCommonRanks.first;
      int maxFreq = interrankFrequencies[reference_Rank]!;
      for (var rank in mostCommonRanks) {
        if (interrankFrequencies[rank]! > maxFreq) {
          reference_Rank = rank;
          maxFreq = interrankFrequencies[rank]!;
        }
      }
    } else {
      // Sinon, prendre le plus élevé
      reference_Rank = interrankFrequencies.keys.reduce((a, b) => a > b ? a : b);
    }

    // Comparer les autres vœux au reference_Rank
    for (var entry in choices.entries) {
      double currentRank = entry.value.interranking;
      if ((currentRank - reference_Rank).abs() > 1e-6) {
        diff_dict[entry.key] = entry.value;
      }
    }

    return diff_dict;
  }

  Map<int, List<Student>> ladder_interranking(
      List<Student> allStudents) {
    /// Construit une "échelle" (ladder) des étudiants qui ont obtenu une meilleure
    /// position (interclassement) que l'étudiant courant pour un même établissement,
    /// uniquement pour les vœux dont l'interclassement diffère du rang de référence.
    ///
    /// Retourne une map où la clé est la position du vœu dans `choices`
    /// et la valeur est la liste des étudiants ayant un interclassement plus favorable
    /// pour la même école.
    Map<int, List<Student>> ladder = {};
    Map<int, Choice> diffDict = diff_interrankings();
    //print("Here is the diff_dict ${diffDict}");
    if (diffDict.isEmpty) return {};
    for (var entry in diffDict.entries) {
      Choice c = entry.value; // Le choix problématique
      int key = entry.key; // Son index dans la liste des vœux
      ladder[key] = [];
      for (Student other in allStudents) {
        if (other.id == id) continue;
        for (Choice otherChoice in other.choices.values) {
          if (otherChoice.school.id == c.school.id &&
              otherChoice.interranking > c.interranking) {
            ladder.putIfAbsent(key, () => []);
            ladder[key]!.add(other);
          }
        }
      }
    }
    return ladder;
  }
}