abstract class JSASTVisitor {
  void visitExpressionStatement(ExpressionStatement stmt);
  void visitAssignmentExpression(AssignmentExpression stmt);
  dynamic visitThisExpression(ThisExpr stmt);
  dynamic visitMemberExpression(MemberExpr stmt);
  dynamic visitExpression(Expression stmt);
  void visitIfStatement(IfStatement stmt);
  dynamic visitBinaryExpression(BinaryExpression stmt);
  bool visitLogicalExpression(LogicalExpression stmt);
  dynamic visitUnaryExpression(UnaryExpression stmt);
  dynamic visitLiteral(Literal stmt);
  dynamic visitIdentifier(Identifier stmt);
  dynamic visitBlockStatement(BlockStatement stmt);
  dynamic visitCallExpression(CallExpression stmt);
  Function visitArrowFunctionExpression(ArrowFunctionExpression stmt);
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
abstract class ASTNode {
  dynamic accept(JSASTVisitor visitor);
}
class IfStatement implements ASTNode {
  ASTNode test,consequent;
  ASTNode? alternate;
  IfStatement(this.test,this.consequent,this.alternate);
  static IfStatement fromJson(var jsonNode,ASTBuilder builder) {
    return IfStatement(builder.buildNode(jsonNode['test']),
        builder.buildNode(jsonNode['consequent']),
        (jsonNode['alternate']!=null)?builder.buildNode(jsonNode['alternate']):null
      );
  }
  @override
  void accept(JSASTVisitor visitor) {
    visitor.visitIfStatement(this);
  }
}
class BlockStatement implements ASTNode {
  List<ASTNode> statements;
  BlockStatement(this.statements);
  static BlockStatement fromJson(var jsonNode,ASTBuilder builder) {
    List<ASTNode> nodes = [];
    List stmts = jsonNode['body'];
    stmts.forEach((node) {
      nodes.add(builder.buildNode(node));
    });
    return BlockStatement(nodes);
  }
  @override
  void accept(JSASTVisitor visitor) {
    visitor.visitBlockStatement(this);
  }
}
abstract class Expression extends ASTNode {}
abstract class BooleanExpression extends Expression {}
class UnaryExpression implements Expression {
  Expression argument;
  UnaryOperator op;
  UnaryExpression(this.argument,this.op);
  static UnaryExpression fromJson(var jsonNode,ASTBuilder builder) {
    String operator = jsonNode['operator'];
    UnaryOperator? op;
    if ( operator == '-' ) {
      op = UnaryOperator.minus;
    } else if ( operator == '+' ) {
      op = UnaryOperator.plus;
    } else if ( operator == '!' ) {
      op = UnaryOperator.not;
    } else if ( operator == 'typeof' ) {
      op = UnaryOperator.typeof;
    } else if ( operator == 'void' ) {
      op = UnaryOperator.voidop;
    } else {
      Exception(operator+' is not yet supported');
    }
    return UnaryExpression(builder.buildNode(jsonNode['argument']) as Expression, op!);
  }

