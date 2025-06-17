import 'package:mobinsa/model/School.dart';
import 'package:mobinsa/model/Student.dart';

class Choice {
  School school;
  double interranking;
  Student student;
  String? post_comment;
  Choice (this.school, this.interranking,this.student);

  bool accepted(Student s) {
    //affectation d'une offre de séjour à un élève
    if (this.school.accepted(s)) {
      student.accepted = this;
      print("ACCEPTED CHOICE");
      return true;
    }
    return false;
  }


  @override
  String toString() {
    // Attention à ne pas imprimer student.toString() ici pour éviter une boucle infinie
    // si Student.toString() imprime aussi ses Choice qui impriment leur Student, etc.
    // Imprimez juste des informations clés de l'étudiant si nécessaire, ou son ID/nom.
    return 'Choix{École: $school, Classement Inter.: $interranking}';
  }

  @override
  bool operator ==(Object other) {
    // TODO: implement ==
    return super == other;
  }


}