// Copyright (c) 2018, the Zefyr project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:notus/notus.dart';

import 'editable_box.dart';
import 'rich_text.dart';
import 'scope.dart';
import 'theme.dart';

/// Represents single line of rich text document in Zefyr editor.
class ZefyrLine extends StatefulWidget {
  const ZefyrLine({Key key, @required this.node, this.style, this.padding})
      : assert(node != null),
        super(key: key);

  /// Line in the document represented by this widget.
  final LineNode node;

  /// Style to apply to this line. Required for lines with text contents,
  /// ignored for lines containing embeds.
  final TextStyle style;

  /// Padding to add around this paragraph.
  final EdgeInsets padding;

  @override
  _ZefyrLineState createState() => _ZefyrLineState();
}

class _ZefyrLineState extends State<ZefyrLine> {
  final LayerLink _link = LayerLink();
  final List<GestureRecognizer> _recognizers = [];

  @override
  void dispose() {
    _recognizers.forEach((r) => r.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scope = ZefyrScope.of(context);
    if (scope.isEditable) {
      ensureVisible(context, scope);
    }
    final theme = Theme.of(context);

    Widget content;
    if (widget.node.hasLineEmbed) {
      content = buildEmbed(context, scope);
    } else {
      assert(widget.style != null);
      content = ZefyrRichText(
        node: widget.node,
        text: buildText(context, scope),
      );
    }

    if (scope.isEditable) {
      Color cursorColor;
      switch (theme.platform) {
        case TargetPlatform.iOS:
        case TargetPlatform.macOS:
          cursorColor ??= CupertinoTheme.of(context).primaryColor;
          break;

        case TargetPlatform.android:
        case TargetPlatform.fuchsia:
        case TargetPlatform.windows:
        case TargetPlatform.linux:
          cursorColor = theme.cursorColor;
          break;
      }

      content = EditableBox(
        child: content,
        node: widget.node,
        layerLink: _link,
        renderContext: scope.renderContext,
        showCursor: scope.showCursor,
        selection: scope.selection,
        selectionColor: theme.textSelectionColor,
        cursorColor: cursorColor,
      );
      content = CompositedTransformTarget(link: _link, child: content);
    }

    if (widget.padding != null) {
      return Padding(padding: widget.padding, child: content);
    }
    return content;
  }

  void ensureVisible(BuildContext context, ZefyrScope scope) {
    if (scope.selection.isCollapsed &&
        widget.node.containsOffset(scope.selection.extentOffset)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        bringIntoView(context);
      });
    }
  }

  void bringIntoView(BuildContext context) {
    final scrollable = Scrollable.of(context);
    final object = context.findRenderObject();
    assert(object.attached);
    final viewport = RenderAbstractViewport.of(object);
    assert(viewport != null);

    final offset = scrollable.position.pixels;
    var target = viewport.getOffsetToReveal(object, 0.0).offset;
    if (target - offset < 0.0) {
      scrollable.position.jumpTo(target);
      return;
    }
    target = viewport.getOffsetToReveal(object, 1.0).offset;
    if (target - offset > 0.0) {
      scrollable.position.jumpTo(target);
    }
  }

  TextSpan buildText(BuildContext context, ZefyrScope scope) {
    final theme = ZefyrTheme.of(context);
    final children = widget.node.children
        .map((node) => _segmentToTextSpan(context, scope, node, theme))
        .toList(growable: false);
    return TextSpan(style: widget.style, children: children);
  }

  InlineSpan _segmentToTextSpan(
    BuildContext context,
    ZefyrScope scope,
    Node node,
    ZefyrThemeData theme,
  ) {
    final TextNode segment = node;
    final attrs = segment.style;

    final registry = scope.attributeMap;

    final style = _getTextStyle(attrs, theme);

    GestureRecognizer recognizer;

    for (final attr in attrs.attributes.values) {
      if (attr.isSet) {
        final gdf = registry.get(attr.key)?.gestureRecognizerFactory;
        if (gdf != null) {
          recognizer = gdf(context, scope, attr.value);
          if (recognizer != null) {
            _recognizers.add(recognizer);
            break;
          }
        }
      }
    }

    return TextSpan(
      text: segment.stringValue,
      style: style,
      recognizer: recognizer,
    );
  }

  TextStyle _getTextStyle(NotusStyle style, ZefyrThemeData theme) {
    var result = TextStyle();
    if (style.containsSame(NotusAttribute.bold)) {
      result = result.merge(theme.attributeTheme.bold);
    }
    if (style.containsSame(NotusAttribute.italic)) {
      result = result.merge(theme.attributeTheme.italic);
    }
    if (style.contains(NotusAttribute.link)) {
      result = result.merge(theme.attributeTheme.link);
    }
    // TODO proper style management for registered attributes
    if (style.values.any((v) => v.key == 'tag')) {
      result = result.merge(TextStyle(color: Colors.green));
    }
    return result;
  }

  Widget buildEmbed(BuildContext context, ZefyrScope scope) {
    final node = widget.node.children.first as EmbedNode;
    final embed = scope.embedMap.get(node.type.key);
    return embed.builder(scope, context, node);
  }
}
