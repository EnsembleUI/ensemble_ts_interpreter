
import 'dart:convert';

import 'package:ensemble_ts_interpreter/invokables/InvokableRegExp.dart';
import 'package:ensemble_ts_interpreter/invokables/invokablecommons.dart';
import 'package:ensemble_ts_interpreter/invokables/invokablemath.dart';
import 'package:ensemble_ts_interpreter/invokables/invokablecontroller.dart';
import 'package:jsparser/jsparser.dart';
import 'package:jsparser/src/ast.dart';

class Bindings extends RecursiveVisitor<dynamic> {
  List<String> bindings = [];
  List<String> resolve(Program program) {
    visit(program);
    return bindings;
  }
  String convertToString(List<String> list) {
    String rtn = '';
    list.forEach((element) {rtn += '.'+element;});
    return rtn;
  }
  @override
  visitVariableDeclarator(VariableDeclarator node) {
    String name = visitName(node.name);
    bindings.add(name);
    return name;
  }
  @override
  visitBinary(BinaryExpression node) {
    dynamic left = node.left.visitBy(this);
    dynamic right = node.right.visitBy(this);
    if ( left is String ) {
      bindings.add(left);
    }
    if ( right is String ) {
      bindings.add(right);
    }
    return bindings;
  }
  @override
  visitMember(MemberExpression node) {
    dynamic obj = node.object.visitBy(this);
    return obj + '.' + node.property.visitBy(this);
  }
  @override
  String visitName(Name node) {
    return node.value;
  }
  @override
  visitNameExpression(NameExpression node) {
    return node.name.visitBy(this);
  }
  @override
  visitCall(CallExpression node) {
    if ( node.arguments != null ) {
      for ( Expression exp in node.arguments ) {
        dynamic rtn = exp.visitBy(this);
        if ( rtn is String ) {
          bindings.add(rtn);
        }
      }
    }
  }
  @override
  visitAssignment(AssignmentExpression node) {
    if ( node.right != null ) {
      dynamic rtn = node.right.visitBy(this);
      if ( rtn is String ) {
        bindings.add(rtn);
      }
    }
  }
  @override
  visitExpressionStatement(ExpressionStatement node) {
    dynamic rtn = node.expression.visitBy(this);
    if ( rtn is String ) {
      bindings.add(rtn);
    }
  }
  @override
  visitIndex(IndexExpression node, {bool computeAsPattern=false}) {
    dynamic obj = node.object.visitBy(this);
    dynamic prop;
    if ( node.property is LiteralExpression ) {
      prop = (node.property as LiteralExpression).value;
    }
    if ( obj is String ) {
      if ( prop is num ) {
        return obj + '['+prop.toString()+']';
      } else if ( prop is String ) {
        return obj + "['"+prop+"']";
      }
    }
  }

  @override
  visitConditional(ConditionalExpression node) {
    return node.condition.visitBy(this);
  }

