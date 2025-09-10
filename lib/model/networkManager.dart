


import 'dart:async';
import 'dart:io';
import 'dart:convert';

import 'package:mobinsa/model/ServerRuntimeChecker.dart';
import 'package:flutter/cupertino.dart';

/// Class which manages the collaboratives sessions initiated by the Jury Master
///
/// Has the ChangeNotifier Mixin for UI Updates
class NetworkManager with ChangeNotifier{
  /// Statuses that are used to determine the NetworkManager state
  ///
  /// initializedStatus représente l'état où tout les éléments de la classe ont été correctement chargés, mais le programme n'as pas été lancé
  static const String initializedStatus = "initialized";
  /// Représente lorsque le serveur à été lancé et a pu communiquer avec Mobinsa
  static const String connectedStatus = "connected";

  /// Représente lorsque le serveur à été arrêté
  static const String offStatus = "off";

  /// Messages between the Server and the Master Program follow this structure
  /// ACTION;SENDER;DATA
  /// Where ACTION is one of the headers that are defined below, and sender is the xIdentity constant
  /// And DATA depends on what action was specified before
  ///
  // Header from the HTTP server

  /// Le détail de ces headers peut être retrouvé sur la page suivante https://github.com/tkdev1755/mobinsaHttpServer/blob/main/mobinsaHttpServer.dart
  static const String httpServerIdentity = "mHTTPServerV1.0.0";
  static const String httpHandshakeHeader = "httpInit";
  static const String httpSessionDataReceivedHeader = "fSessionData";
  static const String httpNewUserHeader = "newUser";
  static const String httpLoginDataHeader = "loginGetData";
  static const String httpInitOkHeader = "initDataSend";
  static const String httpInitSent = "fInitData";
  static const String httpVoteOkHeader = "voteOk";
  static const String httpVoteEndHeader = "voteEndOk";
  static const String httpVoteUpdateHeader = "voteUpdate";

  static const String handShakeMessage = "MobINSAHTTPServer - v1.0.0";

  // Header from the master program (this one)
  /// Chaine de caractère contenant la version actuelle de MobINSA
  final String softwareVersion;
  /// Chaine de caractère contenant l'identité du "programme" lors des communications avec le serveur HTTP
  ///
  /// Présent dans le champ SENDER des messages échangés (cf l.25)
  late final String masterProgramIdentity;
  /// Header envoyé pour le premier échange de données entre le serveur (mdp de la session)
  static const String sessionDataHeader = "sessionDataExchange";
  /// Header envoyé pour l'échange des données des étudiants et destinations
  static const String initDataHeader = "initData";
  /// Header envoyé lorsqu'un utilisateur se re-connecte pour envoyer la liste des étudiants/destination à jour
  static const String loginDataHeader = "loginData";
  /// Header envoyé pour indiquer le départ d'un vote au serveur
  static const String startVoteHeader  = "startVote";
  /// Header envoyé pour indiquer l'arrêt du vote au server
  static const String stopVoteHeader = "closeVote";
  /// Header envoyé lorsqu'une mise jour survient au niveau des données des étudiants (choix accepté, refusé...)
  static const String sessionUpdateHeader = "sessionUpdate";
  /// Header envoyé pour indiquer au serveur d'arrêter le jury collaboratif
  static const closeConnectionsHeader = "closeConnections";
  /// Socket sur laquelle le programme écoute les messages du serveur
  ServerSocket? _server;

  // Bools and completers to display messages on the graphical interface
  /// Indique si le mot de passe de la session a été entré
  bool hasInitializedPassword = false;
  /// Indique si le jury a été arrêté par l'utilisateur
  bool closedConnections = false;
  /// Indique si la _serverSocket à été correctement ouverte
  bool _isInitialized = false;
  /// Indique si le programme à pu établir une connexion avec le serveur HTTP
  bool _isConnected = false;
  /// Indique si le jury à été lancé par l'utilisateur sur l'interface graphique
  bool hasJuryStarted = false;
  /// Indique si un vote à été démarré par l'utilisateur
  bool hasVoteStarted = false;
  /// Objet Completer pour permette à l'interface graphique de savoir si le serveur HTTP s'est connecté
  Completer<bool> _isConnectedFuture = Completer<bool>();
  /// Getter pour faire appel à l'Objet Completer au niveau de l'interface graphique
  Future<bool> get isConnectedFuture => _isConnectedFuture.future;

