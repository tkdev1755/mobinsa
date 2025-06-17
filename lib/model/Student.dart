import 'package:mobinsa/model/Choice.dart';
import 'package:mobinsa/model/School.dart';

class Student {
  int id ;
  String name;
  Map <int,Choice> choices;
  Choice? accepted;
  School? accepted_school;
  String specialization;
  int ranking_s1 ;
  int ects_number;
  String lang_lvl;
  double missed_hours;
  String comment;
  String? post_comment;
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

  void add_post_comment( String new_comment ) {
    this.post_comment = new_comment;
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
        '  Post-Commentaire: "${post_comment ?? 'N/A'}",\n'
        '  Vœux: $choicesString\n'
        '  Vœu Accepté: ${accepted ?? 'Aucun'}\n'
        '}';
  }
}
