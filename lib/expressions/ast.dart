abstract class JSASTVisitor {
  void visitExpressionStatement(ExpressionStatement stmt);
  void visitAssignmentExpression(AssignmentExpression stmt);
  dynamic visitMemberExpression(MemberExpr stmt);
  void visitIfStatement(IfStatement stmt);
  bool visitBinaryExpression(BinaryExpression stmt);
  bool visitLogicalExpression(LogicalExpression stmt);
  dynamic visitLiteral(Literal stmt);
  dynamic visitIdentifier(Identifier stmt);
  void visitBlockStatement(BlockStatement stmt);
}
enum Operator {
  equal,equals,and,or,lt,gt,ltEquals,gtEquals
}
abstract class ASTNode {
  void accept(JSASTVisitor visitor);
}
class IfStatement implements ASTNode {
  ASTNode test,consequent;
  ASTNode? alternate;
  IfStatement(this.test,this.consequent,this.alternate);
  static IfStatement fromJson(var jsonNode,ASTBuilder builder) {
    return IfStatement(builder.buildNode(jsonNode['test']),
        builder.buildNode(jsonNode['consequent']),
        builder.buildNode(jsonNode['alternate'])
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
abstract class BooleanExpression extends ASTNode {}
class BinaryExpression implements BooleanExpression {
  ASTNode left,right;
  Operator op;
  BinaryExpression(this.left,this.op,this.right);
  static BinaryExpression fromJson(var jsonNode,ASTBuilder builder) {
    String operator = jsonNode['operator'];
    Operator? op;
    if ( operator == '==' ) {
      op = Operator.equals;
    } else if ( operator == '<' ) {
      op = Operator.lt;
    } else if ( operator == '<=' ) {
      op = Operator.ltEquals;
    } else if ( operator == '>' ) {
      op = Operator.gt;
    } else if ( operator == '<=' ) {
      op = Operator.gtEquals;
    } else {
      Exception(operator+' is not yet supported');
    }
    return BinaryExpression(builder.buildNode(jsonNode['left']),
        op!,
        builder.buildNode(jsonNode['right'])
    );
  }
  @override
  void accept(JSASTVisitor visitor) {
    visitor.visitBinaryExpression(this);
  }
}
class LogicalExpression implements BooleanExpression {
  BooleanExpression left,right;
  Operator op;
  LogicalExpression(this.left,this.op,this.right);
  static LogicalExpression fromJson(var jsonNode,ASTBuilder builder) {
    String operator = jsonNode['operator'];
    Operator? op;
    if ( operator == '&&' ) {
      op = Operator.and;
    } else if ( operator == '||' ) {
      op = Operator.or;
    } else {
      Exception(operator+' is not yet supported');
    }
    BooleanExpression left = builder.buildNode(jsonNode['left']) as BooleanExpression;
    return LogicalExpression(builder.buildNode(jsonNode['left']) as BooleanExpression,
        op!,
        builder.buildNode(jsonNode['right']) as BooleanExpression
    );
  }
  @override
  void accept(JSASTVisitor visitor) {
    visitor.visitLogicalExpression(this);
  }
}
class Literal implements ASTNode {
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
class Identifier implements ASTNode {
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
  void accept(JSASTVisitor visitor) {
    visitor.visitExpressionStatement(this);
  }
}

class AssignmentExpression implements ASTNode {
  ASTNode left,right;
  Operator op;
  AssignmentExpression(this.left,this.op,this.right);
  static AssignmentExpression fromJson(var jsonNode,ASTBuilder builder) {
    Operator op;
    if ( jsonNode['operator'] == '=' ) {
      op = Operator.equal;
    } else {
      throw Exception('Operator '+jsonNode['operator']+' is not yet supported');
    }
    return AssignmentExpression(builder.buildNode(jsonNode['left']), op, builder.buildNode(jsonNode['right']));
  }
  @override
  void accept(JSASTVisitor visitor) {
    visitor.visitAssignmentExpression(this);
  }
}
class MemberExpr implements ASTNode {
  String object,property;
  MemberExpr(this.object,this.property);
  static MemberExpr fromJson(var jsonNode,ASTBuilder builder) {
    String prop = jsonNode['property']['name'];
    return MemberExpr(jsonNode['object']['name'], prop);
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
    } else if ( type == 'BlockStatement' ) {
      return BlockStatement.fromJson(node, this);
    } else if ( type == 'BinaryExpression' ) {
      return BinaryExpression.fromJson(node, this);
    }
    throw Exception(node.toString()+' is not yet supported');
  }
}