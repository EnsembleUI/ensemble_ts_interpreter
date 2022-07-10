import 'dart:io';
import 'dart:ui';

import 'package:duration/locale.dart';
import 'package:ensemble_ts_interpreter/invokables/invokable.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:duration/duration.dart' as lib;

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
  /// input should be # of seconds
  static String prettyDuration(dynamic input, {Locale? locale}) {
    if (input == null) {
      return '';
    }
    if (input !is int) {
      input = int.tryParse(input.toString());
    }

    String localeString = locale?.languageCode ?? 'nl'; // ?? Intl.getCurrentLocale().substring(0, 2);
    return lib.prettyDuration(
      Duration(seconds: input),
      abbreviated: false,
      upperTersity: lib.DurationTersity.week,
      tersity: lib.DurationTersity.minute,
      locale: DurationLocale.fromLanguageCode(localeString) ?? EnglishDurationLocale()
    );
  }
  static String prettyDate(dynamic input) {
    DateTime? dateTime = parseDateTime(input)?.toLocal();
    if (dateTime != null) {
      return DateFormat.yMMMd().format(dateTime);
    }
    return '';
  }
  static String prettyDateTime(dynamic input) {
    DateTime? dateTime = parseDateTime(input)?.toLocal();
    if (dateTime != null) {
      return DateFormat.yMMMd().format(dateTime) + ' ' + DateFormat.jm().format(dateTime);
    }
    return '';
  }
  /// try to parse the input into a DateTime.
  /// The returned DateTime is in UTC/GMT timezone (not your local DateTime)
  static DateTime? parseDateTime(dynamic input) {
    if (input is int) {
      return DateTime.fromMillisecondsSinceEpoch(input * 1000);
    } else if (input is String) {
      int? intValue = int.tryParse(input);
      if (intValue != null) {
        return DateTime.fromMillisecondsSinceEpoch(intValue * 1000);
      } else {
        // try parse ISO format
        try {
          return DateTime.parse(input);
        } on FormatException catch (_, e) {}

        // try http date format e.g Thu, 23 Jan 2022 05:05:05 GMT+0200

        // Note that HttpDate parser won't work if we have an offset e.g GMT+0700 or GMT -02:00
        // we'll remove the offset, parse the date, then adjust manually afterward
        String updatedInput = input;
        Duration? offset;
        bool isNegativeOffset = false;
        RegExpMatch? match = RegExp(r'.+ GMT(?<offset>\s?([+-])(\d{2}):?(\d{2}))$').firstMatch(input);
        if (match != null) {
          // remove any offset from the string so we can parse it
          String rawOffset = match.namedGroup('offset')!;
          updatedInput = updatedInput.substring(0, input.indexOf(rawOffset));
          //print(updatedInput);

          isNegativeOffset = match.group(2) == '-' ? true : false;
          int hourOffset = int.parse(match.group(3)!);
          int minuteOffset = int.parse(match.group(4)!);

          offset = Duration(hours: hourOffset, minutes: minuteOffset);
        }
        try {
          DateTime gmtDateTime = HttpDate.parse(updatedInput);
          // adjust the offset
          if (offset != null) {
            gmtDateTime = isNegativeOffset ? gmtDateTime.add(offset) : gmtDateTime.subtract(offset);
            //print(parsedDateTime);
          }
          // we parsed the date as GMT, need to convert to our local time
          return gmtDateTime;
        } catch (e) {}

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
      'prettyDuration': () => InvokablePrimitive.prettyDuration(val)
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