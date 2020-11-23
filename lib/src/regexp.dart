import 'package:swiss_knife/src/collections.dart';

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
        {bool multiLine = false, bool caseSensitive = true}) =>
    RegExpDialect(dialectWords,
            multiLine: multiLine, caseSensitive: caseSensitive)
        .getPattern(pattern);

/// Represents a dialect. Compiles it on construction.
class RegExpDialect {
  Map<String, String> _dialect;

  final bool multiLine;

  final bool caseSensitive;

  RegExpDialect(Map<String, String> dialect,
      {bool multiLine = false,
      bool caseSensitive = true,
      bool throwCompilationErrors = true})
      : multiLine = multiLine ?? false,
        caseSensitive = caseSensitive ?? true {
    _dialect = _compile(dialect, throwCompilationErrors);
  }

  RegExpDialect._(this._dialect, this.multiLine, this.caseSensitive);

  /// Returns a copy of this instance with parameters [multiLine] and [caseSensitive].
  /// If this instance already have the same parameters returns this instance.
  RegExpDialect withParameters(
      {bool multiLine = false,
      bool caseSensitive = true,
      bool throwCompilationErrors = true}) {
    multiLine ??= false;
    caseSensitive ??= true;

    if (hasErrors && (throwCompilationErrors ?? true)) {
      throw StateError(
          "Can't use a dialect with errors. Words with errors: ${errorWords.join(', ')}");
    }

    if (this.multiLine == multiLine && this.caseSensitive == caseSensitive) {
      return this;
    }

    return RegExpDialect._(_dialect, multiLine, caseSensitive);
  }

  factory RegExpDialect.from(dynamic dialect,
      {bool multiLine, bool caseSensitive, bool throwCompilationErrors}) {
    if (dialect == null) return null;

    if (dialect is RegExpDialect) {
      return dialect.withParameters(
          multiLine: multiLine,
          caseSensitive: caseSensitive,
          throwCompilationErrors: throwCompilationErrors);
    }

    if (dialect is Map) {
      var map = asMapOfString(dialect);
      return RegExpDialect(map,
          multiLine: multiLine,
          caseSensitive: caseSensitive,
          throwCompilationErrors: throwCompilationErrors);
    }

    return null;
  }

  Map<String, String> _compile(
      Map<String, String> dialect, bool throwCompilationErrors) {
    throwCompilationErrors ??= true;

    for (var i = 0; i < 20; i++) {
      var words2 = dialect.map((k, v) => MapEntry(
          k, _compileWordPatternAndSaveErrors(dialect, k, v)?.pattern));
      if (isEqualsDeep(dialect, words2)) break;

      if (hasErrors) {
        if (throwCompilationErrors) {
          throw FormatException(
              "Error compiling dialect words: '${errorWords.join("', '")}'");
        } else {
          return dialect;
        }
      }

      dialect = words2;
    }
    return dialect;
  }

  final Map<String, List<String>> _errors = {};

  bool get hasErrors => _errors.isNotEmpty;

  List<String> get errorWords => _errors.keys.toList();

  String getWordErrorMessage(String word) => _errors[word]?.first;

  String getWordErrorPattern(String word) => _errors[word]?.last;

  RegExp _compileWordPatternAndSaveErrors(
      Map<String, String> dialect, String word, String pattern) {
    try {
      return _compileWordPattern(dialect, pattern);
    } catch (e) {
      _errors[word] = [e.toString(), pattern];
      return null;
    }
  }

  static final _PATTERN_WORD_PLACEHOLDER = RegExp(r'(\\\$|\$)(\w+)');

  RegExp _compileWordPattern(Map<String, String> words, String pattern) {
    var translated = pattern.replaceAllMapped(_PATTERN_WORD_PLACEHOLDER, (m) {
      var mark = m.group(1);
      var key = m.group(2);

      if (mark == r'\$') return '$mark$key';

      var value = words[key];
      return value ?? '$mark$key';
    });
    return RegExp(translated,
        multiLine: multiLine, caseSensitive: caseSensitive);
  }

  List<String> get words => _dialect.keys.toList();

  final Map<String, RegExp> _wordsPatterns = {};

  /// Returns [RegExp] pattern for [word]. Will cache [RegExp] instances.
  RegExp getWordPattern(String word) {
    if (word == null) return null;
    var regexp = _wordsPatterns[word];
    if (regexp != null) return regexp;

    var pattern = _dialect[word];
    if (pattern == null) return null;

    if (hasErrors) {
      if (_errors.containsKey(word)) {
        throw StateError("Can't use word with compilation error! Word: $word");
      }

      var patternWords = _PATTERN_WORD_PLACEHOLDER
          .allMatches(pattern)
          .map((m) => m.group(2))
          .toList();

      var patternWordsWithError =
          patternWords.where((w) => _errors.containsKey(w)).toList();

      if (patternWordsWithError.isNotEmpty) {
        throw StateError(
            "Can't use word with compilation error! Words: $patternWordsWithError");
      }
    }

    regexp =
        RegExp(pattern, multiLine: multiLine, caseSensitive: caseSensitive);

    _wordsPatterns[word] = regexp;

    return regexp;
  }

  final Map<String, RegExp> _patterns = {};

  /// Returns a compiled [RegExp] [pattern], using `$words` in dialect.
  RegExp getPattern(String pattern) {
    var regexp = _patterns[pattern];
    if (regexp != null) return regexp;

    regexp = _compileWordPattern(_dialect, pattern);
    _patterns[pattern] = regexp;
    return regexp;
  }
}

final RegExp STRING_PLACEHOLDER_PATTERN = RegExp(r'{{(/?\w+(?:/\w+)*/?)}}');

/// Builds a string using as place holders in the format `{{key}}`
/// from [parameters] and [extraParameters].
String buildStringPattern(String pattern, Map parameters,
    [List<Map> extraParameters]) {
  if (pattern == null) return null;

  return replaceStringMarks(pattern, STRING_PLACEHOLDER_PATTERN, (varName) {
    while (varName.startsWith('/')) {
      varName = varName.substring(1);
    }

    while (varName.endsWith('/')) {
      varName = varName.substring(0, varName.length - 1);
    }

    var val = findKeyPathValue(parameters, varName);

    if (val == null && extraParameters != null) {
      for (var parameters2 in extraParameters) {
        if (parameters2 != null && parameters2.isNotEmpty) {
          val = findKeyPathValue(parameters2, varName);
          if (val != null) break;
        }
      }
    }

    return val != null ? val.toString() : '';
  });
}

/// Replaces String [s] marks using [marksPattern] and [markResolver].
///
/// [marksPattern] A [RegExp] with the mark pattern and a 1 group with the mark name.
/// [markResolver] Resolves mark name (from [marksPattern] group(1)) to a value to replace the [marksPattern] match.
String replaceStringMarks(String s, RegExp marksPattern,
    String Function(String markName) markResolver) {
  if (s == null) return null;

  var matches = marksPattern.allMatches(s);

  var strFilled = '';

  var pos = 0;
  for (var match in matches) {
    var prev = s.substring(pos, match.start);
    strFilled += prev;

    var markName = match.group(1);

    var val = markResolver(markName);

    strFilled += '$val';

    pos = match.end;
  }

  if (pos < s.length) {
    var prev = s.substring(pos);
    strFilled += prev;
  }

  return strFilled;
}
