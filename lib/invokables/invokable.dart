mixin Invokable {
  Map<String, Function> getters();
  Map<String, Function> setters();
  Map<String, Function> methods();
  dynamic get(String prop);
  void set(String prop,dynamic val);
}