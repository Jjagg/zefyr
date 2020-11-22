// Copyright (c) 2018, the Zefyr project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'package:collection/collection.dart';
import 'package:quiver_hashcode/hashcode.dart';

/// Scope of a style attribute, defines context in which an attribute can be
/// applied.
enum NotusAttributeScope {
  /// Inline-scoped attributes are applicable to all characters within a line.
  ///
  /// Inline attributes cannot be applied to the line itself.
  inline,

  /// Line-scoped attributes are only applicable to a line of text as a whole.
  ///
  /// Line attributes do not have any effect on any character within the line.
  /// Only one line attribute may be applied to a line at any time.
  line,
}

/// Interface for objects which provide access to an attribute key.
///
/// Implemented by [NotusAttribute] and [NotusAttributeBuilder].
abstract class NotusAttributeKey {
  /// Unique key of this attribute.
  String get key;
}

abstract class NotusAttributeBase<T> implements NotusAttributeKey {
  @override
  final String key;

  /// Scope of this attribute.
  final NotusAttributeScope scope;

  /// Returns `true` if this is a line-scoped attribute.
  bool get isLineScoped => scope == NotusAttributeScope.line;

  /// Returns `true` if this is an inline-scoped attribute.
  bool get isInlineScoped => scope == NotusAttributeScope.inline;

  const NotusAttributeBase(this.key, this.scope);

  NotusAttribute<T> get unset => NotusAttribute<T>(key, scope, null);
  NotusAttribute<T> withValue(T value) => NotusAttribute<T>(key, scope, value);
}

/// Style attribute applicable to a segment of a Notus document.
///
/// All supported attributes are available via static fields on this class.
/// Here is an example of applying styles to a document:
///
///     void makeItPretty(Notus document) {
///       // Format 5 characters at position 0 as bold
///       document.format(0, 5, NotusAttribute.bold);
///       // Similarly for italic
///       document.format(0, 5, NotusAttribute.italic);
///       // Format first line as a heading (h1)
///       // Note that there is no need to specify character range of the whole
///       // line. Simply set index position to anywhere within the line and
///       // length to 0.
///       document.format(0, 0, NotusAttribute.h1);
///     }
///
/// List of supported attributes:
///
///   * [NotusAttribute.bold]
///   * [NotusAttribute.italic]
///   * [NotusAttribute.link]
///   * [NotusAttribute.heading]
class NotusAttribute<T> extends NotusAttributeBase<T> {
  // Inline attributes

  /// Bold style attribute.
  static const bold = NotusAttribute('bold', NotusAttributeScope.inline, true);

  /// Italic style attribute.
  static const italic =
      NotusAttribute('italic', NotusAttributeScope.inline, true);

  /// Link style attribute.
  // ignore: const_eval_throws_exception
  static const link = LinkAttributeBuilder._();

  // Line attributes

  /// Heading style attribute.
  // ignore: const_eval_throws_exception
  static const heading = HeadingAttributeBuilder._();

  /// Level 1 heading, equivalent of `H1` in HTML.
  static const h1 = NotusAttribute('header', NotusAttributeScope.line, 1);

  /// Level 2 heading, equivalent of `H2` in HTML.
  static const h2 = NotusAttribute('header', NotusAttributeScope.line, 2);

  /// Level 3 heading, equivalent of `H3` in HTML.
  static const h3 = NotusAttribute('header', NotusAttributeScope.line, 3);

  /// Formats a block of lines as a bullet list.
  static const ul = NotusAttribute('list', NotusAttributeScope.line, 'bullet');

  /// Formats a block of lines as a number list.
  static const ol = NotusAttribute('list', NotusAttributeScope.line, 'ordered');

  /// Formats a block of lines as a quote.
  static const bq =
      NotusAttribute('blockquote', NotusAttributeScope.line, true);

  /// Formats a block of lines as a code snippet, using monospace font.
  static const code =
      NotusAttribute('code-block', NotusAttributeScope.line, true);

  const NotusAttribute(String key, NotusAttributeScope scope, this.value)
      : super(key, scope);

  /// Value of this attribute.
  ///
  /// If value is `null` then this attribute represents a transient action
  /// of removing associated style and is never persisted in a resulting
  /// document.
  ///
  /// See also [unset], [NotusStyle.merge] and [NotusStyle.put]
  /// for details.
  final T value;

  /// Returns special "unset" version of this attribute.
  ///
  /// Unset attribute's [value] is always `null`.
  ///
  /// When composed into a rich text document, unset attributes remove
  /// associated style.
  NotusAttribute<T> get unset => NotusAttribute<T>(key, scope, null);

