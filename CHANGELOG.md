## 2.5.26

- Optimize: `parseInt`, `parseDouble` and `parseNum`.
- Fix: `listNotMatchesAll` and `listMatchesAny` when leading with lists with `null` elements. 
- Dart 2.12.0+ compliant: `dartfmt` and `dartanalyzer`.

## 2.5.25

- `TreeReferenceMap`: ensure that `root` is not null.
- `EventStream`: Added `listenOneShot`.

## 2.5.24

- `TreeReferenceMap`:
  - fix `getParentKey`.

## 2.5.23

- Added `TreeReferenceMap`: an alternative to Weak References (nonexistent in Dart).

## 2.5.22

- `MimeType.byExtension`: Added parameter `defaultAsApplication`.

## 2.5.21

- `MimeType`: Added `htmlTag` and `isAudio`.
- Added `unquoteString`.

## 2.5.20
 
- Added `ObjectCache`.
- Added `Dimension`.
- Added `ContextualResource` and `ContextualResourceResolver`:
  - Resolves a resource based into a context, like screen dimension.
- Added: `parseFromInlineProperties` and `dateFormat_YYYY_MM`.
- `EventStream`:
  - Added `eventValidator`.
- `Math`: 
  - `minMax`, `maxInList` and `minInList`: added optional `comparator` parameter.

## 2.5.19

- `MimeType`: Added `isCharsetUTF16`, `isText`, `isXML`, `isXHTML`, `isFormURLEncoded`, `isStringType`.
- `dateFormat_YY*`: added optional parameter `delimiter`.
- `InteractionCompleter`: Added field `triggerDelayLimit`.
- `Math`:
  - Added collection methods: `subtract`, `multiply` and `divide`.

## 2.5.18

- Improve API Documentation.

## 2.5.17

- Added `resolveURL`, similar to `resolveUri`.
- Added `replaceStringMarks`.
- `buildStringPattern` using `replaceStringMarks` and now returns empty string for null parameters.
- Added `EventStreamDelegator`, to point to instances of `EventStream` not instantiated yet.  
- Added `ListenerWrapper`, to handle `StreamSubscription` related to a listener and useful to create one shot listeners.

## 2.5.16

- New `AsyncValue`: to handle values that comes from `Future`.
- Added `isEncodedJSON`, `isEncodedJSONList` and `isEncodedJSONMap`: to check if a `String` is an encoded JSON.
- ADded `isDigit`, `isAlphaNumeric`, `isDigitString`, `isAlphaNumericString`.
- Added `listMatchesAny`, `isListValuesIdentical`, `listContainsAll`, `ensureNotEmptyString`, `deepCatchesValues`.
- `MimeType.fileExtension`: support for `svg`, `xhtml`, `mpeg`, `mp3`, `ico`.
- Changed method signature: `getUriRootURL`, `getUriBaseHostAndPort`, `resolveUri`.

## 2.5.15

- Added: `isEmptyString`, `isNotEmptyString`, `isListEntriesAllOfType`.
- Added `deepCopyMap`.
- `deepCopy`: added parameter `copier`.
- `NNField`: Added `resolver`.
- `MimeType`: added SVG support.
- `InteractionCompleter`:
  - `interact`: Added parameters `interactionParameters` and `ignoreConsecutiveEqualsParameters`.
  - Added `dispose`.
- `encodeJSON`: Added parameter `toEncodable`.
- Added: `toEncodableJSON`.
- `parseInt`, `parseDouble` and `parseNum` now returns default value (`def`) in case of parsing error.
- isDouble now can parse `.00` pattern.
- Fix: `dataSizeFormat`.

## 2.5.14

- `MimeType`: Added new types.
- Added constructor `MimeType.byExtension`.
- `MimeType`: Fixed parsing of `gif`.
- `EventStream`: Added `cancelAllSingletonSubscriptions`, `cancelSingletonSubscription`, `getSingletonSubscription`.
- Added `listenStreamWithInteractionCompleter`.
- pedantic: ^1.9.2

## 2.5.13

- `removeUriQueryString`: avoid blank fragment in the URL.

## 2.5.12

- Added `isPositiveNumber`, `isNegativeNumber`.
- Added `MimeType.APPLICATION_ZIP`.
- Added `maxInIterable`, `minInIterable`.
- Added `deepReplaceValues`, `deepReplaceListValues`, `deepReplaceMapValues`.
- Added `parseComparable`, `removeEmptyEntries`, `sortMapEntries`, `sortMapEntriesByValue`, `sortMapEntriesByKey`.

## 2.5.11

- Added `NNField`.
- Added `clipNumber`.
- `parseBool`: if value is a num: true = v > 0
- More tests.

## 2.5.10

- Fix typo.

## 2.5.9

- `MimeType`: Added `charset`.
- Added: `parseJSON`, `isBlankString`, `isBlankStringInRange`, `isEqualsSet`, `isEqualsIterable`.
- Added: `asTreeOfKeyString`, `parseMapEntry`, `groupIterableBy`, `sumIterable`, `averageIterable`.
- Added: `parseJSON`, `encodeJSON`.
- Removed `splitRegExp`. `split` now accepts `Pattern` (`String` and `RegExp`).
- Optimized `isBlankCodeUnit`.

## 2.5.8

- Added string helpers: `isBlankChar`, `isBlankCodeUnit`, `hasBlankChar`, `hasBlankCharInRange`.
- IO: `catFile`, `catFileBytes`, `saveFile`, `saveFileBytes`.
- `InteractionCompleter`: `cancel`
- `MimeType``: equals and hashcode.
- Added: `isEqualsList`, `isEqualsMap`.

## 2.5.7

- Added: `isInUnixEpochRange`
- New event handler: `InteractionCompleter`.

## 2.5.6

- dartfmt
- test_coverage: ^0.4.2

## 2.5.5

- Change `isEmptyValue` to is `isEmptyObject`.
- Added `isNotEmptyObject`.

## 2.5.4

- Fix `MimeType.parse` when parameter `mimeType` is empty and `defaultMimeType` is null.
- Fix `DataURLBase64.asDataURLString`
- dartfmt.

## 2.5.3 

- fix buildStringPattern() extraParameters issue.

## 2.5.2

- Math.mean() returns 0 on empty lists.
- dartfmt.
- Add badges to README.md

## 2.5.1

- Math.sum()
- More API Documentation.

## 2.5.0

- dartfmt.

## 2.4.2

- Added API Documentation.
- dataSizeFormat() now accepts decimalBase and binaryBase parameters.
- Pair.swapAB().
- Scale and ScaleNum.
- getPathWithoutFileName(...).
- MimeType: added alias and file extension for gzip.
- (FIX) LoadController: _idCounter to private.
- (FIX) EventStream.listenAsFuture(): ensure that completer is called only once.

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

