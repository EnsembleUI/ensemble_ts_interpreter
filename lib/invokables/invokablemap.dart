import 'package:ensemble_ts_interpreter/invokables/invokable.dart';

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
  dynamic getProperty(dynamic prop) {
    return map[prop];
  }

  @override
  void setProperty(dynamic prop, dynamic val) {
    map[prop] = val;
  }

}