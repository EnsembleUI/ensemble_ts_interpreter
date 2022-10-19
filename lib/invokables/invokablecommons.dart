import 'dart:convert';

import 'package:ensemble_ts_interpreter/invokables/invokable.dart';

class JSON extends Object with Invokable {
  @override
  Map<String, Function> methods() {
    return {
      'stringify': (dynamic value) => (value != null )? json.encode(value) : null,
      'parse': (String value) => json.decode(value)
    };
  }

  @override
  Map<String, Function> getters() {
    return {};
  }

  @override
  Map<String, Function> setters() {
    return {};
  }
}