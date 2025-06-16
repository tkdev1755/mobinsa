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

}