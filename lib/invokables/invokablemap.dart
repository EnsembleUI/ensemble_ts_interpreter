import 'package:sdui/invokables/invokable.dart';

class InvokableMap extends Object with Invokable {
  Map map;
  InvokableMap(this.map);
  @override
  Map<String, Function> getters() {
    return {};
  }

  @override
  Map<String, Function> methods() {
    return {};
  }

  @override
  Map<String, Function> setters() {
    return {};
  }

  @override
  getProperty(String prop) {
    return map[prop];
  }

  @override
  void setProperty(String prop, val) {
    map[prop] = val;
  }

}