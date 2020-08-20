enum EmbedPlacement {
  /// Inline embeds can be placed in a [LineNode] next to [TextNode]s or other
  /// inline [EmbedNode]s.
  inline,

  /// Line embeds are always the only child in a [LineNode].
  line
}

/// Type of an embed, used to define an embed's [key] and [placement], as
/// well as a function to parse the embed's value, [fromJson].
class EmbedType {
  final EmbedPlacement placement;
  final String key;
  final Object Function(dynamic) fromJson;
  final String Function(EmbedType, Object) _stringify;

  const EmbedType(this.placement, this.key,
      {this.fromJson = _defaultFromJson,
      String Function(EmbedType, Object) stringify = _defaultStringify})
      : _stringify = stringify;

  String stringify(Object value) => _stringify(this, value);

  static Object _defaultFromJson(dynamic json) => json;

  static String _defaultStringify(EmbedType type, Object obj) =>
      '$type.key: ${obj.toString()}';
}

class EmbedTypeMap {
  final Map<String, EmbedType> _embedMap;

  /// Function to call to create an embed for object inserts with missing keys.
  final EmbedType Function(String key) createMissing;

  const EmbedTypeMap._(this._embedMap, this.createMissing);

  factory EmbedTypeMap(List<EmbedType> embeds,
      [EmbedType Function(String key) createMissing]) {
    assert(embeds != null);
    return EmbedTypeMap._({for (var e in embeds) e.key: e},
        createMissing ?? defaultCreateMissing);
  }

  EmbedType get(String key) => _embedMap[key] ?? createMissing(key);

  static EmbedType defaultCreateMissing(String key) =>
      EmbedType(EmbedPlacement.line, key);

  static const EmbedTypeMap fallback = EmbedTypeMap._({}, defaultCreateMissing);
}
