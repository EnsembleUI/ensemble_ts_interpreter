import 'package:ensemble_ts_interpreter/invokables/invokable.dart';
import 'package:ensemble_ts_interpreter/invokables/invokableprimitives.dart';
import 'package:ensemble_ts_interpreter/parser/ast.dart';
import 'package:json_path/json_path.dart';

class InvokableController {
  static bool isPrimitive(dynamic val) {
    bool rtn = val == null;
    if ( !rtn ) {
      rtn = val is String || val is num || val is bool; //add more
    }
    return rtn;
  }
  static bool isNative(dynamic val) {
    bool rtn = isPrimitive(val);
    if ( !rtn ) {
      rtn = val is Map || val is List || val is RegExp;
    }
    return rtn;
  }
  static Map<String, Function> methods(dynamic val) {
    if ( val == null ) {
      return {};
    } else if ( val is Invokable ) {
      return val.methods();
    } else if ( val is String) {
      return _String.methods(val);
    } else if ( val is bool ) {
      return _Boolean.methods(val);
    } else if ( val is num ) {
      return _Number.methods(val);
    } else if ( val is Map ) {
      return _Map.methods(val);
    } else if ( val is List ) {
      return _List.methods(val);
    } else if ( val is RegExp ) {
      return _RegExp.methods(val);
    }
    return {};
  }
  static Map<String, Function> setters(dynamic val) {
    if ( val == null ) {
      return {};
    } else if ( val is Invokable ) {
      return val.setters();
    } else if ( val is String) {
      return _String.setters(val);
    } else if ( val is bool ) {
      return _Boolean.setters(val);
    } else if ( val is num ) {
      return _Number.setters(val);
    } else if ( val is Map ) {
      return _Map.setters(val);
    } else if ( val is List ) {
      return _List.setters(val);
    } else if ( val is RegExp ) {
      return _RegExp.setters(val);
    }
    return {};
  }
  static Map<String, Function> getters(dynamic val) {
    if ( val == null ) {
      return {};
    } else if ( val is Invokable ) {
      return val.getters();
    } else if ( val is String) {
      return _String.getters(val);
    } else if ( val is bool ) {
      return _Boolean.getters(val);
    } else if ( val is num ) {
      return _Number.getters(val);
    } else if ( val is Map ) {
      return _Map.getters(val);
    } else if ( val is List ) {
      return _List.getters(val);
    } else if ( val is RegExp ) {
      return _RegExp.setters(val);
    }
    return {};
  }
  static dynamic getProperty(dynamic val, dynamic prop) {
    if ( val == null ) {
      return null;
    } else if ( val is Invokable ) {
      return val.getProperty(prop);
    } else if ( val is String) {
      return _String.getProperty(val, prop);
    } else if ( val is bool ) {
      return _Boolean.getProperty(val, prop);
    } else if ( val is num ) {
      return _Number.getProperty(val, prop);
    } else if ( val is Map ) {
      return _Map.getProperty(val, prop);
    } else if ( val is List ) {
      return _List.getProperty(val, prop);
    } else if ( val is RegExp ) {
      return _RegExp.getProperty(val, prop);
    }
    return null;
  }
  static dynamic setProperty(dynamic val, dynamic prop, dynamic value) {
    if ( val == null ) {
      throw Exception('Cannot set a property on a null object. Property=$prop and prop value=$value');
    } else if ( val is Invokable ) {
      return val.setProperty(prop,value);
    } else if ( val is String) {
      return _String.setProperty(val, prop, value);
    } else if ( val is bool ) {
      return _Boolean.setProperty(val, prop, value);
    } else if ( val is num ) {
      return _Number.setProperty(val, prop, value);
    } else if ( val is Map ) {
      return _Map.setProperty(val, prop, value);
    } else if ( val is List ) {
      return _List.setProperty(val, prop, value);
    } else if ( val is RegExp ) {
      return _RegExp.setProperty(val, prop, value);
    }
    return {};
  }
  static List<String> getGettableProperties(dynamic obj) {
    if ( obj is Invokable ) {
      return Invokable.getGettableProperties(obj);
    } else {
      return InvokableController.getters(obj).keys.toList();
    }
  }
  static List<String> getSettableProperties(dynamic obj) {
    if ( obj is Invokable ) {
      return Invokable.getSettableProperties(obj);
    } else {
      return InvokableController.setters(obj).keys.toList();
    }
  }
  static Map<String, Function> getMethods(dynamic obj) {
    if ( obj is Invokable ) {
      return Invokable.getMethods(obj);
    } else {
      return InvokableController.methods(obj);
    }
  }

}

