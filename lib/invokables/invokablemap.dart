import 'package:ensemble_ts_interpreter/invokables/invokable.dart';
import 'package:json_path/json_path.dart';
class InvokableMap extends Object with Invokable {
  Map map;
  InvokableMap(this.map);
  @override
  Map<String, Function> getters() {
    return {};
  }

  @override
  Map<String, Function> methods() {
    return {
      'path':(String path,Function? mapFunction) {
        return JsonPath(path)
            .read(map)
            .map((match)=>(mapFunction!=null)?mapFunction([match.value]):match.value)
            .toList();
      }


    };
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