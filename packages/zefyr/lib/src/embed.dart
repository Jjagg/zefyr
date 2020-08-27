import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:notus/notus.dart';

import 'widgets/horizontal_rule.dart';
import 'widgets/image.dart';
import 'widgets/scope.dart';

/// Embed to be registered in a [ZefyrEmbedRegistry].
class ZefyrEmbed {
  /// The type of this embed.
  final EmbedType type;

  /// Builder to create the zefyr widget for the given [EmbedNode].
  final Widget Function(ZefyrScope, BuildContext, EmbedNode) builder;

  const ZefyrEmbed(this.type, this.builder);
}

/// Map passed to [ZefyrScope] to allow custom widgets to be created
/// from insert objects in the [NotusDocument]'s [Delta].
class ZefyrEmbedRegistry {
  final Map<String, ZefyrEmbed> _embedMap;

  /// Function to call to create an embed for object inserts with missing keys.
  final ZefyrEmbed Function(String key) createMissing;

  const ZefyrEmbedRegistry._(this._embedMap, this.createMissing);

  factory ZefyrEmbedRegistry(List<ZefyrEmbed> embeds,
      [ZefyrEmbed Function(String key) createMissing]) {
    assert(embeds != null);
    return ZefyrEmbedRegistry._({for (var e in embeds) e.type.key: e},
        createMissing ?? defaultCreateMissing);
  }

  /// Get the embed registered with the given [key]. Calls [createMissing]
  /// if no embed is registered with the key.
  ZefyrEmbed get(String key) => _embedMap[key] ?? createMissing(key);

  NotusEmbedRegistry toTypeMap(
          [EmbedType Function(String key) createMissing]) =>
      NotusEmbedRegistry(
          _embedMap.values.map((e) => e.type).toList(), createMissing);

  /// The default for [createMissing].
  ///
  /// Throws a [ArgumentError] in debug mode.
  /// Renders a red card with error text in release mode.
  static ZefyrEmbed defaultCreateMissing(String key) => ZefyrEmbed(
      EmbedType(EmbedPlacement.line, key),
      kDebugMode
          ? throw ArgumentError.value(
              key, 'key', 'Missing embed handler for key `$key`.')
          : (scope, ctx, node) => Padding(
                padding: const EdgeInsets.all(8.0),
                child: Card(
                    color: Colors.red,
                    child: Center(
                        child: Text('Missing embed handler for key `$key`.'))),
              ));

  static const ZefyrEmbedRegistry fallback = ZefyrEmbedRegistry._(
      {'hr': ZefyrEmbeds.hrEmbed, 'image': ZefyrEmbeds.imageEmbed},
      defaultCreateMissing);
}

Widget _createHorizontalRule(
        ZefyrScope scope, BuildContext context, Node node) =>
    ZefyrHorizontalRule(node: node);

Widget _createImage(ZefyrScope scope, BuildContext context, Node node) =>
    ZefyrImage(node: node, delegate: scope.imageDelegate);

class ZefyrEmbeds {
  static const ZefyrEmbed hrEmbed =
      ZefyrEmbed(NotusEmbeds.hrEmbed, _createHorizontalRule);
  static const ZefyrEmbed imageEmbed =
      ZefyrEmbed(NotusEmbeds.imageEmbed, _createImage);
}
