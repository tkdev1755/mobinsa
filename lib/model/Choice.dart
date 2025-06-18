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
    if (school.accepted(s)) {
      student.accepted = this;
      print("ACCEPTED CHOICE");
      return true;
    }
    return false;
  }

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

  void remove_choice() {
    student.accepted = null;
    school.add_slots(student);
  }

  bool is_incoherent(){
    if (!(school.specialization.contains(student.get_next_year()))){
      return true;
    }
    else {
      return false;
    }

  }




  @override
  String toString() {
    // Attention à ne pas imprimer student.toString() ici pour éviter une boucle infinie
    // si Student.toString() imprime aussi ses Choice qui impriment leur Student, etc.
    // Imprimez juste des informations clés de l'étudiant si nécessaire, ou son ID/nom.
    // return 'Choix{École: $school, Classement Inter.: $interranking}';
    return school.name;
  }

  @override
  bool operator ==(Object other) {
    // if (identical(this, other)) return true;
    if (other is! Choice) return false;
    return school.id == other.school.id;
  }


}