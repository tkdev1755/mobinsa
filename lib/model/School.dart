import 'package:mobinsa/model/Student.dart';

class School{ //classe définissant les écoles/offres de séjours présentant toutes les informations importantes (niveau acad&miqu, langue d'ensignement,...)
  int id;
  String name; //string définissant l'initulé de l'offre de séjour
  String content_type;
  int available_slots; //nombre de places disponible
  int b_slots; //nombre de place disponible en bachelor
  int m_slots; //nombre de place disponible en master
  List<String> specialization; //liste des spécialisations qui peuvent postuler à cette offre de séjour
  String graduation_level;
  String program; // Formation concernée par l'offre de séjour
  String use_langage; // langue d'enseignement
  String req_lang_level; //niveau minimum de langue souhaité
  String academic_level; //niveau académque souhaité
  bool is_full = false;

  School(this.id, this.name, this.content_type, this.available_slots, this.b_slots, this.m_slots, this.specialization, this.graduation_level, this.program, this.use_langage, this.req_lang_level, this.academic_level);


  void reduce_slots(Student s) { //réduire le nombre de places d'une offre de séjour si on affecté une mobilité à un étudiant
    if(this.available_slots > 0) {
      this.available_slots--;
      if(s.year > 2) this.m_slots--;
      else if (s.year==2) this.b_slots--;
      if(this.available_slots == 0)
        this.is_full = true;
    }
  }

  void add_slots() { //augmenter le nombre de places si on décide d'enlever une mobilité à un élève
    this.available_slots++;
  }

  // bool accepted(Student s) { //affectation d'une offre de séjour à un élève
  //   if(this.available_slots > 0 && s.specialization.contains(s.specialization) && ) {
  //    this.reduce_slots(s);
  //    return true; }
  //  return false;
  // }
}