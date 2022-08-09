import 'package:ensemble_ts_interpreter/invokables/invokable.dart';
import 'package:ensemble_ts_interpreter/parser/newjs_interpreter.dart';
import 'package:json_path/json_path.dart';
import 'dart:convert';
import 'dart:io';
import 'package:test/test.dart';
import 'package:jsparser/jsparser.dart';
import 'package:jsparser/src/ast.dart';
class Ensemble extends Object with Invokable {
  String? name;
  String? navigateScreenCalledForScreen;
  Ensemble(this.name);
  @override
  Map<String, Function> getters() {
    return {};
  }

  @override
  Map<String, Function> methods() {
    return {
      'navigateScreen': (screenName) => navigateScreenCalledForScreen = screenName
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
    Program ast = parsejs("""
      ensembleStore.session.login.contextId = response.body.data.contextID;
      ensemble.navigateScreen("KPN Home");
      """);
    Map<String, dynamic> context = initContext();
    JSInterpreter(ast,context).evaluate();
    expect(context['ensembleStore']['session']['login']['contextId'],'123456');
    expect((context['ensemble'] as Ensemble).navigateScreenCalledForScreen,'KPN Home');
  });
  test('expressionTest', () async {
    Program ast = parsejs("""
      ensemble.name
      """);
    Map<String, dynamic> context = initContext();
    dynamic rtnValue = JSInterpreter(ast,context).evaluate();
    expect(rtnValue,(context['ensemble'] as Ensemble).name);
  });
  test('propsThroughQuotesTest', () async {
    Program ast = parsejs("""
      var a = 0;
      ensembleStore.session.login.cookie = response.headers['Set-Cookie'].split(';')[a]
      """);
    Map<String, dynamic> context = initContext();
    dynamic rtnValue = JSInterpreter(ast,context).evaluate();
    expect(context['ensembleStore']['session']['login']['cookie'],context['response']['headers']['Set-Cookie'].split(';')[0]);
  });
  test('arrayAccessTest', () async {
    Program ast = parsejs("""
      users[0] = users[users.length-1];
      users[0];
      """);
    Map<String, dynamic> context = initContext();
    dynamic rtnValue = JSInterpreter(ast,context).evaluate();
    expect(rtnValue,context['users'][1]);
  });
  test('mapTest', () async {
    Program ast = parsejs("""
      users.map(function (user) {
        user.name += "NEW";
      });
      """);
    Map<String, dynamic> context = initContext();
    String origValue = context['users'][1]['name'];
    dynamic rtnValue = JSInterpreter(ast,context).evaluate();
    expect(context['users'][1]['name'],origValue+'NEW');
  });
  test('variableDeclarationTest', () async {
    Program ast = parsejs("""
      var user = 'John Doe';
      user += ' II';
      var age;
      age = 12;
      age += 3;
      var curr = 12.9382929;
      curr= curr.prettyCurrency();
      var str = 'user='+user+' is '+age+' years old and has '+curr;
      users[0]['name'] = str;
      """);
    Map<String, dynamic> context = initContext();
    context.remove('age');
    String origValue = context['users'][0]['name'];
    dynamic rtnValue = JSInterpreter(ast,context).evaluate();
    expect(context['users'][0]['name'],'user=John Doe II is 15 years old and has \$12.94');
  });
  test('primitives', () async {
    Program ast = parsejs("""
    var curr = '12.3456';
    curr = curr.tryParseDouble().prettyCurrency();
    users[0]['name'] = 'John has '+curr;
      """);
    Map<String, dynamic> context = initContext();
    dynamic rtnValue = JSInterpreter(ast,context).evaluate();
    expect(context['users'][0]['name'],'John has \$12.35');
  });
  test('returnExpression', () async {
    Program ast = parsejs("""
       'quick brown fox '+users[0]["name"]+' over the fence and received '+users[0]["name"].length+' dollars'
      """);
    Map<String, dynamic> context = initContext();
    context['users'][0]["name"] = 'jumped';
    dynamic rtnValue = JSInterpreter(ast,context).evaluate();
    expect(rtnValue,'quick brown fox jumped over the fence and received 6 dollars');
  });
  test('returnIdentifier', () async {
    Map<String, dynamic> context = initContext();
    dynamic rtn = JSInterpreter.fromCode("""age""",context).evaluate();
    expect(rtn,context['age']);
  });
  test('ifstatement', () async {
    Program ast = parsejs("""
      if ( age == 3 ) {
      }
      if ( age == 2 ) {
        users[0]['age'] = 'Two years old';
      } else {
        users[0]['age'] = 'Over Two years old';
      }
      """);
    Map<String, dynamic> context = initContext();
    context['age'] = 3;
    dynamic rtn = JSInterpreter(ast,context).evaluate();
    expect(context['users'][0]['age'],'Over Two years old');
  });
  test('ternary', () async {
    Program ast = parsejs("""
        (age > 2)?users[0]['age']='More than two years old':users[0]['age']='2 and under';
      """);
    Map<String, dynamic> context = initContext();
    context['age'] = 1;
    dynamic rtn = JSInterpreter(ast,context).evaluate();
    expect(context['users'][0]['age'],'2 and under');
  });
  test('variableDeclarationWithArrayTest', () async {
    Program ast = parsejs("""
      var arr = [];
      arr[0] = 'hello';
      arr[1] = ' ';
      arr.add('nobody');
      users.map(function(user) {
        arr.add(' ');
        arr.add('hello '+user.name);
      });
      """);
    Map<String, dynamic> context = initContext();
    dynamic rtn = JSInterpreter(ast,context).evaluate();
    expect((context['arr']).join(''),'hello nobody hello John hello Mary');
  });
  test('moreArrayTests', () async {
    Program ast = parsejs("""
      var a = {};
      apiChart.data = [{
          "color": "0xffffcccb",
          "data": [-97,-33,-57,-56]
        }];
      """);
    Map<String, dynamic> context = initContext();
    dynamic rtn = JSInterpreter(ast,context).evaluate();
    expect(context['apiChart']['data'][0]['data'][1],-33);
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
    final file = File('test_resources/jsonpath.json');
    final json = jsonDecode(await file.readAsString());
    Map<String, dynamic> context = initContext();
    context['response'] = json;
    dynamic rtn = JSInterpreter.fromCode("""
      var result = response.path('\$..Year',function (match) {match});
      """,context).evaluate();
    expect(context['result'][1],1910);
  });
  test('listsortuniquetest', () async {
    Program ast = parsejs("""
      var list = [10,4,2,4,1,3,8,4,5,6,2,4,8,7,2,9,9,1];
      var uniqueList = list.unique();
      var sortedList = uniqueList.sort();
      var strList = ["2","4","4","1","3"];
      strList = strList.unique().sort(function (a,b) {
        var intA = a.tryParseInt();
        var intB = b.tryParseInt();
        if ( intA < intB ) {
          return -1;
        } else if ( intA > intB ) {
          return 1;
        }
        return 0;
      });
      """);
    Map<String, dynamic> context = initContext();
    dynamic rtn = JSInterpreter(ast,context).evaluate();
    expect(context['sortedList'][2],3);
    expect(context['strList'][2],"3");
  });
  test('getstringvaluetest', () async {
    Program ast = parsejs("""
      var stringToBeTranslated = 'r@kpn.signin';
      ensemble.navigateScreen('r@navigateScreen');
      response.name = response.name;
      users[0]['name'] = 'r@John';
      users[1]['name'] = 'Untranslated Mary';
      """);

    Map<String, dynamic> context = initContext();
    String origStr = 'r@kpn.signin';
    context['response']['name'] = 'r@Peter Parker';
    context['users'][0]['name'] = 'r@John';
    dynamic rtn = JSInterpreter(ast,context).evaluate();
    expect(context['stringToBeTranslated'],'Translated $origStr');
    expect(context['response']['name'],'r@Peter Parker');
    expect(context['users'][0]['name'],'Translated r@John');
    expect(context['users'][1]['name'],'Untranslated Mary');
  });
  test('es121', () async {
    Program ast = parsejs("""
      getPrivWiFi.body.status.wlanvap.vap5g0priv.VAPStatus == 'Up' ? true : false
      """);
    Map<String, dynamic> context = initContext();
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
    context['getPrivWiFi'] = getPrivWiFi;
    dynamic rtn = JSInterpreter(ast,context).evaluate();
    expect(rtn,false);
  });
  test('jsparser', () async {
    Program ast = parsejs("""
      var arr = ['worked!'];
      users.map(function(user) {
        arr.push(' ');
        arr.push('hello '+user.name);
      });
      """);
    Map<String, dynamic> context = initContext();
    JSInterpreter(ast,context).evaluate();
    expect(context['arr'][0],'worked!');
  });
  test('nullTest', () async {
    Program ast = parsejs("""
      if ( ensemble.test == null ) {
        return 'it worked!';
      } else {
        return 'sad face';
       }
      """);
    Map<String, dynamic> context = initContext();
    dynamic rtn = JSInterpreter(ast,context).evaluate();
    expect(rtn,'it worked!');
  });
  test('notNullTest', () async {
    Program ast = parsejs("""
      if ( ensemble.name == null ) {
        return 'sad face!';
      } else {
        return 'it worked!';
       }
      """);
    Map<String, dynamic> context = initContext();
    dynamic rtn = JSInterpreter(ast,context).evaluate();
    expect(rtn,'it worked!');
  });
  test('arrowFunctionTest', () async {
    Program ast = parsejs("""
      users.map( (user,loser) => {
        user.name += "NEW";
      });
      """);
    Map<String, dynamic> context = initContext();
    String origValue = context['users'][1]['name'];
    dynamic rtnValue = JSInterpreter(ast,context).evaluate();
    expect(context['users'][1]['name'],origValue+'NEW');
  });
  test('bindingconditionaltests', () async {
    Program ast = parsejs("""
      myText.text.toLowerCase();
      ( myText.text == 'hello' ) ? 'Hey' : 'nope';
      ( myWidgets.collection.widgets.text == myAPI.response.body.text ) ? myWidget.text : myDD.value;
      ( myWidgets.collection.widgets.text == '1' ) ? myWidget.text : myDD.value;
      myText.value != 'hello' 
      myWidgets.collection.widgets.text != myAPI.response.body['text'] 
      myWidgets.collection.widgets.text != myAPI.response.body[1];
      abc.text = myWidgets.widget.text;
      """);
    List<String> bindings = Bindings().resolve(ast);
    expect(bindings.length,10);
    expect(bindings[0],'myText.text');
    expect(bindings[1],'myWidgets.collection.widgets.text');
    expect(bindings[2],'myAPI.response.body.text');
    expect(bindings[3],'myWidgets.collection.widgets.text');
    expect(bindings[4],'myText.value');
    expect(bindings[5],'myWidgets.collection.widgets.text');
    expect(bindings[6],"myAPI.response.body['text']");
    expect(bindings[7],"myWidgets.collection.widgets.text");
    expect(bindings[8],"myAPI.response.body[1]");
    expect(bindings[9],"myWidgets.widget.text");
  });
  test('bindingdirecttests', () async {
    Program ast = parsejs("""
      myWidgets;
      myAPI.response;
      myAPI.response.body.text;

      """);
    List<String> bindings = Bindings().resolve(ast);
    expect(bindings.length,3);
    expect(bindings[0],'myWidgets');
    expect(bindings[1],'myAPI.response');
    expect(bindings[2],'myAPI.response.body.text');
  });
  test('bindingfunctionargumenttests', () async {
    Program ast = parsejs("""
      utils.translate(myText.text);
      utils.translate(myText.getProperty(allProperties.textProps.property(widget.text)));
      abc.text = utils.translate(myText.getProperty(allProperties.textProps.property(widget.text2)));
      utils.translate(myText.text('myText'));
      utils.translate('myText');
      abc.text = utils.translate(myText.getProperty(allProperties.textProps.property('text')));
      abc.text = utils.translate(myText.getProperty(allProperties.textProps.property('text'+myWidget.text)));
      """);
    List<String> bindings = Bindings().resolve(ast);
    expect(bindings.length,4);
    expect(bindings[0],'myText.text');
    expect(bindings[1],'widget.text');
    expect(bindings[2],'widget.text2');
    expect(bindings[3],'myWidget.text');
  });
  test('functiondeclarationtext', () async {
    Program ast = parsejs("""
      function noArgFunction() {
        var salaries = [10000,200000];
        salaries[1] = 900000;
        return salaries;
      }
      function updateSalary(users,salaries) {
        users.map(function(user) {
          user['salary'] = salaries[i];
          user['age'] = age;
          i++;
        });
      }
      var i = 0;
      var users = [{'name':'Khurram'},{'name':'Mahmood'}];
      updateSalary(users,noArgFunction());

        
      """);
    Map<String, dynamic> context = initContext();
    dynamic rtnValue = JSInterpreter(ast,context).evaluate();
    expect(context['users'][0]['name'],'Khurram');
    expect(context['users'][0]['salary'],10000);
    expect(context['users'][1]['salary'],900000);
    expect(context['users'][1]['age'],3);
  });
}