import 'dart:io';
import 'package:json2bv/parser.dart';

void main(List<String> arguments) {
  final dir = Directory('models');
  if (!dir.existsSync()) dir.createSync();
  var outputClasses = '';
  var contents = File(arguments[0]).readAsStringSync();
  var parser = Parser();
  parser.parse(contents, arguments[1]);
}
