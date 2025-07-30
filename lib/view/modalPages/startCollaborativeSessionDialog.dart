

import 'package:flutter/material.dart';
import 'package:mobinsa/model/School.dart';
import 'package:mobinsa/model/networkManager.dart';

import '../../model/Student.dart';
import '../uiElements.dart';

class StartCollaborativeSessionDialog extends StatefulWidget {
  final NetworkManager networkManager;
  final List<bool> startNetworkSession;
  final List<Student> students;
  final List<School> schools;
  StartCollaborativeSessionDialog({super.key, required this.networkManager, required this.startNetworkSession, required this.students, required this.schools});

  @override
  State<StartCollaborativeSessionDialog> createState() => _StartCollaborativeSessionDialogState();
}

class _StartCollaborativeSessionDialogState extends State<StartCollaborativeSessionDialog> {
  Future<bool>? connectedToHttpServer;
  bool sendingData = false;
  bool sentData = false;
  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
          padding: EdgeInsets.all(20),
          width: 450,
          height: 500,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Démarrer une session collaborative", style: UiText().mediumText,),
              UiShapes.bPadding(10),
              Text("Souhaitez-vous activer la session collaborative ? ",style: UiText().nText,),
              UiShapes.bPadding(10),
              Row(
                children: [
                  Text("Démarrer la sesion collaborative", style: UiText().nsText,),
                  Spacer(),
                  Switch(value: widget.startNetworkSession[0], onChanged: (value) async{
                    if (widget.startNetworkSession[0]){
                      if (widget.networkManager.isServerInitialized()){
                        print("Stopping communications");
                        widget.networkManager.closedConnections = true;
                        await widget.networkManager.closeConnections();
                        widget.startNetworkSession[0] = false;
                        setState(() {
                        });
                      }
                    }
                    else{
                      print("Starting communications");
                      widget.startNetworkSession[0] = await widget.networkManager.startNetworkCommunications();
                      setState(() {
                      });
                      print("Listening to messages");
                      widget.networkManager.listenToMessages();
                    }
                  }),
                ],
              ),
              UiShapes.bPadding(20),
              Expanded(child: sessionStatus())
            ],
          ),
      ),
    );
  }

  Widget sessionStatus(){
    switch (widget.networkManager.getStatus()){
      case NetworkManager.initializedStatus:
        return connectionFutureStatus();
        break;
      case NetworkManager.offStatus:
        return Container();
      default:
        return Container();
    }
  }
  Widget connectionFutureStatus(){
    return FutureBuilder(future: widget.networkManager.isConnectedFuture, builder: (BuildContext context, AsyncSnapshot snap){
      if (snap.hasData){
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Mob'INSA est désormais disponible à l'adresse 127.0.0.1", style: UiText().nText,),
            UiShapes.bPadding(10),
            Text("Clients connectés", style: UiText().nText,),
            Expanded(
                child: ListenableBuilder(listenable: widget.networkManager, builder: (BuildContext context, Widget? child){
                  return ListView.builder(
                      itemCount: widget.networkManager.connectedClients.length,
                      scrollDirection: Axis.vertical,
                      itemBuilder: (BuildContext context, int index){
                        return Card(
                          child: Container(
                            padding: EdgeInsets.all(8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(widget.networkManager.connectedClients[index]["name"], style: UiText().nText,),
                                  UiShapes.bPadding(5),
                                  Text(widget.networkManager.connectedClients[index]["mail"], style: UiText().smallText,),
                                ],
                              )),
                        );
                      });
                })
            ),
            Row(
              children: [
                Visibility(
                  visible: sendingData,
                  child : CircularProgressIndicator(),
                  replacement: Visibility(
                    visible: !widget.networkManager.hasJuryStarted,
                    replacement: ElevatedButton(onPressed: (){}, child: Text("Fermer le jury")),
                      child: ElevatedButton(onPressed: () async {
                        Map<String,List> data = {
                          "students" : [],
                          "schools" : []
                        };
                        for (var student in widget.students){
                          data["students"]!.add(student.toJson());
                        }
                        for (var school in widget.schools){
                          data["schools"]!.add(school.toJson());
                        }
                        widget.networkManager.sendInitialData(data);
                        setState(() {
                          sendingData = true;
                        });
                        await widget.networkManager.startJury;
                        setState(() {
                          sendingData = false;
                          sentData = true;
                          Future.delayed(Duration(seconds: 2), (){
                            if (mounted){
                              sentData = false;
                            }
                          });
                        });
                      }, child: Text("Démarrer le jury")),
                  )
                ),
                AnimatedOpacity(
                  opacity: sentData ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  child: Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: UiShapes().frameRadius,
                    ),
                    child: Text(
                      "Fichier enregistré !",
                      style: UiText(color: UiColors.white).smallText,
                    ),
                  ),
                ),
              ],
            )
          ],
        );
      }
      else{
        return Container(
          child: Row(
            children: [
              Text("Démarrage du serveur", style: UiText().nText,),
              Spacer(),
              CircularProgressIndicator()
            ],
          ),
        );
      }
    });
  }
}