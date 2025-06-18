import 'package:flutter/material.dart';
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

  void add_student(id, name, choices, specialization, ranking_s1, ects_number,
      lang_lvl, missed_hours, comment) {
    this.id = id;
    this.name = name;
    for (int i = 0; i < choices.length; i++) {
      this.choices = choices[i];
    }

    this.specialization = specialization;
    this.ranking_s1 = ranking_s1;
    this.ects_number = ects_number;
    this.lang_lvl = lang_lvl;
    this.missed_hours = missed_hours;
    this.comment = comment;
    year_departement(specialization);
    this.accepted_school = null;
  }

  void year_departement(String specialization) {
    if (specialization.contains("2")) {
      this.year = 2;
    }
    else if (specialization.contains("3")) {
      this.year = 3;
    }
    else if (specialization.contains("4")) {
      this.year = 4;
    }
    else {
      this.year = 5;
    }

    if (specialization.contains("MRI")) {
      this.departement = "MRI";
    }
    else if (specialization.contains("STI")) {
      this.departement = "STI";
    }
    else {
      this.departement = "GSI";
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

  void add_post_comment(int selectedChoice , String new_comment ) {
    if (choices.containsKey(selectedChoice)){
      this.choices[selectedChoice]!.post_comment =  new_comment;
    }
    else {
      throw Exception("The selected choice doesn't exists");
    }
  }

  String get_next_year() {
    return "$departement ${this.year + 1}A";
  }

  Student clone(){
    return Student(this.id, this.name,this.choices,this.specialization,this.ranking_s1,this.ects_number,this.lang_lvl,this.missed_hours,this.comment);
  }

  @override
  String toString() {
    String choicesString = choices.entries.map((entry) => '\n    Vœu ${entry.key}: ${entry.value}').join('');
    String refusedChoicesString = refused.isNotEmpty ? refused.map((choice) => '\n    Refusé: ${choice}').join('') : '\n    Aucun refus';
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

  Map<int, Choice> diff_interrankings(List<Student> allStudents) {
    Map<int, Choice> problematicChoices = {};
    for (int i = 0; i < choices.length; i++) {
      if (!choices.containsKey(i)) {
        throw Exception();
      }
      Choice myChoice = choices[i]!;
      School school = myChoice.school;
      double myRank = myChoice.interranking;
      for (Student other in allStudents) {
        if (other.id == this.id) continue;
        for (Choice otherChoice in other.choices.values) {
          if (otherChoice.school.id == school.id &&
              otherChoice.interranking < myRank) {
            problematicChoices[i] = myChoice;
          }
        }
        if (problematicChoices.containsKey(i)) break;
      }
    }
    return problematicChoices;
  }

  Map<(Choice, int), List<Student>> ladder_interranking(
      List<Student> allStudents) {
    Map<(Choice, int), List<Student>> ladder = {};
    Map<int, Choice> diff_dict = diff_interrankings(allStudents);
    if (diff_dict.isEmpty) return {};
    for (var entry in diff_dict.entries) {
      Choice c = entry.value;
      int key = entry.key;
      ladder[(c, key)] = [];
      for (Student other in allStudents) {
        if (other.id == this.id) continue;
        for (Choice otherChoice in other.choices.values) {
          if (otherChoice.school.id == c.school.id &&
              otherChoice.interranking < c.interranking) {
            ladder.putIfAbsent((c, key), () => []);
            ladder[(c, key)]!.add(other);
          }
          if (ladder.containsKey((c, key))) break;
        }
      }
    }
    return ladder;
  }
}
