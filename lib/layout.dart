import 'package:sdui/view.dart';
import 'package:flutter/widgets.dart';

class Layout {
  final Map map;
  final View view;
  Layout(this.map,this.view);
  static Layout from(Map map,View view) {
    return Layout(map,view);
  }
  Widget build(BuildContext context) {
    Widget rtn = const Text('hey');
    map.forEach((k,v) {
      if (k == "Form") {
        rtn = buildForm(v as Map, context);
      }
    });
    return rtn;
  }
  Form buildForm(Map props,BuildContext context) {
    if ( props['items'] == null ) {
      throw Exception('Form must have items property');
    }
    List children = props['items'] as List;
    List<Widget> childWidgets = [];
    for ( final String id in children) {
      WidgetView? wv = view.get(id);
      if ( wv != null ) {
        childWidgets.add(wv.widget);
      }
    }
    return Form(child:Column(children:childWidgets));
  }
}