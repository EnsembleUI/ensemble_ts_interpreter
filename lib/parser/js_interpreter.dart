import 'package:ensemble_ts_interpreter/invokables/invokable.dart';
import 'package:ensemble_ts_interpreter/invokables/invokablelist.dart';
import 'package:ensemble_ts_interpreter/invokables/invokablemap.dart';
import 'package:ensemble_ts_interpreter/invokables/invokableprimitives.dart';
import 'ast.dart';
class Stack<E> {
  final _list = <E>[];
  void push(E value) => _list.add(value);
  E pop() => _list.removeLast();
  E get peek => _list.last;
  bool get isEmpty => _list.isEmpty;
  bool get isNotEmpty => _list.isNotEmpty;
  int get length => _list.length;
  @override
  String toString() => _list.toString();
}
class Interpreter extends JSASTVisitor {
  Stack<Map> contexts = Stack();
  Interpreter(Map globalContext) {
    contexts.push(globalContext);
  }
  Interpreter cloneForContext(Map context) {
    Interpreter i = Interpreter(contexts._list.first);
    i.pushContext(context);
    return i;
  }
  void pushContext(Map context) {
    contexts.push(context);
  }
  Map popContext() {
    return contexts.pop();
  }
  Map? findContext(String name) {
    //go in reverse order looking for the name
    for ( var i=contexts.length-1;i>=0;i-- ) {
      if ( contexts._list.elementAt(i).containsKey(name) ) {
        return contexts._list.elementAt(i);
      }
    }
    return null;
  }
  void insertValue(String name,dynamic value) {
    Map context = contexts.peek;
    if ( context.containsKey(name) ) {
      throw Exception('A key with name='+name+' already exists in this context');
    }
    context[name] = value;
  }
  //insert or update
  void upsertValue(String name,dynamic value) {
    Map? m = findContext(name);
    if ( m != null ) {
      m[name] = value;
    } else {
      contexts.peek[name] = value;
    }
  }
  dynamic getValue(String name) {
    Map? m = findContext(name);
    if ( m != null ) {
      return m[name];
    }
    return null;
  }
  dynamic evaluate(List<ASTNode> json) {
    dynamic rtnValue;
    for (ASTNode node in json) {
      rtnValue = node.accept(this);
    }
    return rtnValue;
  }
  @override
  dynamic visitExpressionStatement(ExpressionStatement stmt) {
    if ( stmt.expression is Expression ) {
      return getValueFromExpression(stmt.expression as Expression);
    } else {
      throw Exception("Statements other than Expressions not yet implemented for ExpressionStatement. stmt="+stmt.expression.toString());
    }
  }
  /*
  dynamic compute(ASTNode node) {
    dynamic val;
    if ( node is MemberExpr ) {
      val = visitMemberExpression(node as MemberExpr);
    } else if ( node is Literal ) {
      val = visitLiteral(node as Literal);
    } else if ( node is Identifier ) {
      val = visitIdentifier(node as Identifier);
    }
    return val;
  }
   */
  dynamic getValueFromExpression(Expression exp) {
    dynamic val = visitExpression(exp);
    if ( exp is Identifier || exp is ThisExpr ) {
      //not a literal, need to get it from context
      val = getValue(val);
    }
    return val;
  }
  @override
  void visitAssignmentExpression(AssignmentExpression stmt) {
    dynamic val = getValueFromExpression(stmt.right);
    if ( stmt.left is MemberExpr ) {
      ObjectPattern pattern = visitMemberExpression(stmt.left as MemberExpr,computeAsPattern: true);
      var obj = pattern.obj;
      if ( stmt.op == AssignmentOperator.equal ) {
        obj.setProperty(pattern.property, val);
      } else if ( stmt.op == AssignmentOperator.plusEqual ) {
        obj.setProperty(pattern.property, obj.getProperty(pattern.property) + val);
      } else if ( stmt.op == AssignmentOperator.minusEqual ) {
        obj.setProperty(pattern.property, obj.getProperty(pattern.property) - val);
      } else {
        throw Exception("AssignentOperator="+stmt.op.toString()+" in stmt="+stmt.toString()+" is not yet supported");
      }
    } else if ( stmt.left is Identifier ) {
      String name = visitIdentifier(stmt.left as Identifier);
      dynamic value = getValue(name);
      if ( value != null ) {
        if ( stmt.op == AssignmentOperator.equal ) {
          value = val;
        } else if ( stmt.op == AssignmentOperator.plusEqual ) {
          value += val;
        } else if ( stmt.op == AssignmentOperator.minusEqual ) {
          value -= val;
        } else {
          throw Exception("AssignentOperator="+stmt.op.toString()+" in stmt="+stmt.toString()+" is not yet supported");
        }
      } else {
        value = val;
      }
      upsertValue(name, value);
    }
  }
  dynamic executeConditional(Expression testExp,ASTNode consequent,ASTNode? alternate) {
    dynamic condition = visitExpression(testExp);
    bool test = (condition)?true:false;
    /* if ( stmt.test is! BooleanExpression ) {
      dynamic rtn = visitExpression(stmt.test as Expression);
      throw Exception('only boolean expression is supported as test for if stmt '+stmt.toString());
    }
    bool test = evaluateBooleanExpression(stmt.test as BooleanExpression);

    */
    dynamic rtn;
    if ( test ) {
      rtn = consequent.accept(this);
    } else {
      if ( alternate != null ) {
        rtn = alternate.accept(this);
      }
    }
    return rtn;
  }
  @override
  dynamic visitConditionalExpression(ConditionalExpression stmt) {
    return executeConditional(stmt.test,stmt.consequent,stmt.alternate);
  }
  @override
  dynamic visitIfStatement(IfStatement stmt) {
    return executeConditional(stmt.test as Expression,stmt.consequent,stmt.alternate);
  }
  bool evaluateBooleanExpression(BooleanExpression stmt) {
    bool rtn = false;
    if ( stmt is LogicalExpression ) {
      rtn = visitLogicalExpression(stmt);
    } else if ( stmt is BinaryExpression ) {
      rtn = visitBinaryExpression(stmt);
    } else {
      throw Exception(stmt.toString()+' is an unsupported boolean expression');
    }
    return rtn;
  }
  @override
  bool visitLogicalExpression(LogicalExpression stmt) {
    dynamic left = getValueFromExpression(stmt.left);
    bool rtn = false;
    if ( stmt.op == LogicalOperator.and ) {
      if ( !left ) {
        rtn = left;
      } else {
        dynamic right = getValueFromExpression(stmt.right);
        rtn = left && right;
      }
    } else if ( stmt.op == LogicalOperator.or ) {
      bool right = getValueFromExpression(stmt.right);
      rtn = left || right;
    } else {
      throw Exception('unrecognized operator:'+stmt.op.toString()+' in expression '+stmt.toString());
    }
    return rtn;
  }
  @override
  dynamic visitBinaryExpression(BinaryExpression stmt) {
    dynamic left = getValueFromExpression(stmt.left);
    dynamic right = getValueFromExpression(stmt.right);
    dynamic rtn = false;
    if ( left is String || right is String ) {
      //let's say left is a string and right is an integer. Dart does not allow an operation like
      //concatenation on different types, javascript etc do allow that
      left = left.toString();
      right = right.toString();
    }
    if ( stmt.op == BinaryOperator.equals ) {
      rtn = left == right;
    } else if ( stmt.op == BinaryOperator.notequals) {
      rtn = left != right;
    } else if ( stmt.op == BinaryOperator.lt ) {
      rtn = left < right;
    } else if ( stmt.op == BinaryOperator.ltEquals ) {
      rtn = left <= right;
    } else if ( stmt.op == BinaryOperator.gt ) {
      rtn = left > right;
    } else if ( stmt.op == BinaryOperator.gtEquals ) {
      rtn = left >= right;
    } else if ( stmt.op == BinaryOperator.minus ) {
      rtn = left - right;
    } else if ( stmt.op == BinaryOperator.plus ) {
      rtn = left + right;
    } else {
      throw Exception(stmt.op.toString() + ' is not yet supported');
    }
    return rtn;
  }
  @override
  dynamic visitLiteral(Literal stmt) {
    if ( stmt.value is String ) {
      Function? getStringFunc = getValue('getStringValue');
      if (getStringFunc != null) {
        //this takes care of translating strings into different languages
        return Function.apply(getStringFunc, [stmt.value]);
      }
    }
    return stmt.value;
  }
  @override
  String visitIdentifier(Identifier stmt) {
    return stmt.name;
  }
  @override
  dynamic visitBlockStatement(BlockStatement stmt) {
    dynamic rtn;
    for ( var statement in stmt.statements ) {
      rtn = statement.accept(this);
    }
    return rtn;
  }
  @override
  dynamic visitThisExpression(ThisExpr stmt, {bool computeAsPattern=false}) {
    return "this";
  }
  Invokable? getInvokable(dynamic exp) {

  }
  @override
  dynamic visitMemberExpression(MemberExpr stmt, {bool computeAsPattern=false}) {
    var exp = getValueFromExpression(stmt.object);
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
      throw Exception('unable to compute obj='+stmt.object.toString()+' for member expression='+stmt.toString());
    }
    dynamic val;
    var property = visitExpression(stmt.property);
    if ( obj is Map ) {
      obj = InvokableMap(obj);
    } else if ( obj is List ) {
      obj = InvokableList(obj);
    }
    if ( obj is! Invokable ) {
      throw Exception("unknown object.; obj must be of type Invokable but is "+obj.toString());
    }
    if ( computeAsPattern ) {
      val = ObjectPattern(obj, property);
    } else {
      val = obj.getProperty(property);
    }
    return val;
  }
  dynamic computeArguments(List<ASTNode> args,{bool resolveIdentifiers=false}) {
    List l = [];
    for ( var stmt in args ) {
      if ( resolveIdentifiers ) {
        l.add(getValueFromExpression(stmt as Expression));
      } else {
        l.add(visitExpression(stmt as Expression));
      }
    }
    return l;
  }
  @override
  dynamic visitCallExpression(CallExpression stmt) {
    dynamic val;
    if ( stmt.callee is MemberExpr ) {
      ObjectPattern pattern = visitMemberExpression(stmt.callee as MemberExpr,computeAsPattern:true);
      var obj = pattern.obj;
      Function? method = obj.methods()[pattern.property];
      List? arguments = computeArguments(stmt.arguments,resolveIdentifiers:true);
      if ( method != null ) {
        val = Function.apply(method, arguments);
      } else {
        throw Exception("cannot compute statement="+stmt.toString()+" as no method found for property="+pattern.property.toString());
      }
      return val;
    }

  }


  @override
  dynamic visitUnaryExpression(UnaryExpression stmt) {
    dynamic val = visitExpression(stmt.argument);
    if ( stmt.op == UnaryOperator.minus ) {
      val = -1 * val;
    } else if ( stmt.op == UnaryOperator.typeof ) {
      val = val.runtimeType;
    } else if ( stmt.op == UnaryOperator.not ) {
      val = !val;
    } else {
      throw Exception(stmt.op.toString()+" not yet implemented. stmt="+stmt.toString());
    }
    return val;
  }

  @override
  Function visitArrowFunctionExpression(ArrowFunctionExpression stmt) {
    final List<dynamic> args = computeArguments(stmt.params);
    return (List<dynamic> params) {
      /*
        1. create a map, parmValueMap
        2. go through params and create a args[i]: parm[i] entry in the map
        3. push the map to the context stack
        4. execute the blockstatement or expression
       */
      if ( args.length != params.length ) {
        throw Exception("visitArrowFunctionExpression: args.length != params.length. They must be equal");
      }
      Map ctx = {};
      for ( int i=0;i<args.length;i++ ) {
        ctx[args.elementAt(i)] = params.elementAt(i);
      }
      Interpreter i = cloneForContext(ctx);
      dynamic rtn;
      try {
        if (stmt.blockStmt != null) {
          rtn = i.visitBlockStatement(stmt.blockStmt!);
        } else {
          rtn = i.visitExpression(stmt.expression!);
        }
      } on ControlFlowReturnException catch(e) {
        rtn = e.returnValue;
      }
      return rtn;
    };
  }

  @override
  void visitVariableDeclaration(VariableDeclaration stmt) {
    if ( stmt.kind == VariableDeclarationKind.constant ) {
      throw Exception('const variable declaration is not yet supported. Use let or var instead');
    }
    for ( VariableDeclarator decl in stmt.declarators ) {
      visitVariableDeclarator(decl);
    }
  }

  @override
  void visitVariableDeclarator(VariableDeclarator decl) {
    String name = visitIdentifier(decl.id);
    dynamic value;
    if (decl.init != null) {
      value = getValueFromExpression(decl.init!);
    }
    insertValue(name, value);
  }

  @override
  visitArrayExpression(ArrayExpression stmt) {
    List arr = [];
    for ( Expression obj in stmt.arr ) {
      arr.add(getValueFromExpression(obj));
    }
    return arr;
  }

  @override
  Map visitObjectExpression(ObjectExpr stmt) {
    Map obj = {};
    for ( Property property in stmt.properties ) {
      Map prop = visitProperty(property);
      obj[prop['key']] = prop['value'];
    }
    return obj;
  }

  @override
  Map visitProperty(Property stmt) {
    return {
      'key':getValueFromExpression(stmt.key),
      'value':getValueFromExpression(stmt.value)
    };
  }

  @override
  visitReturnStatement(ReturnStatement stmt) {
    dynamic returnValue;
    if ( stmt.argument != null ) {
      returnValue = getValueFromExpression(stmt.argument!);
    }
    throw ControlFlowReturnException(returnValue);
  }

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
