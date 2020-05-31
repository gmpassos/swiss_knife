import 'events.dart';

typedef LoaderFunction = Future<bool> Function();

/// Controls a load process.
class LoadController {
  static int _idCounter = 0;

  static String _newID() => (++_idCounter).toString();

  /// Global ID of this loader.
  String id = (++_idCounter).toString();

  LoaderFunction _loader;

  final EventStream<LoadController> onLoad = EventStream();

  LoadController([String id]) {
    this.id = id ?? _newID();
  }

  LoadController.function(this._loader, [String id]) {
    if (_loader == null) throw ArgumentError('Null LoaderFunction');
    this.id = id ?? _newID();
  }

  /// The actual loading function that is handled by this [LoadController].
  LoaderFunction get loader => _loader;

  set loader(LoaderFunction value) {
    _loader = value;
  }

  Future<bool> _loadFuture;

  bool _loaded = false;

  /// Returns [true] if is loaded.
  bool get isLoaded => _loaded;

  /// Returns [false] if is not loaded.
  bool get isNotLoaded => !isLoaded;

  /// Returns [true] if is loaded and successful.
  bool _loadSuccessful;

  bool get loadSuccessful => _loadSuccessful;

  /// Does the load process.
  ///
  /// [loader] the function to use in the load process. If already set by the constructor will throws [StateError].
  Future<bool> load([LoaderFunction loader]) async {
    if (_loadFuture != null) return _loadFuture;

    if (loader != null) {
      if (_loader != null) {
        throw StateError(
            "LoadController[$id] already have a LoaderFunction: can't pass another as parameter.");
      }
      _loader = loader;
    }

    if (_loader == null) {
      throw ArgumentError(
          'LoadController[$id] without LoaderFunction: required as parameter when calling load().');
    }

    _loadFuture = _loader();
    _loadSuccessful = await _loadFuture;

    _loaded = true;

    onLoad.add(this);

    print(this);

    return _loadSuccessful;
  }

  @override
  String toString() {
    return 'LoadController{id: $id, loaded: $_loaded, loadSuccessful: $_loadSuccessful}';
  }
}
