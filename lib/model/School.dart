import 'package:mobinsa/model/Student.dart';

class School {
  //classe définissant les écoles/offres de séjours présentant toutes les informations importantes (niveau acad&miqu, langue d'ensignement,...)
  static int global_id = 0;
  late int id;
  String name; //string définissant l'initulé de l'offre de séjour
  String country;
  String content_type;
  int available_slots; //nombre de places disponible
  late int remaining_slots; //nombres de places restantes
  int b_slots; //nombre de place disponible en bachelor
  int m_slots; //nombre de place disponible en master
  List<String> specialization; //liste des spécialisations qui peuvent postuler à cette offre de séjour
  String graduation_level;
  String program; // Formation concernée par l'offre de séjour
  String use_langage; // langue d'enseignement
  String req_lang_level; //niveau minimum de langue souhaité
  String academic_level; //niveau académque souhaité
  bool is_full = false;
  bool is_full_b = false;
  bool is_full_m = false;

  School(this.name, this.country, this.content_type, this.available_slots,
      this.b_slots, this.m_slots, this.specialization, this.graduation_level,
      this.program, this.use_langage, this.req_lang_level,
      this.academic_level) {
    id = global_id;
    remaining_slots = available_slots;
    global_id++;
  }


  void reduce_slots(Student s) {
    //réduire le nombre de places d'une offre de séjour si on affecté une mobilité à un étudiant
    if (remaining_slots > 0) {
      remaining_slots--;
      // this.available_slots--;
      if (s.year > 2) {
        m_slots--;
        print("SLOT SUCCESSFULLY REMOVED MASTER");
        if (m_slots == 0) is_full_m = true;
      }
      else if (s.year == 2) {
        b_slots--;
        print("SLOT SUCCESSFULLY REMOVED LICENCE");
        if (b_slots == 0) is_full_b = true;
      }
    }
    if (remaining_slots == 0) {
      is_full = true;
    }
  }

  void add_slots(Student s) {
    //augmenter le nombre de places si on décide d'enlever une mobilité à un élève
    if(remaining_slots < available_slots){
      remaining_slots++;
      if (s.year > 2) m_slots++;
      if (s.year == 2) b_slots++;
    }
    else{
      print("NO MORE SLOTS AVAILABLE");
    }
  }

  bool accepted(Student s) {
    //affectation d'une offre de séjour à un élève
    print("s.year : ${s.year}");
    print("this.b_slots : ${b_slots}");
    print("this.specialization : ${specialization}");
    print("s.get_next_year() : ${s.get_next_year()}");
    if (s.year == 2 && b_slots > 0 && specialization.contains(s.get_next_year())) {
      print("ACCEPTED SCHOOL LICENCE");
      reduce_slots(s);
      return true;
    }
    else if (s.year > 2 && m_slots > 0 && specialization.contains(s.get_next_year())) {
      print("ACCEPTED SCHOOL MASTER");
      reduce_slots(s);
      return true;
    }
    return false;
  }
  @override
  String toString() {
    // TODO: implement toString
    return "Ecole : $name - $country - $specialization";
  }
}