  defaultNode(Node node) {
    dynamic rtn;
    node.forEach((node) {
      rtn = visit(node);
    });
    return rtn;
  }
}
class JSInterpreter extends RecursiveVisitor<dynamic> {
  late String code;
  late Program program;
  Map<Scope,Map<String,dynamic>> contexts= {};
  @override
  defaultNode(Node node) {
    dynamic rtn;
    node.forEach((node)=> rtn = visit(node));
    return rtn;
  }
  RegExp regExp(String regex,String options) {
    RegExp r =  RegExp(regex);
    return r;
  }
  void addGlobals(Map<String,dynamic> context) {
    context['regExp']= regExp;
    context['Math'] = InvokableMath();
    context['parseFloat'] = (String s) => double.parse(s);
    context['parseInt'] = (String s) => int.parse(s);
    context['parseDouble'] = (String s) => double.parse(s);
    context['JSON'] = JSON();
  }
  JSInterpreter(this.code, this.program, Map<String,dynamic> programContext) {
    contexts[program] = programContext;
    addGlobals(programContext);
  }
  JSInterpreter.fromCode(String code, Map<String,dynamic> programContext): this(code,parseCode(code),programContext);
  static Program parseCode(String code) {
    return parsejs(code);
  }
  static String toJSString(Map map) {
    int i = 0;
    Map placeHolders = {};
    String keyPrefix = '__ensemble_placeholder__';
    var encoded = jsonEncode(map, toEncodable: (value) {
      if (value is JavascriptFunction) {
        String key = keyPrefix + i.toString();
        placeHolders[key] = value.functionCode;
        i++;
        return key;
      }
      throw UnsupportedError('Cannot convert to JSON: $value');
    });
    placeHolders.forEach((key, value) {
      encoded = encoded.replaceFirst('\"$key\"', value);
    });
    return encoded;
  }
  Scope enclosingScope(Node node) {
    while (node is! Scope) {
      node = node.parent;
    }
    return node;
  }
  Map<String,dynamic> findProgramContext(Node node) {
    Scope scope = enclosingScope(node);
    while (scope is! Program) {
      scope = enclosingScope(scope.parent);
    }
    return getContextForScope(scope);
  }
  JSInterpreter cloneForContext(Scope scope,Map<String,dynamic> ctx,bool inheritContexts) {
    JSInterpreter i = JSInterpreter(this.code, this.program,getContextForScope(this.program));
    if ( inheritContexts ) {
      contexts.keys.forEach((key) {
        i.contexts[key] = contexts[key]!;
      });
    }
    i.contexts[scope] = ctx;
    return i;
  }
  Scope findScope(Name nameNode) {
    String name = nameNode.value;
    Node parent = nameNode.parent;
    Node node = nameNode;
    if (parent is FunctionNode && parent.name == node && !parent.isExpression) {
      node = parent.parent;
    }
    Scope scope = enclosingScope(node);
    while (scope is! Program) {
      if (scope.environment == null)
        throw "$scope does not have an environment";
      if (scope.environment.contains(name)) return scope;
      scope = enclosingScope(scope.parent);
    }
    return scope;
  }
  Map<String,dynamic> getContextForScope(Scope scope) {
    return contexts[scope]!;
  }
  void addToContext(Name node, dynamic value) {
    Map m = getContextForScope(node.scope);
    m[node.value] = value;
  }
  dynamic removeFromContext(Name node) {
    Map m = getContextForScope(node.scope);
    return m.remove(node.value);
  }
  dynamic getValueFromNode(Node node) {
    dynamic value = node.visitBy(this);
    if ( value is Name ) {
      value = getValue(value);
    } else if ( node is ThisExpression ) {
      value = getValueFromString(value);
    }
    return value;
  }
  dynamic getValueFromString(String name) {
    Map m = getContextForScope(program);
    if ( m.containsKey(name) ) {
      return m[name];
    }
    return null;
  }
  dynamic getValue(Name node) {
    Scope scope = findScope(node);
    Map m = getContextForScope(scope);
    return m[node.value];
  }
  evaluate({Node? node}) {
    dynamic rtn;
    try {
      if (node != null) {
        rtn = visit(node);
      } else {
        //first visit all the function declarations
        for ( int i=program.body.length-1;i>=0;i-- ) {
          Statement stmt = program.body[i];
          if ( stmt is FunctionDeclaration ) {
            stmt.visitBy(this);
          }
        }
        rtn = visit(program);
        if (rtn is Name) {
          rtn = getValue(rtn);
        }
      }
    } on ControlFlowReturnException catch(e) {
      rtn = e.returnValue;
    } catch (error) {
      throw Exception("Error: ${error.toString()} while executing $code");
    }
    return rtn;
  }
  dynamic executeConditional(Expression testExp,Node consequent,Node? alternate) {
    dynamic condition = testExp.visitBy(this);
    bool test = (condition != null && condition)?true:false;
    dynamic rtn;
    if ( test ) {
      rtn = consequent.visitBy(this);
    } else {
      if ( alternate != null ) {
        rtn = alternate.visitBy(this);
      }
    }
    return rtn;
  }
  @override
  visitThis(ThisExpression node) {
    return 'this';
  }
  @override
  visitConditional(ConditionalExpression node) {
    return executeConditional(node.condition,node.then,node.otherwise);
  }
  @override
  visitIf(IfStatement node) {
    return executeConditional(node.condition,node.then,node.otherwise);
  }
  @override
  visitProperty(Property node) {
    return {'key':getValueFromNode(node.key),'value':getValueFromNode(node.value)};
  }
  @override
  visitObject(ObjectExpression node) {
    Map obj = {};
    for ( Property property in node.properties ) {
      Map prop = visitProperty(property);
      obj[prop['key']] = prop['value'];
    }
    return obj;
  }
  @override
  visitReturn(ReturnStatement node) {
    dynamic returnValue;
    if ( node.argument != null ) {
      returnValue = getValueFromExpression(node.argument!);
    }
    throw ControlFlowReturnException(returnValue);
  }
  @override
  visitUnary(UnaryExpression node) {
    dynamic val = getValueFromNode(node.argument);
    switch(node.operator) {
      case '-': val = -1 * val;break;
      case 'typeof': val = val.runtimeType;break;
      case '!': val = !val;break;
      default: throw Exception(node.operator+" not yet implemented. stmt="+node.toString());
    }
    return val;
  }
  @override
  visitUpdateExpression(UpdateExpression node) {
    dynamic name = node.argument.visitBy(this);
    dynamic val = getValue(name);
    num number;
    if ( val is num ) {
      number = val;
    } else {
      throw Exception(
          'The operator ' + node.operator + ' is only valid for numbers and ' +
              node.argument.toString() + ' is not a number');
    }
    if ( node.isPrefix ) {
      switch (node.operator) {
        case '++': ++number;break;
        case '--': --number;break;
      }
    } else {
      switch (node.operator) {
        case '++': number++;break;
        case '--': number++;break;
      }
    }
    addToContext(name, number);
    return number;
  }
  @override
  visitFunctionDeclaration(FunctionDeclaration node) {
    JavascriptFunction? func = getValue(node.function.name);
    if ( func == null ) {
      addToContext(node.function.name, visitFunctionNode(node.function));
    }
    return func;
  }
  @override
  visitFunctionNode(FunctionNode node, {bool? inheritContext}) {
    final List<dynamic> args = computeArguments(node.params);
    return JavascriptFunction((List<dynamic>? _params) {
      /*
        1. create a map, parmValueMap
        2. go through params and create a args[i]: parm[i] entry in the map
        3. push the map to the context stack
        4. execute the blockstatement or expression
       */
      List<dynamic> params = _params??[];
      if ( args.length != params.length ) {
        throw Exception("visitFunctionNode: args.length ($args.length)  != params.length ($params.length). They must be equal. ");
      }
      Map<String,dynamic> ctx = {};
      if ( node.params != null ) {
        for (int i = 0; i < node.params.length; i++) {
          ctx[node.params[i].value] = params.elementAt(i);
        }
      }
      JSInterpreter i = cloneForContext(node,ctx,inheritContext??false);
      dynamic rtn;
      try {
        if (node.body != null) {
          rtn = node.body.visitBy(i);
        }
      } on ControlFlowReturnException catch(e) {
        rtn = e.returnValue;
      }
      if ( rtn is Node ) {
        rtn = i.getValueFromNode(rtn);
      }
      return rtn;
    },code!.substring(node.start,node.end));
  }
  @override
  visitFunctionExpression(FunctionExpression node) {
    return visitFunctionNode(node.function,inheritContext:true);
  }
  @override
  visitBlock(BlockStatement node) {
    dynamic rtn;
    for ( Node stmt in node.body ) {
      rtn = stmt.visitBy(this);
    }
    return rtn;
  }
  @override
  visitVariableDeclarator(VariableDeclarator node) {
    Name name = node.name;
    dynamic value;
    if ( node.init != null ) {
      value = node.init.visitBy(this);
    }
    addToContext(name,value);
  }
  @override
  visitBinary(BinaryExpression node) {
    dynamic left = getValueFromExpression(node.left);
    dynamic right = getValueFromExpression(node.right);
    dynamic rtn = false;
    if ( left is String || right is String ) {
      //let's say left is a string and right is an integer. Dart does not allow an operation like
      //concatenation on different types, javascript etc do allow that
      if ( left != null ) {
        left = left.toString();
      }
      if ( right != null ) {
        right = right.toString();
      }
    }
    bool done = true;
    switch (node.operator) {
      case '==': rtn = left == right;break;
      case '!=': rtn = left != right;break;
      case '<': rtn = left < right;break;
      case '<=': rtn = left <= right;break;
      case '>': rtn = left > right;break;
      case '>=': rtn = left >= right;break;
      case '-': rtn = left - right;break;
      case '+': rtn = left + right;break;
      case '/': rtn = left / right;break;
      case '*': rtn = left * right;break;
      case '%': rtn = left % right;break;
      case '|': rtn = left | right;break;
      case '^': rtn = left ^ right;break;
      case '<<': rtn = left << right;break;
      case '>>': rtn = left >> right;break;
      case '&': rtn = left & right;break;
      default: done = false;break;
    }
    if ( node.operator == '||' ) {
      if ( left == true || left != null ) {
        rtn = left;
      } else if ( right == true || right != null ) {
        rtn = right;
      } else if ( left == null || right == null ) {
        rtn = null;
      } else {
        rtn = false;
      }
      done = true;
    } else if ( node.operator == '&&' ) {
      if ( left == false || right == false ) {
        rtn = false;
      } else if ( left == null || right == null ) {
        rtn = null;
      } else {
        rtn = right;
      }
      done = true;
    }
    if ( !done ) {
      throw Exception(node.operator + ' is not yet supported');
    }
    return rtn;
  }
  @override
  visitBreak(BreakStatement node) {
    throw ControlFlowBreakException();
  }
  @override
  visitForIn(ForInStatement node) {
    dynamic right = getValueFromNode(node.right);
    dynamic left = node.left.visitBy(this);
    if ( right is! Map ) {
      throw Exception('for...in is only allowed for js objects or maps. $right is not a map');
    }
    if ( left is! Name ) {
      throw Exception('left side in the for...in expression must be a name node. $node.left is not name');
    }
    Map map = right;
    for ( dynamic key in map.keys ) {
      addToContext(left, key);
      try {
        node.body.visitBy(this);
      } on ControlFlowBreakException catch(e) {
        break;
      }
    }
    removeFromContext(left);
  }
  @override
  visitLiteral(LiteralExpression node) {
    Map<String,dynamic> programContext = findProgramContext(node);
    if ( node.value is String ) {
      Function? getStringFunc = programContext['getStringValue'];
      if (getStringFunc != null) {
        //this takes care of translating strings into different languages
        return Function.apply(getStringFunc, [node.value]);
      }
    }
    return node.value;
  }
  @override
  visitArray(ArrayExpression node) {
    List arr = [];
    node.forEach((node) {
      arr.add(node.visitBy(this));
    });
    return arr;
  }
  @override
  visitNameExpression(NameExpression node) {
    return node.name.visitBy(this);
  }
  List computeArguments(List<Node> args,{bool resolveNames=false}) {
    List l = [];
    for ( Node node in args ) {
      if ( resolveNames ) {
        if ( node is Expression ) {
          dynamic v = getValueFromExpression(node);
          if ( v is JavascriptFunction ) {
            l.add(v._onCall);
          } else {
            l.add(v);
          }
        } else if ( node is Name ) {
          l.add(getValue(node));
        }
      } else {
        l.add(node.visitBy(this));
      }
    }
    return l;
  }
  executeMethod(dynamic method,List<Expression> declaredArguments) {
    List<dynamic> arguments = computeArguments(declaredArguments,resolveNames:true);
    if ( method is Function ) {
      //functions being called from js to dart
      if (arguments.length == 0) {
        return Function.apply(method, null);
      } else {
        return Function.apply(method, arguments);
      }
    } else {
      if (arguments.length == 0) {
        return method();
      } else {
        return method(arguments);
      }
    }
  }
  @override
  visitCall(CallExpression node) {
    dynamic val;
    if ( node.callee is NameExpression ) {
      final method = getValue((node.callee as NameExpression).name);
      val = executeMethod(method, node.arguments);
    } else if ( node.callee is MemberExpression || node.callee is IndexExpression ) {
        ObjectPattern? pattern;
        dynamic method;
        if (node.callee is MemberExpression) {
          pattern = visitMember(
              node.callee as MemberExpression, computeAsPattern: true);
          method = InvokableController.methods(pattern!.obj)[pattern.property];
          //old: method = pattern!.obj.methods()[pattern.property];
        } else if ( node.callee is IndexExpression ) {
          pattern = visitIndex(
              node.callee as IndexExpression, computeAsPattern: true);
          method = InvokableController.getProperty(pattern!.obj,pattern.property);
          //old: method = pattern!.obj.getProperty(pattern.property);
        }
        if ( method == null ) {
          throw Exception("cannot compute statement="+node.toString()+" as no method found for property="+((pattern != null)?pattern.property.toString():''));
        }
        val = executeMethod(method, node.arguments);
      }
    return val;
  }
  @override
  visitAssignment(AssignmentExpression node) {
    dynamic val = getValueFromExpression(node.right);
    ObjectPattern? pattern;
    if ( node.left is MemberExpression ) {
      pattern = visitMember(node.left as MemberExpression, computeAsPattern: true);
    } else if ( node.left is IndexExpression ) {
      pattern = visitIndex(node.left as IndexExpression, computeAsPattern: true);
    }
    if ( pattern != null ) {
      var obj = pattern.obj;
      switch (node.operator) {
        case '=': InvokableController.setProperty(obj, pattern.property, val);break;
        case '+=': InvokableController.setProperty(obj,pattern.property, InvokableController.getProperty(obj,pattern.property) + val);break;
        case '-=': InvokableController.setProperty(obj,pattern.property, InvokableController.getProperty(obj,pattern.property) - val);break;
        case '*=': InvokableController.setProperty(obj,pattern.property, InvokableController.getProperty(obj,pattern.property) * val);break;
        case '/=': InvokableController.setProperty(obj,pattern.property, InvokableController.getProperty(obj,pattern.property) / val);break;
        case '%=': InvokableController.setProperty(obj,pattern.property, InvokableController.getProperty(obj,pattern.property) % val);break;
        case '<<=': InvokableController.setProperty(obj,pattern.property, InvokableController.getProperty(obj,pattern.property) << val);break;
        case '>>=': InvokableController.setProperty(obj,pattern.property, InvokableController.getProperty(obj,pattern.property) >> val);break;
        case '|=': InvokableController.setProperty(obj,pattern.property, InvokableController.getProperty(obj,pattern.property) | val);break;
        case '^=': InvokableController.setProperty(obj,pattern.property, InvokableController.getProperty(obj,pattern.property) ^ val);break;
        case '&=': InvokableController.setProperty(obj,pattern.property, InvokableController.getProperty(obj,pattern.property) & val);break;
        default: throw Exception(
            "AssignentOperator=" + node.operator + " in stmt=" +
                node.toString() + " is not yet supported");
      }
    } else if ( node.left is Name || node.left is NameExpression ) {
      Name n;
      if ( node.left is NameExpression ) {
        n = (node.left as NameExpression).name;
      } else {
        n = node.left as Name;
      }
      dynamic value = getValue(n);
      if ( value != null ) {
        switch(node.operator) {
          case '=': value = val;break;
          case '+=': value += val;break;
          case '-=': value -= val;break;
          case '*=': value *= val;break;
          case '/=': value /= val;break;
          case '%=': value %= val;break;
          case '<<=': value <<= val;break;
          case '>>=': value >>= val;break;
          case '|=': value |= val;break;
          case '^=': value ^= val;break;
          case '&=': value &= val;break;
          default: throw Exception(
              "AssignentOperator=" + node.operator + " in stmt=" +
                  node.toString() + " is not yet supported");
          }

        } else {
        value = val;
      }
      addToContext(n, value);
    }
  }
  @override
  visitRegexp(RegexpExpression node) {
    bool allMatches = false, dotAll = false, multiline = false, ignoreCase = false,unicode = false;

    int index = node.regexp.lastIndexOf('/');
    if ( index != -1 ) {
      String options = node.regexp.substring(index);
      if ( options.contains('i') ) {
        ignoreCase = true;
      }
      if ( options.contains('g') ) {
        allMatches = true;
      }
      if ( options.contains('m') ) {
        multiline = true;
      }
      if ( options.contains('s') ) {
        dotAll = true;
      }
      if ( options.contains('u') ) {
        unicode = true;
      }
    }
    return RegExp(node.regexp.substring(0,index).replaceAll('/', ''),
        multiLine: multiline,
        caseSensitive: !ignoreCase,
        dotAll: dotAll,
        unicode: unicode
    );
  }



