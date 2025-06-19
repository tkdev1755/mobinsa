/// Représente les statistiques de répartition des choix et des refus.
///
/// Cette classe permet de suivre combien d'étudiants ont obtenu leur
/// 1er, 2e ou 3e choix, ainsi que combien ont été refusés de toutes leurs options.
class Stats {
  /// Nombre d'étudiants ayant obtenu leur premier choix.
  int choice1 = 0;

  /// Nombre d'étudiants ayant obtenu leur deuxième choix.
  int choice2 = 0;

  /// Nombre d'étudiants ayant obtenu leur troisième choix.
  int choice3 = 0;

  /// Nombre d'étudiants ayant été refusés dans toutes leurs options.
  int rejected = 0;

  /// Constructeur par défaut de la classe [Stats].
  Stats();
  /// Incrémente le nombre d'étudiants ayant obtenu leur premier choix.
  void add_c1() {
    choice1 = choice1 + 1;
  }

  /// Incrémente le nombre d'étudiants ayant obtenu leur deuxième choix.
  void add_c2() {
    choice2 = choice2 + 1;
  }

  /// Incrémente le nombre d'étudiants ayant obtenu leur troisième choix.
  void add_c3() {
    choice3 = choice3 + 1;
  }

  /// Incrémente le nombre d'étudiants refusés dans tous leurs choix.
  void add_r() {
    rejected = rejected + 1;
  }

  /// Retourne une chaîne de caractères décrivant les statistiques.
  @override
  String toString() {
    return 'Résultats {Choix 1: $choice1, Choix 2: $choice2, Choix 3: $choice3, rejected: $rejected}';
  }
}