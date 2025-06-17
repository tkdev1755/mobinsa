import 'package:mobinsa/model/Choice.dart';
import 'package:mobinsa/model/School.dart';

class Student {
  int id ;
  String name;
  Map <int,Choice> choices;
  Choice? accepted;
  List<Choice> refused = [];
  School? accepted_school;
  String specialization;
  int ranking_s1 ;
  int ects_number;
  String lang_lvl;
  double missed_hours;
  String comment;

  late int year;
  late String departement;



  Student(this.id, this.name,this.choices,this.specialization,this.ranking_s1,this.ects_number,this.lang_lvl,this.missed_hours,this.comment){
    year_departement(specialization);
  }
  void add_student(id, name,choices,specialization,ranking_s1,ects_number,lang_lvl,missed_hours,comment) {
    this.id = id;
    this.name = name;
      for(int i=0;i<choices.length;i++) {
        this.choices = choices[i] ;
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

  void year_departement (String specialization){
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

  void addRefusedChoice(Choice choice){
    refused.add(choice);
  }

  void removeRefusedChoice(Choice choice){
    refused.remove(choice);
  }
  void add_post_comment(int selectedChoice , String new_comment ) {
    if (choices.containsKey(selectedChoice)){
      this.choices[selectedChoice]!.post_comment =  new_comment;
    }
    else{
      throw Exception("The selected choice doesn't exists");
    }
  }

  String get_next_year (){
    return "$departement ${this.year + 1}A";
  }
  @override
  String toString() {
    String choicesString = choices.entries.map((entry) => '\n    Vœu ${entry.key}: ${entry.value}').join('');
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
        '}';
  }

  Map<int,List<Choice>> diff_interrankings(init_list) {
    //Cette fonction permet de récupérer les étudiants ayant des voeux problématiques, c'est-à-dire des voeux avec un interclassement différent des autres
    late Map<int,List<Choice>> diff_dict = {};
    for (Student s in init_list) {
      var ChoiceList = s.choices.values.toList();
      if(ChoiceList.isEmpty) continue;
      double ReferenceRank = ChoiceList.first.interranking;
      List<Choice> problematicChoices = ChoiceList.where((choice) => choice.interranking != ReferenceRank).toList();
      if (problematicChoices.isNotEmpty) {
        diff_dict[s.id] = problematicChoices;
      }
    }
    return diff_dict;
  }

  Map<(Student,int),List<Student>> ladder_interrankigs(init_list) {
    // Cette fonction construit une map associant, pour chaque étudiant et chaque vœu problématique (où un autre étudiant a un meilleur interclassement sur la même école),
    // la liste des étudiants mieux classés sur ce même vœu.
    // Elle permet ainsi d’identifier les cas où un étudiant est dépassé par d’autres candidats pour un vœu donné.

    Map<int,List<Choice>> diff_dict = diff_interrankings(init_list);
    Map<(Student,int),List<Student>> ladder_map = {};
    for(int i in diff_dict.keys) {
      Student student = init_list.firstWhere((s) => s.id == i);
      List<Choice> problematicChoices = diff_dict[i]!;
      for(Choice c in problematicChoices) {
        int choiceKey = student.choices.entries.firstWhere((e) => e.value == c).key;
        for(Student other in init_list) {
          if (other.id == i) continue;
            for(Choice c2 in other.choices.values) {
              if(c.school.id == c2.school.id && c.interranking < c2.interranking) {
                // Ajoute à la map (si la clé n'existe pas encore)
                ladder_map.putIfAbsent((student,choiceKey), () => []);
                // Empêche les doublons
                if (!ladder_map[choiceKey]!.any((s) => s.id == other.id)) {
                  ladder_map[(student,choiceKey)]!.add(other); }
            }
          }
        }
      }
    }
    return ladder_map; // Retourne une map liant chaque couple (étudiant, numéro de vœu) à la liste des étudiants mieux classés sur ce vœu.
  }

}
