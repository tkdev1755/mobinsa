import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:http/http.dart' as http ;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart' as pp;

class SoftwareUpdater{

  static final String _user = "tkdev1755";
  static final String _repo = "mobinsa";
  static final Uri _repoUrl = Uri.parse("https://api.github.com/repos/$_user/$_repo/releases/latest");

  static String windowsAssetName = "mobinsa_windows.zip";
  static String macOSAssetName = "mobinsa_macos_universal.zip";
  static String linuxAssetName = "mobinsa_linux.zip";
  static String downloadFolder = "update";
  late (int, int, int) currentVersion;
  DateTime? latestPull;

  Map<String, dynamic>? latestVersionData;
  (int, int, int)? latestVersion;

  PackageInfo packageInfo;

  SoftwareUpdater(this.packageInfo){
    currentVersion = parsePackageVersion();
  }

  (int,int,int) parsePackageVersion(){
    List<String> currentVer = packageInfo.version.split(".");
    int major = int.parse(currentVer[0]);
    int minor = currentVer.length >= 2 ? int.parse(currentVer[1]) : 0;
    int patch = currentVer.length >= 3 ? int.parse(currentVer[2]) : 0;
    print("Parsed local ver is ${major}, $minor, $patch");
    return (major, minor, patch);
  }
  (int,int,int) parseRemoteVersion(String remoteVersion){
    List<String> currentVer = remoteVersion.substring(1).split(".");
    int major = int.parse(currentVer[0]);
    int minor = currentVer.length >= 2 ? int.parse(currentVer[1]) : 0;
    int patch = currentVer.length >= 3 ? int.parse(currentVer[2]) : 0;
    print("Parsed remote ver is ${major}, $minor, $patch");
    return (major, minor, patch);
  }

  bool updateVersionData(){
    return latestPull == null || DateTime.now().difference(latestPull!).inHours > 2;
  }

  Future<int> getLatestVersionData() async {
    if (updateVersionData()){
      http.Response response = await http.get(_repoUrl);
      if (response.statusCode == 200){
        latestVersionData = jsonDecode(response.body);
        latestPull = DateTime.now();
        return 1;
      }
      else{
        return 0;
      }
    }
    else{
      return 1;
    }

  }

  Future<(int, int, int)?> getLatestVersionNumber() async {
    int result = await getLatestVersionData();
    if (result == 1){
      return parseRemoteVersion(latestVersionData!["name"]);
    }
    return null;
  }

  Future<String?> getLatestVersionDetails() async{
    int result = await getLatestVersionData();
    if (result != 1){
      return null;
    }
    return latestVersionData?["body"];
  }

  Future<bool> isUpToDate() async{
    latestVersion = await getLatestVersionNumber();
    if (latestVersion == null){
      throw Exception("Failed to pull latest version");
    }
    return currentVersion.$1>=latestVersion!.$1 && currentVersion.$2>=latestVersion!.$2 && currentVersion.$3>= latestVersion!.$3;
  }


  Future<String> getAssetUrl() async {
    int result = await getLatestVersionData();
    if (result != 1){
      throw Exception("Impossible to get the Asset URL");
    }
    List<dynamic> assets = latestVersionData!["assets"];
    assets = assets.where((e) => e.containsKey("name")).toList();
    if (Platform.isWindows){
      Map<String,dynamic> windowsAsset = assets.firstWhere((e) => e["name"] == windowsAssetName);
      if (!windowsAsset.containsKey("browser_download_url")){
        throw Exception(("Impossible to find the Windows browser_download_url"));
      }
      return windowsAsset["browser_download_url"];
    }
    if (Platform.isMacOS){
      Map<String,dynamic> macOSAsset = assets.firstWhere((e) => e["name"] == macOSAssetName);
      if (!macOSAsset.containsKey("browser_download_url")){
        throw Exception(("Impossible to find the MacOS browser_download_url"));
      }
      return macOSAsset["browser_download_url"];
    }
    if (Platform.isLinux){
      Map<String,dynamic> linuxAsset = assets.firstWhere((e) => e["name"] == linuxAssetName);
      if (!linuxAsset.containsKey("browser_download_url")){
        throw Exception(("Impossible to find the Linux browser_download_url"));
      }
      return linuxAsset["browser_download_url"];
    }
    else{
      throw Exception("Unsupported Platform at the moment");
    }
  }

