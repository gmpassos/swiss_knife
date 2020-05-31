import 'package:swiss_knife/src/collections.dart';

/// Splits [s] using [delimiter] and [limit].
///
/// [delimiter] RegExp to use to split [s].
/// [limit] The maximum elements to return.
///
/// Note: Standard Dart split doesn't have [limit] parameter.
List<String> splitRegExp(String s, Pattern delimiter, [int limit]) {
  if (limit == null) return s.split(delimiter);
  if (limit == 1) return [s];

  if (limit == 2) {
    for (var match in delimiter.allMatches(s)) {
      var s1 = s.substring(0, match.start);
      var s2 = s.substring(match.end);
      return [s1, s2];
    }
    return [s];
  }

  if (limit <= 0) limit = s.length;

  var parts = <String>[];

  var sOffset = 0;

  --limit;

  for (var match in delimiter.allMatches(s)) {
    var start = match.start - sOffset;
    var end = match.end - sOffset;

    var s1 = s.substring(0, start);
    var s2 = s.substring(end);

    parts.add(s1);

    s = s2;
    sOffset = match.end;

    if (parts.length == limit) {
      break;
    }
  }

  parts.add(s);

  return parts;
}

/// Returns [true] if [regExp] has any match at [s].
///
/// [regExp] Uses [parseRegExp] to parse.
bool regExpHasMatch(dynamic regExp, String s) {
  var theRegExp = parseRegExp(regExp);
  return theRegExp.hasMatch(s);
}

/// Parses [regExp] parameter to [RegExp].
RegExp parseRegExp(dynamic regExp) {
  if (regExp == null) return null;
  return regExp is RegExp ? regExp : RegExp(regExp.toString());
}

/// A Replacer using RegExp.
///
/// Allows use of `$1`, `$2` or `${1}`, `${2}` as group place holders.
///
/// Used by [regExpReplaceAll].
class _RegExpReplacer {
  List _parts;

  _RegExpReplacer(String replace) {
    var matches = RegExp(r'(?:\$(\d+)|\${(\d+)})').allMatches(replace);

    _parts = [];

    var cursor = 0;
    for (var match in matches) {
      if (match.start > cursor) {
        var sPrev = replace.substring(cursor, match.start);
        _parts.add(sPrev);
      }

      var g1 = match.group(1);
      var g2 = match.group(2);

      var id = g1 ?? g2;

      var groupID = int.parse(id);

      _parts.add(groupID);

      cursor = match.end;
    }

    if (cursor < replace.length) {
      var sEnd = replace.substring(cursor);
      _parts.add(sEnd);
    }
  }

  String replaceMatch(Match match) {
    var s = '';

    for (var part in _parts) {
      if (part is int) {
        var groupValue = match.group(part);
        if (groupValue != null) {
          s += groupValue;
        }
      } else {
        s += part;
      }
    }

    return s;
  }

  String replaceAll(dynamic regExp, String s) {
    var theRegExp = parseRegExp(regExp);
    return s.replaceAllMapped(theRegExp, replaceMatch);
  }
}

/// Uses [regExp] to replace matches at [s], substituting with [replace].
///
/// [replace] accepts use of `$1`, `$2` or `${1}`, `${2}` as group place holders.
String regExpReplaceAll(dynamic regExp, String s, String replace) {
  return _RegExpReplacer(replace).replaceAll(regExp, s);
}

/// Uses [regExp] to replace matches at [s], substituting with [replace] Function results.
String regExpReplaceAllMapped(
    dynamic regExp, String s, String Function(Match match) replace) {
  var theRegExp = parseRegExp(regExp);
  return s.replaceAllMapped(theRegExp, replace);
}

/// Builds a [RegExp] using a dialect of words ([Map] parameter [dialectWords]).
///
/// Each word in the dialect can be a RegExp pattern as string,
/// but with word place holders in the syntax.
///
/// A word place holder in the syntax is a word name
/// (key in [dialectWords] Map) in the format: `$wordName`
///
/// [pattern] The final pattern, constructed using the dialect and word place holders.
/// [multiLine] If [true] the returned [RegExp] will be multiLine.
/// [caseSensitive] If [true] the returned [RegExp] will be case-sensitive.
RegExp regExpDialect(Map<String, String> dialectWords, String pattern,
    {bool multiLine = false, bool caseSensitive = true}) {
  for (var i = 0; i < 10; i++) {
    var words2 = dialectWords.map(
        (k, v) => MapEntry(k, _regExpDialectImpl(dialectWords, v).pattern));
    if (isEqualsDeep(dialectWords, words2)) break;
    dialectWords = words2;
  }
  return _regExpDialectImpl(dialectWords, pattern);
}

RegExp _regExpDialectImpl(Map<String, String> words, String pattern,
    {bool multiLine = false, bool caseSensitive = true}) {
  var translated = pattern.replaceAllMapped(RegExp(r'(\\\$|\$)(\w+)'), (m) {
    var mark = m.group(1);
    var key = m.group(2);

    if (mark == r'\$') return '$mark$key';

    var value = words[key];
    return value ?? '$mark$key';
  });
  return RegExp(translated, multiLine: multiLine, caseSensitive: caseSensitive);
}

/// Builds a string using as place holders in the format `{{key}}`
/// from [parameters] and [extraParameters].
String buildStringPattern(String pattern, Map parameters,
    [List<Map> extraParameters]) {
  if (pattern == null) return null;

  var matches = RegExp(r'{{(/?\w+(?:/\w+)*/?)}}').allMatches(pattern);

  var strFilled = '';

  var pos = 0;
  for (var match in matches) {
    var prev = pattern.substring(pos, match.start);
    strFilled += prev;

    var varName = match.group(1);

    while (varName.startsWith('/')) {
      varName = varName.substring(1);
    }

    while (varName.endsWith('/')) {
      varName = varName.substring(0, varName.length - 1);
    }

    var val = findKeyPathValue(parameters, varName);

    if (val == null && extraParameters != null) {
      for (var parameters2 in extraParameters) {
        val = findKeyPathValue(parameters2, varName);
      }
    }

    strFilled += '$val';

    pos = match.end;
  }

  if (pos < pattern.length) {
    var prev = pattern.substring(pos);
    strFilled += prev;
  }

  return strFilled;
}
