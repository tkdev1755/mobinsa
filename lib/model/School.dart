import 'package:mobinsa/model/Student.dart';

class School {
  //classe définissant les écoles/offres de séjours présentant toutes les informations importantes (niveau acad&miqu, langue d'ensignement,...)
  static int global_id = 0;

  /// static string to use when parsing the json, or serializing the class
  static String jsonId = "id";
  static String jsonName = "name";
  static String jsonCountry  = "country";
  static String jsonContent_type = "content_type";
  static String jsonAvailable_slots = "available_slots";
  static String jsonRemaining_slots = "remaining_slots";
  static String jsonB_slots = "b_slots";
  static String jsonM_slots = "m_slots";
  static String jsonSpecialization = "specialization";
  static String jsonGraduationLVL = "graduation_level";
  static String jsonProgram = "program";
  static String jsonUseLanguage = "use_language";
  static String jsonReq_lang_lvl = "req_lang_lvl";
  static String json_academic_lvl = "academic_lvl";
  static String jsonIsFull = "is_full";
  static String jsonIsFull_b = "is_full_b";
  static String jsonIsFull_m = "is_full_m";

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

  static void setGlobalID(int globalID){
    global_id = globalID;
  }

  void setId(int id){
    this.id = id;
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
    //Les 2A ne pourront quand même pas prendre de formation en master !
    if (s.year == 2 && this.b_slots > 0 ) {
      print("ACCEPTED SCHOOL LICENCE");
      reduce_slots(s);
      return true;
    }
    else if (s.year > 2 && this.m_slots > 0 ) {
      print("ACCEPTED SCHOOL MASTER");
      reduce_slots(s);
      return true;
    }
    return false;
  }
  @override
  String toString() {
    // TODO: implement toString
    return "Ecole : $id - $name - $country - $specialization";
  }

  Map<String,dynamic> toJson(){
    return {
      jsonId : id,
      jsonName : name,
      jsonCountry : country,
      jsonContent_type : content_type,
      jsonAvailable_slots : available_slots,
      jsonRemaining_slots : remaining_slots,
      jsonB_slots : b_slots,
      jsonM_slots : m_slots,
      jsonSpecialization : specialization,
      jsonGraduationLVL : graduation_level,
      jsonProgram : program,
      jsonUseLanguage : use_langage,
      jsonReq_lang_lvl : req_lang_level,
      json_academic_lvl : academic_level,
      jsonIsFull : is_full,
      jsonIsFull_b : is_full_b,
      jsonIsFull_m : is_full_m,
    };
  }

  factory School.fromJson(Map<String, dynamic> json) {
    School school = School(
      json[jsonName],                          // name
      json[jsonCountry],                       // country
      json[jsonContent_type],                  // content_type
      json[jsonAvailable_slots],               // available_slots
      json[jsonB_slots],                       // b_slots
      json[jsonM_slots],                       // m_slots
      List<String>.from(json[jsonSpecialization]), // specialization
      json[jsonGraduationLVL],                 // graduation_level
      json[jsonProgram],
      json[jsonUseLanguage],                   // use_langage
      json[jsonReq_lang_lvl],                  // req_lang_level
      json[json_academic_lvl],                 // academic_level
    );
    school.setId(json[jsonId]);
    school.remaining_slots = json[jsonRemaining_slots];
    school.is_full = json[jsonIsFull];
    school.is_full_b = json[jsonIsFull_b];
    school.is_full_m = json[jsonIsFull_m];
    return  school;
  }

}
