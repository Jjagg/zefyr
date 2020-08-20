import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:notus/notus.dart';

import 'widgets/horizontal_rule.dart';
import 'widgets/image.dart';
import 'widgets/scope.dart';

/// Embed to be registered in a [ZefyrEmbedMap].
class ZefyrEmbed {
  /// The type of this embed.
  final EmbedType type;

  /// Builder to create the zefyr widget for the given [EmbedNode].
  final Widget Function(ZefyrScope, BuildContext, EmbedNode) builder;

  const ZefyrEmbed(this.type, this.builder);
}

/// Map passed to [ZefyrScope] to allow custom widgets to be created
/// from insert objects in the [NotusDocument]'s [Delta].
class ZefyrEmbedMap {
  final Map<String, ZefyrEmbed> _embedMap;

  /// Function to call to create an embed for object inserts with missing keys.
  final ZefyrEmbed Function(String key) createMissing;

  ZefyrEmbedMap(Map<String, ZefyrEmbed> embedMap,
      [ZefyrEmbed Function(String key) createMissing])
      : assert(embedMap != null),
        _embedMap = embedMap,
        createMissing = createMissing ?? defaultCreateMissing;

  /// Get the embed registered with the given [key]. Calls [createMissing]
  /// if no embed is registered with the key.
  ZefyrEmbed get(String key) => _embedMap[key] ?? createMissing(key);

  EmbedTypeMap toTypeMap([EmbedType Function(String key) createMissing]) =>
      EmbedTypeMap(_embedMap.values.map((e) => e.type), createMissing);

  /// The default for [createMissing].
  ///
  /// Renders a red card with error text in debug mode.
  /// Renders nothing in release mode.
  static ZefyrEmbed defaultCreateMissing(String key) => ZefyrEmbed(
      EmbedType(EmbedPlacement.line, key),
      kDebugMode
          ? (scope, ctx, node) => Padding(
                padding: const EdgeInsets.all(8.0),
                child: Card(
                    color: Colors.red,
                    child: Center(
                        child: Text('Missing embed handler for key `$key`.'))),
              )
          : SizedBox.shrink());

  static ZefyrEmbedMap get fallback =>
      ZefyrEmbedMap({'hr': hrEmbed, 'image': imageEmbed});
}

final ZefyrEmbed hrEmbed = ZefyrEmbed(
    EmbedType(EmbedPlacement.line, 'hr', stringify: (t, o) => 'hr'),
    (scope, ctx, n) => ZefyrHorizontalRule(node: n));
final ZefyrEmbed imageEmbed = ZefyrEmbed(
    EmbedType(EmbedPlacement.line, 'image'),
    (scope, ctx, n) => ZefyrImage(node: n, delegate: scope.imageDelegate));
