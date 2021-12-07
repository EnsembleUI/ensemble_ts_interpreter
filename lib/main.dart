import 'dart:collection';

import 'package:ensemble/layout.dart';
import 'package:flutter/material.dart';
import 'package:yaml/yaml.dart';
import 'dart:convert';
import 'package:tuple/tuple.dart';
import 'view.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);
  static const String _title = 'Ensemble Demo';

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    /*
    return MaterialApp(
      title: 'Flutter Demo',
      home: Scaffold(
        appBar: AppBar(title: const Text(_title)),
        body: const MyStatefulWidget(),
      ),
    );
    */
    return const MyStatefulWidget();
  }
}
/// This is the stateful widget that the main application instantiates.
class MyStatefulWidget extends StatefulWidget {
  const MyStatefulWidget({Key? key}) : super(key: key);

  @override
  State<MyStatefulWidget> createState() => _MyStatefulWidgetState();
}

/// This is the private State class that goes with MyStatefulWidget.
class _MyStatefulWidgetState extends State<MyStatefulWidget> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  Future<String> loadAsset(BuildContext context,String name) async {
    return await DefaultAssetBundle.of(context).loadString('assets/'+name);
  }
  Widget buildFrom(YamlMap doc) {
    late Widget rtn = const Text('did not work');
    if (doc['View'] != null) {
      View v = View(doc['View']);
      Layout l = Layout(doc["Layout"], v);
      rtn = l.build(context);
    }
    return rtn;
  }
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      home: Scaffold(
          appBar: AppBar(title: const Text("Hello")),
          body: FutureBuilder<String>(
            future:loadAsset(context,'basic.yaml'),
            builder:(BuildContext context,AsyncSnapshot<String> snapShot) {
              Column rtn = Column();
              if (snapShot.hasData) {
                YamlMap doc = loadYaml(snapShot.requireData);
                rtn = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [buildFrom(doc)]
                );
              }
              return rtn;
            }
          )
      )
    );
   /*
    Widget rtn = const Text("didn't work");
    if ( doc == null ) {
      loadAsset(context, 'basic.yaml').then((def) {
        doc = loadYaml(def);
        print(json.encode(doc));

      });
    }
    return rtn;
    */
    /*
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          TextFormField(
            decoration: const InputDecoration(
              hintText: 'Enter your email',
            ),
            validator: (String? value) {
              if (value == null || value.isEmpty) {
                return 'Please enter some text';
              }
              return null;
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: ElevatedButton(
              onPressed: () {
                // Validate will return true if the form is valid, or false if
                // the form is invalid.
                if (_formKey.currentState!.validate()) {
                  // Process data.
                }
              },
              child: const Text('Submit'),
            ),
          ),
        ],
      ),
    );*/
  }
}