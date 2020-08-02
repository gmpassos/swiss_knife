/// Returns [true] if [c] is a blank char (space, \t, \n, \r).
bool isBlankChar(String c) {
  return c == ' ' || c == '\n' || c == '\t' || c == '\r';
}

/// Returns ![isBlankChar].
bool isNonBlankChar(String c) {
  return !isBlankChar(c);
}

/// Returns [true] if [c] is a blank char code unit.
bool isBlankCodeUnit(int c) {
  return c == ' '.codeUnitAt(0) ||
      c == '\n'.codeUnitAt(0) ||
      c == '\t'.codeUnitAt(0) ||
      c == '\r'.codeUnitAt(0);
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
  var end = offset + length;

  for (var i = offset; i < end; i++) {
    var c = s.codeUnitAt(i);
    if (isBlankCodeUnit(c)) return true;
  }

  return false;
}
