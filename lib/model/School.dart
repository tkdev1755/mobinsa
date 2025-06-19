import 'package:mobinsa/model/Student.dart';

/// Classe représentant une école ou une offre de séjour.
/// Contient toutes les informations nécessaires pour une affectation de mobilité (niveau académique, langue d’enseignement, etc.)
class School {
  /// Identifiant global auto-incrémenté pour chaque instance.
  static int global_id = 0;

  /// Clés utilisées pour la (dé)sérialisation JSON.
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

  /// Identifiant unique de l’école.
  late int id;

  /// Nom de l’offre de séjour.
  String name;

  /// Pays de l’établissement.
  String country;

  /// Type de contenu (par ex. programme, université...).
  String content_type;

  /// Nombre total de places disponibles.
  int available_slots;

  /// Nombre de places restantes.
  late int remaining_slots;

  /// Nombre de places en Bachelor.
  int b_slots;

  /// Nombre de places en Master.
  int m_slots;

  /// Spécialisations acceptées pour cette offre.
  List<String> specialization;

  /// Niveau de diplôme requis (Bachelor/Master).
  String graduation_level;

  /// Programme concerné par l’offre.
  String program;

  /// Langue d’enseignement.
  String use_langage;

  /// Niveau requis dans la langue d’enseignement.
  String req_lang_level;

  /// Niveau académique requis.
  String academic_level;

  /// Indique si toutes les places sont prises.
  bool is_full = false;

  /// Indique si toutes les places en Bachelor sont prises.
  bool is_full_b = false;

  /// Indique si toutes les places en Master sont prises.
  bool is_full_m = false;

  /// Constructeur de la classe School. Initialise les champs et génère un identifiant unique.
  School(this.name, this.country, this.content_type, this.available_slots,
      this.b_slots, this.m_slots, this.specialization, this.graduation_level,
      this.program, this.use_langage, this.req_lang_level,
      this.academic_level) {
    id = global_id;
    remaining_slots = available_slots;
    global_id++;
  }

  /// Définit une nouvelle valeur pour l’identifiant global.
  static void setGlobalID(int globalID){
    global_id = globalID;
  }

  /// Définit l’identifiant de l’instance.
  void setId(int id){
    this.id = id;
  }

  /// Réduit le nombre de places disponibles après affectation d’un étudiant.
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

  /// Augmente le nombre de places disponibles si on retire un étudiant affecté.
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

  /// Tente d’affecter un étudiant à cette offre.
  /// Retourne `true` si l’affectation est réussie, sinon `false`.
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

  /// Retourne une représentation textuelle de l’école.
  @override
  String toString() {
    return "Ecole : $name - $country - $specialization";
  }

  /// Sérialise l’objet School en JSON.
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

  /// Crée une instance de School à partir d’un objet JSON.
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
