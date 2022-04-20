import 'package:sdui/invokables/invokable.dart';
import 'package:sdui/parser/ast.dart';
import 'dart:convert';
import 'dart:io';
import 'package:test/test.dart';

import 'package:sdui/parser/js_interpreter.dart';
class Ensemble extends Object with Invokable {
  String? name;
  Ensemble(this.name);
  @override
  Map<String, Function> getters() {
    return {};
  }

  @override
  Map<String, Function> methods() {
    return {
      'navigateScreen': (screenName) => print('navigate called for '+screenName)
    };
  }

  @override
  Map<String, Function> setters() {
    return {};
  }

  @override
  get(dynamic prop) {
    if ( prop == 'name' ) {
      return name;
    }
    return null;
  }

  @override
  void set(dynamic prop, val) {

  }
  
}
void main() {
  //ensembleStore.session.login.contextId = response.body.data.contextID;
  Map<String, dynamic> context = {
    'response': {
      'name': 'Peter Parker',
      'age': 25,
      'first_name': 'Peter',
      'last-name': 'Parker',
      'body': {
        'data': {
          'contextID': '123456'
        }
      },
      'headers': {
        'Set-Cookie':'abc:xyz;mynewcookie:abc'
      }
    },
    'ensembleStore': {
      'session': {
        'login': {
        }
      }
    },
    'ensemble':Ensemble('EnsembleObject'),
    'users':[{'name':'John'},{'name':'Mary'}]
  };
  test('MapTest', () async {
    /*
    ensembleStore.session.login.contextId = response.body.data.contextID;
    ensemble.navigateScreen("KPN Home");
     */
    final file = File('test_resources/maptest.json');
    final json = jsonDecode(await file.readAsString());
    List<ASTNode> arr = ASTBuilder().buildArray(json['body']);
    Interpreter(context).evaluate(arr);
    expect(context['ensembleStore']['session']['login']['contextId'],'123456');
  });
  test('expressionTest', () async {
    //ensemble.name
    final file = File('test_resources/expression.json');
    final json = jsonDecode(await file.readAsString());
    List<ASTNode> arr = ASTBuilder().buildArray(json['body']);
    dynamic rtnValue = Interpreter(context).evaluate(arr);
    expect(rtnValue,(context['ensemble'] as Ensemble).name);
  });
  test('propsThroughQuotesTest', () async {
    //ensembleStore.session.login.cookie = response.headers['Set-Cookie'].split(';')[0]
    final file = File('test_resources/propsthroughquotes.json');
    final json = jsonDecode(await file.readAsString());
    List<ASTNode> arr = ASTBuilder().buildArray(json['body']);
    dynamic rtnValue = Interpreter(context).evaluate(arr);
    expect(context['ensembleStore']['session']['login']['cookie'],context['response']['headers']['Set-Cookie'].split(';')[0]);
  });
  test('arrayAccessTest', () async {
    /*
    users[0] = users[users.length-1];
    users[0];
     */
    final file = File('test_resources/arrayaccesstest.json');
    final json = jsonDecode(await file.readAsString());
    List<ASTNode> arr = ASTBuilder().buildArray(json['body']);
    dynamic rtnValue = Interpreter(context).evaluate(arr);
    expect(rtnValue,context['users'][1]);
  });
}