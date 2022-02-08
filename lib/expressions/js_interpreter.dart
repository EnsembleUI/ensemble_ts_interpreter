import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'ast.dart';
import 'package:sdui/extensions.dart';

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
    if ( stmt.expression is AssignmentExpression ) {
      visitAssignmentExpression(stmt.expression as AssignmentExpression);
    }
  }
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
  @override
  void visitAssignmentExpression(AssignmentExpression stmt) {
    dynamic val = compute(stmt.right);
    if ( stmt.left is MemberExpr ) {
      MemberExpr exp = stmt.left as MemberExpr;
      var obj = context[exp.object];
      if ( obj is Widget ) {
        (obj as Widget).setProperty(exp.property,val);
      } else {
        obj[exp.property] = val;
      }
    } else if ( stmt.left is Identifier ) {
      context[(stmt.left as Identifier).name] = val;
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
      rtn = visitLogicalExpression(stmt as LogicalExpression);
    } else if ( stmt is BinaryExpression ) {
      rtn = visitBinaryExpression(stmt as BinaryExpression);
    } else {
      throw Exception(stmt.toString()+' is an unsupported boolean expression');
    }
    return rtn;
  }
  @override
  bool visitLogicalExpression(LogicalExpression stmt) {
    bool left = evaluateBooleanExpression(stmt.left);
    bool rtn = false;
    if ( stmt.op == Operator.and ) {
      if ( !left ) {
        rtn = left;
      } else {
        bool right = evaluateBooleanExpression(stmt.right);
        rtn = left && right;
      }
    } else if ( stmt.op == Operator.or ) {
      bool right = evaluateBooleanExpression(stmt.right);
      rtn = left || right;
    } else {
      throw Exception('unrecognized operator:'+stmt.op.toString()+' in expression '+stmt.toString());
    }
    return rtn;
  }
  @override
  bool visitBinaryExpression(BinaryExpression stmt) {
    dynamic left = compute(stmt.left);
    dynamic right = compute(stmt.right);
    bool rtn = false;
    if ( stmt.op == Operator.equals ) {
      rtn = left == right;
    } else if ( stmt.op == Operator.lt ) {
      rtn = left < right;
    } else if ( stmt.op == Operator.ltEquals ) {
      rtn = left <= right;
    } else if ( stmt.op == Operator.gt ) {
      rtn = left > right;
    } else if ( stmt.op == Operator.gtEquals ) {
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
    return context[stmt.name];
  }
  @override
  void visitBlockStatement(BlockStatement stmt) {
    stmt.statements.forEach((statement) {
      statement.accept(this);
    });
  }
  @override
  dynamic visitMemberExpression(MemberExpr stmt) {
    var obj = context[stmt.object];
    dynamic val;
    if ( obj is Widget ) {
      val = (obj as Widget).getProperty(stmt.property);
    } else {
      val = obj[stmt.property];
    }
    return val;
  }
}
