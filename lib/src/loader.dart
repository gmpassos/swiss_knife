
import 'events.dart' ;

typedef LoaderFunction = Future<bool> Function() ;

class LoadController {

  static int idCounter = 0 ;
  static String _newID() => (++idCounter).toString() ;


  String id = (++idCounter).toString() ;
  LoaderFunction _loader ;

  final EventStream<LoadController> onLoad = EventStream() ;

  LoadController([String id]) {
    this.id = id ??_newID() ;
  }

  LoadController.function(this._loader, [String id]) {
    if (_loader == null) throw ArgumentError('Null LoaderFunction');
    this.id = id ??_newID() ;
  }

  LoaderFunction get loader => _loader;

  set loader(LoaderFunction value) {
    _loader = value;
  }
  Future<bool> _loadFuture ;
  bool _loaded = false ;

  bool get isLoaded => _loaded ;

  bool get isNotLoaded => !isLoaded ;

  bool _loadSuccessful ;
  bool get loadSuccessful => _loadSuccessful;

  Future<bool> load( [ LoaderFunction loader ] ) async {
    if (_loadFuture != null) return _loadFuture ;

    if ( loader != null ) {
      if ( _loader != null ) throw StateError("LoadController[$id] already have a LoaderFunction: can't passa another as parameter.") ;
      _loader = loader ;
    }

    if ( _loader == null ) throw ArgumentError('LoadController[$id] without LoaderFunction: required as parameter when calling load().');

    _loadFuture = _loader();
    _loadSuccessful = await _loadFuture ;

    _loaded = true ;

    onLoad.add(this) ;

    print( this );

    return _loadSuccessful ;
  }

  @override
  String toString() {
    return 'LoadController{id: $id, loaded: $_loaded, loadSuccessful: $_loadSuccessful}';
  }

}


