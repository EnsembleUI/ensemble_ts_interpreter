import 'package:ensemble_ts_interpreter/invokables/invokable.dart';
import 'package:ensemble_ts_interpreter/parser/ast.dart';
import 'package:ensemble_ts_interpreter/parser/find_bindables.dart';
import 'package:json_path/json_path.dart';
import 'dart:convert';
import 'dart:io';
import 'package:test/test.dart';
import 'package:ensemble_ts_interpreter/parser/js_interpreter.dart';
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
  dynamic getProperty(dynamic prop) {
    if ( prop == 'name' ) {
      return name;
    }
    return null;
  }

  @override
  void setProperty(dynamic prop, dynamic val) {

  }
  
}

class ThisObject with Invokable {
  String _identity = 'Spiderman';
  @override
  Map<String, Function> getters() {
    return {
      'identity': () => _identity
    };
  }

  @override
  Map<String, Function> methods() {
    return {
      'toString': () => 'ThisObject'
    };
  }

  @override
  Map<String, Function> setters() {
    return {
      'identity': (newValue) => _identity = newValue
    };
  }

}
void main() {
  //ensembleStore.session.login.contextId = response.body.data.contextID;
  Map<String, dynamic> initContext() {
    return {
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
      'users':[{'name':'John'},{'name':'Mary'}],
      'this': ThisObject(),
      'age':3,
      'apiChart':{'data':[]},
      'getStringValue': (dynamic value) {
        String? val = value?.toString();
        if ( val != null && val.startsWith('r@') ) {
          return 'Translated $val';
        }
        return val;
      },
    };
  }
  test('MapTest', () async {
    /*
    ensembleStore.session.login.contextId = response.body.data.contextID;
    ensemble.navigateScreen("KPN Home");
     */
    final file = File('test_resources/maptest.json');
    final json = jsonDecode(await file.readAsString());
    Map<String, dynamic> context = initContext();
    List<ASTNode> arr = ASTBuilder().buildArray(json['body']);
    Interpreter(context).evaluate(arr);
    expect(context['ensembleStore']['session']['login']['contextId'],'123456');
  });
  test('expressionTest', () async {
    //ensemble.name
    final file = File('test_resources/expression.json');
    final json = jsonDecode(await file.readAsString());
    Map<String, dynamic> context = initContext();
    List<ASTNode> arr = ASTBuilder().buildArray(json['body']);
    dynamic rtnValue = Interpreter(context).evaluate(arr);
    expect(rtnValue,(context['ensemble'] as Ensemble).name);
  });
  test('propsThroughQuotesTest', () async {
    //ensembleStore.session.login.cookie = response.headers['Set-Cookie'].split(';')[0]
    final file = File('test_resources/propsthroughquotes.json');
    final json = jsonDecode(await file.readAsString());
    Map<String, dynamic> context = initContext();
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
    Map<String, dynamic> context = initContext();
    List<ASTNode> arr = ASTBuilder().buildArray(json['body']);
    dynamic rtnValue = Interpreter(context).evaluate(arr);
    expect(rtnValue,context['users'][1]);
  });
  test('using this', () {

  });
  test('mapTest', () async {
    /*
      users.map(user => {
        user.name += "NEW";
      });
     */
    final file = File('test_resources/arraymaptest.json');
    final json = jsonDecode(await file.readAsString());
    Map<String, dynamic> context = initContext();
    String origValue = context['users'][1]['name'];
    List<ASTNode> arr = ASTBuilder().buildArray(json['body']);
    Interpreter(context).evaluate(arr);
    expect(context['users'][1]['name'],origValue+'NEW');
  });
  test('variableDeclarationTest', () async {
    /*
      let user = 'John Doe';
      user += ' II';
      let age;
      age = 12;
      age += 3;
      var curr = 12.9382929;
      curr= curr.prettyCurrency();
      let str = 'user='+user+' is '+age+' years old and has '+curr;
      users[0]['name'] = str;
     */
    final file = File('test_resources/variabledecl.json');
    final json = jsonDecode(await file.readAsString());
    Map<String, dynamic> context = initContext();
    context.remove('age');
    String origValue = context['users'][0]['name'];
    List<ASTNode> arr = ASTBuilder().buildArray(json['body']);
    Interpreter(context).evaluate(arr);
    expect(context['users'][0]['name'],'user=John Doe II is 15 years old and has \$12.94');
  });
  test('primitives', () async {
    /*
    var curr = '12.3456';
    curr = curr.tryParseDouble().prettyCurrency();
    users[0]['name'] = 'John has '+curr;
     */
    final file = File('test_resources/primitives.json');
    final json = jsonDecode(await file.readAsString());
    Map<String, dynamic> context = initContext();
    List<ASTNode> arr = ASTBuilder().buildArray(json['body']);
    Interpreter(context).evaluate(arr);
    expect(context['users'][0]['name'],'John has \$12.35');
  });
  test('returnExpression', () async {
    /*
      'quick brown fox '+users[0]["name"]+' over the fence and received '+users[0]["name"].length+' dollars'
     */
    final file = File('test_resources/returnexpression.json');
    final json = jsonDecode(await file.readAsString());
    Map<String, dynamic> context = initContext();
    context['users'][0]["name"] = 'jumped';
    List<ASTNode> arr = ASTBuilder().buildArray(json['body']);
    dynamic rtn = Interpreter(context).evaluate(arr);
    expect(rtn,'quick brown fox jumped over the fence and received 6 dollars');
  });
  test('returnIdentifier', () async {
    /*
      age
     */
    final file = File('test_resources/returnidentifier.json');
    final json = jsonDecode(await file.readAsString());
    Map<String, dynamic> context = initContext();
    List<ASTNode> arr = ASTBuilder().buildArray(json['body']);
    dynamic rtn = Interpreter(context).evaluate(arr);
    expect(rtn,context['age']);
  });
  test('ifstatement', () async {
    /*
      if ( age == 2 ) {
        users[0]['age'] = 'Two years old';
      } else {
        users[0]['age'] = 'Over Two years old';
      }
     */
    final file = File('test_resources/ifstatement.json');
    Map<String, dynamic> context = initContext();
    context['age'] = 3;
    final json = jsonDecode(await file.readAsString());
    List<ASTNode> arr = ASTBuilder().buildArray(json['body']);
    dynamic rtn = Interpreter(context).evaluate(arr);
    expect(context['users'][0]['age'],'Over Two years old');
  });
  test('ternary', () async {
    /*
      (age > 2)?users[0]['age']='More than two years old':users[0]['age']='2 and under';
      }
     */
    final file = File('test_resources/ternary.json');
    Map<String, dynamic> context = initContext();
    context['age'] = 1;
    final json = jsonDecode(await file.readAsString());
    List<ASTNode> arr = ASTBuilder().buildArray(json['body']);
    dynamic rtn = Interpreter(context).evaluate(arr);
    expect(context['users'][0]['age'],'2 and under');
  });
  test('variableDeclarationWithArrayTest', () async {
    /*
      var arr = [];
      arr[0] = 'hello';
      arr[1] = ' ';
      arr.add('nobody');
      users.map(user => {
        arr.add(' ');
        arr.add('hello '+user.name);
      });
     */
    final file = File('test_resources/varArrDecl.json');
    final json = jsonDecode(await file.readAsString());
    List<ASTNode> arr = ASTBuilder().buildArray(json['body']);
    Map<String, dynamic> ctx = initContext();
    Interpreter(ctx).evaluate(arr);
    expect((ctx['arr']).join(''),'hello nobody hello John hello Mary');
  });
  test('moreArrayTests', () async {
    /*
    var a = {};
    apiChart.data = [{
        "color": "0xffffcccb",
        "data": [-97,-33,-57,-56]
      }];
     */
    final file = File('test_resources/morearrays.json');
    final json = jsonDecode(await file.readAsString());
    List<ASTNode> arr = ASTBuilder().buildArray(json['body']);
    Map<String, dynamic> ctx = initContext();
    Interpreter(ctx).evaluate(arr);
    expect(ctx['apiChart']['data'][0]['data'][1],-33);
  });
  test('jsonobjecttest', () async {
    /*
    a large json object. See jsonpath.json for the actual object
     */
    final file = File('test_resources/jsonobject.json');
    final json = jsonDecode(await file.readAsString());
    List<ASTNode> arr = ASTBuilder().buildArray(json['body']);
    Map<String, dynamic> ctx = initContext();
    dynamic m = Interpreter(ctx).evaluate(arr);
    expect(ctx['body']['records'][2]['fields']['Year'],"1920");
  });
  test('jsonpathtest', () async {
    /*
      see jsonpath.json. This is not a ast test
     */
    final file = File('test_resources/jsonpath.json');
    final json = jsonDecode(await file.readAsString());
    List years = JsonPath(r'$..Year').read(json).map((match)=>int.parse(match.value)).toList();
    List pop = JsonPath(r'$..Population').read(json).map((match)=>match.value).toList();
    expect(years[3],1930);
    expect(pop[3],6.93);
  });
  test('jsonpathintstest', () async {
    /*
    var result = response.path('$..Year',(match)=>match);
     */
    final file = File('test_resources/jsonpath.json');
    final json = jsonDecode(await file.readAsString());
    Map<String, dynamic> ctx = initContext();
    ctx['response'] = json;

    final astFile = File('test_resources/jsonpathints.json');
    final ast = jsonDecode(await astFile.readAsString());
    List<ASTNode> arr = ASTBuilder().buildArray(ast['body']);
    Interpreter(ctx).evaluate(arr);
    expect(ctx['result'][1],1910);
  });
  test('listsortuniquetest', () async {
    /*
      var list = [10,4,2,4,1,3,8,4,5,6,2,4,8,7,2,9,9,1];
      var uniqueList = list.unique();
      var sortedList = uniqueList.sort();
      var strList = ["2","4","4","1","3"];
      strList = strList.unique().sort((a,b)=> {
        var intA = a.tryParseInt();
        var intB = b.tryParseInt();
        if ( intA < intB ) {
          return -1;
        } else if ( intA > intB ) {
          return 1;
        }
        return 0;
      });
     */
    final file = File('test_resources/listsortunique.json');
    final json = jsonDecode(await file.readAsString());
    List<ASTNode> arr = ASTBuilder().buildArray(json['body']);
    Map<String, dynamic> ctx = initContext();
    Interpreter(ctx).evaluate(arr);
    expect(ctx['sortedList'][2],3);
    expect(ctx['strList'][2],"3");
  });
  test('getstringvaluetest', () async {
    /*
      var stringToBeTranslated = 'r@kpn.signin';
      ensemble.navigateScreen('r@navigateScreen');
      response.name = response.name;
      users[0]['name'] = 'r@John';
      users[1]['name'] = 'Untranslated Mary';
     */
    final file = File('test_resources/getstringvalue.json');
    final json = jsonDecode(await file.readAsString());
    List<ASTNode> arr = ASTBuilder().buildArray(json['body']);
    Map<String, dynamic> ctx = initContext();
    String origStr = 'r@kpn.signin';
    ctx['response']['name'] = 'r@Peter Parker';
    ctx['users'][0]['name'] = 'r@John';
    Interpreter(ctx).evaluate(arr);
    expect(ctx['stringToBeTranslated'],'Translated $origStr');
    expect(ctx['response']['name'],'r@Peter Parker');
    expect(ctx['users'][0]['name'],'Translated r@John');
    expect(ctx['users'][1]['name'],'Untranslated Mary');
  });
  test('highcharts1test', () async {
    /*
    too big to show here
     */
    final file = File('test_resources/highcharts1.json');
    final json = jsonDecode(await file.readAsString());
    List<ASTNode> arr = ASTBuilder().buildArray(json['body']);
    Map<String, dynamic> ctx = initContext();
    var rtn = Interpreter(ctx).evaluate(arr);
    print(rtn.toString());
  });
  test('es121', () async {
    /*
      ${getPrivWiFi.body.status.wlanvap.vap5g0priv.VAPStatus == 'Up' ? true : false }
     */
    final file = File('test_resources/es121.json');
    final json = jsonDecode(await file.readAsString());
    ASTBuilder builder = ASTBuilder();
    List<ASTNode> arr = builder.buildArray(json['body']);
    Map<String, dynamic> ctx = initContext();
    Map getPrivWiFi = {
      'body': {
        'status': {
          'wlanvap': {
            'vap5g0priv': {
              'VAPStatus': 'down'
            }
          }
        }
      }
    };
    ctx['getPrivWiFi'] = getPrivWiFi;
    dynamic rtn = Interpreter(ctx).evaluate(arr);
    expect(rtn,false);
    List<String> exps = BindableExpressionFinder(arr,ctx).findBindables();
    exps.length;
  });
  test('nulltest', () async {
    /*
      if ( ensemble.test == null ) {
        return 'it worked!';
      } else {
        return 'sad face';
       }
     */
    final file = File('test_resources/nulltest.json');
    Map<String, dynamic> context = initContext();
    final json = jsonDecode(await file.readAsString());
    List<ASTNode> arr = ASTBuilder().buildArray(json['body']);
    dynamic rtn = Interpreter(context).evaluate(arr);
    expect(rtn,'it worked!');
  });
  test('notnulltest', () async {
    /*
      if ( ensemble.name == null ) {
        return 'sad face!';
      } else {
        return 'it worked!';
       }
     */
    final file = File('test_resources/notnulltest.json');
    Map<String, dynamic> context = initContext();
    final json = jsonDecode(await file.readAsString());
    List<ASTNode> arr = ASTBuilder().buildArray(json['body']);
    dynamic rtn = Interpreter(context).evaluate(arr);
    expect(rtn,'it worked!');
  });
}