
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobinsa/model/versionManager.dart';
import 'package:mobinsa/view/uiElements.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';



class UpdateDialog extends StatefulWidget {
  final SoftwareUpdater softwareUpdater;
  const UpdateDialog({super.key, required this.softwareUpdater});

  @override
  State<UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<UpdateDialog> {
  late Future<String?> latestVersionInfo;
  bool startedUpdate = false;
  String message = "";
  @override
  @override
  void initState() {
    latestVersionInfo = widget.softwareUpdater.getLatestVersionDetails();
    super.initState();
  }
  Widget build(BuildContext context) {
    return Dialog(

      semanticsRole: SemanticsRole.alert,
      child:Container(
        padding: EdgeInsets.all(20),
        width: MediaQuery.sizeOf(context).width*0.5,
        height: MediaQuery.sizeOf(context).height*0.4,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Une mise à jour est disponible",style: UiText().mediumText,),
            UiShapes.bPadding(10),
            Row(
              children: [
                Text("v${widget.softwareUpdater.currentVersion.$1}.${widget.softwareUpdater.currentVersion.$2}.${widget.softwareUpdater.currentVersion.$3}", style: UiText().smallText,),
                Padding(padding: EdgeInsets.only(right: 10)),
                Icon(PhosphorIcons.arrowRight(), size: 25,),
                Padding(padding: EdgeInsets.only(right: 10)),
                Text("v${widget.softwareUpdater.latestVersion!.$1}.${widget.softwareUpdater.latestVersion!.$2}.${widget.softwareUpdater.latestVersion!.$3}", style: UiText().smallText),
              ],
            ),
            UiShapes.bPadding(10),
            Text("Détails", style: UiText().nText,),
            UiShapes.bPadding(10),
            FutureBuilder(future: latestVersionInfo, builder: (BuildContext context, AsyncSnapshot snap){
              if (snap.hasData){
                return Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      borderRadius: UiShapes().frameRadius,

                    ),
                    child: SingleChildScrollView(
                        child: Text("${snap.data}", style: UiText().nsText,)
                    ),
                  
                );
              }
              else if (snap.hasError){
                return Text("Impossible de récupérer les détails sur la dernière version");
              }
              else{
                return CircularProgressIndicator();
              }
            }),
            Spacer(),
            Visibility(
              visible: !startedUpdate,
              replacement: Row(
                children: [
                  Spacer(),
                  Text("${message}",style: UiText().smallText,),
                  Padding(padding: EdgeInsets.only(right: 20)),
                  CircularProgressIndicator(),
                ],
              ),
              child: Row(
                children: [
                  Spacer(),
                  TextButton(onPressed: (){
                    Navigator.pop(context);
                  }, child: Text("Plus tard", style: GoogleFonts.montserrat(),)),
                  TextButton(onPressed: () async{
                    print("Launching download process");
                    setState(() {
                      startedUpdate = true;
                      message = "Téléchargement de la mise à jour";
                    });
                    String? updatePath = await widget.softwareUpdater.getUpdate() ?? "";
                    if (updatePath == null){
                      print("Erreur lors de la mise à jour");
                      return;
                    }
                    setState(() {
                      message  = "Installation de la mise à jour";
                    });
                    //await widget.softwareUpdater.performUpdate(updatePath);
                    setState(() {
                      startedUpdate = false;
                    });
                  }, child: Text("Télécharger", style: GoogleFonts.montserrat(textStyle: TextStyle(fontWeight: FontWeight.w600)),)),
                ],
              ),
            )
          ],
        ),
      ) ,
    );
  }
}