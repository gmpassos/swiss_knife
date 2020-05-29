## 2.4.1

- isIPAddress()
- parseDateTime() accepts `int`: parsing with `DateTime.fromMillisecondsSinceEpoch(v)`.
- parseDuration()
- enum Unit: getUnitByIndex(), getUnitByName(), parseUnit(), getUnitAsMilliseconds(), getMillisecondsAsUnit()
- getDateTimeWeekDayByName(), getDateTimeStartOf(), getDateTimeEndOf()

## 2.4.0

- date.dart:
  - parseDateTime(...), parseDateTimeFromInlineList(...)
  - formatTimeMillis() change form to be ISO compliant.
  - DateTimeWeekDay: getDateTimeWeekDay(), getDateTimeWeekDay_from_ISO_8601_index().
  - getDateTimeDayStart(), getDateTimeDayEnd(), getDateTimeYesterday(), getDateTimeLastNDays(), getDateTimeThisWeek().
  - getDateTimeLastWeek(), getDateTimeThisMonth(), getDateTimeLastMonth(), getDateTimePreviousMonth(), getDateTimeWeekStart(), getDateTimeWeekEnd().
  - DateRangeType: getDateTimeRange(rangeType, ...)
- uri.dart:
  - getUriBase(), getUriRoot(), getUriBaseScheme(), getUriBaseHost(), getUriBasePort(),
  - getUriBaseHostAndPort(suppressPort80), getUriBaseURL(), buildUri(), resolveUri(), removeUriFragment().
  - removeUriQueryString(), isUriBaseLocalhost(), isUriBaseIP(), isIPv4Address(), getPathFileName().
- utils.dart: toCamelCase()
- math.dart: 
- events.dart: EventStream.isUsed: non used EventStream won't broadcast events (add() and addError() suppressed for optimization).
- data.dart:
  - MimeType
  - Base64: encodeArrayBuffer(), decodeAsArrayBuffer()
  - DataURLBase64: parsePayloadAsBase64(), parsePayloadAsArrayBuffer(), parsePayloadAsString(), DataURLBase64.mimeType.
- collections.dart:
  - Pair<T>
  - MapProperties: getPropertyAsDateTime(), findPropertyAsDateTime(), getPropertyAsDateTimeList(), findPropertyAsDateTimeList(), getPropertyAsStringMap(), findPropertyAsStringMap().
  - sortMapEntries()
  - toFlatListOfStrings()
  - isListOfNum(), isListOfType<T>(...), isListOfTypes<A,V>(...), listContainsType<T>(...)
  - parseListOf(...), parseListOfList(...)
  - isMapOfStringKeysAndListValues(), isMapOfStringKeysAndNumValues().
  - isEmptyValue(val).
- loader.dart: LoadController

## 2.3.10

- MapDelegate ; MapProperties
- isEmail()
- ResourceContent.isLoadedWithError

## 2.3.9

- deepCopy()
- buildStringPattern(), isHttpURL(), getPathExtension(), isAllEquals()
- findKeyPathValue(), parseFromInlineMap()
- ResourceContent, ResourceContentCache (moved from intl_messages)
- fix default value of parseNum().
- remove swiss_knife_browser.dart: moved to package 'dom_tools'.
- resource_portable: ^2.1.7

## 2.3.8

- Accepts dynamic value as input: parseStringFromInlineList, parseIntsFromInlineList, parseNumsFromInlineList, parseDoublesFromInlineList, parseBoolsFromInlineList
- New: isInt, isIntList, isNum, isNumList, isDouble, isDoubleList, isBool, isBoolList

## 2.3.7

- regExpReplaceAll(): allow ${1} marks (previously was only $1).
- fix regExpReplaceAll() when group match is optional.
- regExpDialect()
- isEqualsAsString()
- swiss_knife_vm.dart: catFile(), saveFile()

## 2.3.6

- regExpHasMatch
- regExpReplaceAll

## 2.3.5

- Fix return of parseIntsFromInlineList().
- Added default value for parseXXFromInlineList().

## 2.3.4

- deepHashCode

## 2.3.3

- splitRegExp().
- Tests: split() and splitRegExp() (limits: Java compliant).

## 2.3.2

- isEqualsDeep() ; parseFromInlineList() ;
- parseString() ; parseStringFromInlineList() ;
- parseBool() ; parseNumsFromInlineList() ; parseIntsFromInlineList() ; parseBoolsFromInlineList() ;

## 2.3.1

- Clean code.

## 2.3.0

- More tests.
- Math.min/max/ceil/floor/round/mean/standardDeviation
- parseNum(), parseInt(), parseDouble(), parsePercent(), getEntryIgnoreCase(), putIgnoreCase().
- dataSizeFormat()
- Base64 and DataURLBase64.

## 2.2.1

- Organize code in different dart files.
- Code analysis.
- Upgrade dependencies:
    - intl: ^0.16.1
    - remove "enum_to_string".

## 2.2.0

- Remove locales to package intl_messages.
- Remove rest_client to package mercury_client.

## 2.1.2

- Add LocalesManager.onDefineLocale and LocalesManager.onDefineLocaleGlobal 

## 2.1.1

- Small fixes.

## 2.1.0

- Added Authorization and Credential/Token handling to REST Client.

## 2.0.0

- Update to Dart 2.0.1 and small fixes. Now able to import only utils (swiss_knife_utils.dart)

## 1.0.1

- Fix swiss_knife_browser.dart exports.

## 1.0.0

- Added events example.
- Initial version, created by Stagehand

