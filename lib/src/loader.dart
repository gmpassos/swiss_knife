import 'events.dart';

typedef LoaderFunction = Future<bool> Function();

/// Controls a load process.
class LoadController {
  static int _idCounter = 0;

  static String _newID() => (++_idCounter).toString();

  /// Global ID of this loader.
  String id = (++_idCounter).toString();

  /// The actual loading function that is handled by this [LoadController].
  LoaderFunction loader;

  final EventStream<LoadController> onLoad = EventStream();

  LoadController([String id]) {
    this.id = id ?? _newID();
  }

  LoadController.function(this.loader, [String id]) {
    if (loader == null) throw ArgumentError('Null LoaderFunction');
    this.id = id ?? _newID();
  }

  Future<bool> _loadFuture;

  bool _loaded = false;

  /// Returns [true] if is loaded.
  bool get isLoaded => _loaded;

  /// Returns [false] if is not loaded.
  bool get isNotLoaded => !isLoaded;

  /// Returns [true] if is loaded and successful.
  bool _loadSuccessful;

  /// Returns [true] if load was successful.
  ///
  /// If load is not completed yet will return null.
  bool get loadSuccessful => _loadSuccessful;

  /// Does the load process.
  ///
  /// - [actualLoader]: the function to use in the load process.
  /// Will throw a [StateError] if [loader] is already set by the constructor.
  Future<bool> load([LoaderFunction actualLoader]) async {
    if (_loadFuture != null) return _loadFuture;

    if (actualLoader != null) {
      if (loader != null) {
        throw StateError(
            "LoadController[$id] already have a LoaderFunction: can't pass another as parameter.");
      }
      loader = actualLoader;
    }

    if (loader == null) {
      throw ArgumentError(
          'LoadController[$id] without LoaderFunction: required as parameter when calling load().');
    }

    _loadFuture = loader();
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
