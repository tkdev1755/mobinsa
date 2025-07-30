


import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'dart:convert';

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
  static const String httpJuryUpdateHeader = "juryUpdate";
  static const String httpInitOkHeader = "initDataSend";
  static const String httpInitSent = "fInitData";
  static const String handShakeMessage = "MobINSAHTTPServer - v1.0.0";

  // Header from the master program (this one)
  final String softwareVersion;
  late final String masterProgramIdentity;
  static const String sessionDataHeader = "sessionDataExchange";
  static const String initDataHeader = "initData";
  static const String startJuryHeader  = "startJury";
  static const String closeJuryHeader = "closeJury";
  static const String dataExchangeHeader = "dataExchange";
  static const List<String> masterProgramHeaders = [sessionDataHeader,startJuryHeader, closeJuryHeader, dataExchangeHeader];

  ServerSocket? _server;
  bool closedConnections = false;
  bool _isInitialized = false;
  bool _isConnected = false;
  bool hasJuryStarted = false;
  Completer<bool> _isConnectedFuture = Completer<bool>();
  Future<bool> get isConnectedFuture => _isConnectedFuture.future;
  List<Map<String, dynamic>> connectedClients = [];
  Completer<bool> _newUserConnected = Completer<bool>();
  Future<bool> get newUserConnected => _newUserConnected.future;

  Completer<bool> _startJuryCompleter = Completer<bool>();
  Future<bool> get startJury => _startJuryCompleter.future;

  List<String> trustedEmails = ['john.doe@email.com'];
  Socket? client;
  NetworkManager(this.softwareVersion){
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

  Future<bool> startNetworkCommunications() async {
    _isInitialized = await initServer();
    print("[NETWORK] - Finished starting network communications");
    return _isInitialized;
  }

  bool isServerInitialized() {
   return _isInitialized ;
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
    String recievedData = rawData;
    if (recievedData == handShakeMessage){
      if (!_isConnectedFuture.isCompleted){
        if (client == null) throw Exception("No client was assigned");
        print("[NETWORK] - handshakeWithHttpClient : Connected to Mob'INSA HTTP Server");
        client!.write('${sessionDataHeader};${masterProgramIdentity};{"sessionPassword":"placeholder_password", "trustedEmails" : ${exportStringListToString(trustedEmails)}}');
      }
    }
  }

  void sendInitialData(Map<String,dynamic> data){
    String encodedData = jsonEncode(data);
    if (client == null){
      throw  Exception("HTTP Client Socket isn't initialized");
    }
    print("encoded data -> ${initDataHeader};${masterProgramIdentity};${encodedData}");
    client!.write("${initDataHeader};${masterProgramIdentity};${encodedData}\n");
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
      case httpJuryUpdateHeader:
        print("[NETWORK] - Message type : Jury Update");
        //handleNewUser(sender, rawData);
        break;
      case httpHandshakeHeader:
        print("[NETWORK] - Message type : Handshake with HTTP Server");
        handshakeWithHttpClient(sender,rawData);
        break;
      case httpSessionDataReceivedHeader:
        print("[NETWORK] - Message type : FinishedHandshake");
        _isConnectedFuture.complete(true);
        break;
      case httpInitSent:
        print("[NETWORK] - Message type : Finished sending data");
        hasJuryStarted = true;
        _startJuryCompleter.complete(true);
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