// Copyright (c) 2018, the Zefyr project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:quill_delta/quill_delta.dart';
import 'package:zefyr/zefyr.dart';

import 'full_page.dart';
import 'images.dart';

class ViewScreen extends StatefulWidget {
  @override
  _ViewScreen createState() => _ViewScreen();
}

final doc =
    r'[{"insert":"Zefyr"},{"insert":"\n","attributes":{"header":1}},{"insert":"Soft and gentle rich text editing for Flutter applications.","attributes":{"italic":true}},{"insert":"\n"},{"insert":{"image":"asset://images/breeze.jpg"}},{"insert":"\n"},{"insert":"Photo by Hiroyuki Takeda.","attributes":{"italic":true}},{"insert":"\nZefyr is currently in "},{"insert":"early preview","attributes":{"bold":true}},{"insert":". If you have a feature request or found a bug, please file it at the "},{"insert":"issue tracker","attributes":{"link":"https://github.com/memspace/zefyr/issues"}},{"insert":'
    r'".\nDocumentation"},{"insert":"\n","attributes":{"header":3}},{"insert":"Quick Start","attributes":{"link":"https://github.com/memspace/zefyr/blob/master/doc/quick_start.md"}},{"insert":"\n","attributes":{"list":"bullet"}},{"insert":"Data Format and Document Model","attributes":{"link":"https://github.com/memspace/zefyr/blob/master/doc/data_and_document.md"}},{"insert":"\n","attributes":{"list":"bullet"}},{"insert":"Style Attributes","attributes":{"link":"https://github.com/memspace/zefyr/blob/master/doc/attr'
    r'ibutes.md"}},{"insert":"\n","attributes":{"list":"bullet"}},{"insert":"Heuristic Rules","attributes":{"link":"https://github.com/memspace/zefyr/blob/master/doc/heuristics.md"}},{"insert":"\n","attributes":{"list":"bullet"}},{"insert":"FAQ","attributes":{"link":"https://github.com/memspace/zefyr/blob/master/doc/faq.md"}},{"insert":"\n","attributes":{"list":"bullet"}},{"insert":"Clean and modern look"},{"insert":"\n","attributes":{"header":2}},{"insert":"Zefyr’s rich text editor is built with simplicity and fle'
    r'xibility in mind. It provides clean interface for distraction-free editing. Think Medium.com-like experience.\nMarkdown inspired semantics"},{"insert":"\n","attributes":{"header":2}},{"insert":"Ever needed to have a heading line inside of a quote block, like this:\nI’m a Markdown heading"},{"insert":"\n","attributes":{"blockquote":true,"header":3}},{"insert":"And I’m a regular paragraph"},{"insert":"\n","attributes":{"blockquote":true}},{"insert":"Code blocks"},{"insert":"\n","attributes":{"header'
    r'":2}},{"insert":"Of course:\nimport ‘package:flutter/material.dart’;"},{"insert":"\n","attributes":{"code-block":true}},{"insert":"import ‘package:zefyr/zefyr.dart’;"},{"insert":"\n\n","attributes":{"code-block":true}},{"insert":"void main() {"},{"insert":"\n","attributes":{"code-block":true}},{"insert":" runApp(MyZefyrApp());"},{"insert":"\n","attributes":{"code-block":true}},{"insert":"}"},{"insert":"\n","attributes":{"code-block":true}},{"insert":"\n\n\n"}]';

Delta getDelta() {
  return Delta.fromJson(json.decode(doc) as List);
}

class _ViewScreen extends State<ViewScreen> {
  final doc = NotusDocument.fromDelta(getDelta());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomPadding: true,
      appBar: AppBar(title: ZefyrLogo()),
      body: ListView(
        children: <Widget>[
          SizedBox(height: 16.0),
          ListTile(
            leading: Icon(Icons.info),
            title: Text('ZefyrView inside ListView'),
            subtitle:
                Text('Allows embedding Notus documents in custom scrollables'),
            trailing: Icon(Icons.keyboard_arrow_down),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ZefyrView(
              document: doc,
              imageDelegate: CustomImageDelegate(),
            ),
          )
        ],
      ),
    );
  }
}
