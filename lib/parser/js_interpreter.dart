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
class Interpreter implements JSASTVisitor {
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
      return visitExpression(stmt.expression as Expression);
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
  @override
  void visitAssignmentExpression(AssignmentExpression stmt) {
    dynamic val = visitExpression(stmt.right);
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
      upsertValue(name, val);
    }
  }
  @override
  void visitIfStatement(IfStatement stmt) {
    dynamic rtn = visitExpression(stmt.test as Expression);
    bool test = (rtn)?true:false;
   /* if ( stmt.test is! BooleanExpression ) {
      dynamic rtn = visitExpression(stmt.test as Expression);
      throw Exception('only boolean expression is supported as test for if stmt '+stmt.toString());
    }
    bool test = evaluateBooleanExpression(stmt.test as BooleanExpression);

    */
    if ( test ) {
      stmt.consequent.accept(this);
    } else {
      if ( stmt.alternate != null ) {
        stmt.alternate!.accept(this);
      }
    }
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
    dynamic left = visitExpression(stmt.left);
    bool rtn = false;
    if ( stmt.op == LogicalOperator.and ) {
      if ( !left ) {
        rtn = left;
      } else {
        dynamic right = visitExpression(stmt.right);
        rtn = left && right;
      }
    } else if ( stmt.op == LogicalOperator.or ) {
      bool right = visitExpression(stmt.right);
      rtn = left || right;
    } else {
      throw Exception('unrecognized operator:'+stmt.op.toString()+' in expression '+stmt.toString());
    }
    return rtn;
  }
  @override
  dynamic visitBinaryExpression(BinaryExpression stmt) {
    dynamic left = visitExpression(stmt.left);
    dynamic right = visitExpression(stmt.right);
    dynamic rtn = false;
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
    return stmt.value;
  }
  @override
  dynamic visitIdentifier(Identifier stmt) {
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

  @override
  dynamic visitMemberExpression(MemberExpr stmt, {bool computeAsPattern=false}) {
    var exp = visitExpression(stmt.object);
    dynamic obj;
    if ( stmt.object is MemberExpr || stmt.object is CallExpression ) {
      //like c.value.indexOf. The c.value is a memberexp that then has the indexOf called on it
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
    } else {
      obj = getValue(exp);
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
  dynamic computeArguments(List<ASTNode> args) {
    List l = [];
    for ( var stmt in args ) {
      l.add(visitExpression(stmt as Expression));
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
      if ( method != null ) {
        val = Function.apply(method, computeArguments(stmt.arguments));
      } else {
        throw Exception("cannot compute statement="+stmt.toString()+" as no method found for property="+pattern.property.toString());
      }
      return val;
    }

  }

  @override
  dynamic visitExpression(Expression stmt) {
    if ( stmt is BinaryExpression ) {
      return visitBinaryExpression(stmt);
    } else if ( stmt is LogicalExpression ) {
      return visitLogicalExpression(stmt);
    } else if ( stmt is CallExpression ) {
      return visitCallExpression(stmt);
    } else if ( stmt is MemberExpr ) {
      return visitMemberExpression(stmt);
    } else if ( stmt is AssignmentExpression ) {
      return visitAssignmentExpression(stmt);
    } else if ( stmt is Identifier ) {
      return visitIdentifier(stmt);
    } else if ( stmt is Literal ) {
      return visitLiteral(stmt);
    } else if ( stmt is UnaryExpression ) {
      return visitUnaryExpression(stmt);
    } else if ( stmt is ArrowFunctionExpression ) {
      return visitArrowFunctionExpression(stmt);
    } else if (stmt is ThisExpr) {
      return visitThisExpression(stmt);
    } else {
      throw Exception("This type of expression is not currently supported. Expression="+stmt.toString());
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
      if ( stmt.blockStmt != null ) {
        rtn = i.visitBlockStatement(stmt.blockStmt!);
      } else {
        rtn = i.visitExpression(stmt.expression!);
      }
      return rtn;
    };
  }
}
class ObjectPattern {
  Invokable obj;
  dynamic property;
  ObjectPattern(this.obj,this.property);
}
