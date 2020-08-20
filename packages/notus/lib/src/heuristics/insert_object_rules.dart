import 'package:notus/notus.dart';
import 'package:quill_delta/quill_delta.dart';

/// Fallback rule which simply inserts text as-is without any special handling.
class CatchAllInsertObjectRule extends InsertObjectRule {
  const CatchAllInsertObjectRule();

  @override
  Delta apply(Delta document, int index, String type, Object value) {
    return Delta()
      ..retain(index)
      ..insertObj(type, value);
  }
}
