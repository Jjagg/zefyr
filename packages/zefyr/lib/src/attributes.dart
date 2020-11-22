import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:notus/notus.dart';
import 'package:zefyr/zefyr.dart';

// TODO rename ZefyrTextAttributeHandler
class ZefyrTextAttribute<T> {
  final String key;
  final GestureRecognizer Function(BuildContext context, ZefyrScope scope, dynamic value)
      gestureRecognizerFactory;

  ZefyrTextAttribute._(this.key, this.gestureRecognizerFactory);
  factory ZefyrTextAttribute({
    NotusAttributeBase<T> attribute,
    GestureRecognizer Function(BuildContext context, ZefyrScope scope, dynamic value)
        gestureRecognizerFactory,
  }) {
    return ZefyrTextAttribute._(attribute.key, gestureRecognizerFactory);
  }
}

// TODO rename ZefyrTextAttributeHandlers
class ZefyrAttributeRegistry {
  final Map<String, ZefyrTextAttribute> _attributeMap;

  const ZefyrAttributeRegistry._(this._attributeMap);

  factory ZefyrAttributeRegistry(List<ZefyrTextAttribute> attributes) {
    assert(attributes != null);
    return ZefyrAttributeRegistry._(
        {for (var attr in attributes) attr.key: attr});
  }

  static const ZefyrAttributeRegistry fallback = ZefyrAttributeRegistry._({});

  bool contains(String key) => _attributeMap.containsKey(key);
  ZefyrTextAttribute get(String key) => _attributeMap[key];
}
