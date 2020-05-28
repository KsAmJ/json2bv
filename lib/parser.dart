import 'dart:convert';
import 'dart:io';

import 'package:built_collection/src/list.dart';
import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:json2bv/root.dart';
import 'package:recase/recase.dart';
import 'package:tuple/tuple.dart';

class Parser {
  final _dartfmt = DartFormatter();

  String parse(String jsonString, String topLevelName) {
    var decode = json.decode(jsonString);
    // print(decode);
    var allClasses = <Tuple2<String, List<Subtype>>>[];

    //check if list or map
    if (decode is List) {}

    var topLevel = _getTypedClassFields(decode);
    //print('topLevel$topLevel');
    allClasses.add(Tuple2(topLevelName, topLevel));
    //print(topLevel.length);
    topLevel.forEach((Subtype s) {
      if ((s.type == JsonType.LIST && s.listType == JsonType.MAP) ||
          s.type == JsonType.MAP) {
        var getTypedClassFields = _getTypedClassFields(s.value);
        allClasses.add(Tuple2(s.name, getTypedClassFields));
      }
    });

    var output = _generateStringClass(topLevel, topLevelName);

    var reduce = allClasses
        .map((tuple) => _generateStringClass(tuple.item2, tuple.item1))
        .reduce((s1, s2) => s1 + s2);
    createSerializerClass(_getPascalCaseClassName(topLevelName));
    return reduce;
  }

  String _generateStringClass(List<Subtype> topLevel, String name) {
    var topLevelClass = Class((b) => b
      ..abstract = true
      ..constructors.add(Constructor((b) => b..name = '_'))
      ..implements.add(Reference(
          'Built<${_getPascalCaseClassName(name)}, ${_getPascalCaseClassName(name)}Builder>'))
      ..name = _getPascalCaseClassName(name)
      ..methods = _buildMethods(topLevel)
      ..methods.add(Method((b) => b
        ..name = 'toJson'
        ..returns = Reference('String')
        ..body = Code(
            'return json.encode(serializers.serializeWith(${_getPascalCaseClassName(name)}.serializer, this));')))
      ..methods.add(Method((b) => b
        ..name = 'fromJson'
        ..static = true
        ..requiredParameters.add(Parameter((b) => b
          ..name = 'jsonString'
          ..type = Reference('String')))
        ..returns = Reference(_getPascalCaseClassName(name))
        ..body = Code(
            'return serializers.deserializeWith(${_getPascalCaseClassName(name)}.serializer, json.decode(jsonString));')))
      ..methods.add(Method((b) => b
        ..type = MethodType.getter
        ..name = 'serializer'
        ..static = true
        ..lambda = true
        ..returns = Reference('Serializer<${_getPascalCaseClassName(name)}>')
        ..body = Code('_\$${ReCase(name).camelCase}Serializer')))
      ..constructors.add(
        Constructor((b) => b
          ..factory = true
          ..redirect = refer(' _\$${_getPascalCaseClassName(name)}')
          ..requiredParameters.add(Parameter((b) => b
            ..defaultTo = Code('= _\$${_getPascalCaseClassName(name)}')
            ..name = '[updates(${_getPascalCaseClassName(name)}Builder b)]'))),
      ));

    String classString = topLevelClass.accept(DartEmitter()).toString();
    String header = """
      library ${ReCase(name).snakeCase};
      import 'dart:convert';
      
      import 'package:built_collection/built_collection.dart';
      import 'package:built_value/built_value.dart';
      import 'package:built_value/serializer.dart';
      import 'serializers.dart';
      
      part '${ReCase(name).snakeCase}.g.dart';
    
    """;

    var output = _dartfmt.format(header + classString);

    final filename = 'models/${ReCase(name).snakeCase}.dart';
    File(filename).writeAsString(output).then((File file) {});
    return output;
  }

  void createSerializerClass(String rootObject) {
    var output = """
      import 'package:built_collection/built_collection.dart';
      import 'package:built_value/serializer.dart';

      import 'package:built_value/standard_json_plugin.dart';
      import '${ReCase(rootObject).snakeCase}.dart';

      part 'serializers.g.dart';

      @SerializersFor(const [$rootObject])
      final Serializers serializers =
        (_\$serializers.toBuilder()..addPlugin(StandardJsonPlugin())).build();

      T deserialize<T>(dynamic value) =>
          serializers.deserializeWith<T>(serializers.serializerForType(T), value);

      BuiltList<T> deserializeListOf<T>(dynamic value) => BuiltList.from(
         value.map((value) => deserialize<T>(value)).toList(growable: false));

    """;

    final filename = 'models/serializers.dart';
    File(filename).writeAsString(output).then((File file) {});
  }

  String _getPascalCaseClassName(String name) => ReCase(name).pascalCase;

  ListBuilder<Method> _buildMethods(List<Subtype> topLevel) {
    return ListBuilder(topLevel.map((Subtype s) => Method((b) => b
      ..name = ReCase(s.name).camelCase
      ..returns = _getDartType(s)
      ..annotations
          .add(CodeExpression(Code("BuiltValueField(wireName: '${s.name}')")))
      ..type = MethodType.getter)));
  }

  Reference _getDartType(Subtype subtype) {
    JsonType type = subtype.type;
    switch (type) {
      case JsonType.INT:
        return Reference('int');
      case JsonType.DOUBLE:
        return Reference('double');
      case JsonType.BOOL:
        return Reference('bool');
      case JsonType.STRING:
        return Reference('String');
      case JsonType.MAP:
        return Reference(ReCase(subtype.name).pascalCase);
      case JsonType.LIST:
        return Reference('BuiltList<${_getDartTypeFromJsonType(subtype)}>');
      default:
        return Reference('dynamic');
    }
  }

  String _getDartTypeFromJsonType(Subtype subtype) {
    var type = subtype.listType;
    switch (type) {
      case JsonType.INT:
        return 'int';
      case JsonType.DOUBLE:
        return 'double';
      case JsonType.STRING:
        return 'String';
      case JsonType.MAP:
        return ReCase(subtype.name).pascalCase;
      default:
        return 'dynamic';
    }
  }

  List<Subtype> _getTypedClassFields(decode) {
    List<Subtype> topLevelClass = [];
    var toDecode;

    if (decode is List) {
      toDecode = decode[0];
    } else {
      toDecode = decode;
    }

//  if (toDecode is Map) {
    toDecode.forEach((key, val) {
      topLevelClass.add(_returnType(key, val));
    });
//  }
    return topLevelClass;
  }

  Subtype _returnType(key, val) {
    if (val is String)
      return Subtype(key, JsonType.STRING, val);
    else if (val is int)
      return Subtype(key, JsonType.INT, val);
    else if (val is num)
      return Subtype(key, JsonType.DOUBLE, val);
    else if (val is bool)
      return Subtype(key, JsonType.BOOL, val);
    else if (val is List) {
      return Subtype(key, JsonType.LIST, val, listType: _returnJsonType(val));
    } else if (val is Map) {
      return Subtype(key, JsonType.MAP, val);
    } else
      throw ArgumentError('Cannot resolve JSON-encodable type for $val.');
  }

  JsonType _returnJsonType(List list) {
    var item = list[0];
    //print('got item $item');
    if (item is String)
      return JsonType.STRING;
    else if (item is int)
      return JsonType.INT;
    else if (item is num)
      return JsonType.DOUBLE;
    else if (item is bool)
      return JsonType.BOOL;
    else if (item is Map)
      return JsonType.MAP;
    else
      throw ArgumentError('Cannot resolve JSON-encodable type for $item.');
  }
}
