// Copyright (c) 2018, the Zefyr project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'package:test/test.dart';
import 'package:notus/notus.dart';

void main() {
  group('$NotusStyle', () {
    test('lineStyle', () {
      var attrs = NotusStyle.fromJson(
          <String, dynamic>{'list': 'bullet'}, NotusAttributeRegistry.fallback);
      var attr = attrs.lineStyle();
      expect(attr, NotusAttribute.ul);
    });
  });
}
