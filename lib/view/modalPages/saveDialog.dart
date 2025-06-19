
// Copyright 2018 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:mobinsa/model/School.dart';
import 'package:mobinsa/model/sessionStorage.dart';
import 'package:mobinsa/view/displayApplicants.dart';
import 'package:mobinsa/view/uiElements.dart';
import 'package:intl/intl.dart'; 
import '../../model/Student.dart';



class SaveDialog extends StatefulWidget {
  const SaveDialog({Key? key}) : super(key: key);

  @override
  State<SaveDialog> createState() => _SaveDialogState();
}

class _SaveDialogState extends State<SaveDialog> {
  late Future<List<(String,String)>> saves;
  @override
  void initState(){
    saves = SessionStorage.askForLoadPath();
  }

  String parseSaveText(String filename){

    List<String> splitFilename = filename.split("_").toList();
    if (splitFilename.length < 2){
      return "date inconnue";
    }
    String strDate = splitFilename[1];
    DateTime date = DateFormat(SessionStorage.dateFormat).parse(strDate);
    return "${DateFormat("dd/MM/yyyy").format(date)} à ${DateFormat("HH:mm").format(date)}";
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        padding: EdgeInsets.all(20),
        width: MediaQuery.sizeOf(context).width*0.3,
        height: MediaQuery.sizeOf(context).height*0.4,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Text("Sélectionnez la sauvegarde", style: UiText().mediumText,),
            FutureBuilder(future: saves, builder: (BuildContext context, AsyncSnapshot<List<(String,String)>> data){
              if (data.hasData){
                List<(String,String)> saveList = data.data ?? [];
                return Expanded(
                  child: ListView.builder(
                      itemCount: saveList.length,
                      scrollDirection: Axis.vertical,
                      itemBuilder: (BuildContext context, int index){
                        return saveCard(saveList[index]);
                      }),
                );
              }
              else{
                return Text("Loading saves");
              }
            }),
            ElevatedButton(onPressed: () async {

            }, child: Text("Load save")),

          ],
        ),
      ),
    );
  }
  Widget saveCard((String,String) saveInfo){
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: (){
          String path = saveInfo.$1;
          Map<String, dynamic> encodedData = {};
          try {
          } catch (e, s) {
            print("Something went wrong when loading the file \n Details  : $e, $s");
          }
          try {
            encodedData =   SessionStorage.loadData(path);
          }
          catch (e,s){
            print("Something went wrong when reading the data \n Details : $e, $s");
          }
          List<Student> students = [];
          List<School> schools = [];
          Map<String, dynamic> decodedData = {};

          try {
            decodedData = SessionStorage.deserializeData(encodedData);
          }
          catch(e,s){
            print("Something went wrong when deserializing the Data ?  the data \n Details : $e, $s");
          }
          schools = decodedData["schools"];
          students = decodedData["students"];
          print("schools  ressemble to this ${schools}");
          print("students resemble to this ${students}");
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => DisplayApplicants(schools: schools, students: students, loadedSave: saveInfo,)),);
        },
        child: Container(
          padding: EdgeInsets.all(10),
          child: Row(
            children: [
              Text("Séance du ${parseSaveText(saveInfo.$2)}",style: UiText().nText,),
            ],
          ),
        ),
      ),
    );
  }
}