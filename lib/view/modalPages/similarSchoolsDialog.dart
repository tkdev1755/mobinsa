import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:mobinsa/model/parser.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../model/School.dart';
import '../../model/Student.dart';
import '../uiElements.dart';



class SimilarSchoolsDialog extends StatefulWidget {
  final List<(double, School)>similarSchools;
  final List<School> schools;
  final Map<String, dynamic>problematicSchool;
  final Excel excelFile;
  final List<bool> writeExcelToDisk;
  final List<bool> cancelProcedure;
  SimilarSchoolsDialog({super.key, required this.similarSchools, required this.schools, required this.excelFile, required this.problematicSchool, required this.writeExcelToDisk, required this.cancelProcedure});

  @override
  State<SimilarSchoolsDialog> createState() => _SimilarSchoolsDialogState();
}

class _SimilarSchoolsDialogState extends State<SimilarSchoolsDialog> {
  List<bool> selectedIndex = [false, false];
  String searchedSimilarSchool = "";
  List<(double,School)> searchedSchools =[];
  int selectedSchool = -1;
  bool saveModificationsOnDisk = false;
  bool noException = false;
  @override
  void initState() {
    print("Excel write to disk ${widget.writeExcelToDisk}");
    searchedSchools = widget.similarSchools;
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 850,
        height: 550,
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                    child: Text("L'école du voeu associée n'a pas été trouvée, veuillez sélectionner celle qui convient", style: UiText().nText,)),
                Padding(padding: EdgeInsets.only(right: 20)),
                IconButton(onPressed: (){
                  widget.cancelProcedure[0] = true;
                  Navigator.pop(context);
                },
                    icon: Icon(PhosphorIcons.x()),
                  tooltip: "Annuler",
                )
              ],
            ),
            UiShapes.bPadding(10),
            Expanded(
              child: Row(
                children: [
                  Flexible(
                    flex: 1,
                    child: Container(
                      margin: EdgeInsets.only(right: 10),
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: UiShapes().frameRadius
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("École problématique",style: UiText(weight: FontWeight.w600).nText,),
                          UiShapes.bPadding(10),
                          Text("Nom :", style: UiText().nsText,),
                          Text("${widget.problematicSchool["name"]}", style: UiText(weight: FontWeight.w500).nText),
                          UiShapes.bPadding(10),
                          Text("Pays :", style: UiText().smallText),
                          Text("${widget.problematicSchool["country"]}", style: UiText().nText,),
                          UiShapes.bPadding(10),
                          Text("Formation concernée : ", style: UiText().smallText),
                          Text("${Student.getNextYearFromString(widget.problematicSchool["specialization"])}", style: UiText().nText),
                          UiShapes.bPadding(10),
                          Text("Nom de l'étudiant : ", style: UiText().smallText),
                          Expanded(child: Text("${widget.problematicSchool["studentName"]}", style: UiText().nText, overflow: TextOverflow.fade,)),
                        ],
                      ),
                    ),
                  ),
                  Flexible(
                    flex: 2,
                    child: Container(
                      decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: UiShapes().frameRadius
                      ),
                      margin: EdgeInsets.only(left: 5),
                      padding: EdgeInsets.all(10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Écoles similaires",style: UiText(weight: FontWeight.w600).nText,),
                          UiShapes.bPadding(10),
                          TextField(
                            onChanged: (String value){
                              searchedSimilarSchool = value;
                              searchedSchools = widget.similarSchools.where((e) => e.$2.name.contains(searchedSimilarSchool)).toList();
                              setState(() {
                              });
                            },
                            decoration: InputDecoration(
                              hintText: "Recherchez votre école",
                              suffixIcon: IconButton(onPressed: (){},icon: Icon(PhosphorIcons.magnifyingGlass()))
                            ),
                          ),
                          UiShapes.bPadding(10),
                          Expanded(
                            child: ListView.builder(
                                itemCount: searchedSchools.length,
                                scrollDirection: Axis.vertical,
                                itemBuilder: (BuildContext context, int index){
                                  return similarSchoolCard(searchedSchools[index].$2, searchedSchools[index].$1,index);
                                }
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            UiShapes.bPadding(10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Checkbox(value: widget.writeExcelToDisk[0], onChanged: (bool? value){
                    setState(() {
                      widget.writeExcelToDisk[0] = value ?? widget.writeExcelToDisk[0];
                    });
                  },
                ),
                Text("Sauvegarder ces modifications sur le fichier"),
                Padding(padding: EdgeInsets.only(right: 10),),
                TextButton(
                    onPressed: (){
                      Navigator.pop(context);
                      if (selectedSchool != -1){
                        widget.excelFile.sheets.values.first.row(widget.problematicSchool["concernedCell"].$2)[widget.problematicSchool["concernedCell"].$1]?.value = TextCellValue(searchedSchools[selectedSchool].$2.name);
                        setState(() {
                          print("Write to disk before : ${widget.writeExcelToDisk} | save mods ${saveModificationsOnDisk}");
                          print("Write to disk after : ${widget.writeExcelToDisk} | save mods ${saveModificationsOnDisk}");
                        });
                      }
                    },
                    child: Text("Enregistrer les changements"))
              ],
            )
          ],
        ),
      ),
    );
  }

  bool matchesSpecialization(String specialization, School school){
    return school.specialization.contains(specialization);
  }

  Widget similarSchoolCard(School school, double similarity, int index){
    bool selected = index == selectedSchool;
    bool otherSelected = selectedSchool != -1;
    return Card(
      child: InkWell(
        onTap: (){},
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("${school.name}",style: UiText().nText,),
                  UiShapes.bPadding(10),
                  Text("Pays : ${school.country}",style: UiText().smallText,),
                  UiShapes.bPadding(5),
                  Text("Formation : ${school.getSpecializations()}", style: UiText(
                    color: (
                        matchesSpecialization(Student.getNextYearFromString(widget.problematicSchool["specialization"]), school) ? Colors.green.shade800.toARGB32(): Colors.orange.toARGB32()
                    )
                  ).smallText,)
                ],
              )),
              Visibility(
                visible: selected ,
                replacement: Visibility(
                    visible: otherSelected,
                    replacement: Tooltip(
                      message: "Sélectionner cette école",
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),

                        ),
                        onPressed: (){
                          if (!selected){
                            selectedSchool = index;
                            setState(() {

                            });
                          }
                        }, child: Icon(
                          color: Colors.white,
                          PhosphorIcons.check()),
                      ),
                    ),
                    child: Tooltip(
                      message: "Veuillez déselectionner l'école choisie pour en choisir une autre",
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey,
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        onPressed: null, child: Icon(
                          color: Colors.white,
                          PhosphorIcons.check()),
                      ),
                    )
                ),
                  child: Tooltip(
                    message: "Déselectionner l'école",
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      onPressed: (){
                        setState(() {
                          selectedSchool = -1;
                        });
                      }, child: Icon(
                        color: Colors.white,
                        PhosphorIcons.x()),
                    ),
                  ),
              )
            ],
          ),
        ),
      ),
    );
  }

}