  @override
  dynamic accept(JSASTVisitor visitor) {
    return visitor.visitUnaryExpression(this);
  }

}

class BinaryExpression implements BooleanExpression {
  Expression left,right;
  BinaryOperator op;
  BinaryExpression(this.left,this.op,this.right);
  static BinaryExpression fromJson(var jsonNode,ASTBuilder builder) {
    String operator = jsonNode['operator'];
    BinaryOperator? op;
    if ( operator == '==' ) {
      op = BinaryOperator.equals;
    } else if ( operator == '<' ) {
      op = BinaryOperator.lt;
    } else if ( operator == '<=' ) {
      op = BinaryOperator.ltEquals;
    } else if ( operator == '>' ) {
      op = BinaryOperator.gt;
    } else if ( operator == '<=' ) {
      op = BinaryOperator.gtEquals;
    } else if ( operator == '!=' ) {
      op = BinaryOperator.notequals;
    } else if ( operator == '-' ) {
      op = BinaryOperator.minus;
    } else if ( operator == '+' ) {
      op = BinaryOperator.plus;
    } else if ( operator == '*' ) {
      op = BinaryOperator.multiply;
    } else if ( operator == '/' ) {
      op = BinaryOperator.divide;
    } else {
      Exception(operator+' is not yet supported');
    }
    return BinaryExpression(builder.buildNode(jsonNode['left']) as Expression,
        op!,
        builder.buildNode(jsonNode['right']) as Expression
    );
  }
  @override
  dynamic accept(JSASTVisitor visitor) {
    return visitor.visitBinaryExpression(this);
  }
}
class ArrowFunctionExpression implements Expression {
  BlockStatement? blockStmt;
  Expression? expression;
  List<ASTNode> params;
  ArrowFunctionExpression(this.blockStmt,this.expression,this.params);
  static ArrowFunctionExpression fromJson(var jsonNode,ASTBuilder builder) {
    List<ASTNode> params = builder.buildArray(jsonNode['params']);
    BlockStatement? blockStmt;
    Expression? expression;
    if ( jsonNode['body']['type'] == 'BlockStatement' ) {
      blockStmt = builder.buildNode(jsonNode['body']) as BlockStatement;
    } else {
      expression = builder.buildNode(jsonNode['body']) as Expression;
    }
    return ArrowFunctionExpression(blockStmt,expression,params);
  }
  @override
  accept(JSASTVisitor visitor) {
    visitor.visitArrowFunctionExpression(this);
  }

}
//http://160.16.109.33/github.com/mason-lang/esast/class/src/ast.js~CallExpression.html
class CallExpression implements Expression {
  Expression callee;
  List<ASTNode> arguments;
  CallExpression(this.callee,this.arguments);
  static CallExpression fromJson(var jsonNode,ASTBuilder builder) {
    Expression callee = builder.buildNode(jsonNode['callee']) as Expression;
    return CallExpression(callee, builder.buildArray(jsonNode['arguments']));
  }
  @override
  dynamic accept(JSASTVisitor visitor) {
    return visitor.visitCallExpression(this);
  }
}
class LogicalExpression implements BooleanExpression {
  Expression left,right;
  LogicalOperator op;
  LogicalExpression(this.left,this.op,this.right);
  static LogicalExpression fromJson(var jsonNode,ASTBuilder builder) {
    String operator = jsonNode['operator'];
    LogicalOperator? op;
    if ( operator == '&&' ) {
      op = LogicalOperator.and;
    } else if ( operator == '||' ) {
      op = LogicalOperator.or;
    } else if ( operator == '|' ) {
      op = LogicalOperator.not;
    } else {
      Exception(operator+' is not yet supported');
    }
    Expression left = builder.buildNode(jsonNode['left']) as Expression;
    return LogicalExpression(builder.buildNode(jsonNode['left']) as Expression,
        op!,
        builder.buildNode(jsonNode['right']) as Expression
    );
  }
  @override
  dynamic accept(JSASTVisitor visitor) {
    return visitor.visitLogicalExpression(this);
  }
}
class Literal implements Expression {
  dynamic value;
  Literal(this.value);
  static Literal fromJson(var jsonNode,ASTBuilder builder) {
    return Literal(jsonNode['value']);
  }
  @override
  void accept(JSASTVisitor visitor) {
    visitor.visitLiteral(this);
  }
}
class Identifier implements Expression {
  String name;
  Identifier(this.name);
  static Identifier fromJson(var jsonNode,ASTBuilder builder) {
    return Identifier(jsonNode['name']);
  }
  @override
  void accept(JSASTVisitor visitor) {
    visitor.visitIdentifier(this);
  }
}
class ExpressionStatement implements ASTNode {
  ASTNode expression;
  ExpressionStatement(this.expression);
  static ExpressionStatement fromJson(var jsonNode,ASTBuilder builder) {
    var exp = jsonNode['expression'];
    return ExpressionStatement(builder.buildNode(exp));
  }
  @override
  dynamic accept(JSASTVisitor visitor) {
    return visitor.visitExpressionStatement(this);
  }
}

class AssignmentExpression implements Expression {
  Expression left,right;
  AssignmentOperator op;
  AssignmentExpression(this.left,this.op,this.right);
  static AssignmentExpression fromJson(var jsonNode,ASTBuilder builder) {
    AssignmentOperator op;
    if ( jsonNode['operator'] == '=' ) {
      op = AssignmentOperator.equal;
    } else if ( jsonNode['operator'] == '+=' ) {
      op = AssignmentOperator.plusEqual;
    } else if ( jsonNode['operator'] == '-=' ) {
      op = AssignmentOperator.minusEqual;
    } else {
      throw Exception('Operator '+jsonNode['operator']+' is not yet supported');
    }
    return AssignmentExpression(builder.buildNode(jsonNode['left']) as Expression,
        op, builder.buildNode(jsonNode['right']) as Expression);
  }
  @override
  void accept(JSASTVisitor visitor) {
    visitor.visitAssignmentExpression(this);
  }
}

class ThisExpr implements Expression {
  ThisExpr();
  static ThisExpr fromJson(var jsonNode, ASTBuilder builder) {
    return ThisExpr();
  }
  @override
  accept(JSASTVisitor visitor) {
    visitor.visitThisExpression(this);
  }
}
class MemberExpr implements Expression {
  Expression object,property;
  MemberExpr(this.object,this.property);
  static MemberExpr fromJson(var jsonNode,ASTBuilder builder) {
    return MemberExpr(builder.buildNode(jsonNode['object']) as Expression, builder.buildNode(jsonNode['property']) as Expression);
  }
  @override
  void accept(JSASTVisitor visitor) {
    visitor.visitMemberExpression(this);
  }
}

class ASTBuilder {
  List<ASTNode> buildArray(var jsonArr) {
    List<ASTNode> nodes = [];
    jsonArr.forEach((node) {
      nodes.add(buildNode(node));
    });
    return nodes;
  }
  ASTNode buildNode(var node) {
    String type = node['type'];
    if ( type == 'ExpressionStatement' ) {
      return ExpressionStatement.fromJson(node, this);
    } else if ( type == 'AssignmentExpression' ) {
      return AssignmentExpression.fromJson(node,this);
    } else if ( type == 'MemberExpression' ) {
      return MemberExpr.fromJson(node, this);
    } else if ( type == 'IfStatement' ) {
      return IfStatement.fromJson(node, this);
    } else if ( type == 'Literal' ) {
      return Literal.fromJson(node, this);
    } else if ( type == 'Identifier' ) {
      return Identifier.fromJson(node, this);
    } else if ( type == 'BlockStatement' ) {
      return BlockStatement.fromJson(node, this);
    } else if ( type == 'BinaryExpression' ) {
      return BinaryExpression.fromJson(node, this);
    } else if ( type == 'LogicalExpression' ) {
      return LogicalExpression.fromJson(node, this);
    } else if ( type == 'CallExpression' ) {
      return CallExpression.fromJson(node, this);
    } else if ( type == 'UnaryExpression' ) {
      return UnaryExpression.fromJson(node, this);
    } else if (type == 'ThisExpression') {
      return ThisExpr.fromJson(node, this);
    } else if ( type == 'ArrowFunctionExpression' ) {
      return ArrowFunctionExpression.fromJson(node, this);
    }
    throw Exception(type+" is not yet supported. Full expression is="+node.toString());
  }
}