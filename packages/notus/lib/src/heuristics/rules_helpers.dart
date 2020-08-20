import 'package:quill_delta/quill_delta.dart';

Op getBefore(Delta document, int index) => DeltaIterator(document).skip(index);

Op getAfter(Delta document, int index) {
  final it = DeltaIterator(document);
  it.skip(index);
  return it.next();
}

BeforeAfterOp getBeforeAfter(Delta document, int index) {
  final it = DeltaIterator(document);
  final before = it.skip(index);
  final after = it.next();
  return BeforeAfterOp(before, after);
}

class BeforeAfterOp {
  final Op before;
  final Op after;

  BeforeAfterOp(this.before, this.after);
}
