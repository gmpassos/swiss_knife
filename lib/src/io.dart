
import 'dart:convert';
import 'dart:io';


Future<String> catFile(File file, [Encoding encoding]) async {
  encoding ??= utf8 ;
  return file.readAsString( encoding: encoding ) ;
}

Future<File> saveFile(File file, String data, [Encoding encoding]) async {
  encoding ??= utf8 ;
  return file.writeAsString(data, encoding: encoding, flush: true) ;
}

