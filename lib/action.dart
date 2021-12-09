import 'dart:collection';

import 'package:ensemble/api.dart';
import 'package:ensemble/view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:yaml/yaml.dart';

enum Event {
  click,longPress
}
class EnsembleAction {

}
/*
click:
      call:
        api: genderAPI
        parameters:
          name: a
        success: c.value={gender}
 */
class WidgetAction implements EnsembleAction {
  WidgetView target;
  Event event;
  View view;
  Handler handler;
  WidgetAction(this.target,this.event,this.view,this.handler);
  static WidgetAction from(WidgetView target,String eventName,View view,Map<String,API> apis,YamlMap map) {
    Event? event;
    try {
      Event.values.forEach((e) {
        if ( e.toString() == 'Event.'+eventName.toLowerCase() ) {
          event = e;
        }
      });
    } catch (e) {
      throw Exception("Event by name="+eventName+" is not supported");
    }
    WidgetAction? action;
    map.forEach((k,v) {
      if ( k == "call" ) {
        APIHandler handler = APIHandler.from(view, apis,v);
        action = WidgetAction(target,event!,view,handler);
        if ( event == Event.click ) {
          target.widget = GestureDetector(
            onTap: () {
              print('ontap on '+target.widget.key.toString());
              handler.handle(action!);
            },
            child: target.widget
          );
        }
      } else {
        throw Exception('no handler found for event '+event.toString());
      }
    });
    return action!;
  }
}
class WidgetActions {
  static List<WidgetAction> from(View view,WidgetView target,Map<String,API> apis,YamlMap map) {
    List<WidgetAction> widgetActions = [];
    map.forEach((k,v) {
      widgetActions.add(WidgetAction.from(target,k,view,apis,v));
    });
    return widgetActions;
  }
}
/*
Actions:
  b:
    click:
      call:
        api: genderAPI
        parameters:
          name: a
        success: c.value={gender}
 */
class EnsembleActions {
  static List<EnsembleAction> configure(View view,Map<String,API> apis,YamlMap map) {
    List<EnsembleAction> actions = [];
    map.forEach((k,v) {
      WidgetView? wv = view.get(k);
      if ( wv != null ) {
        actions.addAll(WidgetActions.from(view,wv!,apis,v));
      }
    });
    return actions;
  }
}
abstract class Handler {
  void handle(WidgetAction action);
}
/*
        api: genderAPI
        parameters:
          name: a
        success: c.value={gender}
 */
class APIHandler extends Handler {
  API api;
  Map<String,String>? paramMetaValues;
  APIHandler(this.api,this.paramMetaValues);
  static APIHandler from(View view,Map<String,API> apis,YamlMap map) {
    if ( !apis.containsKey(map['api']) ) {
      throw Exception('api with name='+map['api']+' not define');
    }
    API api = apis[map['api']]!;
    Map<String,String>? paramMetaValues = HashMap();
    if ( map.containsKey('parameters') ) {
      map['parameters'].forEach((k,v){
        paramMetaValues[k.toString()] = v.toString();
      });
    }
    return APIHandler(api, paramMetaValues);
  }
  @override
  void handle(WidgetAction action) {
    print('handle called');
  }

}

