


import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'dart:convert';

import 'package:mobinsa/model/ServerRuntimeChecker.dart';
import 'package:path_provider/path_provider.dart' as pp;
import 'package:path/path.dart' as path;
import 'package:flutter/cupertino.dart';


class NetworkManager with ChangeNotifier{
  static const String initializedStatus = "initialized";
  static const String connectedStatus = "connected";
  static const String offStatus = "off";

  // Header from the HTTP server
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
  final String softwareVersion;
  late final String masterProgramIdentity;
  static const String sessionDataHeader = "sessionDataExchange";
  static const String initDataHeader = "initData";
  static const String loginDataHeader = "loginData";
  static const String startVoteHeader  = "startVote";
  static const String stopVoteHeader = "closeVote";
  static const String sessionUpdateHeader = "sessionUpdate";
  static const List<String> masterProgramHeaders = [sessionDataHeader,startVoteHeader, stopVoteHeader, sessionUpdateHeader];

  ServerSocket? _server;

  // Bools and completers to display messages on the graphical interface
  bool hasInitializedPassword = false;
  bool closedConnections = false;
  bool _isInitialized = false;
  bool _isConnected = false;
  bool hasJuryStarted = false;
  bool hasVoteStarted = false;

  Completer<bool> _isConnectedFuture = Completer<bool>();
  Future<bool> get isConnectedFuture => _isConnectedFuture.future;
  List<Map<String, dynamic>> connectedClients = [];
  Completer<bool> _newUserConnected = Completer<bool>();
  Future<bool> get newUserConnected => _newUserConnected.future;

  Completer<bool> _startJuryCompleter = Completer<bool>();
  Future<bool> get startJury => _startJuryCompleter.future;
  Completer<bool> _startVoteCompleter = Completer<bool>();
  Future<bool> get startedVote => _startJuryCompleter.future;
  Function(Map<String,dynamic> data) onVoteUpdate;
  Map<String,dynamic> Function() onLogin;
  List<String> trustedEmails = ['john.doe@email.com'];
  late String _sessionPassword;
  String httpIPAddress= "";
  String? httpHostAdress;
  Socket? client;
  StringBuffer serverSTDOUT = StringBuffer();
  NetworkManager(this.softwareVersion, this.onVoteUpdate,this.onLogin){
   masterProgramIdentity = "mobinsaV${softwareVersion}";
  }

  Future<bool> initServer() async {
    if (_isInitialized){
      print("Server already initialized");
      return true;
    }
    _server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 7070);
    print("[NETWORK] - Socket opened on ${_server!.address.address}:${_server!.port}");
    return true;
  }

  void setSessionPassword(String password){
    _sessionPassword = password;
  }

  Future<bool> startNetworkCommunications(ServerRuntimeChecker runtimeChecker) async {
    _isInitialized = await initServer();
    Directory serverDirectory = await ServerRuntimeChecker.getServerDirectory();
    runtimeChecker.overrideRuntimeHash(serverDirectory.path);
    if (Platform.isWindows){
      Stream<ProcessResult> processStream = Process.run("${serverDirectory.path}\\windows_x64\\${ServerRuntimeChecker.httpServerProgramName}", [], workingDirectory: "${serverDirectory.path}\\windows_${ServerRuntimeChecker.getArch()}").asStream();
      processStream.listen((ProcessResult? result){
        if (result != null){
          serverSTDOUT.write(utf8.decode(result.stdout));
          serverSTDOUT.write(utf8.decode(result.stderr));
        }
      });
    }
    else if (Platform.isMacOS){
      // For the moment, show the info and ask the user to start the program by double clicking on it
      Process.run("open", [serverDirectory.path]);
    }
    else{
      print(serverDirectory.path);
      List<FileSystemEntity> files = serverDirectory.listSync();
      for (var file in files){
        print(file.path);
      }
      print("${serverDirectory.path}/${ServerRuntimeChecker.httpServerProgramName}");
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
    Future.delayed(Duration(seconds: 2), (){
      String path = Platform.isWindows ? "${serverDirectory.path}\\windows_x64\\${ServerRuntimeChecker.httpServerProgramName}" : "${serverDirectory.path}/${ServerRuntimeChecker.httpServerProgramName}";
      runtimeChecker.overrideRuntimeHash(path);
    });
    return _isInitialized;
  }

  bool isServerInitialized() {
   return _isInitialized ;
  }

  bool ableToSendUpdates(){
    print("isInitialized-${_isInitialized} && isConnected-$_isConnected && hasJuryStarted-$hasJuryStarted");
    return _isInitialized && hasJuryStarted;
  }
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

  void sendInitialData(Map<String,dynamic> data, {bool fromLogin=false}){
    String encodedData = jsonEncode(data);
    if (client == null){
      throw  Exception("HTTP Client Socket isn't initialized");
    }
    client!.write("${fromLogin ? loginDataHeader:initDataHeader};$masterProgramIdentity;$encodedData\n");
  }

  void startVote(Map<String, dynamic> data){
    String encodedData = jsonEncode(data);
    if (client == null){
      throw Exception("HTTP Client Socket isn't initialized");
    }
    String message = '${startVoteHeader};${masterProgramIdentity};${encodedData}\n';
    client!.write(message);
  }

  void stopVote(Map<String, dynamic> data){
    String encodedData = jsonEncode(data);
    if (client == null){
      throw Exception("HTTP Client Socket isn't initialized");
    }
    String message = '${stopVoteHeader};${masterProgramIdentity};${encodedData}\n';
    client!.write(message);
  }

  void updateVote(String sender, String rawData){
    Map<String,dynamic> data = jsonDecode(rawData);
    if (data.containsKey("voteType") && (!(data["voteType"] == "choiceVote") && !data.containsKey("studentID")) ||  (data["voteType"] == "matchVote" && !data.containsKey("studentsID"))){
      throw Exception("Necessary headers for updating the vote are absent");
    }
    onVoteUpdate(data);
    notifyListeners();
  }

  void sendUpdate(Map<String,dynamic> data){
    if (ableToSendUpdates()){
      client?.write("$sessionUpdateHeader;$masterProgramIdentity;${jsonEncode(data)}");
    }
  }

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
      print("[NETWORK] - Client Disconnected");
      return;
    });
  }

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

  void handleError(e,s){
    throw Exception("There was an error while communicating with httpClient ${e}");
  }

  Future<void> closeConnections() async {
    // TODO - Add code to send a message on connection close;
    if (_server == null){
        print("Impossible to server");
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