
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

      expect( MimeType.asMimeType('text/plain'), equals( MimeType.TEXT_PLAIN ));
      expect( MimeType.asMimeType('image/jpeg'), equals( MimeType.IMAGE_JPEG ));
      expect( MimeType.asMimeType('jpeg'), equals( MimeType.IMAGE_JPEG ));
      expect( MimeType.asMimeType('image/png'), equals( MimeType.IMAGE_PNG ));
      expect( MimeType.asMimeType('png'), equals( MimeType.IMAGE_PNG ));
      expect( MimeType.asMimeType('text/html'), equals( MimeType.TEXT_HTML ));
      expect( MimeType.asMimeType('html'), equals( MimeType.TEXT_HTML ));

      expect( MimeType.asMimeType('application/json'), equals( MimeType.APPLICATION_JSON ));
      expect( MimeType.asMimeType('json'), equals( MimeType.APPLICATION_JSON ));

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
      expect( formatTimeMillis( (1000*60*2.5).toInt() )  , equals('2.5 min'));
      expect( formatTimeMillis(1000*60*60), equals('1 hr'));
      expect( formatTimeMillis( (1000*60*60*2.5).toInt() )  , equals('2.5 hr'));
      expect( formatTimeMillis(1000*60*60*24), equals('1 day'));
      expect( formatTimeMillis(1000*60*60*24*2), equals('2 days'));
      expect( formatTimeMillis( (1000*60*60*24*2.5).toInt() )  , equals('2.5 days'));

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

      var pattern1 = regExpDialect({
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

  }
