

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

mixin Invokable {
  Map<String, Function> getters();
  Map<String, Function> setters();
  Map<String, Function> methods();
  dynamic get(String prop);
  void set(String prop,dynamic val);
}
class Controller<T> extends ChangeNotifier {

}
mixin HasController<C,T> on StatefulWidget{
  C get controller;
}
abstract class InvokableState<T extends HasController> extends State<HasController>{
  void changeState() {
    setState(() {

    });
  }

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(changeState);
  }
  @override
  void didUpdateWidget(covariant HasController oldWidget) {
    super.didUpdateWidget(oldWidget);
    oldWidget.controller.removeListener(changeState);
    widget.controller.addListener(changeState);
  }
  @override
  void dispose() {
    super.dispose();
    widget.controller.removeListener(changeState);
  }


}
