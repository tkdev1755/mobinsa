# Mob'INSA

Une application flutter pour étudier les mobilités.

## Quel est le but ?

Cette application a pour but d'aider les différents responsables lors du jury d'attribution des mobilités. 
Pour concevoir cette application, nous avons utilisé le langage dart ainsi que le framework flutter qui permet d'utiliser la 
programmation orienté objet de manière simple et flexible. Cette application n'a pas pour but de fournir un résultat définitif au jury 
quand à l'attribution des mobilités mais seulement un accompagnement afin de gérer les attributions, refus, etc de manière plus souple et visuel.

## Comment utiliser Mob'INSA

L'application Mob'INSA est très simple d'utilisation. Il suffit de cliquer sur l'icône correspondante
puis se laisser guider par la notice utilisateur : //Mettre lien vers le guide utilisateur

## Quelles Fonctionnalités ?
### Fonctionnalités implémentées

✅ - Gestion fluide de tous les étudiants avec une colonne permettant de passer à chaque étudiant très simplement

✅ - Gestion de l'acceptation ou le refus de voeux pour un étudiant

✅ - Ajustement automatique du nombre de place restante sur une offre de séjour en fonction du point précédent

✅ - Récapitulatif des informations importantes sur l'étudiant (niveau d'anglais, heure d'absence,...)

✅ - Récapitulatif des informations importantes sur une offre de séjour (pays, niveau académique,...)

✅ - Possibilité de laisser un commentaire pour un voeu d'un étudiant

✅ - Poissibilité de passer à l'étudiant suivant ou de revenir à l'étudiant précédent à partir d'une page d'un étudiant

✅ - Génération de tableaux excel à partir des résultats que le jury à fixé avec l'outil Mob'INSA (tableau récapitulatif général, tableau récapitulatif pour les étudiants ayant un voeu accepté, tableau récapitulatif pour les étudants n'ayant eu aucune proposition de voeu)

## Questions fréquentes

### Pourquoi il y’a des fichiers `.dll`, `.dylib`, `.so` avec le binaire ?
    - Le langage de programmation utilisé (Dart) ne possède pas de librairie donnant accès au trousseau de clé du système d’exploitation, par conséquent j’ai du développer une "librairie" en C pour interagir avec le trousseau de clés, plus de détail sont donnés dans le wiki. Tout le code source de la « librairie » C est disponible sur le github dans le dossier lib/model/KeychainAPI/${votre_système_d’exploitation}/${votre_système_d’exploitation}keychainAPI.c

----

### Pourquoi avoir développé en Dart et pas en python ?
    - En majeure partie parce que c’est le langage que nous avons trouvé le plus approprié pour ce projet car il permet de compiler sur toutes les plateforms majeurs. 
    - Ce choix est issu d'un vote où chacun a pu proposer un langage de programmation qui lui semblait adéquat pour le projet.
