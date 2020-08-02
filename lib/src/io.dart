import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

/// Loads a file as String using [encoding].
///
/// [encoding] If null uses UTF-8.
Future<String> catFile(File file, [Encoding encoding]) async {
  encoding ??= utf8;
  return file.readAsString(encoding: encoding);
}

/// Loads a [file] bytes.
Future<Uint8List> catFileBytes(File file) async {
  return file.readAsBytes();
}

/// Saves a [file] from [data] string using [encoding].
///
/// [encoding] If null uses UTF-8.
Future<File> saveFile(File file, String data, [Encoding encoding]) async {
  encoding ??= utf8;
  return file.writeAsString(data, encoding: encoding, flush: true);
}

/// Saves a [file] from [data] bytes.
Future<File> saveFileBytes(File file, Uint8List data) async {
  return file.writeAsBytes(data, flush: true);
}