  @override
  visitIndex(IndexExpression node, {bool computeAsPattern=false}) {
    return visitObjectPropertyExpression(node.object,getValueFromExpression(node.property),computeAsPattern: computeAsPattern);
  }
  visitObjectPropertyExpression(Expression object, dynamic property, {bool computeAsPattern=false}) {
    dynamic obj = getValueFromExpression(object);
    dynamic val;
    if ( computeAsPattern ) {
      val = ObjectPattern(obj, property);
    } else {
      val = InvokableController.getProperty(obj, property);
      //old: val = obj.getProperty(property);
    }
    return val;
  }
  @override
  visitMember(MemberExpression node, {bool computeAsPattern=false}) {
    return visitObjectPropertyExpression(node.object,node.property.value,computeAsPattern: computeAsPattern);
  }
  @override
  visitName(Name node) {
    return node;
  }
  dynamic getValueFromExpression(Expression exp) {
    return getValueFromNode(exp);
  }
  noSuchMethod(Invocation invocation) {
    if (!invocation.isMethod || invocation.namedArguments.isNotEmpty)
      super.noSuchMethod(invocation);
    final arguments = invocation.positionalArguments;
    return null;
  }
}
enum BinaryOperator {
  equals,lt,gt,ltEquals,gtEquals,notequals,minus,plus,multiply,divide,inop,instaneof
}
enum AssignmentOperator {
  equal,plusEqual,minusEqual
}
enum LogicalOperator {
  or,and,not
}
enum UnaryOperator {
  minus,plus,not,typeof,voidop
}
enum VariableDeclarationKind {
  constant,let,variable
}
class ControlFlowReturnException implements Exception {
  dynamic returnValue;
  ControlFlowReturnException(this.returnValue);
}
class ControlFlowBreakException implements Exception {
}
class ObjectPattern {
  Object obj;
  dynamic property;
  ObjectPattern(this.obj,this.property);
}
typedef OnCall = dynamic Function(List arguments);
class JavascriptFunction {
  JavascriptFunction(this._onCall,this.functionCode);

  final OnCall _onCall;
  final String functionCode;

  noSuchMethod(Invocation invocation) {
    if (!invocation.isMethod || invocation.namedArguments.isNotEmpty)
      super.noSuchMethod(invocation);
    final arguments = invocation.positionalArguments;
    if ( arguments.length > 0 ) {
      return _onCall(arguments[0]);
    } else {
      return _onCall(arguments);
    }
  }
}