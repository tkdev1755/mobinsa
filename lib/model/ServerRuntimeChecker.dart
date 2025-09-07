
import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:mobinsa/KeychainAPI/keyring.dart';
import 'package:path_provider/path_provider.dart' as pp;
import 'package:path/path.dart' as path;
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:text_analysis/extensions.dart';
import 'package:archive/archive.dart';
class ServerRuntimeChecker with ChangeNotifier {
  static String repoOwner = "tkdev1755";
  static String repoName = "mobinsaHttpServer";
  static Uri repoURI = Uri.parse("https://api.github.com/repos/$repoOwner/${repoName}");
  static String httpServerProgramName = Platform.isWindows ? "mobinsahttpserver.exe" : "mobinsaHttpServer";
  static String httpLibkeychainName = Platform.isWindows ? "libkeychain.dll" : Platform.isLinux ? "libkeychain.so" : "libkeychain.dylib";
  static String macOSAssetName = "mobinsaHTTPServer_macos_x64.zip";
  static String linuxAssetName = "mobinsaHTTPServer_linux_x64.zip";
  static String windowsAssetName = "mobinsaHTTPServer_windows_x64.zip";
  static String _mobinsaServiceName = "mobinsaApp";
  static String _localHashKeychainName = "mobinsaServerlocalHash";
  static const String serverDirectoryName = "mobinsaserver";
  Keyring secureStorage = Keyring();
  Map<String,dynamic>? githubInfo;
  Completer<bool> hasStartedDownloadCompleter = Completer<bool>();
  bool downloadStarted = false;
  bool hasDownloadedSoftware = false;
  Completer<bool> hasInstalledSoftwareCompleter = Completer<bool>();
  bool get hasInstalledSoftware => hasInstalledSoftwareCompleter.isCompleted && hasInstalledSoftwareCompleter.future == Future.value(true);
  ValueNotifier<double> progress = ValueNotifier<double>(0.0);
  bool hasCheckedSoftwareIntegrity = false;
  DateTime? lastPull;
  StreamSubscription? fileChanges;
  bool updateGithubInfo() => lastPull == null || githubInfo == null || (lastPull != null && DateTime.now().difference(lastPull!).inHours < 2);

  Future<Map<String,dynamic>> getRepoInfo() async{
    if (updateGithubInfo()){
      Uri releaseURi = Uri.parse("${repoURI}/releases/latest");
      final response = await http.get(releaseURi);
      if (response.statusCode == 200){
        print("Received data from github");
        Map<String,dynamic> data = jsonDecode(response.body);
        githubInfo = data;
      }
      else{
        throw Exception("Impossible to retrieve repo info");
      }
     return githubInfo!;
    }
    else{
      return githubInfo!;
    }
  }

  static String getArch(){
    String version = Platform.version;
    version = version.substring(version.indexOf('"')).removeQuotes();
    switch (version){
      case "macos_x64":
        return "x64";
      case "macos_arm64":
        return "x64";
      case "windows_x64":
        return "x64";
      case "linux_x64":
        return "x64";
      case "linux_arm64":
        return "x64";
      default:
        throw Exception("Unsupported Arch");
    }
  }

  String getAssetName(){
    if (Platform.isWindows){
      return windowsAssetName;
    }
    else if (Platform.isLinux){
      return linuxAssetName;
    }
    else if (Platform.isMacOS){
      return macOSAssetName;
    }
    else{
      throw Exception("Unsupported OS by the Server Runtime");
    }
  }

  static Future<Directory> getServerDirectory() async{
    Directory tempDir = await pp.getTemporaryDirectory();
    Directory serverDirectory = Directory(path.join(tempDir.path,serverDirectoryName));
    return serverDirectory;
  }

  List<Map<String,dynamic>> getAssetInfo(Map<String,dynamic> data){
    if (!data.containsKey("assets")){
      throw Exception("Assets key doesn't exists");
    }

    return (data["assets"] as List).map((e) => e as Map<String, dynamic>).toList();

  }

