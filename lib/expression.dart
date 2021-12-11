import 'package:expressions/expressions.dart';

class Evaluator {
  Map<String,dynamic> context;
  Evaluator(this.context);
  dynamic eval(String exp) {
    Expression expression = Expression.parse(exp);
    const evaluator = ExpressionEvaluator();
    evaluator.eval(expression, context);
  }
}