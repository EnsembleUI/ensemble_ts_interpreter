import 'package:ensemble_ts_interpreter/invokables/invokable.dart';
import 'package:intl/intl.dart';

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
  static String prettyCurrency(dynamic input) {
    num? value;
    if (input is num) {
      value = input;
    } else if (input is String) {
      value = num.tryParse(input);
    }
    if (value != null) {
      NumberFormat formatter = NumberFormat.currency(locale: 'en_US', symbol: "\$");
      return formatter.format(value);
    }
    return '';
  }
  static String prettyDate(dynamic input) {
    DateTime? dateTime = _parseDateTime(input);
    if (dateTime != null) {
      return DateFormat.yMMMd().format(dateTime);
    }
    return '';
  }
  static String prettyDateTime(dynamic input) {
    DateTime? dateTime = _parseDateTime(input);
    if (dateTime != null) {
      return DateFormat.yMMMd().format(dateTime) + ' ' + DateFormat.jm().format(dateTime);
    }
    return '';
  }
  // try to parse the input into a DateTime
  static DateTime? _parseDateTime(dynamic input) {
    if (input is int) {
      return DateTime.fromMillisecondsSinceEpoch(input * 1000);
    } else if (input is String) {
      int? intValue = int.tryParse(input);
      if (intValue != null) {
        return DateTime.fromMillisecondsSinceEpoch(intValue * 1000);
      } else {
        try {
          return DateTime.parse(input);
        } on FormatException catch (_, e) {}
      }
    }
    return null;
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
      'split': (String delimiter) => val.split(delimiter),
      'prettyCurrency': () => InvokablePrimitive.prettyCurrency(val),
      'prettyDate': () => InvokablePrimitive.prettyDate(val),
      'prettyDateTime': () => InvokablePrimitive.prettyDateTime(val),
      'tryParseInt':() => int.tryParse(val),
      'tryParseDouble':() => double.tryParse(val)
    };
  }

  @override
  Map<String, Function> setters() {
    return {};
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
    return {
      'prettyCurrency': () => InvokablePrimitive.prettyCurrency(val),
      'prettyDate': () => InvokablePrimitive.prettyDate(val),
      'prettyDateTime': () => InvokablePrimitive.prettyDateTime(val),
    };
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