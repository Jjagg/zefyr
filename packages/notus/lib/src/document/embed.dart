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
  final String Function(Object) stringify;

  const EmbedType(this.placement, this.key,
      {this.fromJson = _defaultFromJson, this.stringify = _defaultStringify});

  static Object _defaultFromJson(dynamic json) => json;

  static String _defaultStringify(Object obj) => obj.toString();
}
