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
