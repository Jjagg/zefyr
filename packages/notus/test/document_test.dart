// Copyright (c) 2018, the Zefyr project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:convert';

import 'package:notus/notus.dart';
import 'package:quill_delta/quill_delta.dart';
import 'package:test/test.dart';

import 'matchers.dart';

NotusDocument dartconfDoc() {
  final delta = Delta()..insert('DartConf\nLos Angeles\n');
  return NotusDocument.fromDelta(delta);
}

final ul = NotusAttribute.ul.toJson();
final h1 = NotusAttribute.h1.toJson();

void main() {
  group('$NotusDocument', () {
    test('validates for doc delta', () {
      var badDelta = Delta()
        ..insert('Text')
        ..retain(5)
        ..insert('\n');
      expect(() {
        NotusDocument.fromDelta(badDelta);
      }, throwsArgumentError);
    });

    test('empty document contains single empty line', () {
      final doc = NotusDocument();
      expect(doc.toPlainText(), '\n');
    });

    test('json serialization', () {
      final original = dartconfDoc();
      final jsonData = json.encode(original);
      final doc = NotusDocument.fromJson(json.decode(jsonData) as List);
      expect(doc.copyDelta(), original.copyDelta());
      expect(json.encode(doc), jsonData);
    });

    test('length', () {
      final doc = dartconfDoc();
      expect(doc.length, 21);
    });

    test('toString', () {
      final doc = dartconfDoc();
      expect(doc.toString(), doc.toString());
    });

    test('load non-empty document', () {
      final doc = dartconfDoc();
      expect(doc.toPlainText(), 'DartConf\nLos Angeles\n');
    });

    test('document delta must end with line-break character', () {
      final delta = Delta()..insert('DartConf\nLos Angeles');
      expect(() {
        NotusDocument.fromDelta(delta);
      }, throwsArgumentError);
    });

    test('lookupLine', () {
      final doc = dartconfDoc();
      doc.format(20, 1, NotusAttribute.bq);
      var line1 = doc.lookupLine(3);
      var line2 = doc.lookupLine(13);

      expect(line1.node, const TypeMatcher<LineNode>());
      expect(line1.node.toPlainText(), 'DartConf\n');
      expect(line2.node, const TypeMatcher<LineNode>());
      expect(line2.node.toPlainText(), 'Los Angeles\n');
    });

    test('format applies heuristics', () {
      final doc = dartconfDoc();
      doc.format(0, 15, NotusAttribute.ul);
      expect(doc.root.children, hasLength(1));
      expect(doc.root.children.first, const TypeMatcher<BlockNode>());
    });

    test('format ignores empty changes', () async {
      final doc = dartconfDoc();
      var changeList = doc.changes.toList();
      var change = doc.format(1, 0, NotusAttribute.bold);
      doc.close();
      var changes = await changeList;
      expect(change, isEmpty);
      expect(changes, isEmpty);
    });

    test('format returns actual change delta', () {
      final doc = dartconfDoc();
      final change = doc.format(0, 15, NotusAttribute.ul);
      final expectedChange = Delta()
        ..retain(8)
        ..retain(1, ul)
        ..retain(11)
        ..retain(1, ul);
      expect(change, expectedChange);
    });

    test('format updates document delta', () {
      final doc = dartconfDoc();
      doc.format(0, 15, NotusAttribute.ul);
      final expectedDoc = Delta()
        ..insert('DartConf')
        ..insert('\n', ul)
        ..insert('Los Angeles')
        ..insert('\n', ul);
      expect(doc.copyDelta(), expectedDoc);
    });

    test('format allows zero-length updates', () {
      final doc = dartconfDoc();
      doc.format(0, 0, NotusAttribute.ul);
      final expectedDoc = Delta()
        ..insert('DartConf')
        ..insert('\n', ul)
        ..insert('Los Angeles')
        ..insert('\n');
      expect(doc.copyDelta(), expectedDoc);
    });

    test('insert applies heuristics', () {
      final doc = dartconfDoc();
      doc.format(0, 15, NotusAttribute.ul);
      doc.insert(8, '\n');
      expect(doc.root.children, hasLength(1));
      expect(doc.root.children.first, const TypeMatcher<BlockNode>());
    });

    test('insert returns actual change delta', () {
      final doc = dartconfDoc();
      doc.format(0, 15, NotusAttribute.ul);
      final change = doc.insert(8, '\n');
      final expectedChange = Delta()
        ..retain(8)
        ..insert('\n', ul);
      expect(change, expectedChange);
    });

    test('insert updates document delta', () {
      final doc = dartconfDoc();
      doc.format(0, 15, NotusAttribute.ul);
      doc.insert(8, '\n');
      final expectedDoc = Delta()
        ..insert('DartConf')
        ..insert('\n\n', ul)
        ..insert('Los Angeles')
        ..insert('\n', ul);
      expect(doc.copyDelta(), expectedDoc);
    });

    test('insert throws argument error if change is empty', () {
      final doc = dartconfDoc();
      expect(() {
        doc.insert(8, '');
      }, throwsArgumentError);
    });

    test('replace throws argument error if change is empty', () {
      final doc = dartconfDoc();
      expect(() {
        doc.replace(8, 0, '');
      }, throwsArgumentError);
    });

    test('compose throws assert error if change is empty', () {
      final doc = dartconfDoc();
      expect(() {
        doc.compose(Delta()..retain(1), ChangeSource.local);
      }, throwsA(const TypeMatcher<AssertionError>()));
    });

    test('replace applies heuristic rules', () {
      final doc = dartconfDoc();
      doc.format(0, 0, NotusAttribute.h1);
      doc.replace(8, 1, ' ');
      expect(doc.root.children, hasLength(1));
      LineNode line = doc.root.children.first;
      expect(line.style.get(NotusAttribute.heading), NotusAttribute.h1);
      expect(line.toPlainText(), 'DartConf Los Angeles\n');
    });

    test('delete applies heuristic rules', () {
      final doc = dartconfDoc();
      doc.format(0, 0, NotusAttribute.h1);
      doc.delete(8, 1);
      expect(doc.root.children, hasLength(1));
      LineNode line = doc.root.children.first;
      expect(line.style.get(NotusAttribute.heading), NotusAttribute.h1);
    });

    test('checks for closed state', () {
      final doc = dartconfDoc();
      expect(doc.isClosed, isFalse);
      doc.close();
      expect(doc.isClosed, isTrue);
      expect(() {
        doc.compose(Delta()..insert('a'), ChangeSource.local);
      }, throwsAssertionError);
      expect(() {
        doc.insert(0, 'a');
      }, throwsAssertionError);
      expect(() {
        doc.format(0, 1, NotusAttribute.bold);
      }, throwsAssertionError);
      expect(() {
        doc.delete(0, 1);
      }, throwsAssertionError);
    });

    test('collectStyle', () {
      final doc = dartconfDoc();
      final style = doc.collectStyle(0, 10);
      expect(style, isNotNull);
    });

    test('insert text containing zero-width space', () {
      final doc = dartconfDoc();
      final change = doc.insert(0, EmbedNode.kPlainTextPlaceholder);
      expect(change, isEmpty);
      expect(doc.length, 21);
    });
  });
}
