import 'package:mobinsa/model/School.dart';
import 'package:mobinsa/model/Student.dart';

/// Représente un choix de séjour pour un étudiant dans une école.
/// Contient l'école visée, le classement de l'étudiant, l'étudiant concerné,
/// et éventuellement un commentaire postérieur à la candidature.
class Choice {
  /// Clé JSON pour sérialiser/désérialiser l'école.
  static String jsonSchool = "school";

  /// Clé JSON pour sérialiser/désérialiser le classement inter.
  static String jsonInterranking = "interranking";

  /// Clé JSON pour sérialiser/désérialiser l'étudiant.
  static String jsonStudent = "student";

  /// Clé JSON pour sérialiser/désérialiser un commentaire éventuel.
  static String jsonPostComment = "post_comment";

  /// École ciblée par ce choix.
  School school;

  /// Classement inter du choix pour cet étudiant.
  double interranking;

  /// Étudiant ayant effectué ce choix.
  Student student;

  /// Commentaire éventuel laissé après le traitement du choix.
  String? post_comment;

  /// Crée un nouveau choix pour un étudiant avec une école et un classement.
  Choice (this.school, this.interranking,this.student);

  /// Tente d’accepter ce choix pour l’étudiant donné.
  /// Retourne `true` si l'école valide le choix, sinon `false`.
  bool accepted(Student s) {
    //affectation d'une offre de séjour à un élève
    if (school.accepted(s)) {
      student.accepted = this;
      print("ACCEPTED CHOICE");
      return true;
    }
    return false;
  }

  /// Refuse ce choix pour l’étudiant et l’ajoute à sa liste de choix refusés.
  /// Supprime également le choix actif si celui-ci est en cours.
  void refuse() {
    //refuser un choix et l'ajouter à la liste des choix refusés
    student.addRefusedChoice(this);
    // Retirer le choix de la liste des choix actifs
    if(student.accepted == this){
      remove_choice();
    }
    print("REFUSED CHOICE");
    print(student.refused);
  }

  /// Supprime ce choix comme choix accepté de l’étudiant et libère la place dans l’école.
  void remove_choice() {
    student.accepted = null;
    school.add_slots(student);
  }

  /// Vérifie si ce choix est incohérent avec la spécialisation de l’école.
  /// Retourne `true` si l'école ne propose pas la spécialité attendue.
  bool is_incoherent(){
    if (!(school.specialization.contains(student.get_next_year()))){
      return true;
    }
    else {
      return false;
    }

  }

  // Sérialise ce choix en un objet JSON.
  Map<String, dynamic> toJson(){
    return {
      "school" : school.toJson(),
      "interranking" : interranking,
      "student" : student.id,
      "post_comment" : post_comment ?? "null",
    };
  }

  /// Construit un `Choice` à partir d'un objet JSON et d’un étudiant donné.
  factory Choice.fromJson(Map<String,dynamic> json, Student student){
    School school = School.fromJson(json[jsonSchool]);
    return Choice(school, json[jsonInterranking], student);
  }

  /// Représentation texte du choix.
  /// Affiche seulement le nom de l'école pour éviter les boucles infinies.
  @override
  String toString() {
    // Attention à ne pas imprimer student.toString() ici pour éviter une boucle infinie
    // si Student.toString() imprime aussi ses Choice qui impriment leur Student, etc.
    // Imprimez juste des informations clés de l'étudiant si nécessaire, ou son ID/nom.
    // return 'Choix{École: $school, Classement Inter.: $interranking}';
    return school.name;
  }

  /// Compare deux choix sur la base de l'identifiant de l'école.
  @override
  bool operator ==(Object other) {
    // if (identical(this, other)) return true;
    if (other is! Choice) return false;
    return school.id == other.school.id;
  }




}