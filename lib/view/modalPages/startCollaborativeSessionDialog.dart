

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:mobinsa/model/School.dart';
import 'package:mobinsa/model/ServerRuntimeChecker.dart';
import 'package:mobinsa/model/networkManager.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../model/Student.dart';
import '../uiElements.dart';
import 'mobinsaServerDownloadDialog.dart';

class StartCollaborativeSessionDialog extends StatefulWidget {
  final ServerRuntimeChecker serverRuntimeChecker;
  final NetworkManager networkManager;
  final Function onServerDownloadFunc;
  final List<bool> startNetworkSession;
  final List<Student> students;
  final List<School> schools;
  const StartCollaborativeSessionDialog({super.key, required this.networkManager, required this.startNetworkSession, required this.serverRuntimeChecker,required this.students, required this.schools, required this.onServerDownloadFunc});

  @override
  State<StartCollaborativeSessionDialog> createState() => _StartCollaborativeSessionDialogState();
}

class _StartCollaborativeSessionDialogState extends State<StartCollaborativeSessionDialog> {
  Future<bool>? connectedToHttpServer;
  SharedPreferencesAsync sharedPreferencesAsync = SharedPreferencesAsync();
  bool sendingData = false;
  bool trustedEmailsAdd = false;
  bool startSession = false;
  bool sentData = false;
  String _sessionPassword = "";
  bool expandedLogs = false;
  late Future<int> serverRuntimeStatus;
  @override
  @override
  void initState() {
    // TODO: implement initState
    print("Checking if server was correctly donwloaded");
    try{
      serverRuntimeStatus = widget.serverRuntimeChecker.hasDownloadedServerRuntime();

    }
    catch (e){
        rethrow;
    }
    super.initState();
  }
  void sendAdressByEmail(String address){
    final body = '''
Bonjour,

Rejoignez le jury Collaboratif Mob'INSA à l'adresse suivante :

👉 https://${address}


---

''';
    final mailto = 'mailto:?subject=Rejoignez mon Jury Collaboratif - MobINSA&body=$body';
    if(Platform.isWindows){
      final mailto2 = 'mailto:?subject=Rejoignez%20mon%20Jury%20Collaboratif%20-%20MobINSA';
      Process.run("explorer", [mailto]);
    }
    else{
      Process.run("open", [mailto]);
    }
  }
  Future<List<String>?> getTrustedEmails() async{
    bool trustedEmailsExists = await sharedPreferencesAsync.containsKey("netTrustedEmails");
    return trustedEmailsExists ?  await sharedPreferencesAsync.getStringList("netTrustedEmails") : [];
  }
  void onServerDownload(){
    print("SERVER DOWNLOADED");
    /*setState(() {

    });*/
    serverRuntimeStatus = Future.value(0);
  }
  @override
  Widget build(BuildContext context) {
    Widget StartServerWidget = Container(
      padding: EdgeInsets.all(20),
      width: 950,
      height: 500,
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Démarrer une session collaborative", style: UiText().mediumText,),
                UiShapes.bPadding(10),
                Text("Souhaitez-vous activer la session collaborative ? ",style: UiText().nText,),
                UiShapes.bPadding(10),
                Row(
                  children: [
                    Expanded(child: Text("Démarrer la sesion collaborative", style: UiText().nsText,)),
                    UiShapes.rPadding(20),
                    Switch(value: widget.startNetworkSession[0], onChanged: (value) async{
                      if (widget.startNetworkSession[0]){
                        if (widget.networkManager.isServerInitialized()){
                          print("Stopping communications");
                          widget.networkManager.closedConnections = true;
                          await widget.networkManager.closeConnections();

                        }
                        widget.startNetworkSession[0] = false;
                        widget.networkManager.hasInitializedPassword = false;
                        setState(() {

                        });
                      }
                      else{
                        print("Starting communications");
                        List<String>? trustedEmails = await getTrustedEmails();
                        if (trustedEmails == null){
                          trustedEmailsAdd = true;
                        }
                        widget.startNetworkSession[0] = true;

                        setState(() {
                        });
                      }
                    }),
                  ],
                ),
                UiShapes.bPadding(20),
                Expanded(
                  child: Visibility(
                      replacement: Visibility(visible: widget.startNetworkSession[0],child: Expanded(child: sessionConfigWidget())),
                      visible: widget.networkManager.hasInitializedPassword,
                      child: Expanded(child: sessionStatus())
                  ),
                )
              ],
            ),
          ),
          UiShapes.rPadding(20),
          Expanded(
              flex: 3,
              child: sessionStatus2())
        ],
      ),
    );
    /*if (kDebugMode){
      return Dialog(child : StartServerWidget);
    }*/
    return Dialog(
      child: ListenableBuilder(
        listenable: widget.serverRuntimeChecker,
        builder: (BuildContext context, Widget? child){
          return FutureBuilder(
            future: serverRuntimeStatus,
            builder: (BuildContext context, AsyncSnapshot snap){
              if (snap.hasData){
                if (snap.data == 0){
                  print("Server already downloaded");
                  return StartServerWidget;
                }
                else{
                  print("need to download the server");
                  return MobServerDlDialog(serverRuntimeChecker: widget.serverRuntimeChecker,onServerDownload: onServerDownload,);
                }
              }
              else if (snap.hasError){
                return Container(
                  width: 500,
                  height: 300,
                  child: Container(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,

                      children: [
                        Row(
                          children: [
                            Icon(PhosphorIcons.info()),
                            UiShapes.rPadding(10),
                            Text("Erreur lors de la vérification :",style: UiText().nText,),
                          ],
                        ),
                        UiShapes.bPadding(20),
                        Text("${snap.error}", style: UiText().mediumText,),
                      ],
                    ),
                  ),
                );
              }
              else{
                return Container(
                  padding: EdgeInsets.all(20),
                  child: Row(
                    children: [
                      CircularProgressIndicator(),
                      UiShapes.rPadding(20),
                      Text("Vérification de la présence du logiciel collaboratif", style: UiText().largeText,)
                    ],
                  ),
                );
              }

            },
          );
        },
      ),
    );
  }

  Widget sessionStatus(){
    switch (widget.networkManager.getStatus()){
      case NetworkManager.initializedStatus:
        return connectionFutureStatus();
      case NetworkManager.offStatus:
        return Container();
      default:
        return Container();
    }
  }

  Widget sessionConfigWidget(){
    if (trustedEmailsAdd){
      return Container(
        child: Column(
          children: [
            Text("Vous ne semblez pas avoir d'emails de confiances, veuillez les ajouter ci-dessous"),
          ],
        ),
      );
    }
    else{
      return Container(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Veuillez saisir le mot de passe pour cette session",style: UiText().nText,),
            UiShapes.bPadding(20),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: (String value){
                      _sessionPassword = value;
                    },
                  ),
                ),
                UiShapes.rPadding(30),
                ElevatedButton(onPressed: () async{
                  print("Starting communications");
                  widget.networkManager.setSessionPassword(_sessionPassword);
                  widget.networkManager.hasInitializedPassword = await widget.networkManager.startNetworkCommunications(widget.serverRuntimeChecker);
                  setState(() {

                  });
                  widget.networkManager.listenToMessages();
                }, child: Icon(PhosphorIcons.check())),
              ],
            ),
          ],
        ),
      );
    }
  }
  Widget connectionFutureStatus(){
    return FutureBuilder(future: widget.networkManager.isConnectedFuture, builder: (BuildContext context, AsyncSnapshot snap){
      if (snap.hasData){

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                Expanded(
                  child: Visibility(
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
                                setState(() {
                                  sentData = false;
                                });
                              }
                            });
                          });
                        }, child: Text("Démarrer le jury")),
                    )
                  ),
                ),
                UiShapes.rPadding(20),
                AnimatedOpacity(
                  opacity: sentData ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  child: Container(
                    padding: EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: UiShapes().frameRadius,
                    ),
                    child: Text(
                      "Jury démarré",
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
  Widget sessionStatus2(){
    switch (widget.networkManager.getStatus()){
      case NetworkManager.initializedStatus:
        return connectionFutureStatus2();
      case NetworkManager.offStatus:
        return Container();
      default:
        return Container();
    }
  }
  Widget connectionFutureStatus2(){
    return FutureBuilder(future: widget.networkManager.isConnectedFuture, builder: (BuildContext context, AsyncSnapshot snap){
      if (snap.hasData){
        String httpAdress = widget.networkManager.httpHostAdress != null && widget.networkManager.httpHostAdress != "" ? "${widget.networkManager.httpHostAdress}:8080" :"${widget.networkManager.httpIPAddress}:8080";

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Mob'INSA est désormais disponible à l'adresse", style: UiText().largeText,),
            UiShapes.bPadding(10),
            Row(
              children: [
                Expanded(child: Text("https://${httpAdress}", style: UiText(weight: FontWeight.w600).vLargeText,)),
                UiShapes.rPadding(20),
                IconButton(onPressed: (){
                  sendAdressByEmail(httpAdress);
                }, icon: Icon(PhosphorIcons.paperPlane()), tooltip: "Envoyer par mail",)
              ],
            ),
            UiShapes.bPadding(10),
            ListenableBuilder(
              listenable: widget.networkManager,
              builder: (BuildContext context,Widget? child) {
                return Expanded(
                  child: Visibility(
                    visible: expandedLogs,
                    replacement: Row(
                      children: [
                        Text("Logs du server : ", style: UiText().nText,),
                        Spacer(),
                        IconButton(onPressed: (){
                          setState(() {
                            expandedLogs = true;
                          });
                        }, icon: Icon(PhosphorIcons.arrowDown()))
                      ],
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment : CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text("Logs du server : ", style: UiText().nText,),
                              Spacer(),
                              IconButton(onPressed: (){
                                setState(() {
                                  expandedLogs = false;
                                });
                              }, icon: Icon(PhosphorIcons.arrowUp()))
                            ],
                          ),
                          Text(widget.networkManager.serverSTDOUT.toString()),
                        ],
                      ),
                    ),
                  ),
                );
              }
            )
          ],
        );
      }
      else{
        return ListenableBuilder(
            listenable: widget.networkManager,
            builder: (BuildContext context,Widget? child) {
              return Expanded(
                child: Visibility(
                  visible: expandedLogs,
                  child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment : CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text("Logs du server : ", style: UiText().nText,),
                              Spacer(),
                              IconButton(onPressed: (){
                                setState(() {
                                  expandedLogs = false;
                                });
                              }, icon: Icon(PhosphorIcons.arrowUp()))
                            ],
                          ),
                          Text(widget.networkManager.serverSTDOUT.toString()),
                        ],
                      ),
                    ),
                  replacement: Row(
                    children: [
                      Text("Logs du server : ", style: UiText().nText,),
                      Spacer(),
                      IconButton(onPressed: (){
                        setState(() {
                          expandedLogs = true;
                        });
                      }, icon: Icon(PhosphorIcons.arrowDown()))
                    ],
                  ),
                ),
              );
            }
        );
      }
    });
  }
}