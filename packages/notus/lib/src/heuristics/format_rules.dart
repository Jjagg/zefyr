// Copyright (c) 2018, the Zefyr project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:notus/notus.dart';
import 'package:quill_delta/quill_delta.dart';

/// A heuristic rule for format (retain) operations.
abstract class FormatRule {
  /// Constant constructor allows subclasses to declare constant constructors.
  const FormatRule();

  /// Applies heuristic rule to a retain (format) operation on a [document] and
  /// returns resulting [Delta].
  Delta apply(Delta document, int index, int length, NotusAttribute attribute,
      NotusDocumentContext context);
}

/// Produces Delta with line-level attributes applied strictly to
/// line-break characters.
class ResolveLineFormatRule extends FormatRule {
  const ResolveLineFormatRule() : super();

  @override
  Delta apply(Delta document, int index, int length, NotusAttribute attribute,
      NotusDocumentContext context) {
    if (attribute.scope != NotusAttributeScope.line) return null;

    var result = Delta()..retain(index);
    final iter = DeltaIterator(document);
    iter.skip(index);

    final attrMap = attribute.toMap();

    // Apply line styles to all line-break characters within range of this
    // retain operation.
    var current = 0;
    while (current < length && iter.hasNext) {
      final op = iter.next(length - current);
      if (op is InsertStringOp) {
        final delta = _applyAttribute(op.text, attrMap);
        result.concat(delta);
      } else {
        result.retain(op.length);
      }
      current += op.length;
    }
    // And include extra line-break after retain
    while (iter.hasNext) {
      final op = iter.next();
      final lf = op.indexOf('\n');
      if (lf == -1) {
        result..retain(op.length);
        continue;
      }

      // Unset any other line scoped attributes over the range.
      final unsetMap = op.attributes == null
          ? <String, dynamic>{}
          : Map<String, dynamic>.fromEntries(op.attributes.entries
              .where((e) =>
                  context.attributes.isLineScoped(e.key) && e.value != null)
              .map((e) => MapEntry(e.key, null)));
      unsetMap[attribute.key] = attribute.value;

      result..retain(lf)..retain(1, unsetMap);
      break;
    }
    return result;
  }

  Delta _applyAttribute(String text, Map<String, dynamic> attrMap) {
    final result = Delta();
    var offset = 0;
    var lf = text.indexOf('\n');
    while (lf >= 0) {
      result..retain(lf - offset)..retain(1, attrMap);
      offset = lf + 1;
      lf = text.indexOf('\n', offset);
    }
    // Retain any remaining characters in text
    result.retain(text.length - offset);
    return result;
  }
}

/// Produces Delta with inline-level attributes applied to all characters
/// except line-breaks.
class ResolveInlineFormatRule extends FormatRule {
  const ResolveInlineFormatRule();

  @override
  Delta apply(Delta document, int index, int length, NotusAttribute attribute,
      NotusDocumentContext context) {
    if (attribute.scope != NotusAttributeScope.inline) return null;

    final result = Delta()..retain(index);
    final iter = DeltaIterator(document);
    iter.skip(index);

    // Apply inline styles to all non-line-break characters within range of this
    // retain operation.
    var current = 0;
    while (current < length && iter.hasNext) {
      final op = iter.next(length - current);
      var lf = op.indexOf('\n');
      if (lf != -1) {
        var pos = 0;
        while (lf != -1) {
          result..retain(lf - pos, attribute.toMap())..retain(1);
          pos = lf + 1;
          lf = op.indexOf('\n', pos);
        }
        if (pos < op.length) result.retain(op.length - pos, attribute.toMap());
      } else {
        result.retain(op.length, attribute.toMap());
      }
      current += op.length;
    }

    return result;
  }
}

/// Allows updating link format with collapsed selection.
class FormatLinkAtCaretPositionRule extends FormatRule {
  const FormatLinkAtCaretPositionRule();

  @override
  Delta apply(Delta document, int index, int length, NotusAttribute attribute,
      NotusDocumentContext context) {
    if (attribute.key != NotusAttribute.link.key) return null;
    // TODO apply link to selection improvements
    // If user selection is not collapsed we let it fallback to default rule
    // which simply applies the attribute to selected range.
    // This may still not be a bulletproof approach as selection can span
    // multiple lines or be a subset of existing link-formatted text.
    // So certain improvements can be made in the future to account for such
    // edge cases.
    if (length != 0) return null;

    final result = Delta();
    final iter = DeltaIterator(document);
    final before = iter.skip(index);
    final after = iter.next();
    var startIndex = index;
    var retain = 0;
    if (before != null && before.hasAttribute(attribute.key)) {
      startIndex -= before.length;
      retain = before.length;
    }
    if (after != null && after.hasAttribute(attribute.key)) {
      retain += after.length;
    }
    // There is no link-styled text around `index` position so it becomes a
    // no-op action.
    if (retain == 0) return null;

    result..retain(startIndex)..retain(retain, attribute.toMap());

    return result;
  }
}
