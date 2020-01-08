
class Math {

  static num min(num a, num b) => a < b ? a : b ;
  static num max(num a, num b) => a > b ? a : b ;

}

int parseInt(dynamic v, [int def]) {
  if (v == null) return def ;

  if (v is int) return v ;
  if (v is num) return v.toInt() ;

  String s ;
  if (v is String) {
    s = v ;
  }
  else {
    s = v.toString() ;
  }

  s = s.trim() ;

  if (s.isEmpty) return def ;

  return int.parse(s) ;
}

double parseDouble(dynamic v, [double def]) {
  if (v == null) return def ;

  if (v is double) return v ;
  if (v is num) return v.toDouble();

  String s ;
  if (v is String) {
    s = v ;
  }
  else {
    s = v.toString() ;
  }

  s = s.trim() ;

  if (s.isEmpty) return def ;

  return double.parse(s) ;
}