  /// Returns `true` if this attribute is an unset attribute.
  bool get isUnset => value == null;

  /// Returns `true` if this attribute is not an unset attribute.
  bool get isSet => !isUnset;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! NotusAttribute) return false;
    NotusAttribute typedOther = other;
    return key == typedOther.key &&
        scope == typedOther.scope &&
        value == typedOther.value;
  }

  @override
  int get hashCode => hash3(key, scope, value);

  @override
  String toString() => '$key: $value';

  /// Returns map with key-value mapping of this attribute.
  Map<String, dynamic> toMap() => <String, dynamic>{key: value};
}

class NotusAttributeRegistry {
  final Map<String, NotusAttributeBase> _registry;

  final NotusAttributeBase Function(String key, dynamic value) createMissing;

  NotusAttributeRegistry._(this._registry, this.createMissing);

  factory NotusAttributeRegistry(List<NotusAttributeBase> attributes,
      [NotusAttributeBase Function(String key, dynamic value) createMissing]) {
    assert(attributes != null);
    return NotusAttributeRegistry._({for (var a in attributes) a.key: a},
        createMissing ?? defaultCreateMissing);
  }

  bool contains(String key) => _registry.containsKey(key);
  bool isLineScoped(String key) => _registry[key]?.isLineScoped ?? false;

  NotusAttributeBase get(String key, dynamic value) =>
      _registry[key] ?? createMissing(key, value);

  NotusAttribute _fromKeyValue(String key, dynamic value) {
    var attr = _registry[key];
    attr ??= createMissing(key, value);
    return attr.withValue(value);
  }

  static NotusAttribute defaultCreateMissing(String key, dynamic value) {
    throw ArgumentError.value(key, 'No attribute with key "$key" registered.');
  }

  static final NotusAttributeRegistry fallback =
      NotusAttributeRegistry(_defaultAttributes);

  static const List<NotusAttributeBase> _defaultAttributes = [
    NotusAttribute.bold,
    NotusAttribute.italic,
    NotusAttribute.link,
    NotusAttribute.heading,
    NotusAttribute.ul,
    NotusAttribute.ol,
    NotusAttribute.bq,
    NotusAttribute.code
  ];

  static List<NotusAttributeBase> get defaultAttributes =>
      List.of(_defaultAttributes);
}

/// Collection of style attributes.
class NotusStyle {
  NotusStyle._(this._attributes);

  final Map<String, NotusAttribute> _attributes;

  NotusStyle() : _attributes = {};

  factory NotusStyle.fromRawAttributes(
      Map<String, dynamic> data, NotusAttributeRegistry registry) {
    if (data == null || data.isEmpty) return NotusStyle();

    final result = data.map((String key, dynamic value) {
      var attr = registry._fromKeyValue(key, value);
      return MapEntry<String, NotusAttribute>(key, attr);
    });
    return NotusStyle._(result);
  }

  factory NotusStyle.fromAttribute(NotusAttribute attribute) =>
      NotusStyle._({attribute.key: attribute});

  factory NotusStyle.fromAttributes(Iterable<NotusAttribute> attributes) =>
      NotusStyle._({for (final a in attributes) a.key: a});

  /// Get an [UnmodifiableMapView] with the attributes applied to this style.
  Map<String, NotusAttribute> get attributes =>
      UnmodifiableMapView(_attributes);

  /// Returns `true` if this attribute set is empty.
  bool get isEmpty => _attributes.isEmpty;

  /// Returns `true` if this attribute set is note empty.
  bool get isNotEmpty => _attributes.isNotEmpty;

  /// Returns `true` if this style is not empty and contains only inline-scoped
  /// attributes.
  bool get isInline =>
      isNotEmpty && values.every((item) => item.isInlineScoped);

  /// Checks that this style has only one attribute, and returns that attribute.
  NotusAttribute get single => _attributes.values.single;

  /// Returns `true` if attribute with [key] is present in this set.
  ///
  /// Only checks for presence of specified [key] regardless of the associated
  /// value.
  ///
  /// To test if this set contains an attribute with specific value consider
  /// using [containsSame].
  bool contains(NotusAttributeKey key) => _attributes.containsKey(key.key);

  /// Returns `true` if this set contains attribute with the same value as
  /// [attribute].
  bool containsSame(NotusAttribute attribute) {
    assert(attribute != null);
    return get<dynamic>(attribute) == attribute;
  }