  void overrideRuntimeHash(String path) async{
    String dirHash = await sha256OfDirectory(path);
    secureStorage.updatePassword(_mobinsaServiceName, _localHashKeychainName, dirHash);
    hasCheckedSoftwareIntegrity = true;
  }
  String getRemoteAssetHash(Map<String,dynamic> data) {
    List<Map<String,dynamic>> assetData = getAssetInfo(data) ;
    print("Trying to get asset name");
    String assetName = getAssetName();
    print("Got asset name ${assetName}");
    print(assetData);
    Map<String,dynamic>? selectedAsset = assetData.where((e) => e.containsKey("name") && e["name"] == assetName).firstOrNull;
    print("selected asset is ? ${selectedAsset}");
    if (selectedAsset == null){
      throw Exception("Asset doesn't exists for this platform");
    }
    if (!selectedAsset.containsKey("digest")){
      throw Exception("Assets doesn't seems to have a hash");
    }
    return selectedAsset["digest"];
  }

  Future<bool> checkLocalRuntimeHash(String path) async{
    String? runtimeHash = secureStorage.getPassword(_mobinsaServiceName, _localHashKeychainName);
    bool existingRuntimeHash = runtimeHash != null ;
    print("the localHash exists ? $existingRuntimeHash ");
    if (!existingRuntimeHash) return false;
    String localHash = runtimeHash;
    String dirHash = await sha256OfDirectory(path);
    print("localHash is ${localHash}, \ndir hash is ${dirHash} ");
    return localHash == dirHash;
  }

  Future<bool> checkRuntimeHash(String path) async {
    bool localRuntimeHash =  await checkLocalRuntimeHash(path);
    hasCheckedSoftwareIntegrity = localRuntimeHash;
    print("Software integrity was checked -> ${hasCheckedSoftwareIntegrity}");
    return localRuntimeHash;
  }

