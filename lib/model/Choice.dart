import 'package:mobinsa/model/School.dart';
import 'package:mobinsa/model/Student.dart';

class Choice {
  School school;
  double interranking;
  Student student;

  Choice (this.school, this.interranking,this.student);

  // bool accepted (){
  //   if (school.accepted()){
  //     student.accepted = this;
  //     return true;
  //   }
  //   else {
  //     return false;
  //   }
  // }

  @override
  String toString() {
    // Attention à ne pas imprimer student.toString() ici pour éviter une boucle infinie
    // si Student.toString() imprime aussi ses Choice qui impriment leur Student, etc.
    // Imprimez juste des informations clés de l'étudiant si nécessaire, ou son ID/nom.
    return 'Choix{École: $school, Classement Inter.: $interranking}';
  }

}