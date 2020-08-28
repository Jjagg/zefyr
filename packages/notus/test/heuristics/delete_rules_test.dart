// Copyright (c) 2018, the Zefyr project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'package:test/test.dart';
import 'package:quill_delta/quill_delta.dart';
import 'package:notus/notus.dart';

final ul = NotusAttribute.ul.toMap();
final bold = NotusAttribute.bold.toMap();

void main() {
  group('$PreserveLineStyleOnMergeRule', () {
    final rule = PreserveLineStyleOnMergeRule();
    test('preserves block style', () {
      final ul = NotusAttribute.ul.toMap();
      final doc = Delta()
        ..insert('Title\nOne')
        ..insert('\n', ul)
        ..insert('Two\n');
      final actual = rule.apply(doc, 9, 1, NotusDocumentContext.fallback);
      final expected = Delta()
        ..retain(9)
        ..delete(1)
        ..retain(3)
        ..retain(1, ul);
      expect(actual, expected);
    });

    test('resets block style', () {
      final unsetUl = NotusAttribute.ul.unset.toMap();
      final doc = Delta()
        ..insert('Title\nOne')
        ..insert('\n', NotusAttribute.ul.toMap())
        ..insert('Two\n');
      final actual = rule.apply(doc, 5, 1, NotusDocumentContext.fallback);
      final expected = Delta()
        ..retain(5)
        ..delete(1)
        ..retain(3)
        ..retain(1, unsetUl);
      expect(actual, expected);
    });
  });

  group('$CatchAllDeleteRule', () {
    final rule = CatchAllDeleteRule();

    test('applies change as-is', () {
      final doc = Delta()..insert('Document\n');
      final actual = rule.apply(doc, 3, 5, NotusDocumentContext.fallback);
      final expected = Delta()
        ..retain(3)
        ..delete(5);
      expect(actual, expected);
    });
  });
}
