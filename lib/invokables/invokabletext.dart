import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:sdui/invokables/invokable.dart';

class InvokableText extends StatefulWidget with Invokable,HasController<TextController,InvokableText> {
  @override
  final TextController controller;
  const InvokableText(this.controller, {Key? key}) : super(key:key);

  @override
  State<StatefulWidget> createState() => InvokableTextWidgetState();
  void toUppercase() {
    setters()['value']!(getters()['value']!().toString().toUpperCase());
  }
  int random(int seed,int max) {
    return Random(seed).nextInt(max);
  }
  @override
  get(String prop) {
    Function? f = getters()[prop];
    if ( f != null ) {
      return f();
    }
    throw Exception('getter by name='+prop+' is not defined on this object='+toString());
  }

  @override
  Map<String, Function> getters() {
    return {
      'value': () => controller.value,
      'text': () => controller.value
    };
  }

  @override
  Map<String, Function> methods() {
    return {
      'random': (int seed,int max) { return random(seed,max);},
      'toUpperCase': () => toUppercase(),
      'indexOf': (String str) { return controller.text.indexOf(str);}
    };
  }

  @override
  void set(String prop, val) {
    Function? f = setters()[prop];
    if ( f != null ) {
      f(val);
    }
  }

  @override
  Map<String, Function> setters() {
    return {
      'value': (newValue) => controller.value = newValue,
      'text': (newValue) => controller.value = newValue,
    };
  }
}

class TextController extends Controller<InvokableText> {
  String text;
  TextController(this.text);

  set value (String value) {
    text = value;
    notifyListeners();
  }
  String get value => text;
}
class InvokableTextWidgetState extends InvokableState<InvokableText>{
  @override
  Widget build(BuildContext context) {
    return Text(widget.controller.value);
  }
}