  /// Liste des clients connectés
  List<Map<String, dynamic>> connectedClients = [];
  /// Completer Indiquant si un nouvel utilisateur s'est connecté
  Completer<bool> _newUserConnected = Completer<bool>();
  /// Getter pour faire à appel à l'Objet Completer au niveau de l'interface graphique
  Future<bool> get newUserConnected => _newUserConnected.future;
  /// Objet Completer indiquant si le jury à été démarré correctement
  Completer<bool> _startJuryCompleter = Completer<bool>();
  /// Getter pour faire à appel à l'Objet Completer _startJuryCompleter au niveau de l'interface graphique
  Future<bool> get startJury => _startJuryCompleter.future;
  Completer<bool> _startVoteCompleter = Completer<bool>();
  Future<bool> get startedVote => _startJuryCompleter.future;
  /// Fonction appelée lorsque le Serveur HTTP transmet une mise à jour de vote, permet de refleter le changement sur l'interface graphique
  Function(Map<String,dynamic> data) onVoteUpdate;
  /// Fonction appelée lorsqu'un utilisateur se reconnecte au client web
  Map<String,dynamic> Function() onLogin;
  /// DEPRECATED - Liste contenant les emails de confiance pour le jury, allait utiliser l'authentification à l'aide du CAS pour vérifier leur authenticité
  List<String> trustedEmails = ['john.doe@email.com'];
  /// String contenant le mot de passe de la session collaborative
  late String _sessionPassword;
  /// Adresse IP du serveur HTTP
  String httpIPAddress= "";
  /// Nom d'hôte du serveur HTTP s'il existe
  String? httpHostAdress;
  /// Socket du serveur HTTP
  Socket? client;
  /// Buffer contenant la sortie standard du serveur HTTP
  StringBuffer serverSTDOUT = StringBuffer();
  /// Constructeur
  NetworkManager(this.softwareVersion, this.onVoteUpdate,this.onLogin){
   masterProgramIdentity = "mobinsaV${softwareVersion}";
  }
  /// Fonction initialisant correctement le serveur HTTP
  Future<bool> initServer() async {
    if (_isInitialized){
      print("Server already initialized");
      return true;
    }
    _server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 7070);
    print("[NETWORK] - Socket opened on ${_server!.address.address}:${_server!.port}");
    return true;
  }
  /// Setter pour configurer le mot de passe de la session
  void setSessionPassword(String password){
    _sessionPassword = password;
  }
  /// Fonction démarrant le serveur et ouvrant la socket
  Future<bool> startNetworkCommunications(ServerRuntimeChecker runtimeChecker) async {
    _isInitialized = await initServer();
    Directory serverDirectory = await ServerRuntimeChecker.getServerDirectory();
    //runtimeChecker.overrideRuntimeHash(serverDirectory.path);
    if (Platform.isWindows){
      Stream<ProcessResult> processStream = Process.run("${serverDirectory.path}\\${ServerRuntimeChecker.httpServerProgramName}", [], workingDirectory: "${serverDirectory.path}").asStream();
      processStream.listen((ProcessResult? result){
        if (result != null){
          print("STDOUT res ${result.stdout}");
          print("STDERR res ${result.stderr}");
          serverSTDOUT.write(result.stdout);
          serverSTDOUT.write(result.stderr);
          notifyListeners();
        }
      });
    }
    else if (Platform.isMacOS){
      // For the moment, show the info and ask the user to start the program by double clicking on it
      Process.run("open", [serverDirectory.path]);
    }
    else{

      Process serverProcess = await Process.start("${serverDirectory.path}/${ServerRuntimeChecker.httpServerProgramName}", [],workingDirectory: serverDirectory.path);
      print("Listening to the Standard output of the program");
      serverProcess.stdout.listen((List<int> data){
        print("New entry in the STDOUT :  data right now is ${data}");
        serverSTDOUT.write(utf8.decode(data));
        notifyListeners();
      });
      serverProcess.stderr.listen((List<int> data){
        print("New entry in STDERR : data right now is ${utf8.decode(data)}");
      });
    }
    print("[NETWORK] - Finished starting network communications");
    return _isInitialized;
  }

  /// Getter pour vérifier si le serveur à été initialisé correctement
  bool isServerInitialized() {
   return _isInitialized ;
  }

  /// Getter pour vérifier s'il est possible d'envoyer des mises à jour de jury sur le réseau
  bool ableToSendUpdates(){
    // print("isInitialized-${_isInitialized} && isConnected-$_isConnected && hasJuryStarted-$hasJuryStarted");
    return _isInitialized && hasJuryStarted;
  }

  /// Getter pour obtenir le statut actuel du server
  String getStatus(){
    if (_isInitialized){
      return initializedStatus;
    }
    else if (_isConnected){
      return connectedStatus;
    }
    else{
      return offStatus;
    }
  }
  /// Fonction pour effectuer l'initialisation de la session collaborative auprès du serveur HTTP
  ///
  /// Le "handshake" se passe de la manière suivante
  /// Attente d'un message sous le format "httpInit;;MobINSAHTTPServer - v1.0.0"
  /// Envoi d'un message sous le format sessionData;mobinsaV3.0.0;{...sessionData}"
  void handshakeWithHttpClient(sender, rawData){
    String receivedData = rawData;
    if (receivedData.contains(handShakeMessage) ){
      if (!_isConnectedFuture.isCompleted){
        print(rawData);
        Map<String,dynamic> ipInfo = jsonDecode(rawData);
        if (client == null) throw ("No client was assigned");
        print("[NETWORK] - handshakeWithHttpClient : Connected to Mob'INSA HTTP Server");
        httpIPAddress = ipInfo["ipaddr"];
        print(httpIPAddress);
        httpHostAdress = ipInfo["hostaddr"];
        _isInitialized = true;
        client!.write('${sessionDataHeader};${masterProgramIdentity};{"sessionPassword":"${_sessionPassword}", "trustedEmails" : ${exportStringListToString(trustedEmails)}}');
      }
    }
  }
  /// Fonction envoyant les données du jury
  void sendInitialData(Map<String,dynamic> data, {bool fromLogin=false}){
    String encodedData = jsonEncode(data);
    if (client == null){
      throw  Exception("HTTP Client Socket isn't initialized");
    }
    client!.write("${fromLogin ? loginDataHeader:initDataHeader};$masterProgramIdentity;$encodedData\n");
  }

  /// Fonction envoyant au serveur HTTP l'ordre de démarrer un vote
  void startVote(Map<String, dynamic> data){
    String encodedData = jsonEncode(data);
    if (client == null){
      throw Exception("HTTP Client Socket isn't initialized");
    }
    String message = '${startVoteHeader};${masterProgramIdentity};${encodedData}\n';
    client!.write(message);
  }

  /// Fonction appelée lorsque le header httpVoteUpdateHeader est reçu, permet de refleter les changements sur l'interface graphique
  void updateVote(String sender, String rawData){
    Map<String,dynamic> data = jsonDecode(rawData);
    if (data.containsKey("voteType") && (!(data["voteType"] == "choiceVote") && !data.containsKey("studentID")) ||  (data["voteType"] == "matchVote" && !data.containsKey("studentsID"))){
      throw Exception("Necessary headers for updating the vote are absent");
    }
    onVoteUpdate(data);
    notifyListeners();
  }

  /// Fonction envoyant au serveur HTTP l'ordre de démarrer un vote
  void stopVote(Map<String, dynamic> data){
    String encodedData = jsonEncode(data);
    if (client == null){
      throw Exception("HTTP Client Socket isn't initialized");
    }
    String message = '${stopVoteHeader};${masterProgramIdentity};${encodedData}\n';
    client!.write(message);
  }

  /// Fonction envoyant les mises à jour de jury au serveur HTTP
  void sendUpdate(Map<String,dynamic> data){
    if (ableToSendUpdates()){
      client?.write("$sessionUpdateHeader;$masterProgramIdentity;${jsonEncode(data)}");
    }
  }

  /// Fonction écoutant les messages reçu sur la socket _server,
  void listenToMessages(){
    print("[NETWORK] - Listening to new messages");
    _server!.listen((Socket client) async {
      print("[NETWORK] - New Client is connected");
      this.client = client;
      await this.client!.listen(processMessages,onError : handleError).asFuture();
      if (!closedConnections){
        client.destroy();
        this.client = null;
        closeConnections();
      }

      return;
    });
  }

  /// Fonction appelée à chaque fois qu'un message est reçu sur la socket _server
  void processMessages(data){
    print("[NETWORK] - processMessage : Recieved Message");
    String receivedData = utf8.decode(data);
    List<String> decodedMessage = receivedData.split(";");
    if (decodedMessage.length < 3) throw Exception("Unrecognized format");
    String primitive = decodedMessage[0];
    String sender = decodedMessage[1];
    String rawData = decodedMessage[2];
    switch (primitive){
      case httpNewUserHeader:
        print("[NETWORK] - Message type : New user");
        _newUserConnected = Completer<bool>();
        handleNewUser(sender, rawData);
        break;
      case httpVoteUpdateHeader:
        print("[NETWORK] - Message type : Jury Update");
        updateVote(sender,rawData);
        break;
      case httpHandshakeHeader:
        print("[NETWORK] - Message type : Handshake with HTTP Server");
        print("message : ${receivedData}");
        handshakeWithHttpClient(sender,rawData);
        break;
      case httpSessionDataReceivedHeader:
        print("[NETWORK] - Message type : FinishedHandshake");
        _isConnectedFuture.complete(true);
        break;
      case httpInitSent:
        print("[NETWORK] - Message type : HTTP client received all jury data");
        hasJuryStarted = true;
        _startJuryCompleter.complete(true);
        notifyListeners();
      case httpLoginDataHeader:
        print("[NETWORK] - Message type : User logged back in, sending updated data");
        Map<String,dynamic> sessionData = onLogin();
        sendInitialData(sessionData, fromLogin: true);
      case httpVoteOkHeader:
        print("[NETWORK] - Message type :  Vote started on clients end");
        hasVoteStarted = true;
        _startVoteCompleter.complete(true);
        notifyListeners();
      case httpVoteEndHeader:
        print("[NETWORK] - Message type :  Vote stopped on clients end");
        hasVoteStarted = false;
        _startVoteCompleter = Completer<bool>();
        notifyListeners();

      default:
        throw Exception("Unknown Header from HTTP Server -> ${primitive}");
    }
    print("[NETWORK] - processMessage : Processed Message");
  }
  /// Fonction appelée à chaque fois qu'un nouvel utilisateur à pu se connecter au jury collaboratif
  void handleNewUser(String sender, String rawData){
    Map<String,dynamic> userInfo = jsonDecode(rawData);
    print(userInfo);
    connectedClients.add({
      "name" : userInfo["name"],
      "mail" : userInfo["mail"],
      "uid"  : userInfo["uid"],
    });
    notifyListeners();
  }
  /// Fonction appelée losrqu'une erreur de transmission survient avec le serveur HTTP
  void handleError(e,s){
    throw Exception("There was an error while communicating with httpClient ${e}");
  }
  /// Fonction permettant de fermer proprement toutes les connections ouvertes
  Future<void> closeConnections() async {
    client?.write("$closeConnectionsHeader;${masterProgramIdentity};null");
    if (_server == null){
        print("Impossible to get server");
        throw Exception("Server is not initialized");
    }
    await _server!.close();

    print("[NETWORK] Closed Socket on ${_server!.address.address}:${_server!.port}");
    _server = null;
    _isConnectedFuture = Completer<bool>();
    _newUserConnected = Completer<bool>();
    if (client != null){
      client!.destroy();
    }

    connectedClients.clear();
    _startJuryCompleter = Completer<bool>();
    hasJuryStarted = false;
    _isInitialized = false;
    hasVoteStarted = false;
    _startVoteCompleter = Completer<bool>();
    notifyListeners();
  }
  /// Fonction utiliateur permettant de passer une liste au format json
  String exportStringListToString(List<String> words){
    StringBuffer str = StringBuffer();
    str.write("[");
    for (var word in words){
      if (words.indexOf(word) == words.length-1) {
        str.write('"$word"');
      } else {
        str.write('"$word",');
      }

    }
    str.write("]");
    print(str);
    return str.toString();
  }
}