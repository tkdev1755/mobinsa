import 'dart:io';

import 'package:excel/excel.dart';

class SheetParser{


  static Excel parseExcel(String path){

    File newFile = File(path);
    if (newFile.existsSync()){
      Excel parsedData = Excel.decodeBytes(newFile.readAsBytesSync());
      Excel createdFile= Excel.createExcel();
      String? test;
      String test2 = test ?? "DUMN";
      print(parsedData.sheets.values.firstOrNull?.rows[1]);
      print("Decoded File sheets : ${parsedData.sheets}, $parsedData");
      print("Decoded File  : ${parsedData.tables}");
      return parsedData;
    }
    else{
      throw Exception();
    }
  }
}