  Future<String> getAssetName() async{
    int result = await getLatestVersionData();
    if (result != 1){
      throw Exception("Impossible to get the Asset name");
    }
    List<dynamic> assets = latestVersionData!["assets"];
    assets = assets.where((e) => e.containsKey("name")).toList();
    if (Platform.isWindows){
      Map<String,dynamic> windowsAsset = assets.firstWhere((e) => e["name"] == windowsAssetName);
      if (!windowsAsset.containsKey("browser_download_url")){
        throw Exception(("Impossible to find the Windows browser_download_url"));
      }
      return windowsAsset["name"];
    }
    if (Platform.isMacOS){
      Map<String,dynamic> macOSAsset = assets.firstWhere((e) => e["name"] == macOSAssetName);
      if (!macOSAsset.containsKey("name")){
        throw Exception(("Impossible to find the MacOS browser_download_url"));
      }
      return macOSAsset["name"];
    }
    if (Platform.isLinux){
      Map<String,dynamic> linuxAsset = assets.firstWhere((e) => e["name"] == linuxAssetName);
      if (!linuxAsset.containsKey("name")){
        throw Exception(("Impossible to find the Linux browser_download_url"));
      }
      return linuxAsset["name"];
    }
    else{
      throw Exception("Unsupported Platform at the moment");
    }
  }

  // Get the latest release URL according to your system and sends you to it on your web browser
  Future<String?> getUpdate() async{
    String assetUrl = await getAssetUrl();
    String assetName = await getAssetName();
    if (true){
      if (Platform.isWindows){
        await Process.start(
          'cmd',
          ['/c', 'start', '', assetUrl],
          runInShell: true,
        );
      }
      else{
        await Process.run("open", [assetUrl]);
      }
    }
    else{
      final updateUrl = Uri.parse(await getAssetUrl());
      final assetResponse = await http.get(updateUrl, headers: {
        'Accept': 'application/octet-stream',
      });
      if (assetResponse.statusCode == 200){
        final updateFolder = "${(await pp.getTemporaryDirectory()).path}/$downloadFolder";
        Directory updateDirectory = Directory(updateFolder);
        if (!updateDirectory.existsSync()){
          updateDirectory.createSync();
        }
        final updateZipPath = File("${updateDirectory.path}/${assetName}");
        updateZipPath.writeAsBytesSync(assetResponse.bodyBytes);
        print("Saved file at ${updateDirectory.path}/${assetName}");
        return updateZipPath.path;
      }
      throw Exception("Unable to download the requested asset ${assetResponse.statusCode}");
    }
    return null;
  }

  // Unused function at the moment because of OS-Specific oddities
  Future<void> performUpdate(String path) async{
    if (Platform.isWindows){
    }
    else{
      File assetFile = File(path);
      Directory assetDirectory = Directory(path.substring(0, path.length-4));
      if (!assetFile.existsSync()){
        throw Exception("The file doesn't seem to exist");
      }
      if (!assetDirectory.existsSync()){
        assetDirectory.createSync();
      }

      final List<int> bytes = assetFile.readAsBytesSync();
      late Archive archive;
      try {
        archive = ZipDecoder().decodeBytes(bytes);
      }
      catch (e){
        throw Exception("The file seems to be corrupt : ${e}");
      }
      for (var file in archive){
        final outputPath = "${assetDirectory.path}/${file.name}";
        if (file.isFile){
          final outFile = File(outputPath);
          await outFile.create(recursive: true);
          outFile.writeAsBytesSync(file.content as List<int>);
          print("File ${file.name} successfully dezipped to $assetDirectory");
        }
        else{
          final dir = Directory(outputPath);
          await dir.create(recursive: true);
          print(file.content);
          print("Directory successfully created to $assetDirectory");
        }
      }
      if (Platform.isMacOS){
        performUpdateMacOS("${assetDirectory.path}/mobinsa.app");
      }
      else if (Platform.isMacOS){
        performUpdateLinux(assetDirectory.path);
      }
    }
  }

  performUpdateMacOS(String appDir){
    List<String> currentAppInstallDirList = Platform.resolvedExecutable.split("/");
    currentAppInstallDirList.removeRange(currentAppInstallDirList.length-3, currentAppInstallDirList.length);
    String cwd = currentAppInstallDirList.join("/");

    ProcessResult test = Process.runSync("open", ["-R",appDir]);
    ProcessResult test2 = Process.runSync("open", ["-R",cwd]);
    print("appDir open ${test.stdout} \n ${test.stderr}");
    print("appDir open ${test.stdout} \n ${test.stderr}");
  }

  performUpdateLinux(String appDir){
    final cwd = Platform.resolvedExecutable;
    print("cwd is ${cwd}");
    ProcessResult test = Process.runSync("open", [appDir]);
    ProcessResult test2 = Process.runSync("open", [cwd]);
  }

  @override
  String toString() {
    return "${currentVersion.$1}.${currentVersion.$2}.${currentVersion.$3}";
  }

}