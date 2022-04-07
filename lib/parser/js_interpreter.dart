import 'package:sdui/invokables/invokable.dart';
import 'package:sdui/invokables/invokableprimitives.dart';
import 'ast.dart';

class Interpreter implements JSASTVisitor {
  Map context;
  Interpreter(this.context);
  void evaluate(List<ASTNode> json) {
    for (ASTNode node in json) {
      node.accept(this);
    }
  }
  @override
  void visitExpressionStatement(ExpressionStatement stmt) {
    if ( stmt.expression is Expression ) {
      visitExpression(stmt.expression as Expression);
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
      if ( stmt.op != AssignmentOperator.equal ) {
        throw Exception("AssignentOperator="+stmt.op.toString()+" in stmt="+stmt.toString()+" is not yet supported");
      }
      if ( obj is Invokable ) {
        obj.set(pattern.property, val);
      }
    } else if ( stmt.left is Identifier ) {
      String name = visitIdentifier(stmt.left as Identifier);
      context[name] = val;
    }
  }
  @override
  void visitIfStatement(IfStatement stmt) {
    if ( stmt.test is! BooleanExpression ) {
      throw Exception('only boolean expression is supported as test for if stmt '+stmt.toString());
    }
    bool test = evaluateBooleanExpression(stmt.test as BooleanExpression);
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
  bool visitBinaryExpression(BinaryExpression stmt) {
    dynamic left = visitExpression(stmt.left);
    dynamic right = visitExpression(stmt.right);
    bool rtn = false;
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
  void visitBlockStatement(BlockStatement stmt) {
    for ( var statement in stmt.statements ) {
      statement.accept(this);
    }
  }
  @override
  dynamic visitMemberExpression(MemberExpr stmt, {bool computeAsPattern=false}) {
    var exp = visitExpression(stmt.object);
    dynamic obj;
    if ( stmt.object is MemberExpr ) {
      //like c.value.indexOf. The c.value is a memberexp that then has the indexOf called on it
      if ( InvokablePrimitive.isPrimitive(exp) ) {
        obj = InvokablePrimitive.getPrimitive(exp);
      } else if ( exp is Invokable ) {
        obj = exp;
      } else {
        throw Exception('unable to compute obj='+stmt.object.toString()+' for member expression='+stmt.toString());
      }
    } else {
      obj = context[exp];
    }
    dynamic val;
    var property = visitExpression(stmt.property);
    if ( obj is! Invokable ) {
      throw Exception("unknown object.; obj must be of type Invokable but is "+obj.toString());
    }
    if ( computeAsPattern ) {
      val = ObjectPattern(obj, property);
    } else {
      val = obj.get(property);
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
    } else {
      throw Exception(stmt.op.toString()+" not yet implemented. stmt="+stmt.toString());
    }
    return val;
  }
}
class ObjectPattern {
  Invokable obj;
  String property;
  ObjectPattern(this.obj,this.property);
}
