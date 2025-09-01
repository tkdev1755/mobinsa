
import 'package:flutter/material.dart';
import 'package:mobinsa/model/ServerRuntimeChecker.dart';
import 'package:mobinsa/view/uiElements.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class MobServerDlDialog extends StatefulWidget {
  final ServerRuntimeChecker serverRuntimeChecker;
  final Function onServerDownload;
  const MobServerDlDialog({super.key, required this.serverRuntimeChecker, required this.onServerDownload});

  @override
  State<MobServerDlDialog> createState() => _MobServerDlDialogState();
}

class _MobServerDlDialogState extends State<MobServerDlDialog> {
  Stream<double>? downloadStream;
  bool hasBegunDownload = false;
  String displayedMessage = "Démarrage du téléchargement";
  bool installState = false;
  @override
  Widget build(BuildContext context) {
    return Visibility(
      visible: !hasBegunDownload,
      replacement: Container(
        width: 600,
        height: 250,
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            widget.serverRuntimeChecker.downloadStarted ? CircularProgressIndicator() :
                ValueListenableBuilder<double>(valueListenable: widget.serverRuntimeChecker.progress,
                    builder: (BuildContext context, value,child){
                      if (value == 1 && widget.serverRuntimeChecker.hasDownloadedSoftware && !widget.serverRuntimeChecker.hasInstalledSoftware && !installState){
                        displayedMessage = "Installation du logiciel";
                        //widget.serverRuntimeChecker.installServerRuntime();
                        print("NOW INSTALLING THE SOFTWARE");
                        widget.serverRuntimeChecker.installServerRuntime();
                        installState = true;
                        widget.onServerDownload();
                      }
                      return LinearProgressIndicator(
                        value: value,
                        borderRadius: UiShapes().frameRadius,
                      );

                    }
                ),
            Text(displayedMessage, style: UiText().mediumText,)
          ],
        ),
      ),
      child: Container(
        width: 600,
        height: 250,
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Icon(PhosphorIcons.info()),
                UiShapes.rPadding(10),
                Text("Information", style: UiText().nText,),
              ],
            ),
            UiShapes.bPadding(20),
            Text("Il semble que le module permettant les jury collaboratifs n'est pas installé, souhaitez-vous l'installer ?",style: UiText().mediumText,),
            UiShapes.bPadding(10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton(onPressed: (){
                  Navigator.pop(context);
                }, child: Text("Non")),
                UiShapes.rPadding(20),
                ElevatedButton(onPressed: () async{
                  setState(() {
                    hasBegunDownload = true;
                    widget.serverRuntimeChecker.downloadServerRuntime();
                  });
                  if (widget.serverRuntimeChecker.hasCompletedCompleters()){
                    widget.serverRuntimeChecker.resetAllCompleters();
                  }
                  await widget.serverRuntimeChecker.hasStartedDownloadCompleter.future;
                  displayedMessage = "Téléchargement du module complémentaire";
                  setState(() {

                  });
                }, child: Text("Oui")),
              ],
            )
          ],
        ),
      )
    );
  }
}