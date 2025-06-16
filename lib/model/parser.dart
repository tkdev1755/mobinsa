import 'dart:io';

import 'package:excel/excel.dart';

class SheetParser{


  static Excel parseExcel(String path){

    File newFile = File(path);
    if (newFile.existsSync()){
      Excel parsedData = Excel.decodeBytes(newFile.readAsBytesSync());
      print("Decoded File sheets : ${parsedData.sheets}");
      print("Decoded File  : ${parsedData.tables}");
      return parsedData;
    }
    else{
      throw Exception();
    }
  }
}