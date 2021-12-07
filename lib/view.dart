
import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:yaml/yaml.dart';
import 'package:flutter/cupertino.dart';

class View {
  static const String PROPERTIES = "properties";
  String title = '';
  final List<WidgetView> items = [];
  final Map<String,WidgetView> idWidgetMap = HashMap<String,WidgetView>();
  View (YamlMap map) {
    title = map['title'];
    var list = map['items'];
    if ( list != null ) {
      for ( final YamlMap item in list ) {
        //a. *Where are you going : Auto-complete
        item.forEach((k,v) {
          var arr = k.split('.');
          String id = arr[0];
          String label = arr[1];
          WidgetView? wv = WidgetViewFactory.getWidgetView(v, id, label, null);
          if ( wv != null ) {
            items.add(wv);
            idWidgetMap[id] = wv;
          }
        });
      }
    }
  }
  WidgetView? get(String id) {
    return idWidgetMap[id];
  }
}
class WidgetViewFactory {
  static WidgetView? getWidgetView(String name,String key,String label, Map? properties) {
    WidgetView? rtn;
    if ( name == 'TextInput' ) {
      rtn = WidgetView(
          TextFormField(
              key: Key(key),
              decoration: InputDecoration(labelText:label,hintText:label),
          ), properties);
    } else if ( name == 'Button' ) {
      rtn = WidgetView(
          TextButton(
            key: Key(key),
            onPressed: () { },
            child: Text(label)
          ),properties
      );
    } else if ( name == 'Text' ) {
      rtn = WidgetView(
          Text(
            label,
            key: Key(key)
          ),properties
       );
    }
    return rtn;
  }
}
class WidgetView {
  final Widget widget;
  final Map? properties;
  WidgetView(this.widget,this.properties);
}