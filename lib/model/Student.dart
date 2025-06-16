import 'package:mobinsa/model/Choice.dart';

class Student {
  int id ;
  String name;
  Map <int,Choice> choices;
  Choice? accepted;
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

}