class _String {
  static Map<String, Function> getters(String val) {
    return {
      'length': () => val.length
    };
  }
  static dynamic getProperty(String obj, dynamic prop) {
    Function? f = getters(obj)[prop];
    if ( f != null ) {
      return f();
    }
    throw Exception('getter by name='+prop+' is not defined on this object='+obj.toString());
  }
  static void setProperty(String obj, dynamic prop, dynamic val) {
    Function? func = setters(obj)[prop];
    if (func != null) {
      func(val);
    }
  }
  static Map<String, Function> methods(String val) {
    return {
      'indexOf': (String str) => val.indexOf(str),
      'lastIndexOf': (String str,[start=-1]) => (start == -1)?val.lastIndexOf(str):val.lastIndexOf(str,start),
      'charAt': (index)=> val[index],
      'startsWith': (str) => val.startsWith(str),
      'endsWith': (str) => val.endsWith(str),
      'includes': (str) => val.contains(str),
      'toLowerCase': () => val.toLowerCase(),
      'toUpperCase': () => val.toUpperCase(),
      'match': (regexp) => (regexp as RegExp).firstMatch(val),
      'matchAll': (regexp) => (regexp as RegExp).allMatches(val),
      'padStart': (n,[str=' ']) => val.padLeft(n,str),
      'padEnd': (n,[str=' ']) => val.padRight(n,str),
      'substring': (start,[end=-1]) => (end == -1)?val.substring(start):val.substring(start,end),
      'split': (String delimiter) => val.split(delimiter),
      'prettyCurrency': () => InvokablePrimitive.prettyCurrency(val),
      'prettyDate': () => InvokablePrimitive.prettyDate(val),
      'prettyDateTime': () => InvokablePrimitive.prettyDateTime(val),
      'tryParseInt':() => int.tryParse(val),
      'tryParseDouble':() => double.tryParse(val)
    };
  }
  static Map<String, Function> setters(String val) {
    return {};
  }
}
class _Boolean {
  static Map<String, Function> getters(bool val) {
    return {};
  }

  static Map<String, Function> methods(bool val) {
    return {};
  }

  static Map<String, Function> setters(bool val) {
    return {};
  }
  static dynamic getProperty(bool obj, dynamic prop) {
    Function? f = getters(obj)[prop];
    if ( f != null ) {
      return f();
    }
    throw Exception('getter by name='+prop+' is not defined on this object='+obj.toString());
  }
  static void setProperty(bool obj, dynamic prop, dynamic val) {
    Function? func = setters(obj)[prop];
    if (func != null) {
      func(val);
    }
  }
}
class _Number {
  static Map<String, Function> getters(num val) {
    return {};
  }
  static Map<String, Function> methods(num val) {
    return {
      'prettyCurrency': () => InvokablePrimitive.prettyCurrency(val),
      'prettyDate': () => InvokablePrimitive.prettyDate(val),
      'prettyDateTime': () => InvokablePrimitive.prettyDateTime(val),
      'prettyDuration': () => InvokablePrimitive.prettyDuration(val),
      'toFixed': (int fractionDigits) => val.toStringAsFixed(fractionDigits)
    };
  }
  static Map<String, Function> setters(num val) {
    return {};
  }
  static dynamic getProperty(num obj, dynamic prop) {
    Function? f = getters(obj)[prop];
    if ( f != null ) {
      return f();
    }
    throw Exception('getter by name='+prop+' is not defined on this object='+obj.toString());
  }
  static void setProperty(num obj, dynamic prop, dynamic val) {
    Function? func = setters(obj)[prop];
    if (func != null) {
      func(val);
    }
  }
}
class _Map {
  static Map<String, Function> getters(Map map) {
    return {};
  }
  static Map<String, Function> methods(Map map) {
    return {
      'path':(String path,Function? mapFunction) {
        return JsonPath(path)
            .read(map)
            .map((match)=>(mapFunction!=null)?mapFunction([match.value]):match.value)
            .toList();
      }


    };
  }
  static Map<String, Function> setters(Map val) {
    return {};
  }
  static dynamic getProperty(Map map, dynamic prop) {
    return map[prop];
  }

  static void setProperty(Map map, dynamic prop, dynamic val) {
    map[prop] = val;
  }
}
class _List {
  static Map<String, Function> getters(List list) {
    return {
      'length':() => list.length
    };
  }

  static Map<String, Function> methods(List list) {
    return {
      'map': (Function f) =>  {
        list.map((e) => f([e])).toList()
      },
      'filter': (Function f) => list.where((e) => f([e])).toList(),
      'forEach': (Function f) =>  {
        list.forEach((e) => f([e]))
      },
      'add': (dynamic val) => list.add(val),
      'push': (dynamic val) => list.add(val),
      'indexOf': (dynamic val) => list.indexOf(val),
      'unique': () => list.toSet().toList(),
      'sort': ([Function? f]) {
        if ( f == null ) {
          list.sort();
        } else {
          list.sort((a,b)=> f([a,b]));
        }
        return list;

      },
      'sortF': ([Function? f]) {
        if ( f == null ) {
          list.sort();
        } else {
          list.sort((a,b)=> f([a,b]));
        }
        return list;
      }
    };
  }

  static Map<String, Function> setters(List list) {
    return {};
  }

  static dynamic getProperty(List list, dynamic prop) {
    if ( prop is int ) {
      return list[prop];
    }
    Function? f = getters(list)[prop];
    if ( f != null ) {
      return f();
    }
    throw Exception('getter by name='+prop+' is not defined on this object='+list.toString());
  }

  static void setProperty(List list, dynamic prop, dynamic val) {
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
class _RegExp {
  static Map<String, Function> getters(RegExp val) {
    return {};
  }

  static Map<String, Function> methods(RegExp val) {
    return {
      'test': (String input) => val.hasMatch(input),
    };
  }

  static Map<String, Function> setters(RegExp val) {
    return {};
  }
  static dynamic getProperty(RegExp obj, dynamic prop) {
    Function? f = getters(obj)[prop];
    if ( f != null ) {
      return f();
    }
    throw Exception('getter by name='+prop+' is not defined on this object='+obj.toString());
  }
  static void setProperty(RegExp obj, dynamic prop, dynamic val) {
    Function? func = setters(obj)[prop];
    if (func != null) {
      func(val);
    }
  }
}