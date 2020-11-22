// Copyright (c) 2018, the Zefyr project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:notus/notus.dart';
import 'package:quill_delta/quill_delta.dart';

/// A heuristic rule for insert operations.
abstract class InsertRule {
  /// Constant constructor allows subclasses to declare constant constructors.
  const InsertRule();

  /// Applies heuristic rule to an insert operation on a [document] and returns
  /// resulting [Delta].
  Delta apply(
      Delta document, int index, String text, NotusDocumentContext context);
}

/// Fallback rule which simply inserts text as-is without any special handling.
class CatchAllInsertRule extends InsertRule {
  const CatchAllInsertRule();

  @override
  Delta apply(
      Delta document, int index, String text, NotusDocumentContext context) {
    return Delta()
      ..retain(index)
      ..insert(text);
  }
}

/// Preserves line format when user splits the line into two.
///
/// This rule ignores scenarios when the line is split on its edge, meaning
/// a line-break is inserted at the beginning or the end of the line.
class PreserveLineStyleOnSplitRule extends InsertRule {
  const PreserveLineStyleOnSplitRule();

  bool isEdgeLineSplit(Op before, Op after) {
    if (before == null) return true; // split at the beginning of a doc
    return before.endsWith('\n') || after.startsWith('\n');
  }

  @override
  Delta apply(
      Delta document, int index, String text, NotusDocumentContext context) {
    if (text != '\n') return null;

    final iter = DeltaIterator(document);
    final before = iter.skip(index);
    final after = iter.next();
    if (isEdgeLineSplit(before, after)) return null;
    final result = Delta()..retain(index);
    if (after.contains('\n')) {
      // It is not allowed to combine line and inline styles in insert
      // operation containing line-break together with other characters.
      // The only scenario we get such operation is when the text is plain.
      assert(!after.hasAttributes);
      // No attributes to apply so we simply create a new line.
      result.insert('\n');
      return result;
    }
    // Continue looking for line-break.
    Map<String, dynamic> attributes;
    while (iter.hasNext) {
      final op = iter.next();
      final lf = op.indexOf('\n');
      if (lf >= 0) {
        attributes = op.attributes;
        break;
      }
    }
    result.insert('\n', attributes);
    return result;
  }
}

/// Resets format for a newly inserted line when insert occurred at the end
/// of a line (right before a line-break).
class ResetLineFormatOnNewLineRule extends InsertRule {
  const ResetLineFormatOnNewLineRule();

  @override
  Delta apply(
      Delta document, int index, String text, NotusDocumentContext context) {
    if (text != '\n') return null;

    final iter = DeltaIterator(document);
    iter.skip(index);
    final target = iter.next();

    if (target.startsWith('\n')) {
      Map<String, dynamic> resetStyle;
      if (target.attributes != null &&
          target.attributes.containsKey(NotusAttribute.heading.key)) {
        resetStyle = NotusAttribute.heading.unset.toMap();
      }
      return Delta()
        ..retain(index)
        ..insert('\n', target.attributes)
        ..retain(1, resetStyle)
        ..trim();
    }
    return null;
  }
}

/// Heuristic rule to exit current block when user inserts two consecutive
/// line-breaks.
// TODO: update this rule to handle code blocks differently, at least allow 3 consecutive line-breaks before exiting.
class AutoExitBlockRule extends InsertRule {
  const AutoExitBlockRule();

  bool isEmptyLine(Op previous, Op target) {
    return (previous == null || previous.endsWith('\n')) &&
        target.startsWith('\n');
  }

  @override
  Delta apply(
      Delta document, int index, String text, NotusDocumentContext context) {
    if (text != '\n') return null;

    final iter = DeltaIterator(document);
    final previous = iter.skip(index);
    final target = iter.next();
    final blockAttributeKey = target.hasAttributes
        ? target.attributes.keys
            .firstWhere((a) => context.attributes.isLineScoped(a), orElse: () => null)
        : null;
    if (isEmptyLine(previous, target) && blockAttributeKey != null) {
      // We reset block style even if this line is not the last one in its
      // block which effectively splits the block into two.
      // TODO: For code blocks this should not split the block but allow inserting as many lines as needed.
      Map<String, dynamic> attributes;
      if (target.attributes != null) {
        attributes = Map<String, dynamic>.of(target.attributes);
      } else {
        attributes = <String, dynamic>{};
      }
      attributes[blockAttributeKey] = null;
      return Delta()..retain(index)..retain(1, attributes);
    }
    return null;
  }
}

/// Preserves inline styles when user inserts text inside formatted segment.
class PreserveInlineStylesRule extends InsertRule {
  const PreserveInlineStylesRule();

