import 'package:notus/notus.dart';
import 'package:quill_delta/quill_delta.dart';

/// A heuristic rule for insert object operations.
abstract class InsertObjectRule {
  /// Constant constructor allows subclasses to declare constant constructors.
  const InsertObjectRule();

  /// Applies heuristic rule to an insert object operation on a [document] and returns
  /// resulting [Delta].
  Delta apply(Delta document, int index, EmbedType type, Object value,
      NotusStyle style, NotusDocumentContext context);
}

/// Fallback rule which simply inserts text as-is without any special handling.
class CatchAllInsertObjectRule extends InsertObjectRule {
  const CatchAllInsertObjectRule();

  @override
  Delta apply(Delta document, int index, EmbedType type, Object value,
      NotusStyle style, NotusDocumentContext context) {
    return Delta()
      ..retain(index)
      ..insertObject(type.key, value, style?.toMap());
  }
}

/// Handles all object inserts with placement [EmbedPlacement.line].
class InsertLinePlacedObjectRule extends InsertObjectRule {
  const InsertLinePlacedObjectRule();

  @override
  Delta apply(Delta document, int index, EmbedType type, Object value,
      NotusStyle style, NotusDocumentContext context) {
    // We are only interested in line-placed objects
    if (type.placement != EmbedPlacement.line) return null;

    final result = Delta()..retain(index);
    final iter = DeltaIterator(document);
    final previous = iter.skip(index);
    final target = iter.next();

    // Check if [index] is on an empty line already.
    final isNewlineBefore = previous == null || previous.endsWith('\n');
    final isNewlineAfter = target.startsWith('\n');
    final isOnEmptyLine = isNewlineBefore && isNewlineAfter;
    if (isOnEmptyLine) {
      return result..insertObject(type.key, value, style?.toMap());
    }
    // We are on a non-empty line, split it (preserving style if needed)
    // and insert our embed.
    final lineStyle = _getLineStyle(iter, target);
    if (!isNewlineBefore) {
      result..insert('\n', lineStyle);
    }
    result..insertObject(type.key, value, style?.toMap());
    if (!isNewlineAfter) {
      result..insert('\n');
    }
    return result;
  }

  Map<String, dynamic> _getLineStyle(DeltaIterator iterator, Op current) {
    if (current.contains('\n')) {
      return current.attributes;
    }
    // Continue looking for line-break.
    Map<String, dynamic> attributes;
    while (iterator.hasNext) {
      final op = iterator.next();
      if (op.contains('\n')) {
        attributes = op.attributes;
        break;
      }
    }
    return attributes;
  }
}
