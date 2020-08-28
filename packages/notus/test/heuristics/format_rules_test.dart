// Copyright (c) 2018, the Zefyr project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'package:test/test.dart';
import 'package:quill_delta/quill_delta.dart';
import 'package:notus/notus.dart';

final ul = NotusAttribute.ul.toMap();
final bold = NotusAttribute.bold.toMap();

void main() {
  group('$ResolveLineFormatRule', () {
    final rule = ResolveLineFormatRule();

    test('apply', () {
      final doc = Delta()..insert('Correct\nLine\nStyle\nRule\n');

      final actual = rule.apply(
          doc, 0, 20, NotusAttribute.ul, NotusDocumentContext.fallback);
      expect(actual, isNotNull);
      final ul = NotusAttribute.ul.toMap();
      final expected = Delta()
        ..retain(7)
        ..retain(1, ul)
        ..retain(4)
        ..retain(1, ul)
        ..retain(5)
        ..retain(1, ul)
        ..retain(4)
        ..retain(1, ul);
      expect(actual, expected);
    });

    test('apply with zero length (collapsed selection)', () {
      final doc = Delta()..insert('Correct\nLine\nStyle\nRule\n');
      final actual = rule.apply(
          doc, 0, 0, NotusAttribute.ul, NotusDocumentContext.fallback);
      expect(actual, isNotNull);
      final ul = NotusAttribute.ul.toMap();
      final expected = Delta()..retain(7)..retain(1, ul);
      expect(actual, expected);
    });

    test('override existing line-scoped attribute', () {
      final ul = NotusAttribute.ul.toMap();
      final doc = Delta()..insert('Title')..insert('\n', ul);
      final actual = rule.apply(
          doc, 0, 0, NotusAttribute.bq, NotusDocumentContext.fallback);
      final expected = Delta()
        ..retain(5)
        ..retain(
            1,
            NotusStyle.fromAttributes(
                [NotusAttribute.ul.unset, NotusAttribute.bq]).toMap());
      expect(actual, expected);
    });
  });

  group('$ResolveInlineFormatRule', () {
    final rule = ResolveInlineFormatRule();

    test('apply', () {
      final doc = Delta()..insert('Correct\nLine\nStyle\nRule\n');

      final actual = rule.apply(
          doc, 0, 20, NotusAttribute.bold, NotusDocumentContext.fallback);
      expect(actual, isNotNull);
      final b = NotusAttribute.bold.toMap();
      final expected = Delta()
        ..retain(7, b)
        ..retain(1)
        ..retain(4, b)
        ..retain(1)
        ..retain(5, b)
        ..retain(1)
        ..retain(1, b);
      expect(actual, expected);
    });
  });

  group('$FormatLinkAtCaretPositionRule', () {
    final rule = FormatLinkAtCaretPositionRule();

    test('apply', () {
      final link =
          NotusAttribute.link.fromString('https://github.com/memspace/bold');
      final newLink =
          NotusAttribute.link.fromString('https://github.com/memspace/zefyr');
      final doc = Delta()
        ..insert('Visit our ')
        ..insert('website', link.toMap())
        ..insert(' for more details.\n');

      final actual =
          rule.apply(doc, 13, 0, newLink, NotusDocumentContext.fallback);
      expect(actual, isNotNull);
      final expected = Delta()..retain(10)..retain(7, newLink.toMap());
      expect(actual, expected);
    });
  });
}
