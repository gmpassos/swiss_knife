import 'package:resource_portable/resource.dart';
import 'package:swiss_knife/src/events.dart';

/// A cache for [ResourceContent].
class ResourceContentCache {
  final Map<String, ResourceContent> _resources = {};

  int get size => _resources.length;

  bool contains(dynamic resource) {
    return get(resource) != null;
  }

  /// Returns a [ResourceContent] using [resource] as key.
  ///
  /// If the cache already have a resolved ResourceContent will
  /// prioritize it and return it.
  ///
  /// [resource] can be of type [Resource], [ResourceContent], [Uri] or Uri string.
  ResourceContent get(dynamic resource) {
    if (resource == null) return null;

    var resourceContent = ResourceContent.from(resource);

    var cacheKey = _cacheKey(resourceContent);
    if (cacheKey == null) return resourceContent;

    var cached = _resources[cacheKey];
    if (cached != null) {
      if (identical(cached, resourceContent)) return resourceContent;

      if (resourceContent.hasContent && !cached.hasContent) {
        var content = resourceContent._content;

        cached._content = content;
        cached.onLoad.add(content);
      }

      return cached;
    }

    _resources[cacheKey] = resourceContent;

    return resourceContent;
  }

  /// Remove a [ResourceContent] associated with [resource].
  /// See [get] for [resource] description.
  ResourceContent remove(dynamic resource) {
    if (resource == null) return null;

    var resourceContent = ResourceContent.from(resource);

    var cacheKey = _cacheKey(resourceContent);
    if (cacheKey == null) return resourceContent;

    var cached = _resources.remove(cacheKey);
    return cached;
  }

  String _cacheKey(ResourceContent resourceContent) {
    var uri = resourceContent.uri;
    if (uri != null) return uri.toString();

    if (resourceContent.hasContent) {
      var content = resourceContent.getContentIfLoaded();

      String init;
      String end;

      if (content.length > 6) {
        init = content.substring(0, 3);
        end = content.substring(content.length - 3);
      } else if (content.length > 4) {
        init = content.substring(0, 2);
        end = content.substring(content.length - 2);
      } else if (content.length > 2) {
        init = content.substring(0, 1);
        end = content.substring(content.length - 1);
      } else {
        init = content;
        end = '';
      }

      return '${content.hashCode}:${content.length}<$init|$end>';
    }

    return null;
  }

  /// Clears the cache.
  void clear() {
    _resources.clear();
  }
}

/// Represents a Resource Content
class ResourceContent {
  /// The resource (with [Uri]).
  final Resource resource;

  /// The resolved content/body.
  String _content;

  ResourceContent(this.resource, [this._content]) {
    if (resource == null && _content == null) {
      throw StateError('Invalid arguments: resource and content are null');
    }
  }

  /// Constructor with [Resource] from [uri].
  ///
  /// [content] in case of content/body is already resolved.
  ResourceContent.fromURI(dynamic uri, [String content])
      : this(Resource(uri), content);

  factory ResourceContent.from(dynamic rsc) {
    if (rsc is ResourceContent) return rsc;
    if (rsc is Resource) return ResourceContent(rsc);
    return ResourceContent.fromURI(rsc);
  }

  /// Reset and disposes any loaded content.
  void reset() {
    _readFuture = null;
    if (resource != null) {
      _content = null;
    }
    _loaded = false;
    _loadError = false;
  }

  Future<String> _readFuture;

  /// Notifies events when load is completed.
  EventStream<String> onLoad = EventStream();

  /// Returns the content after resolve it.
  Future<String> getContent() async {
    if (hasContent) return _content;

    if (resource == null) return null;

    _readFuture ??= resource.readAsString().then((c) {
      _onLoad(c, false);
      return c;
    }, onError: (e) {
      _onLoad(null, true);
      return null;
    });

    return _readFuture;
  }

  /// Returns the content if [isLoaded].
  String getContentIfLoaded() => isLoaded ? _content : null;

  bool _loaded = false;

  bool _loadError = false;

  void _onLoad(String content, bool loadError) {
    _content = content;
    _loaded = true;
    _loadError = loadError;
    onLoad.add(content);
  }

  /// Returns [true] if loaded.
  bool get isLoaded => _loaded;

  /// Returns [true] if loaded with error.
  bool get isLoadedWithError => _loadError;

  /// Returns [true] if has content/body.
  bool get hasContent => _content != null;

  /// The [Resource.uri].
  Uri get uri => resource.uri;

  /// Return resolved [Uri] from [Resource.uriResolved].
  Future<Uri> get uriResolved => resource.uriResolved;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ResourceContent &&
          runtimeType == other.runtimeType &&
          resource.uri == other.resource.uri;

  @override
  int get hashCode => uri.hashCode;

  @override
  String toString() {
    return 'ResourceContent{resource: ${uri}';
  }

  /// Resolves [url] using this [ResourceContent] as reference (base [Uri]).
  Future<Uri> resolveURL(String url) async {
    return resolveURLFromReference(this, url);
  }

  /// Resolves an [url] using another [ResourceContent] as [reference] (base [Uri]).
  static Future<Uri> resolveURLFromReference(
      ResourceContent reference, String url) async {
    url = url.trim();

    if (url.startsWith(RegExp(r'^[\w-]'))) {
      url = './$url';
    }

    if (url.startsWith('./')) {
      var uri = reference != null ? await reference.uriResolved : null;
      uri ??= await ResourceContent.fromURI('./').uriResolved;

      var uriPath = Uri.decodeComponent(uri.path) + '/';

      var uriPathParts = uriPath.split('/');
      if (uriPath.endsWith('/')) uriPathParts.removeLast();

      var resolvedPath;
      if (uriPathParts.isNotEmpty) {
        uriPathParts.removeLast();
        uriPathParts.add(url.substring(2));
        resolvedPath = uriPathParts.join('/');
      } else {
        resolvedPath = url.substring(2);
      }

      return Uri(
          scheme: uri.scheme,
          userInfo: uri.userInfo,
          host: uri.host,
          port: uri.port,
          path: resolvedPath);
    } else if (url.startsWith('/')) {
      var uri = reference != null ? await reference.uriResolved : null;
      uri ??= await ResourceContent.fromURI('./').uriResolved;

      return Uri(
          scheme: uri.scheme,
          userInfo: uri.userInfo,
          host: uri.host,
          port: uri.port,
          path: url);
    }

    return Uri.parse(url);
  }
}
