
import 'package:ensemble_ts_interpreter/invokables/invokable.dart';
import 'package:ensemble_ts_interpreter/invokables/invokablelist.dart';
import 'package:ensemble_ts_interpreter/invokables/invokablemap.dart';
import 'package:ensemble_ts_interpreter/invokables/invokableprimitives.dart';
import 'package:jsparser/jsparser.dart';
import 'package:jsparser/src/ast.dart';
import 'package:jsparser/src/lexer.dart';
import 'package:jsparser/src/parser.dart';
import 'package:jsparser/src/annotations.dart';
import 'package:jsparser/src/noise.dart';

import 'package:jsparser/src/ast.dart';

class JSInterpreter extends RecursiveVisitor<dynamic> {
  Program program;
  Map<Scope,Map<String,dynamic>> contexts= {};
  @override
  defaultNode(Node node) {
    dynamic rtn;
    node.forEach((node)=> rtn = visit(node));
    return rtn;
  }
  JSInterpreter(this.program, Map<String,dynamic> programContext) {
    contexts[program] = programContext;
  }
  JSInterpreter.fromCode(String code, Map<String,dynamic> programContext): this(parsejs(code),programContext);

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
  JSInterpreter cloneForContext(Scope scope,Map<String,dynamic> ctx) {
    JSInterpreter i = JSInterpreter(this.program,getContextForScope(this.program));
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
  dynamic getValueFromNode(Node node) {
    dynamic value = node.visitBy(this);
    if ( value is Name || node is ThisExpression ) {
      value = getValue(value);
    }
    return value;
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
        dynamic rtn = visit(program);
        if (rtn is Name) {
          rtn = getValue(rtn);
        }
      }
    } on ControlFlowReturnException catch(e) {
      rtn = e.returnValue;
    }
    return rtn;
  }
  dynamic executeConditional(Expression testExp,Node consequent,Node? alternate) {
    dynamic condition = testExp.visitBy(this);
    bool test = (condition)?true:false;
    /* if ( stmt.test is! BooleanExpression ) {
      dynamic rtn = visitExpression(stmt.test as Expression);
      throw Exception('only boolean expression is supported as test for if stmt '+stmt.toString());
    }
    bool test = evaluateBooleanExpression(stmt.test as BooleanExpression);

    */
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
  visitFunctionExpression(FunctionExpression node) {
    final List<dynamic> args = computeArguments(node.function.params);
    return (List<dynamic> params) {
      /*
        1. create a map, parmValueMap
        2. go through params and create a args[i]: parm[i] entry in the map
        3. push the map to the context stack
        4. execute the blockstatement or expression
       */
      if ( args.length != params.length ) {
        throw Exception("visitFunctionExpression: args.length != params.length. They must be equal");
      }
      Map<String,dynamic> ctx = {};
      if ( node.function.params != null ) {
        for (int i = 0; i < node.function.params.length; i++) {
          ctx[node.function.params[i].value] = params.elementAt(i);
        }
      }
      JSInterpreter i = cloneForContext(node.function,ctx);
      dynamic rtn;
      try {
        if (node.function.body != null) {
          rtn = node.function.body.visitBy(i);
        }
      } on ControlFlowReturnException catch(e) {
        rtn = e.returnValue;
      }
      if ( rtn is Node ) {
        rtn = i.getValueFromNode(rtn);
      }
      return rtn;
    };
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
  visitFunctionNode(FunctionNode node) {
    // TODO: implement visitFunctionNode
    return super.visitFunctionNode(node);
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
      left = left.toString();
      right = right.toString();
    }
    switch (node.operator) {
      case '==': rtn = left == right;break;
      case '!=': rtn = left != right;break;
      case '<': rtn = left < right;break;
      case '<=': rtn = left <= right;break;
      case '>': rtn = left > right;break;
      case '>=': rtn = left >= right;break;
      case '-': rtn = left - right;break;
      case '+': rtn = left + right;break;
      default: throw Exception(node.operator + ' is not yet supported');
    }
    return rtn;
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
          l.add(getValueFromExpression(node));
        } else if ( node is Name ) {
          l.add(getValue(node));
        }
      } else {
        l.add(node.visitBy(this));
      }
    }
    return l;
  }
  @override
  visitCall(CallExpression node) {
    dynamic val;
    if ( node.callee is MemberExpression ) {
      ObjectPattern pattern = visitMember(node.callee as MemberExpression,computeAsPattern:true);
      var obj = pattern.obj;
      Function? method = obj.methods()[pattern.property];
      List? arguments = computeArguments(node.arguments,resolveNames:true);
      if ( method != null ) {
        val = Function.apply(method, arguments);
      } else {
        throw Exception("cannot compute statement="+node.toString()+" as no method found for property="+pattern.property.toString());
      }
      return val;
    }
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
        case '=': obj.setProperty(pattern.property, val);break;
        case '+=': obj.setProperty(pattern.property, obj.getProperty(pattern.property) + val);break;
        case '-=': obj.setProperty(pattern.property, obj.getProperty(pattern.property) - val);break;
        case '*=': obj.setProperty(pattern.property, obj.getProperty(pattern.property) * val);break;
        case '/=': obj.setProperty(pattern.property, obj.getProperty(pattern.property) / val);break;
        case '%=': obj.setProperty(pattern.property, obj.getProperty(pattern.property) % val);break;
        case '<<=': obj.setProperty(pattern.property, obj.getProperty(pattern.property) << val);break;
        case '>>=': obj.setProperty(pattern.property, obj.getProperty(pattern.property) >> val);break;
        case '|=': obj.setProperty(pattern.property, obj.getProperty(pattern.property) | val);break;
        case '^=': obj.setProperty(pattern.property, obj.getProperty(pattern.property) ^ val);break;
        case '&=': obj.setProperty(pattern.property, obj.getProperty(pattern.property) & val);break;
        default: throw Exception(
            "AssignentOperator=" + node.operator + " in stmt=" +
                node.toString() + " is not yet supported");break;
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
                  node.toString() + " is not yet supported");break;
          }

        } else {
        value = val;
      }
      addToContext(n, value);
    }
  }
  @override
  visitIndex(IndexExpression node, {bool computeAsPattern=false}) {
    return visitObjectPropertyExpression(node.object,getValueFromExpression(node.property),computeAsPattern: computeAsPattern);
  }
  visitObjectPropertyExpression(Expression object, dynamic property, {bool computeAsPattern=false}) {
    var exp = getValueFromExpression(object);
    dynamic obj;
    if (InvokablePrimitive.isPrimitive(exp)) {
      obj = InvokablePrimitive.getPrimitive(exp);
    } else if (exp is Invokable) {
      obj = exp;
    } else if (exp is Map) {
      obj = InvokableMap(exp);
    } else if ( exp is List ) {
      obj = InvokableList(exp);
    } else {
      throw Exception('unable to compute obj='+object.toString()+' for expression='+object.parent.toString());
    }
    if ( obj is Map ) {
      obj = InvokableMap(obj);
    } else if ( obj is List ) {
      obj = InvokableList(obj);
    }
    if ( obj is! Invokable ) {
      throw Exception("unknown object.; obj must be of type Invokable but is "+obj.toString());
    }
    dynamic val;
    if ( computeAsPattern ) {
      val = ObjectPattern(obj, property);
    } else {
      val = obj.getProperty(property);
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
class ObjectPattern {
  Invokable obj;
  dynamic property;
  ObjectPattern(this.obj,this.property);
}