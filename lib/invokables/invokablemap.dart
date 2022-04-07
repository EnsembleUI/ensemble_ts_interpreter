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
  get(String prop) {
    return map[prop];
  }

  @override
  void set(String prop, val) {
    map[prop] = val;
  }

}