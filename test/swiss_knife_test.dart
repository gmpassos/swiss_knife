
import 'package:swiss_knife/swiss_knife.dart';
import 'package:test/test.dart';

void main() {


  group('Math', () {
    setUp(() {});

    test('Collections', () {

      expect( isEquivalentMap( {'a':1,'b':2} , {'b':2,'a':1}  ), equals(true));
      expect( isEquivalentMap( {'a':1,'b':2} , {'b':3,'a':1}  ), equals(false));

      expect( isEquivalentList( [1,2,3,4] , [4,3,2,1] , sort: true ), equals(true));
      expect( isEquivalentList( [1,2,3,4] , [4,3,2,1] , sort: false ), equals(false));

      expect( findKeyValue( {'a':11, 'b':22} , ['A'] , true ), equals(11));
      expect( findKeyValue( {'a':11, 'b':22} , ['A'] , false ), equals(null));
      expect( findKeyValue( {'a':11, 'b':22} , ['a'] , false ), equals(11));

      expect( findKeyName( {'a':11, 'b':22} , ['A'] , true ), equals('a'));
      expect( findKeyName( {'a':11, 'b':22} , ['A'] , false ), equals(null));
      expect( findKeyName( {'a':11, 'b':22} , ['a'] , false ), equals('a'));

      expect( findKeyName( {'Aa':11, 'b':22} , ['aa','Aa'] , false ), equals('Aa'));

      expect( findKeyEntry( {'Aa':11, 'b':22} , ['aa','Aa'] , false ).toString() , equals( MapEntry('Aa',11).toString() ));

      expect( getIgnoreCase( {'Aa':11, 'b':22} , 'aa' ) , equals(11));
      expect( getEntryIgnoreCase( {'Aa':11, 'b':22} , 'aa' ).value , equals(11));

      {
        var map = {'Aa':11.0, 'b':22};
        expect( map['Aa'] , equals(11.0));
        putIgnoreCase( map , 'aa' , 11.1 );
        expect( map['Aa'] , equals(11.1));
      }

    });


    test('deep', () {

      expect( isEquivalentMap( {'a': [1,2] ,'b':2} , {'b':2,'a': [1,2]}  ), equals(false));
      expect( isEquivalentMap( {'a': [1,2] ,'b':2} , {'b':2,'a': [1,2]}  , deep: true ), equals(true));
      expect( isEquivalentMap( {'a': [1,2] ,'b':2} , {'b':2,'a': [1,'2']}  , deep: true ), equals(false));

      expect( isEquivalentMap( {'a': {'x':[1,2]} ,'b':2} , {'b':2,'a': {'x': [1,2]} }  ), equals(false));
      expect( isEquivalentMap( {'a': {'x':[1,2]} ,'b':2} , {'b':2,'a': {'x': [1,2]} } , deep: true  ), equals(true));
      expect( isEquivalentMap( {'a': {'x':[1,2]} ,'b':2} , {'b':2,'a': {'x': [1,'2']} } , deep: true  ), equals(false));

    });

  });


  group('String', () {
    setUp(() {});

    test('split', () {

      expect( split('a,b,c', ','), equals( ['a','b','c'] ));
      expect( split('a,b,c', ',' , 0), equals( ['a','b','c'] ));
      expect( split('a,b,c', ',' , 1), equals( ['a,b,c'] ));
      expect( split('a,b,c', ',' , 2), equals( ['a','b,c'] ));
      expect( split('a,b,c', ',' , 3), equals( ['a','b','c'] ));

      expect( split('a,b,c,d', ',' , 0), equals( ['a','b','c','d'] ));
      expect( split('a,b,c,d', ',' , 1), equals( ['a,b,c,d'] ));
      expect( split('a,b,c,d', ',' , 2), equals( ['a','b,c,d'] ));
      expect( split('a,b,c,d', ',' , 3), equals( ['a','b','c,d'] ));
      expect( split('a,b,c,d', ',' , 4), equals( ['a','b','c','d'] ));
      expect( split('a,b,c,d', ',' , 5), equals( ['a','b','c','d'] ));

      expect( split('a,', ',' , 0), equals( ['a',''] ));
      expect( split('a,', ',' , 1), equals( ['a,'] ));
      expect( split('a,', ',' , 2), equals( ['a',''] ));
      expect( split('a,', ',' , 3), equals( ['a',''] ));

      expect( split('a,b,', ',' , 0), equals( ['a','b',''] ));
      expect( split('a,b,', ',' , 1), equals( ['a,b,'] ));
      expect( split('a,b,', ',' , 2), equals( ['a','b,'] ));
      expect( split('a,b,', ',' , 3), equals( ['a','b',''] ));

      expect( split('AA,,BB,,CC', ',,'), equals( ['AA','BB','CC'] ));
      expect( split('AA,,BB,,CC,,', ',,'), equals( ['AA','BB','CC',''] ));
      expect( split('AA,,BB,,CC', ',,', 2), equals( ['AA','BB,,CC'] ));
      expect( split('AA,,BB,,CC', ',,', 3), equals( ['AA','BB','CC'] ));
      expect( split('AA,,BB,,CC,,', ',,', 3), equals( ['AA','BB','CC,,'] ));

    });

    test('splitRegexp', () {

      var delimiter = RegExp(',');

      expect( splitRegExp('a,b,c', delimiter), equals( ['a','b','c'] ));
      expect( splitRegExp('a,b,c', delimiter , 0), equals( ['a','b','c'] ));
      expect( splitRegExp('a,b,c', delimiter , 1), equals( ['a,b,c'] ));
      expect( splitRegExp('a,b,c', delimiter , 2), equals( ['a','b,c'] ));
      expect( splitRegExp('a,b,c', delimiter , 3), equals( ['a','b','c'] ));

      expect( splitRegExp('a,b,c,d', delimiter , 0), equals( ['a','b','c','d'] ));
      expect( splitRegExp('a,b,c,d', delimiter , 1), equals( ['a,b,c,d'] ));
      expect( splitRegExp('a,b,c,d', delimiter , 2), equals( ['a','b,c,d'] ));
      expect( splitRegExp('a,b,c,d', delimiter , 3), equals( ['a','b','c,d'] ));
      expect( splitRegExp('a,b,c,d', delimiter , 4), equals( ['a','b','c','d'] ));
      expect( splitRegExp('a,b,c,d', delimiter , 5), equals( ['a','b','c','d'] ));

      expect( splitRegExp('a,b,', delimiter , 0), equals( ['a','b',''] ));
      expect( splitRegExp('a,b,', delimiter , 1), equals( ['a,b,'] ));
      expect( splitRegExp('a,b,', delimiter , 2), equals( ['a','b,'] ));
      expect( splitRegExp('a,b,', delimiter , 3), equals( ['a','b',''] ));


      expect( splitRegExp('AA,,BB,,CC', ',,'), equals( ['AA','BB','CC'] ));
      expect( splitRegExp('AA,,BB,,CC,,', ',,'), equals( ['AA','BB','CC',''] ));
      expect( splitRegExp('AA,,BB,,CC', ',,', 2), equals( ['AA','BB,,CC'] ));
      expect( splitRegExp('AA,,BB,,CC', ',,', 3), equals( ['AA','BB','CC'] ));
      expect( splitRegExp('AA,,BB,,CC,,', ',,', 3), equals( ['AA','BB','CC,,'] ));

    });

  });


  group('Math', () {

    setUp(() {
    });

    test('max,min', () {

      expect( Math.max(11, 22), equals(22));
      expect( Math.min(11, 22), equals(11));

      expect( Math.minMax( [11, 33, 22] ), equals( Pair(11,33) ) );

    });

    test('ceil,floor,round', () {

      expect( Math.ceil( 2.2 ), equals(3));
      expect( Math.floor(2.2), equals(2));

      expect( Math.round(2.2), equals(2));
      expect( Math.round(2.7), equals(3));

    });

    test('statistics', () {

      expect( Math.mean( [2,4] ), equals(3));

    });

    test('parseNum', () {

      expect( parseNum(0), equals(0));
      expect( parseNum(1), equals(1));
      expect( parseNum(-1), equals(-1));
      expect( parseNum(3), equals(3));
      expect( parseNum(3.3), equals(3.3));
      expect( parseNum(-3.3), equals(-3.3));
      expect( parseNum('0'), equals(0));
      expect( parseNum('1'), equals(1));
      expect( parseNum('2'), equals(2));
      expect( parseNum('5.5'), equals(5.5));
      expect( parseNum('-1'), equals(-1));
      expect( parseNum('-2'), equals(-2));
      expect( parseNum('-5.5'), equals(-5.5));

      expect( parseNumsFromList([1,2,3.3,'-5.5','11.5']), equals([1,2,3.3,-5.5,11.5]));

    });

    test('parseInt', () {

      expect( parseInt(0), equals(0));
      expect( parseInt(1), equals(1));
      expect( parseInt(-1), equals(-1));
      expect( parseInt(3), equals(3));
      expect( parseInt(3.3), equals(3));
      expect( parseInt(-3.3), equals(-3));
      expect( parseInt('0'), equals(0));
      expect( parseInt('1'), equals(1));
      expect( parseInt('2'), equals(2));
      expect( parseInt('5.5'), equals(5));
      expect( parseInt('-1'), equals(-1));
      expect( parseInt('-2'), equals(-2));
      expect( parseInt('-5.5'), equals(-5));

    });


    test('parseDouble', () {

      expect( parseDouble(0), equals(0));
      expect( parseDouble(1), equals(1));
      expect( parseDouble(-1), equals(-1));
      expect( parseDouble(3), equals(3));
      expect( parseDouble(3.3), equals(3.3));
      expect( parseDouble(-3.3), equals(-3.3));
      expect( parseDouble('0'), equals(0));
      expect( parseDouble('1'), equals(1));
      expect( parseDouble('2'), equals(2));
      expect( parseDouble('5.5'), equals(5.5));
      expect( parseDouble('-1'), equals(-1));
      expect( parseDouble('-2'), equals(-2));
      expect( parseDouble('-5.5'), equals(-5.5));

    });

    test('parsePercent', () {

      expect( parsePercent('0%'), equals(0));
      expect( parsePercent('10%'), equals(10));
      expect( parsePercent('-10%'), equals(-10));
      expect( parsePercent('0.1%'), equals(0.1));
      expect( parsePercent('-0.1%'), equals(-0.1));

      expect( parsePercent(null), equals(null));
      expect( parsePercent(double.nan), equals(null));

      expect( formatPercent(0), equals('0%'));
      expect( formatPercent(1), equals('1%'));
      expect( formatPercent(-1), equals('-1%'));
      expect( formatPercent(10), equals('10%'));
      expect( formatPercent(-10), equals('-10%'));
      expect( formatPercent(10.01), equals('10.01%'));
      expect( formatPercent(-10.01), equals('-10.01%'));
      expect( formatPercent(3.3), equals('3.3%'));

      expect( formatPercent(0.33, 2, true), equals('33%'));
      expect( formatPercent(0.333, 2, true), equals('33.30%'));
      expect( formatPercent(0.3333, 2, true), equals('33.33%'));
      expect( formatPercent(1/3, 2, true), equals('33.33%'));
      expect( formatPercent(1/3, 3, true), equals('33.333%'));
      expect( formatPercent(1/3, 4, true), equals('33.3333%'));

      expect( formatPercent(33), equals('33%'));
      expect( formatPercent(33.3), equals('33.3%'));
      expect( formatPercent(100/3), equals('33.33%'));

      expect( formatPercent(-100/3), equals('-33.33%'));

    });


    test('formatDecimal', () {

      expect( formatDecimal(0), equals('0'));
      expect( formatDecimal(1), equals('1'));
      expect( formatDecimal(-1), equals('-1'));
      expect( formatDecimal(10), equals('10'));
      expect( formatDecimal(-10), equals('-10'));
      expect( formatDecimal(10.01), equals('10.01'));
      expect( formatDecimal(-10.01), equals('-10.01'));
      expect( formatDecimal(3.3), equals('3.3'));

      expect( formatDecimal(33.0, 2), equals('33'));
      expect( formatDecimal(33.30, 2), equals('33.3'));
      expect( formatDecimal(33.33, 2), equals('33.33'));
      expect( formatDecimal(1/3, 2), equals('0.33'));
      expect( formatDecimal(1/3, 3), equals('0.333'));
      expect( formatDecimal(1/3, 4), equals('0.3333'));

      expect( formatDecimal(33), equals('33'));
      expect( formatDecimal(33.3), equals('33.3'));
      expect( formatDecimal(100/3), equals('33.33'));

      expect( formatDecimal(-100/3), equals('-33.33'));

    });

  });

  group('Data', () {

    setUp(() {
    });

    test('Base64,DataURLBase64', () {

      var text = 'Hello' ;
      var textBase64 = 'SGVsbG8=' ;

      expect( Base64.encode(text), equals(textBase64));
      expect( Base64.decode(textBase64), equals(text));

      expect( DataURLBase64.matches('data:text/plain;base64,$textBase64'), equals(true));

      expect( DataURLBase64.parse('data:text/plain;base64,$textBase64').payloadBase64, equals(textBase64));
      expect( DataURLBase64.parse('data:text/plain;base64,$textBase64').payload, equals(text));

    });

    test('MimeType', () {

      expect( MimeType.parse('text/plain').toString(), equals( MimeType.TEXT_PLAIN ));
      expect( MimeType.parse('image/jpeg').toString(), equals( MimeType.IMAGE_JPEG ));
      expect( MimeType.parse('jpeg').toString(), equals( MimeType.IMAGE_JPEG ));
      expect( MimeType.parse('image/png').toString(), equals( MimeType.IMAGE_PNG ));
      expect( MimeType.parse('png').toString(), equals( MimeType.IMAGE_PNG ));
      expect( MimeType.parse('text/html').toString(), equals( MimeType.TEXT_HTML ));
      expect( MimeType.parse('html').toString(), equals( MimeType.TEXT_HTML ));

      expect( MimeType.parse('application/json').toString(), equals( MimeType.APPLICATION_JSON ));
      expect( MimeType.parse('json').toString(), equals( MimeType.APPLICATION_JSON ));

    });

    test('dataSizeFormat()', () {

      expect( dataSizeFormat(100), equals('100 bytes'));
      expect( dataSizeFormat(1024), equals('1 KB'));
      expect( dataSizeFormat(1024*2), equals('2 KB'));

      expect( dataSizeFormat(1024*1024), equals('1 MB'));
      expect( dataSizeFormat(1024*1024*2), equals('2 MB'));
      expect( dataSizeFormat( (1024*1024*2.5).toInt() ), equals('2.5 MB'));
      expect( dataSizeFormat( (1024*1024*(2+1/3)).toInt() ), equals('2.33 MB'));

    });

  });


  group('Date', ()
  {
    setUp(() {});

    test('Base64,DataURLBase64', () {

      expect( formatTimeMillis(1), equals('1 ms'));
      expect( formatTimeMillis(123), equals('123 ms'));
      expect( formatTimeMillis(1000), equals('1 sec'));
      expect( formatTimeMillis(1500), equals('1.5 sec'));
      expect( formatTimeMillis(2000), equals('2 sec'));
      expect( formatTimeMillis(1000*60), equals('1 min'));
      expect( formatTimeMillis(1000*60*2), equals('2 min'));
      expect( formatTimeMillis( (1000*60*2.5).toInt() )  , equals('2 min 30 s'));
      expect( formatTimeMillis(1000*60*60), equals('1 h'));
      expect( formatTimeMillis( (1000*60*60*2.5).toInt() )  , equals('2 h 30 min'));
      expect( formatTimeMillis(1000*60*60*24), equals('1 d'));
      expect( formatTimeMillis(1000*60*60*24*2), equals('2 d'));
      expect( formatTimeMillis( (1000*60*60*24*2.5).toInt() )  , equals('2 d 12 h'));

    });
  });

  group('deepHashCode', ()
  {
    setUp(() {});

    test('Base64,DataURLBase64', () {

      expect( {'a': 1, 'b': 1}.hashCode == {'a': 1, 'b': 1}.hashCode , equals(false));
      expect( deepHashCode( {'a': 1, 'b': 1} ) == {'a': 1, 'b': 1}.hashCode , equals(false));
      expect( deepHashCode( {'a': 1, 'b': 1} ) == deepHashCode( {'a': 1, 'b': 1} ) , equals(true));

    });
  });


  group('RegExp', ()
  {
    setUp(() {});

    test('regExpHasMatch', () {

      expect( regExpHasMatch( r'\w\s*(,+)\s*\w',  'a,b' ) , equals(true));
      expect( regExpHasMatch( r'\w\s*(,+)\s*\w',  'a, b' ) , equals(true));
      expect( regExpHasMatch( r'\w\s*(,+)\s*\w',  'a ,b' ) , equals(true));
      expect( regExpHasMatch( r'\w\s*(,+)\s*\w',  'a , b' ) , equals(true));
      expect( regExpHasMatch( r'\w\s*(,+)\s*\w',  'a ;, b' ) , equals(false));


    });

    test('regExpReplaceAll', () {

      expect( regExpReplaceAll( r'\s*(,+)\s*',  'a ,b, c ,, d' , '\$1' ) , equals('a,b,c,,d'));
      expect( regExpReplaceAll( r'\s*(,+)\s*',  'a ,b, c ,, d' , '-\$1-' ) , equals('a-,-b-,-c-,,-d'));

      expect( regExpReplaceAll( r'\s*(,+)\s*',  'a ,b, c ,, d' , '\${1}' ) , equals('a,b,c,,d'));
      expect( regExpReplaceAll( r'\s*(,+)\s*',  'a ,b, c ,, d' , '-\${1}-' ) , equals('a-,-b-,-c-,,-d'));

    });

    test('regExpDialect', () {

      var pattern1 = regExpDialect(
        {
          's': '[ \t]' ,
          'commas': ',+' ,
        }
        ,
        r'$s*($commas)$s*'
      );

      expect( regExpReplaceAll( pattern1,  'a ,b, c ,, d' , '\$1' ) , equals('a,b,c,,d'));
      expect( regExpReplaceAll( pattern1,  'a ,b, c ,, d' , '-\$1-' ) , equals('a-,-b-,-c-,,-d'));

    });

  });


  group('Uri', ()
  {
    setUp(() {});

    test('isIPv4Address', () {

      expect( isIPv4Address('0.0.0.0') , equals(true));
      expect( isIPv4Address('192.168.0.1') , equals(true));
      expect( isIPv4Address('10.0.0.1') , equals(true));
      expect( isIPv4Address('172.123.12.1') , equals(true));

      expect( isIPv4Address('000.021.01.0') , equals(false));
      expect( isIPv4Address('123.456.789.123') , equals(false));

      expect( isIPv4Address('abc def') , equals(false));
      expect( isIPv4Address('0.0.0') , equals(false));

    });

    test('isIPv6Address', () {

      expect( isIPv6Address('::1') , equals(true));

      expect( isIPv6Address('::') , equals(true));
      expect( isIPv6Address('::/0') , equals(true));
      expect( isIPv6Address('0000:0000:0000:0000:0000:0000:0000:0000') , equals(true));

      expect( isIPv6Address('2001:db8:a0b:12f0::1') , equals(true));


      expect( isIPv6Address('0.0.0.0') , equals(false));
      expect( isIPv6Address('192.168.0.1') , equals(false));
      expect( isIPv6Address('10.0.0.1') , equals(false));
      expect( isIPv6Address('172.123.12.1') , equals(false));

      expect( isIPv6Address('000.021.01.0') , equals(false));
      expect( isIPv6Address('123.456.789.123') , equals(false));

      expect( isIPv6Address('abc def') , equals(false));
      expect( isIPv6Address('0.0.0') , equals(false));

    });


    test('UriBase', () {

      expect( getUriBase().toString() , matches(r'^file:///.+'));
      expect( getUriRoot().toString() , equals('file:///'));
      expect( getUriBaseHost() , equals(''));
      expect( getUriBasePort() , equals(0));
      expect( getUriBaseScheme() , equals('file'));
      expect( getUriBaseHostAndPort() , equals(''));
      expect( getUriBaseURL() , equals('file:///'));

      expect( isUriBaseLocalhost() , equals(true));

      expect( isLocalhost('localhost') , equals(true));
      expect( isLocalhost('127.0.0.1') , equals(true));
      expect( isLocalhost('::1') , equals(true));
      expect( isLocalhost('local') , equals(false));
      expect( isLocalhost('www.foo.com') , equals(false));
      expect( isLocalhost('0.0.0.0') , equals(false));

    });


    test('Uri', () {

      expect( buildUri('http', 'foo', 80).toString() , equals('http://foo/'));
      expect( buildUri('http', 'foo', 81).toString() , equals('http://foo:81/'));

      expect( buildUri('http', 'foo', 81, path: 'path/x' , queryString: 'query=1', fragment: 'frag1').toString() , equals('http://foo:81/path/x?query=1#frag1'));

      expect( buildUri('http', 'foo', 81, path: 'path/x' , path2: './y', queryString: 'query=1', fragment: 'frag1').toString() , equals('http://foo:81/path/y?query=1#frag1'));
      expect( buildUri('http', 'foo', 81, path: 'path/x' , path2: 'y', queryString: 'query=1', fragment: 'frag1').toString() , equals('http://foo:81/path/y?query=1#frag1'));

      expect( buildUri('http', 'foo', 81, path: 'path/x/' , path2: './y', queryString: 'query=1', fragment: 'frag1').toString() , equals('http://foo:81/path/x/y?query=1#frag1'));
      expect( buildUri('http', 'foo', 81, path: 'path/x/' , path2: 'y', queryString: 'query=1', fragment: 'frag1').toString() , equals('http://foo:81/path/x/y?query=1#frag1'));

      expect( buildUri('http', 'foo', 81, path: 'path/x' , path2: '/y', queryString: 'query=1', fragment: 'frag1').toString() , equals('http://foo:81/y?query=1#frag1'));

      expect( resolveUri('/').toString() , equals('file:///'));
      expect( resolveUri('/foo.txt').toString() , equals('file:///foo.txt'));

      expect( resolveUri('./foo.txt').toString() , matches(r'^file:///.+?/foo\.txt$'));

      expect( removeUriFragment('https://foo:81/path/x?query=1#section1').toString() , equals('https://foo:81/path/x?query=1'));
      expect( removeUriQueryString('https://foo:81/path/x?query=1#section1').toString() , equals('https://foo:81/path/x#section1'));

    });

    test('Path', () {

      expect( getPathFileName('/some/path/file-x.txt').toString() , equals('file-x.txt'));
      expect( getPathExtension('/some/path/file-x.txt').toString() , equals('txt'));

    });

  });


  group('isType', ()
  {
    setUp(() {});

    test('isInt', () {
      expect( isInt(1), equals(true));
      expect( isInt(1.0), equals(true));
      expect( isInt(123), equals(true));
      expect( isInt('1'), equals(true));
      expect( isInt('123'), equals(true));

      expect( isInt('aa'), equals(false));
      expect( isInt(''), equals(false));
      expect( isInt(1.1), equals(false));
      expect( isInt(true), equals(false));
      expect( isInt(null), equals(false));
    });

    test('isNum', () {
      expect( isNum(1), equals(true));
      expect( isNum(1.0), equals(true));
      expect( isNum(123), equals(true));
      expect( isNum('1'), equals(true));
      expect( isNum('123'), equals(true));
      expect( isNum(1.1), equals(true));

      expect( isNum('aa'), equals(false));
      expect( isNum(''), equals(false));
      expect( isNum(true), equals(false));
      expect( isNum(null), equals(false));
    });

    test('isDouble', () {
      expect( isDouble(1.0), equals(true));
      expect( isDouble(2.0), equals(true));
      expect( isDouble(2.2), equals(true));
      expect( isDouble(1.1), equals(true));
      expect( isDouble('123.1'), equals(true));

      expect( isDouble('1'), equals(false));
      expect( isDouble('123'), equals(false));
      expect( isDouble('aa'), equals(false));
      expect( isDouble(''), equals(false));
      expect( isDouble(true), equals(false));
      expect( isDouble(null), equals(false));
    });

    test('isBool', () {
      expect( isBool(true), equals(true));
      expect( isBool(false), equals(true));
      expect( isBool('true'), equals(true));
      expect( isBool('false'), equals(true));
      expect( isBool('yes'), equals(true));
      expect( isBool('no'), equals(true));

      expect( isBool(1.0), equals(false));
      expect( isBool(2.0), equals(false));
      expect( isBool(2.2), equals(false));
      expect( isBool(1.1), equals(false));
      expect( isBool('123.1'), equals(false));

      expect( isBool('1'), equals(false));
      expect( isBool('123'), equals(false));
      expect( isBool('aa'), equals(false));
      expect( isBool(''), equals(false));
      expect( isBool(null), equals(false));
    });

    test('isIntList', () {
      expect( isIntList('1'), equals(false));
      expect( isIntList('1,2'), equals(true));
      expect( isIntList('1,2,3'), equals(true));

      expect( isIntList('1'), equals(false));
      expect( isIntList('123'), equals(false));

      expect( isIntList('1 2 3'), equals(false));
      expect( isIntList('1 2 3', ' '), equals(true));

      expect( isIntList('a,a'), equals(false));
      expect( isIntList(123), equals(false));
      expect( isIntList(null), equals(false));
    });

    test('isNumList', () {
      expect( isNumList('1'), equals(false));
      expect( isNumList('1,2'), equals(true));
      expect( isNumList('1.1,2'), equals(true));
      expect( isNumList('1,2,3'), equals(true));
      expect( isNumList('1,2.2,3'), equals(true));
      expect( isNumList('1.1,2.2,3'), equals(true));

      expect( isNumList('1'), equals(false));
      expect( isNumList('1.1'), equals(false));
      expect( isNumList('123'), equals(false));
      expect( isNumList('123.4'), equals(false));

      expect( isNumList('1 2 3'), equals(false));
      expect( isNumList('1 2 3', ' '), equals(true));
      expect( isNumList('1.1 2.2 3', ' '), equals(true));

      expect( isNumList('a,a'), equals(false));
      expect( isNumList(123), equals(false));
      expect( isNumList(null), equals(false));
    });

    test('isDoubleList', () {
      expect( isDoubleList('1'), equals(false));

      expect( isDoubleList('1,2.2'), equals(false));
      expect( isDoubleList('1.1,2'), equals(false));
      expect( isDoubleList('1.1,2.2'), equals(true));

      expect( isDoubleList('1,2,3'), equals(false));
      expect( isDoubleList('1.1,2.2,3.3'), equals(true));

      expect( isDoubleList('1'), equals(false));
      expect( isDoubleList('1.1'), equals(false));
      expect( isDoubleList('123'), equals(false));
      expect( isDoubleList('123.4'), equals(false));

      expect( isDoubleList('1 2 3'), equals(false));
      expect( isDoubleList('1 2 3', ' '), equals(false));
      expect( isDoubleList('1.1 2.2 3.3', ' '), equals(true));

      expect( isDoubleList('a,a'), equals(false));
      expect( isDoubleList(123), equals(false));
      expect( isDoubleList(null), equals(false));
    });


    test('isBoolList', () {
      expect( isBoolList('true'), equals(false));

      expect( isBoolList('true,true,false'), equals(true));
      expect( isBoolList('true,yes,no'), equals(true));

      expect( isBoolList(1), equals(false));
      expect( isBoolList(123), equals(false));
      expect( isBoolList(1.2), equals(false));
      expect( isBoolList('aaa'), equals(false));
      expect( isBoolList(true), equals(false));
      expect( isBoolList(false), equals(false));
    });

    test('toFlatListOfStrings', () {
      expect( toFlatListOfStrings(null), equals([]) );
      expect( toFlatListOfStrings(''), equals([]) );
      expect( toFlatListOfStrings(' '), equals([]) );

      expect( toFlatListOfStrings('a'), equals(['a']) );
      expect( toFlatListOfStrings('a b c'), equals(['a','b','c']) );

      expect( toFlatListOfStrings( ['a b c', ['d e', ' f ','g']] ), equals(['a','b','c','d','e','f','g']) );

      expect( toFlatListOfStrings( ['a b c', ['d e', [' f '],'g']] ), equals(['a','b','c','d','e','f','g']) );

      expect( toFlatListOfStrings( ['   ', 'a b c  ', ['d e', null, '',  [' f ', 'g'], [],'h']] ), equals(['a','b','c','d','e','f','g','h']) );

      expect( toFlatListOfStrings(['a',' b ','c']), equals(['a','b','c']) );
      expect( toFlatListOfStrings(['a',' b ','c'], trim: true), equals(['a','b','c']) );
      expect( toFlatListOfStrings(['a',' b ','c'], trim: false), equals(['a','b','c']) );

      expect( toFlatListOfStrings(['a',' b ','c'], trim: null), equals(['a','b','c']) );

      expect( toFlatListOfStrings([' a ',' b ','c_d'], delimiter: '_'), equals(['a','b','c','d']) );
      expect( toFlatListOfStrings([' a ',' b ','c_d'], delimiter: '_', trim: true), equals(['a','b','c','d']) );
      expect( toFlatListOfStrings([' a ',' b ','c_d'], delimiter: '_', trim: false), equals([' a ',' b ','c','d']) );

    });


  });


  group('Date', () {
    setUp(() {});

    test('getDateTimeStartOf/EndOf', () {

      expect( getDateTimeStartOf( DateTime(2020, 03, 12, 10, 30, 59, 300) , Unit.Seconds ), equals( DateTime(2020, 03, 12, 10, 30, 59, 0) ));
      expect( getDateTimeEndOf( DateTime(2020, 03, 12, 10, 30, 59, 300) , 'sec' ), equals( DateTime(2020, 03, 12, 10, 30, 59, 999) ));

      expect( getDateTimeStartOf( DateTime(2020, 03, 12, 10, 30, 59, 300) , 'min' ), equals( DateTime(2020, 03, 12, 10, 30, 0, 0) ));
      expect( getDateTimeEndOf( DateTime(2020, 03, 12, 10, 30, 59, 300) , 'min' ), equals( DateTime(2020, 03, 12, 10, 30, 59, 999) ));

      expect( getDateTimeStartOf( DateTime(2020, 03, 12, 10, 30, 59, 300) , 'hour' ), equals( DateTime(2020, 03, 12, 10, 0, 0, 0) ));
      expect( getDateTimeEndOf( DateTime(2020, 03, 12, 10, 30, 59, 300) , 'hour' ), equals( DateTime(2020, 03, 12, 10, 59, 59, 999) ));

      expect( getDateTimeStartOf( DateTime(2020, 03, 12, 10, 30, 59, 300) , 'day' ), equals( DateTime(2020, 03, 12, 0, 0, 0, 0) ));
      expect( getDateTimeEndOf( DateTime(2020, 03, 12, 10, 30, 59, 300) , 'day' ), equals( DateTime(2020, 03, 12, 23, 59, 59, 999) ));

      expect( getDateTimeStartOf( DateTime(2020, 03, 12, 10, 30, 59, 300) , 'month' ), equals( DateTime(2020, 03, 1, 0, 0, 0, 0) ));
      expect( getDateTimeEndOf( DateTime(2020, 03, 12, 10, 30, 59, 300) , Unit.Months ), equals( DateTime(2020, 03, 31, 23, 59, 59, 999) ));

      expect( getDateTimeStartOf( DateTime(2020, 03, 12, 10, 30, 59, 300) , 'y' ), equals( DateTime(2020, 01, 1, 0, 0, 0, 0) ));
      expect( getDateTimeEndOf( DateTime(2020, 03, 12, 10, 30, 59, 300) , Unit.Years ), equals( DateTime(2020, 12, 31, 23, 59, 59, 999) ));


    });


  });


}
