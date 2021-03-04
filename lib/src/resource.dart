import 'package:resource_portable/resource.dart';
import 'package:swiss_knife/src/events.dart';
import 'package:swiss_knife/src/uri.dart';
import 'package:swiss_knife/swiss_knife.dart';

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
  factory ResourceContent.fromURI(dynamic uri, [String content]) {
    if (uri == null && content == null) return null;

    if (uri is Uri) {
      return ResourceContent(Resource(uri), content);
    } else if (uri is String) {
      return ResourceContent(Resource(uri), content);
    } else if (uri is ResourceContent) {
      return ResourceContent(Resource(uri.uri), content);
    } else {
      var url = uri.toString();
      return ResourceContent(Resource(url), content);
    }
  }

  factory ResourceContent.from(dynamic rsc) {
    if (rsc is ResourceContent) return rsc;
    if (rsc is Resource) return ResourceContent(rsc);
    return ResourceContent.fromURI(rsc);
  }

  /// Resolved [url] before instantiate [fromURI].
  factory ResourceContent.fromResolvedUrl(String url,
      {String baseURL, String content}) {
    if (url == null) {
      if (content != null) return ResourceContent(null, content);
      return null;
    }

    var resolvedURL = resolveUri(url, baseURL: baseURL);
    if (resolvedURL == null && content == null) return null;

    return ResourceContent.fromURI(resolvedURL, content);
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

  /// Triggers content load.
  void load() {
    getContent();
  }

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

  /// Returns [uri] file extension.
  String get uriFileExtension {
    var uri = this.uri;
    if (uri == null) return null;
    return getPathExtension(uri.toString());
  }

  /// Returns a [MimeType] based into the [uri] file name extension.
  MimeType get uriMimeType {
    var uri = this.uri;
    if (uri == null) return null;
    return MimeType.byExtension(uri.toString());
  }

  /// Return resolved [Uri] from [Resource.uriResolved].
  Future<Uri> get uriResolved => resource.uriResolved;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ResourceContent &&
          runtimeType == other.runtimeType &&
          resource.uri == other.resource.uri;

  @override
  int get hashCode => uri?.hashCode ?? 0;

  @override
  String toString() {
    return 'ResourceContent{resource: $uri}';
  }

  /// Resolves [url] using this [ResourceContent] as reference (base [Uri]).
  Future<Uri> resolveURL(String url) async {
    return resolveURLFromReference(this, url);
  }

  static final RegExp PATTERN_URL_INIT = RegExp(r'\w+://');

  /// Resolves an [url] using another [ResourceContent] as [reference] (base [Uri]).
  static Future<Uri> resolveURLFromReference(
      ResourceContent reference, String url) async {
    if (url == null) return null;
    url = url.trim();

    if (url.startsWith(PATTERN_URL_INIT)) {
      return Uri.parse(url);
    }

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

/// Wraps a resource and the related context.
class ContextualResource<T, C extends Comparable<C>>
    implements Comparable<ContextualResource<T, C>> {
  /// The resource associated with [context].
  final T resource;

  /// The contexts, that implements [Comparable].
  final C context;

  static S _resolveContext<T, S>(T resource, dynamic context) {
    if (context == null) return null;

    if (context is S) {
      return context;
    } else if (context is Function) {
      var v = context(resource);
      return _resolveContext(resource, v);
    }

    throw StateError("Can't resolve resource ($resource) context: $context");
  }

  ContextualResource(T resource, dynamic context)
      : resource = resource,
        context = _resolveContext<T, C>(resource, context);

  static List<ContextualResource<T, C>> toList<T, C extends Comparable<C>>(
          Iterable<T> resources, C Function(T resource) context) =>
      resources.map((r) => ContextualResource<T, C>(r, context)).toList();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ContextualResource &&
          runtimeType == other.runtimeType &&
          resource == other.resource &&
          context == other.context;

  @override
  int get hashCode => resource.hashCode ^ context.hashCode;

  @override
  int compareTo(ContextualResource<T, C> other) =>
      context.compareTo(other.context);

  int compareContext(C context) => this.context.compareTo(context);

  @override
  String toString() =>
      'ContextualResource{resource: $resource, context: $context}';
}

/// Resolves a resource based into a context, like screen dimension or OS.
class ContextualResourceResolver<T, C extends Comparable<C>> {
  /// The context comparator, to overwrite default comparator of [C].
  final Comparator<C> contextComparator;

  ContextualResourceResolver(
      {Map<String, dynamic> resources,
      this.contextComparator,
      this.defaultContext,
      this.defaultResource}) {
    if (resources != null) {
      for (var entry in resources.entries) {
        var k = entry.key;
        var v = entry.value;

        if (v is ContextualResource) {
          add(k, [v]);
        } else if (v is Iterable) {
          add(k, v);
        } else if (v is Function) {}
      }
    }
  }

  final Map<String, Set<ContextualResource<T, C>>> _resources = {};
  final Map<String, List<ContextualResource<T, C>>> _resourcesSorted = {};

  /// The resources keys.
  List<String> get keys => _resources.keys.toList();

  /// Clears all resources.
  void clear() {
    _resources.clear();
    _resourcesSorted.clear();
  }

  /// Adds a resources with a dynamic [value].
  void addDynamic(String key, dynamic value,
      [ContextualResource<T, C> Function(dynamic value) mapper]) {
    if (value is ContextualResource) {
      add(key, [value]);
    } else if (value is Iterable) {
      for (var e in value) {
        addDynamic(key, e);
      }
    } else if (value is Function) {
      var v = value(key);
      addDynamic(key, v);
    }
  }

  /// Adds a resource.
  void add(String key, Iterable<ContextualResource<T, C>> options) {
    if (isEmptyObject(options)) return;

    var entries =
        _resources.putIfAbsent(key, () => <ContextualResource<T, C>>{});

    var size = entries.length;
    entries.addAll(options);

    if (entries.length != size) {
      _resourcesSorted.remove(key);
    }
  }

  /// The default resource to return when is not possible to resolve one.
  ContextualResource<T, C> defaultResource;

  /// The default context to be used when resolve is called without one.
  C defaultContext;

  /// Resolves a resource.
  T resolve(String key, [C context]) {
    var options = _resources[key];
    if (isEmptyObject(options)) return defaultResource?.resource;

    context ??= defaultContext;
    if (context == null) {
      return (defaultResource ?? options.first)?.resource;
    }

    var sortedOptions = _resourcesSorted.putIfAbsent(key, () {
      var list = options.toList();
      list.sort();
      return list;
    });

    return _getResource(sortedOptions, context)?.resource;
  }

  ContextualResource<T, C> _getResource(
      List<ContextualResource<T, C>> options, C context) {
    var low = 0;
    var high = options.length - 1;

    var comparator = contextComparator;

    while (low <= high) {
      var mid = (low + high) ~/ 2;
      var midVal = options[mid];

      var cmp = comparator != null
          ? comparator(midVal.context, context)
          : midVal.compareContext(context);

      if (cmp < 0) {
        low = mid + 1;
      } else if (cmp > 0) {
        high = mid - 1;
      } else {
        return midVal;
      } // key found
    }

    return options[low];
  }

  /// Returns a resolved resource using [defaultContext].
  T operator [](String key) => resolve(key);

  @override
  String toString() {
    return 'ScalableResourceResolver{resources: $_resources}';
  }
}
