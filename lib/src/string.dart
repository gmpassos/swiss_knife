import 'math.dart';

/// Returns [true] if [c] is a blank char (space, \t, \n, \r).
bool isBlankChar(String? c) {
  return c == ' ' || c == '\n' || c == '\t' || c == '\r';
}

/// Returns ![isBlankChar].
bool isNonBlankChar(String? c) {
  return !isBlankChar(c);
}

final int _codeUnitSpace = ' '.codeUnitAt(0);
final int _codeUnitN = '\n'.codeUnitAt(0);
final int _codeUnitR = '\r'.codeUnitAt(0);
final int _codeUnitT = '\t'.codeUnitAt(0);

/// Returns [true] if [c] is a blank char code unit.
bool isBlankCodeUnit(int c) {
  return c == _codeUnitSpace ||
      c == _codeUnitN ||
      c == _codeUnitT ||
      c == _codeUnitR;
}

/// Returns ![isBlankCodeUnit].
bool isNotBlankCodeUnit(int c) {
  return !isBlankCodeUnit(c);
}

/// Returns [true] if [s] has a blank character.
bool hasBlankChar(String s) {
  return hasBlankCharFrom(s, 0);
}

/// Returns [true] if [s] has a blank character from [offset].
bool hasBlankCharFrom(String s, [int offset = 0]) {
  return hasBlankCharInRange(s, offset, s.length - offset);
}

/// Returns [true] if [s] has a blank character in range [offset]+[length].
bool hasBlankCharInRange(String s, int offset, int length) {
  if (length <= 0) return false;

  var end = Math.min(s.length, offset + length);

  for (var i = offset; i < end; i++) {
    var c = s.codeUnitAt(i);
    if (isBlankCodeUnit(c)) return true;
  }

  return false;
}

/// Returns [true] if [s] has only blank characters.
bool isBlankString(String s, [int offset = 0]) {
  return isBlankStringInRange(s, offset, s.length - offset);
}

/// Returns [true] if [s] has only blank characters in range [offset]+[length].
bool isBlankStringInRange(String s, int offset, int length) {
  if (length <= 0) return false;

  var end = Math.min(s.length, offset + length);

  for (var i = offset; i < end; i++) {
    var c = s.codeUnitAt(i);
    if (!isBlankCodeUnit(c)) return false;
  }

  return true;
}

// ignore: non_constant_identifier_names
final int _codeUnit__ = '_'.codeUnitAt(0);
// ignore: non_constant_identifier_names
final int _codeUnit_0 = '0'.codeUnitAt(0);
// ignore: non_constant_identifier_names
final int _codeUnit_9 = '9'.codeUnitAt(0);
// ignore: non_constant_identifier_names
final int _codeUnit_a = 'a'.codeUnitAt(0);
// ignore: non_constant_identifier_names
final int _codeUnit_z = 'z'.codeUnitAt(0);
// ignore: non_constant_identifier_names
final int _codeUnit_A = 'A'.codeUnitAt(0);
// ignore: non_constant_identifier_names
final int _codeUnit_Z = 'Z'.codeUnitAt(0);

bool isDigit(int c) {
  if (c < _codeUnit_0 || c > _codeUnit_9) return false;
  return true;
}

bool isAlphaNumeric(int c) {
  if (c < _codeUnit_0 ||
      c > _codeUnit_z ||
      ((c > _codeUnit_9 && c < _codeUnit_A) ||
          (c > _codeUnit_Z && c < _codeUnit_a && c != _codeUnit__))) {
    return false;
  }
  return true;
}

bool isDigitString(String s, [int offset = 0]) {
  return isDigitStringInRange(s, offset, s.length - offset);
}

bool isDigitStringInRange(String s, int offset, int length) {
  if (length <= 0) return false;

  var end = Math.min(s.length, offset + length);

  for (var i = offset; i < end; i++) {
    var c = s.codeUnitAt(i);
    if (!isDigit(c)) return false;
  }

  return true;
}

bool isAlphaNumericString(String s, [int offset = 0]) {
  return isAlphaNumericStringInRange(s, offset, s.length - offset);
}

bool isAlphaNumericStringInRange(String s, int offset, int length) {
  if (length <= 0) return false;

  var end = Math.min(s.length, offset + length);

  for (var i = offset; i < end; i++) {
    var c = s.codeUnitAt(i);
    if (!isAlphaNumeric(c)) return false;
  }

  return true;
}

/// Removes quotes from [String] [s]
String unquoteString(String s) {
  if (s.length <= 1) return s;

  if ((s.startsWith('"') && s.endsWith('"')) ||
      (s.startsWith("'") && s.endsWith("'"))) {
    return s.substring(1, s.length - 1);
  }

  return s;
}
