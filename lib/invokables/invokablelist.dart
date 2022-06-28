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
      },
      'add': (dynamic val) => list.add(val),
      'push': (dynamic val) => list.add(val),
      'indexOf': (dynamic val) => list.indexOf(val),
      'unique': () => list.toSet().toList()
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
      if ( prop >= 0 && prop < list.length ) {
        list[prop] = val;
      } else if ( list.length == prop ) {
        list.add(val);
      }
    } else {
      throw Exception('The passed in prop ='+prop.toString()+' is invalid for this array');
    }
  }
}