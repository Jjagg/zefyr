// Copyright (c) 2018, the Zefyr project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:notus/notus.dart';
import 'package:quill_delta/quill_delta.dart';
import 'package:test/test.dart';

NotusDocument dartconfDoc() {
  final delta = Delta()..insert('DartConf\nLos Angeles\n');
  return NotusDocument.fromDelta(delta);
}

final ul = NotusAttribute.ul.toMap();
final h1 = NotusAttribute.h1.toMap();

void main() {
  group('$NotusHeuristics', () {
    test('ensures heuristics are applied', () {
      final doc = dartconfDoc();
      final heuristics = NotusHeuristics(
        formatRules: [],
        insertRules: [],
        deleteRules: [],
      );

      expect(() {
        heuristics.applyInsertRules(doc, 0, 'a', NotusDocumentContext.fallback);
      }, throwsStateError);

      expect(() {
        heuristics.applyDeleteRules(doc, 0, 1, NotusDocumentContext.fallback);
      }, throwsStateError);

      expect(() {
        heuristics.applyFormatRules(doc, 0, 1, NotusAttribute.bold, NotusDocumentContext.fallback);
      }, throwsStateError);
    });
  });
}
