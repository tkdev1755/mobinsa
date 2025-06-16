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


  Student(this.id, this.name,this.choices,this.specialization,this.ranking_s1,this.ects_number,this.lang_lvl,this.missed_hours,this.comment);

}