  Future<String> sha256OfFile(String path) async {
    final file = File(path);
    final bytes = file.readAsBytesSync();
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<String> sha256OfDirectory(String path) async {
    print("Now computing $path Hash");
    final dir = Directory(path);
    if (!dir.existsSync()) {
      throw Exception('Le dossier $path n’existe pas');
    }
    final digests = <String>[];
    for (final entity in dir.listSync(recursive: true, followLinks: false)) {
      print("Now computing $entity Hash");
      if (entity is File) {
        final hash = await sha256OfFile(entity.path);
        digests.add('$hash:${entity.path}');
      }
    }
    // Trie pour éviter que l’ordre des fichiers change le résultat
    digests.sort();
    final joined = digests.join('\n');
    print("Got local Hash -> Sending it");
    return sha256.convert(utf8.encode(joined)).toString();
  }


  StreamSubscription listenForChangesOnDisk(String path){
    Directory serverDirectory = Directory(path);
    if (!serverDirectory.existsSync()){
      print("Server directory doesn't exist");
      throw Exception("Server Directory Doesn't exists");
    }
    Stream directoryStream = serverDirectory.watch();
    print("Listening for changes on ${path}");
    return directoryStream.listen((data){
      print("Change detected, software integrity must be checked");
      hasCheckedSoftwareIntegrity = false;
    },onDone: (){}
    );
  }

  Uri getServerRuntimeAssetUrl(Map<String,dynamic> data){
    List<Map<String,dynamic>> assetData = getAssetInfo(data);
    String assetName = getAssetName();
    print(assetName);
    Map<String,dynamic>? selectedAsset = assetData.where((e) => e.containsKey("name") && e["name"] == assetName).firstOrNull;
    if (selectedAsset == null){
      throw Exception("Impossible to get the asset info");
    }
    if (!selectedAsset.containsKey("browser_download_url")){
      throw Exception("Bad Asset info");
    }
    return Uri.parse(selectedAsset["browser_download_url"]);
  }

  Future<int> hasDownloadedServerRuntime() async{
    if (hasCheckedSoftwareIntegrity){
      Future.delayed(Duration(milliseconds: 100));
      return 0;
    }
    Directory serverDirectory = await getServerDirectory();
    if (!serverDirectory.existsSync()){
      print("Server directory doesn't exists $serverDirectory");
      return -1;
    }
    if (Platform.isWindows){
      serverDirectory = Directory("${serverDirectory.path}\\windows_${getArch()}");
    }
    bool serverHashVerification = await checkRuntimeHash(serverDirectory.path);
    print("Is hash equals ? ${serverHashVerification}");
    if (serverHashVerification){
      fileChanges = listenForChangesOnDisk(serverDirectory.path);
    }
    return serverHashVerification ? 0 : -2;
  }

  Future<void> downloadServerRuntime() async{
    Dio dio = Dio();
    Directory serverDirectory = await getServerDirectory();
    if (serverDirectory.existsSync()){
      List<FileSystemEntity> dir = serverDirectory.listSync();
      if (dir.isNotEmpty){
        for (var file in dir){

          file.deleteSync(recursive: true);
        }
      }
      serverDirectory.deleteSync();
      serverDirectory.createSync();
    }
    else{
      serverDirectory.createSync();
    }
    Map<String,dynamic> data = await getRepoInfo();
    print("Got repo Info");
    Uri assetUrl = getServerRuntimeAssetUrl(data);
    /*print("Got asset Url ${assetUrl}");
    final request = await http.Client().send(http.Request('GET', assetUrl));
    print("Got asset Url Sent request");
    if (request.statusCode != 200){
      throw Exception("Impossible to download the following ${request.reasonPhrase}");
    }*/
    //final contentLength = request.contentLength ?? 0;
    String fileName = getAssetName();
    hasStartedDownloadCompleter.complete(true);
    await dio.download(assetUrl.toString(), path.join(serverDirectory.path,fileName),
     onReceiveProgress: (int received,int total){
      if (total != -1){
        progress.value = received/total;
      }
     }
    );
    progress.value = 1.0;
    hasDownloadedSoftware = true;
    notifyListeners();
    print("Finished downloading software -> Available at ${serverDirectory.path}");
    /*await for (final chunk in request.stream) {
      bytesReceived += chunk.length;
      file.add(chunk);
      if (contentLength > 0) {
        yield bytesReceived / contentLength; // renvoie une valeur entre 0 et 1
      }
    }*/
  }

  Future<void> installServerRuntime() async{
    print("Installing the server runtime");
    Directory serverDirectory = await getServerDirectory();
    print("Checking if the directory already exists");
    if (!serverDirectory.existsSync()){
      throw Exception("Impossible to install the Server Runtime if the server doesn't exists");
    }
    print("Now listing the elements of the directory and searching for the archive");
    List<FileSystemEntity> items = serverDirectory.listSync();
    String slash = Platform.isWindows ?"\\" : "/";
    Iterable<FileSystemEntity> searchedArchive = items.where((e) => e.path.split(slash).last == getAssetName());
    print("There is ${items.length} elements in the server folder");
    if (searchedArchive.isEmpty){
      throw Exception("Asset wasn't downloaded properly");
    }
    print("Beginning archive unzipping");
    File archiveFile = File(searchedArchive.first.path);
    Archive archive = ZipDecoder().decodeBytes(archiveFile.readAsBytesSync());
    for (var file in archive){
      String filename = file.name;
      String filepath = path.join(serverDirectory.path, filename);
      if (file.isFile){
        final File outFile = File(filepath);
        outFile.createSync(recursive:  true);
        outFile.writeAsBytesSync(file.content as List<int>);
      }
      else{
        Directory(filepath).createSync(recursive: true);
      }
    }
    print("Cleaned the archive");
    // Cleaning up
    archiveFile.deleteSync();
    String serverExecutableName = Platform.isWindows ? "mobinsahttpserver.exe" : "mobinsaHttpServer";
    String executablePath = "${serverDirectory.path}/$serverExecutableName";
    String directoryHash = await sha256OfDirectory(serverDirectory.path);
    secureStorage.updatePassword(_mobinsaServiceName, _localHashKeychainName,directoryHash);

    print("Directory Hash is ${directoryHash}");
    if (!Platform.isWindows){
      await Process.run("chmod", ["+x", executablePath]);
      hasInstalledSoftwareCompleter.complete(true);
    }
    else{
      hasInstalledSoftwareCompleter.complete(true);
    }
    notifyListeners();
  }

  bool hasCompletedCompleters(){
    return hasInstalledSoftwareCompleter.isCompleted || hasStartedDownloadCompleter.isCompleted || downloadStarted || hasDownloadedSoftware;
  }
  void resetAllCompleters(){
    hasInstalledSoftwareCompleter = Completer<bool>();
    hasStartedDownloadCompleter = Completer<bool>();
    hasStartedDownloadCompleter = Completer<bool>();
    downloadStarted = false;
    hasDownloadedSoftware = false;
    progress = ValueNotifier<double>(0.0);
  }

  void dispose(){
    super.dispose();
    if (fileChanges != null){
      print("cancelling file changes listener on ${getServerDirectory()}");
      fileChanges!.cancel();
    }
  }
}