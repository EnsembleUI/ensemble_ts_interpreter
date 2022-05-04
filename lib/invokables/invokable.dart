import 'package:flutter/widgets.dart';

mixin Invokable {
  /// mark these functions as protected as we need the implementations,
  /// but discourage direct usages.
  /// Reasons:
  ///  1. There are more base getters/setters/methods from the base class.
  ///     Users can just focus on defining only applicable fields for their
  ///     classes but still get the base implementations automatically.
  ///  2. setProperty() will automatically notify the controller's listeners
  ///     for changes, enabling the listeners (widget state) to redraw.
  ///
  /// Use getProperty/setProperty/callMethod instead of these.
  @protected
  Map<String, Function> getters();
  @protected
  Map<String, Function> setters();
  @protected
  Map<String, Function> methods();

  List<String> getGettableProperties() {
    List<String> rtn = getters().keys.toList();
    if (this is HasController) {
      rtn.addAll((this as HasController).controller.getBaseGetters().keys);
    }
    return rtn;
  }

  List<String> getSettableProperties() {
    List<String> rtn = setters().keys.toList();
    if (this is HasController) {
      rtn.addAll((this as HasController).controller.getBaseSetters().keys);
    }
    return rtn;
  }

  Map<String, Function> getMethods() {
    Map<String, Function> rtn = methods();
    if (this is HasController) {
      rtn.addAll((this as HasController).controller.getBaseMethods());
    }
    return rtn;
  }

  dynamic getProperty(dynamic prop) {
    Function? func = getters()[prop];
    if (func == null && this is HasController) {
      func = (this as HasController).controller.getBaseGetters()[prop];
    }

    if (func != null) {
      return func();
    }
  }

  /// update a property. If this is a HasController (i.e. Widget), notify it of changes
  void setProperty(dynamic prop, dynamic val) {
    Function? func = setters()[prop];
    if (func == null && this is HasController) {
      func = (this as HasController).controller.getBaseSetters()[prop];
    }

    if (func != null) {
      func(val);

      // ask our controller to notify its listeners of changes
      if (this is HasController) {
        (this as HasController).controller.dispatchChanges();
      }
    }
  }
}

/// Base Mixin for Widgets that want to participate in Ensemble widget tree.
/// This works in conjunction with Controller and WidgetState
mixin HasController<C extends Controller, S extends WidgetStateMixin> on StatefulWidget{
  C get controller;
}

abstract class Controller extends ChangeNotifier {
  // notify listeners of changes
  void dispatchChanges() {
    notifyListeners();
  }

  // your controllers may want to extend these to provide base implementations
  Map<String, Function> getBaseGetters() {
    return {};
  }
  Map<String, Function> getBaseSetters() {
    return {};
  }
  Map<String, Function> getBaseMethods() {
    return {};
  }
}

/// purely for type checking so WidgetState implementation
/// has the correct type
mixin WidgetStateMixin {
}

/// base state for Flutter widgets that want to be of Invokable type
abstract class BaseWidgetState<W extends HasController> extends State<W> with WidgetStateMixin {
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
  void didUpdateWidget(covariant W oldWidget) {
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
