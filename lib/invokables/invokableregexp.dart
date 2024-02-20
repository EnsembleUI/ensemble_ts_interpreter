import 'package:ensemble_ts_interpreter/invokables/invokable.dart';

class InvokableRegExp extends Object with Invokable {
  RegExp regExp;
  InvokableRegExp(this.regExp);
  @override
  Map<String, Function> getters() {
    // TODO: implement getters
    throw UnimplementedError();
  }

  @override
  Map<String, Function> methods() {
    return {
      'test': (String input) => regExp.hasMatch(input),
      'exec': (String input) {
        var match = regExp.firstMatch(input);
        return match != null ? _getNamedGroups(match) : null;
      },
      'match': (String input) {
        return input.split(regExp);
      },
      'search': (String input) => input.indexOf(regExp.toString()),
      'replace': (String input, String replacement) =>
          input.replaceAll(regExp, replacement),
      'split': (String input) => input.split(regExp),
      'matchAll': (String input) {
        List<Map<String, String>> matches = [];
        for (var match in regExp.allMatches(input)) {
          matches.add(_getNamedGroups(match));
        }
        return matches;
      },
    };
  }

  Map<String, String> _getNamedGroups(RegExpMatch match) {
    var namedGroups = <String, String>{};
    for (var groupName in match.groupNames) {
      namedGroups[groupName] = match.namedGroup(groupName)!;
    }
    return namedGroups;
  }

  @override
  Map<String, Function> setters() {
    // TODO: implement setters
    throw UnimplementedError();
  }
}
