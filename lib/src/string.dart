/// Returns [true] if [c] is a blank char (space, \t, \n, \r).
bool isBlankChar(String c) {
  return c == ' ' || c == '\n' || c == '\t' || c == '\r';
}

/// Returns ![isBlankChar].
bool isNonBlankChar(String c) {
  return !isBlankChar(c);
}

final int _codeUnit_space = ' '.codeUnitAt(0);
final int _codeUnit_n = '\n'.codeUnitAt(0);
final int _codeUnit_r = '\r'.codeUnitAt(0);
final int _codeUnit_t = '\t'.codeUnitAt(0);

/// Returns [true] if [c] is a blank char code unit.
bool isBlankCodeUnit(int c) {
  return c == _codeUnit_space ||
      c == _codeUnit_n ||
      c == _codeUnit_t ||
      c == _codeUnit_r;
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
bool hasBlankCharFrom(String s, int offset) {
  if (s == null) return false;
  return hasBlankCharInRange(s, offset, s.length - offset);
}

/// Returns [true] if [s] has a blank character in range [offset]+[length].
bool hasBlankCharInRange(String s, int offset, int length) {
  if (s == null) return false;

  offset ??= 0;
  length ??= s.length - offset;
  if (length <= 0) return false;

  var end = offset + length;

  for (var i = offset; i < end; i++) {
    var c = s.codeUnitAt(i);
    if (isBlankCodeUnit(c)) return true;
  }

  return false;
}

/// Returns [true] if [s] has only blank characters.
bool isBlankString(String s, [int offset]) {
  if (s == null) return false;
  offset ??= 0;
  return isBlankStringInRange(s, offset, s.length - offset);
}

/// Returns [true] if [s] has only blank characters in range [offset]+[length].
bool isBlankStringInRange(String s, int offset, int length) {
  if (s == null) return false;

  offset ??= 0;
  length ??= s.length - offset;
  if (length <= 0) return false;

  var end = offset + length;

  for (var i = offset; i < end; i++) {
    var c = s.codeUnitAt(i);
    if (!isBlankCodeUnit(c)) return false;
  }

  return true;
}

final int _codeUnit__ = '_'.codeUnitAt(0);
final int _codeUnit_0 = '0'.codeUnitAt(0);
final int _codeUnit_9 = '9'.codeUnitAt(0);
final int _codeUnit_a = 'a'.codeUnitAt(0);
final int _codeUnit_z = 'z'.codeUnitAt(0);
final int _codeUnit_A = 'A'.codeUnitAt(0);
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

bool isDigitString(String s, [int offset]) {
  if (s == null) return false;
  offset ??= 0;
  return isDigitStringInRange(s, offset, s.length - offset);
}

bool isDigitStringInRange(String s, int offset, int length) {
  if (s == null) return false;

  offset ??= 0;
  length ??= s.length - offset;
  if (length <= 0) return false;

  var end = offset + length;

  for (var i = offset; i < end; i++) {
    var c = s.codeUnitAt(i);
    if (!isDigit(c)) return false;
  }

  return true;
}

bool isAlphaNumericString(String s, [int offset]) {
  if (s == null) return false;
  offset ??= 0;
  return isAlphaNumericStringInRange(s, offset, s.length - offset);
}

bool isAlphaNumericStringInRange(String s, int offset, int length) {
  if (s == null) return false;

  offset ??= 0;
  length ??= s.length - offset;
  if (length <= 0) return false;

  var end = offset + length;

  for (var i = offset; i < end; i++) {
    var c = s.codeUnitAt(i);
    if (!isAlphaNumeric(c)) return false;
  }

  return true;
}

/// Removes quotes from [String] [s]
String unquoteString(String s) {
  if (s == null) return null;
  if (s.length <= 1) return s;

  if ((s.startsWith('"') && s.endsWith('"')) ||
      (s.startsWith("'") && s.endsWith("'"))) {
    return s.substring(1, s.length - 1);
  }

  return s;
}
