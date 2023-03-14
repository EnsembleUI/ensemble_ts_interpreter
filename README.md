
This is a javascript [ES5] (https://www.geeksforgeeks.org/difference-between-es5-and-es6/) parser and interpreter written entirely in dart. 

### What it is
- Primary use case is to let users type in simple js that you want to execute inline. This should be not used as a general replacement for dart in flutter
- Runs in the same process as your Dart/Flutter code so no need to use the browser's javascript engine. As a result, this is fast. 
- Unlike react native, doesn't require any bridge or have memory issues
- Supports most common use cases right now such as functions, lists, all primitive types (string, number, arrays, dates) etc. 
- Highly extensible. The context object could be json or any dart object enhanced with the Invokable mixin (see below)

### How to use
Simply call the ```JSInterpreter``` with the code you want to evaluate while passing it the context. 

```JSInterpreter.fromCode(code, context).evaluate();```

```context``` is the key object here. You can pass json as context (see examples below) or pass an instance of [Invokable] (https://github.com/EnsembleUI/ensemble_ts_interpreter/blob/master/lib/invokables/invokable.dart) which could be any Dart object. 

### Examples
All the examples are in the unit test suite - [new_interpreter_tests] (https://github.com/EnsembleUI/ensemble_ts_interpreter/blob/master/test/new_interpreter_tests.dart)

Listing some here. 

#### Filter a list

```
    Map<String, dynamic> context = {
      'items': ['one', 'two', 'three'],
      'nested': [
        {'id': 1, 'label': 'eggs', 'type': ''},
        {'id': 2, 'label': 'strawberry', 'type': 'fruit'},
        {'id': 3, 'label': 'nut'}
      ]
    };

    String code = """
      var flatList = items.filter(function(e) {
        return e != 'two';
      });
      
      var nestedList = nested.filter(function(e) {
        return e['type'] == 'fruit'
      });
    """;
    
    JSInterpreter.fromCode(code, context).evaluate();
```
#### Different String functions

```
    Map<String, dynamic> context = initContext();

    String code = """
        var arr = ['a','b','c','d'];
        var b = arr.at(1);
        var arr2 = arr.concat(['e','f']);
        var f = arr2.find(function (element)  { 
              var rtn = ( element == 'f' )? true : false;
              return rtn;
         });
         var includes = arr2.includes('e');
         var str = arr.join();
         var str2 = arr.join('-');
         var str3 = arr.join('');
         var last = arr2.pop(); 
         var nums = [1,2,3,4,5];
         var sum = nums.reduce(function (value, element) {
            return value + element;
            });
         var reversed = arr.reverse();
        """;

    JSInterpreter.fromCode(code, context).evaluate();
```




