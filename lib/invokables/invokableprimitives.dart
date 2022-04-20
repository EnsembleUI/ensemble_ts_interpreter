import 'package:sdui/invokables/invokable.dart';

abstract class InvokablePrimitive {
  static Invokable? getPrimitive(dynamic t) {
    if ( t == null ) {
      return InvokableNull();
    } else if ( t is String ) {
      return InvokableString(t);
    } else if ( t is bool ){
      return InvokableBoolean(t);
    } else if ( t is num ) {
      return InvokableNumber(t);
    }
    return null;
  }
  static bool isPrimitive(dynamic val) {
    bool rtn = val == null;
    if ( !rtn ) {
      rtn = val is String || val is num || val is bool; //add more
    }
    return rtn;
  }
  dynamic getValue();

}
class InvokableString extends InvokablePrimitive with Invokable {
  String val;
  InvokableString(this.val);
  @override
  String getValue() {
    return val;
  }

  @override
  Map<String, Function> getters() {
    return {
      'length': () => val.length
    };
  }

  @override
  Map<String, Function> methods() {
    return {
      'indexOf': (String str) => val.indexOf(str),
      'split': (String str) => val.split(str)
    };
  }

  @override
  Map<String, Function> setters() {
    return {};
  }

  @override
  dynamic getProperty(dynamic prop) {
    Function? f = getters()[prop];
    if ( f != null ) {
      return f();
    }
    return null;
  }

  @override
  void setProperty(dynamic prop, dynamic val) {
    // TODO: implement set
  }
}
class InvokableBoolean extends InvokablePrimitive with Invokable {
  bool val;
  InvokableBoolean(this.val);
  @override
  bool getValue() {
    return val;
  }

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
    // TODO: implement get
    throw UnimplementedError();
  }

  @override
  void setProperty(dynamic prop, dynamic val) {
    // TODO: implement set
  }

}
class InvokableNumber extends InvokablePrimitive with Invokable {
  num val;
  InvokableNumber(this.val);

  @override
  num getValue() {
    return val;
  }

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
    // TODO: implement get
    throw UnimplementedError();
  }

  @override
  void setProperty(dynamic prop, dynamic val) {
    // TODO: implement set
  }

}
class InvokableNull extends InvokablePrimitive with Invokable {

  @override
  dynamic getValue() {
    return null;
  }

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
    return null;
  }

  @override
  void setProperty(dynamic prop, dynamic val) {
    throw Exception("cannot set property on null. prop="+prop);
  }

}