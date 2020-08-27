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
      '${type.key}: ${obj.toString()}';
}

class NotusEmbedRegistry {
  final Map<String, EmbedType> _registry;

  /// Function to call to create an embed for object inserts with missing keys.
  final EmbedType Function(String key, Object value) createMissing;

  const NotusEmbedRegistry._(this._registry, this.createMissing);

  factory NotusEmbedRegistry(List<EmbedType> embeds,
      [EmbedType Function(String key) createMissing]) {
    assert(embeds != null);
    return NotusEmbedRegistry._({for (var e in embeds) e.key: e},
        createMissing ?? defaultCreateMissing);
  }

  EmbedType get(String key, Object value) =>
      _registry[key] ?? createMissing(key, value);

  static EmbedType defaultCreateMissing(String key, Object value) =>
      EmbedType(EmbedPlacement.line, key);

  static const NotusEmbedRegistry fallback = NotusEmbedRegistry._(
      {'hr': NotusEmbeds.hrEmbed, 'image': NotusEmbeds.imageEmbed},
      defaultCreateMissing);
}

class NotusEmbeds {
  static String _stringifyHr(EmbedType t, Object o) => 'hr';
  static const EmbedType hrEmbed =
      EmbedType(EmbedPlacement.line, 'hr', stringify: _stringifyHr);
  static const EmbedType imageEmbed = EmbedType(EmbedPlacement.line, 'image');
}