  @override
  Delta apply(
      Delta document, int index, String text, NotusDocumentContext context) {
    // This rule is only applicable to characters other than line-break.
    if (text.contains('\n')) return null;

    final iter = DeltaIterator(document);
    final previous = iter.skip(index);
    // If there is a line-break in previous chunk, there should be no inline
    // styles. Also if there is no previous operation we are at the beginning
    // of the document so no styles to inherit from.
    if (previous == null || previous.contains('\n')) return null;

    final attributes = previous.attributes;
    final hasLink =
        (attributes != null && attributes.containsKey(NotusAttribute.link.key));
    if (!hasLink) {
      return Delta()
        ..retain(index)
        ..insert(text, attributes);
    }
    // Special handling needed for inserts inside fragments with link attribute.
    // Link style should only be preserved if insert occurs inside the fragment.
    // Link style should NOT be preserved on the boundaries.
    var noLinkAttributes = Map<String, dynamic>.of(previous.attributes);
    noLinkAttributes.remove(NotusAttribute.link.key);
    final noLinkResult = Delta()
      ..retain(index)
      ..insert(text, noLinkAttributes.isEmpty ? null : noLinkAttributes);
    final next = iter.next();
    if (next == null) {
      // Nothing after us, we are not inside link-styled fragment.
      return noLinkResult;
    }
    final nextAttributes = next.attributes ?? <String, dynamic>{};
    if (!nextAttributes.containsKey(NotusAttribute.link.key)) {
      // Next fragment is not styled as link.
      return noLinkResult;
    }
    // We must make sure links are identical in previous and next operations.
    if (attributes[NotusAttribute.link.key] ==
        nextAttributes[NotusAttribute.link.key]) {
      return Delta()
        ..retain(index)
        ..insert(text, attributes);
    } else {
      return noLinkResult;
    }
  }
}

/// Applies link format to text segment (which looks like a link) when user
/// inserts space character after it.
class AutoFormatLinksRule extends InsertRule {
  const AutoFormatLinksRule();

  @override
  Delta apply(
      Delta document, int index, String text, NotusDocumentContext context) {
    // This rule applies to a space inserted after a link, so we can ignore
    // everything else.
    if (text != ' ') return null;

    final iter = DeltaIterator(document);
    final previous = iter.skip(index);
    // No previous operation means no link.
    if (previous == null) return null;

    // Split text of previous operation in lines and words and take last word to test.
    final candidate = previous.split('\n').last.split(' ').last;
    try {
      final link = Uri.parse(candidate);
      if (!['https', 'http'].contains(link.scheme)) {
        // TODO Need to relax auto link conditions
        // Markdig: https://github.com/lunet-io/markdig/blob/master/src/Markdig.Tests/Specs/AutoLinks.md
        return null;
      }
      final attributes = previous.attributes ?? <String, dynamic>{};

      // Do nothing if already formatted as link.
      if (attributes.containsKey(NotusAttribute.link.key)) return null;

      attributes
          .addAll(NotusAttribute.link.fromString(link.toString()).toMap());
      return Delta()
        ..retain(index - candidate.length)
        ..retain(candidate.length, attributes)
        ..insert(text, previous.attributes);
    } on FormatException {
      return null; // Our candidate is not a link.
    }
  }
}

/// Forces text inserted on the same line with an embed (before or after it)
/// to be moved to a new line adjacent to the original line.
///
/// This rule assumes that a line is only allowed to have single embed child.
class ForceNewlineForInsertsAroundEmbedRule extends InsertRule {
  const ForceNewlineForInsertsAroundEmbedRule();

  @override
  Delta apply(
      Delta document, int index, String text, NotusDocumentContext context) {
    final iter = DeltaIterator(document);
    final previous = iter.skip(index);
    final target = iter.next();
    final beforeEmbed = target?.isObject() ?? false;
    final afterEmbed = previous?.isObject() ?? false;
    if (beforeEmbed || afterEmbed) {
      final delta = Delta()..retain(index);
      if (beforeEmbed && !text.endsWith('\n')) {
        return delta..insert(text)..insert('\n');
      }
      if (afterEmbed && !text.startsWith('\n')) {
        return delta..insert('\n')..insert(text);
      }
      return delta..insert(text);
    }
    return null;
  }
}

/// Preserves block style when user pastes text containing line-breaks.
/// This rule may also be activated for changes triggered by auto-correct.
class PreserveBlockStyleOnPasteRule extends InsertRule {
  const PreserveBlockStyleOnPasteRule();

  bool isEdgeLineSplit(Op before, Op after) {
    if (before == null) return true; // split at the beginning of a doc
    return before.endsWith('\n') || after.startsWith('\n');
  }

  @override
  Delta apply(
      Delta document, int index, String text, NotusDocumentContext context) {
    if (!text.contains('\n') || text.length == 1) {
      // Only interested in text containing at least one line-break and at least
      // one more character.
      return null;
    }

    final iter = DeltaIterator(document);
    iter.skip(index);

    // Look for next line-break.
    Map<String, dynamic> lineAttributes;
    while (iter.hasNext) {
      final op = iter.next();
      final lf = op.indexOf('\n');
      if (lf >= 0) {
        lineAttributes = op.attributes;
        break;
      }
    }

    final lineStyleKey = lineAttributes != null
        ? lineAttributes.keys
            .firstWhere((a) => context.attributes.isLineScoped(a), orElse: () => null)
        : null;

    Map<String, dynamic> resetStyle;
    Map<String, dynamic> blockStyle;
    if (lineStyleKey != null) {
      if (lineStyleKey == NotusAttribute.heading.key) {
        resetStyle = NotusAttribute.heading.unset.toMap();
      } else if (context.attributes.contains(lineStyleKey)) {
        blockStyle = <String, dynamic>{
          lineStyleKey: lineAttributes[lineStyleKey]
        };
      }
    }

    final lines = text.split('\n');
    final result = Delta()..retain(index);
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (line.isNotEmpty) {
        result.insert(line);
      }
      if (i == 0) {
        result.insert('\n', lineAttributes);
      } else if (i == lines.length - 1) {
        if (resetStyle != null) result.retain(1, resetStyle);
      } else {
        result.insert('\n', blockStyle);
      }
    }

    return result;
  }
}
