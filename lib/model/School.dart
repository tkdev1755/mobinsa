class School{
  int id;
  String name;
  String content_type;
  int available_slots;
  int b_slots;
  int m_slots;
  List<String> specialization;
  String graduation_level;
  String program;
  String use_langage;
  String req_lang_level;
  String academic_level;
  bool is_full = false;

  School(this.id, this.name, this.content_type, this.available_slots, this.b_slots, this.m_slots, this.specialization, this.graduation_level, this.program, this.use_langage, this.req_lang_level, this.academic_level);
  void reduce_slots() {}
  void add_slots() {}
  bool accepted() {
    return true;
  }
}