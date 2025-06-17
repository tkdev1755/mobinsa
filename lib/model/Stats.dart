class Stats {
  int choice1 = 0;
  int choice2 = 0;
  int choice3 = 0;
  int rejected = 0;

  Stats();
  void add_c1() {
    choice1 = choice1 + 1;
  }

  void add_c2() {
    choice2 = choice2 + 1;
  }

  void add_c3() {
    choice3 = choice3 + 1;
  }

  void add_r() {
    rejected = rejected + 1;
  }

  @override
  String toString() {
    return 'Résultats {Choix 1: $choice1, Choix 2: $choice2, Choix 3: $choice3, rejected: $rejected}';
  }
}