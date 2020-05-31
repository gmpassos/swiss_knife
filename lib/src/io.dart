import 'dart:convert';
import 'dart:io';

/// Loads a file as String using [encoding].
///
/// [encoding] If null uses UTF-8.
Future<String> catFile(File file, [Encoding encoding]) async {
  encoding ??= utf8;
  return file.readAsString(encoding: encoding);
}

/// Saves a file from [data] string using [encoding].
///
/// [encoding] If null uses UTF-8.
Future<File> saveFile(File file, String data, [Encoding encoding]) async {
  encoding ??= utf8;
  return file.writeAsString(data, encoding: encoding, flush: true);
}
