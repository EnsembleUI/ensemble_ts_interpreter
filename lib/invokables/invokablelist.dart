import 'package:sdui/invokables/invokable.dart';

class InvokableList extends Object with Invokable {
  List list;
  InvokableList(this.list);
  @override
  Map<String, Function> getters() {
    return {
      'length':() => list.length
    };
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
  get(dynamic prop) {
    if ( prop is int ) {
      return list[prop];
    }
    Function? f = getters()[prop];
    if ( f != null ) {
      return f();
    }
    throw Exception('getter by name='+prop+' is not defined on this object='+toString());
  }

  @override
  void set(dynamic prop, val) {
    if ( prop is int ) {
      list[prop] = val;
    }
  }
}