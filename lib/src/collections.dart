

bool isEquivalentList(List l1, List l2, [bool sort = false]) {
  if (l1 == l2) return true ;

  if (l1 == null) return false ;
  if (l2 == null) return false ;

  var length = l1.length;
  if ( length != l2.length ) return false ;

  if (sort) {
    l1.sort();
    l2.sort();
  }

  for (var i = 0; i < l1.length; ++i) {
    var v1 = l1[i];
    var v2 = l2[i];
    if (v1 != v2) return false ;
  }

  return true ;
}

bool isEquivalentIterator(Iterable it1, Iterable it2) {
  if (it1 == it2) return true ;

  if (it1 == null) return false ;
  if (it2 == null) return false ;

  var length = it1.length;
  if (length != it2.length) return false ;

  for (int i = 0 ; i < length; i++) {
    var elem1 = it1.elementAt(i) ;
    var elem2 = it2.elementAt(i) ;

    if ( elem1 != elem2 ) return false ;
  }

  return true ;
}

bool isEquivalentMap(Map m1, Map m2) {
  if (m1 == m2) return true ;

  if (m1 == null) return false ;
  if (m2 == null) return false ;

  if (m1.length != m2.length) return false ;

  var k1 = new List.from(m1.keys);
  var k2 = new List.from(m2.keys);

  if ( !isEquivalentList(k1,k2,true) ) return false ;

  for (var k in k1) {
    var v1 = m1[k];
    var v2 = m2[k];

    if ( v1 != v2 ) return false ;
  }

  return true ;
}

void addAllToList(List l, dynamic v) {
  if (v == null) return ;

  if (v is List) {
    l.addAll(v);
  }
  else {
    l.add(v);
  }
}

List joinLists(List l1, [List l2, List l3, List l4, List l5, List l6, List l7, List l8, List l9]) {
  List l = [] ;

  if (l1 != null) l.addAll(l1) ;
  if (l2 != null) l.addAll(l2) ;
  if (l3 != null) l.addAll(l3) ;
  if (l4 != null) l.addAll(l4) ;
  if (l5 != null) l.addAll(l5) ;
  if (l6 != null) l.addAll(l6) ;
  if (l7 != null) l.addAll(l7) ;
  if (l8 != null) l.addAll(l8) ;
  if (l9 != null) l.addAll(l9) ;

  return l ;
}

List copyList(List l) {
  if (l == null) return null ;
  return new List.from(l);
}

List<String> copyListString(List<String> l) {
  if (l == null) return null ;
  return new List<String>.from(l);
}

Map copyMap(Map m) {
  if (m == null) return null ;
  return new Map.from(m);
}

Map<String,String> copyMapString(Map<String,String> m) {
  if (m == null) return null ;
  return new Map<String,String>.from(m);
}

MapEntry<String,V> getEntryIgnoreCase<V>(Map<String,V> map, String key) {
  var val = map[key] ;
  if (val != null) return MapEntry(key, val) ;

  if (key == null) return null ;

  var keyLC = key.toLowerCase() ;

  for (var k in map.keys) {
    if ( k.toLowerCase() == keyLC ) {
      var value = map[k];
      return MapEntry<String,V>( k , value ) ;
    }
  }

  return null ;
}

V getIgnoreCase<V>(Map<String,V> map, String key) {
  var entry = getEntryIgnoreCase(map, key) ;
  return entry != null ? entry.value : null ;
}

V putIgnoreCase<V>(Map<String,V> map, String key, V value) {
  var entry = getEntryIgnoreCase(map, key) ;
  if (entry != null) {
    map[ entry.key ] = value ;
    return entry.value ;
  }
  else {
    map[ key ] = value ;
    return null ;
  }
}

Map asMap(dynamic o) {
  if (o == null) return null ;
  if (o is Map) return o ;

  Map m = {} ;

  if (o is List) {
    int sz = o.length ;

    for (int i = 0 ; i < sz ; i+=2) {
      dynamic key = o[i] ;
      dynamic val = o[i+1] ;
      m[key] = val ;
    }
  }
  else {
    throw new StateError("Can't handle type: "+ o) ;
  }

  return m ;
}

List<Map> asListOfMap( dynamic o ) {
  if (o == null) return null ;
  List<dynamic> l = o as List<dynamic> ;
  return l.map( (e) => asMap(e) ).toList() ;
}

bool isListOfStrings(List list) {
  if (list == null || list.isEmpty) return false ;

  for (var value in list) {
    if ( !(value is String) ) return false ;
  }

  return true ;
}

List<String> asListOfString( dynamic o ) {
  if (o == null) return null ;
  List<dynamic> l = o as List<dynamic> ;
  return l.map( (e) => e.toString() ).toList() ;
}

MapEntry<K,V> findKeyEntry<K,V>(Map<K,V> map, List<K> keys, [bool ignoreCase]) {
  if (map == null || keys == null) return null ;

  ignoreCase ??= false ;

  if (ignoreCase) {
    for (var key in keys) {
      if ( map.containsKey(key) ) return MapEntry(key, map[key]) ;

      String keyLC = key.toString().toLowerCase() ;

      for (var k in map.keys) {
        if ( k.toString().toLowerCase() == keyLC ) {
          var value = map[k];
          return MapEntry<K,V>( k , value ) ;
        }
      }
    }
  }
  else {
    for (var key in keys) {
      if ( map.containsKey(key) ) return MapEntry(key, map[key]) ;
    }
  }

  return null ;
}

V findKeyValue<K,V>(Map<K,V> map, List<K> keys, [bool ignoreCase]) {
  var entry = findKeyEntry(map, keys, ignoreCase) ;
  return entry != null ? entry.value : null ;
}

K findKeyName<K,V>(Map<K,V> map, List<K> keys, [bool ignoreCase]) {
  var entry = findKeyEntry(map, keys, ignoreCase) ;
  return entry != null ? entry.key : null ;
}