  bool hasLineStyle() => _attributes.values.any((a) => a.isLineScoped);

  NotusAttribute get lineStyle => _attributes.values
      .firstWhere((a) => a.isLineScoped && a.value != null, orElse: () => null);

  NotusStyle unsetLineStyle() {
    final ls = lineStyle;
    if (ls != null) return merge(ls.unset);
    return this;
  }

  /// Returns value of specified attribute [key] in this set.
  T value<T>(NotusAttributeKey key) => get(key).value;

  /// Returns [NotusAttribute] from this set by specified [key] or null if [key] is not set.
  NotusAttribute<T> get<T>(NotusAttributeKey key) =>
      _attributes[key.key] as NotusAttribute<T>;

  /// Returns collection of all attribute keys in this set.
  Iterable<String> get keys => _attributes.keys;

  /// Returns collection of all attributes in this set.
  Iterable<NotusAttribute> get values => _attributes.values;

  /// Puts [attribute] into this attribute set and returns result as a new set.
  NotusStyle put(NotusAttribute attribute) {
    final result = Map<String, NotusAttribute>.from(_attributes);

    if (attribute.isLineScoped && attribute.isSet) {
      result.removeWhere((key, value) => value.isLineScoped);
    }

    result[attribute.key] = attribute;
    return NotusStyle._(result);
  }

  /// Merges this attribute set with [attribute] and returns result as a new
  /// attribute set.
  ///
  /// Performs compaction if [attribute] is an "unset" value, e.g. removes
  /// corresponding attribute from this set completely.
  ///
  /// See also [put] method which does not perform compaction and allows
  /// constructing styles with "unset" values.
  NotusStyle merge(NotusAttribute attribute) {
    final merged = Map<String, NotusAttribute>.from(_attributes);
    _mergeRaw(merged, attribute);
    return NotusStyle._(merged);
  }

  /// Merges all attributes from [other] into this style and returns result
  /// as a new instance of [NotusStyle].
  NotusStyle mergeAll(NotusStyle other) {
    final merged = Map<String, NotusAttribute>.from(_attributes);
    for (var value in other.values) {
      _mergeRaw(merged, value);
    }
    return NotusStyle._(merged);
  }

  static void _mergeRaw(
      Map<String, NotusAttribute> map, NotusAttribute attribute) {
    if (attribute.isUnset) {
      map.remove(attribute.key);
    } else {
      if (attribute.isLineScoped) {
        map.removeWhere((key, value) => value.isLineScoped);
      }

      map[attribute.key] = attribute;
    }
  }

  /// Removes [attributes] from this style and returns new instance of
  /// [NotusStyle] containing result.
  NotusStyle removeAll(Iterable<NotusAttribute> attributes) {
    final merged = Map<String, NotusAttribute>.from(_attributes);
    attributes.map((item) => item.key).forEach(merged.remove);
    return NotusStyle._(merged);
  }

  // TODO toMap for NotusStyle is abused
  // It's used to create deltas:
  // e.g. Delta()..insert(_value, style.toMap());
  // The Op ctor copies the map, which is wasteful.

  /// Returns key-value map of attributes in this style.
  Map<String, dynamic> toMap() => _attributes.isEmpty
      ? null
      : _attributes.map((key, attr) => MapEntry(key, attr.value));

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! NotusStyle) return false;
    NotusStyle typedOther = other;
    final eq = const MapEquality<String, NotusAttribute>();
    return eq.equals(_attributes, typedOther._attributes);
  }

  @override
  int get hashCode {
    final hashes =
        _attributes.entries.map((entry) => hash2(entry.key, entry.value));
    return hashObjects(hashes);
  }

  @override
  String toString() => "{${_attributes.values.join(', ')}}";
}

/// Builder for link attribute values.
///
/// There is no need to use this class directly, consider using
/// [NotusAttribute.link] instead.
class LinkAttributeBuilder extends NotusAttributeBase<String> {
  static const _kLink = 'link';
  const LinkAttributeBuilder._() : super(_kLink, NotusAttributeScope.inline);

  /// Creates a link attribute with specified link [value].
  NotusAttribute<String> fromString(String value) =>
      NotusAttribute<String>(key, scope, value);
}

/// Builder for heading attribute styles.
///
/// There is no need to use this class directly, consider using
/// [NotusAttribute.heading] instead.
class HeadingAttributeBuilder extends NotusAttributeBase<int> {
  static const _kHeading = 'header';
  const HeadingAttributeBuilder._()
      : super(_kHeading, NotusAttributeScope.line);
}
