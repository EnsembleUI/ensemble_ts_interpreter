import 'package:ensemble_ts_interpreter/invokables/invokable.dart';

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
    return {
      'map': (Function f) =>  {
        list.map((e) => f([e])).toList()
      }
    };
  }

  @override
  Map<String, Function> setters() {
    return {};
  }

  @override
  dynamic getProperty(dynamic prop) {
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
  void setProperty(dynamic prop, dynamic val) {
    if ( prop is int ) {
      list[prop] = val;
    }
  }
}