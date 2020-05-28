# json2bv

A JSON To built_value CLI Classes Generator
It generates the models from a `.json` file and a serializer file to use
you need to install the `built_value` package to your app from https://pub.dev/packages/built_value

To use add the `json2bv` to your PATH or copy the file on the `lib` directory of your flutter/dart app along with the `.json` file you want to model/serialize

The command generate the models from the `.json` file and inside a models folder

To Generate run the command
```
$ ./json2bv [JSON File] [Top Level Class Name]
```

Example:
if the json file name is `input.json` and the desired model name is `Link Information` the command should be

```
./json2bv input.json "Link Information"
```
the base classes will be generated after that you should adjust your missing imports (if more than one class generated "nested objects") and run
```
flutter pub run build_runner build
```
to generate the part files `.g.dart`

Notice:
This is still a work on progress and based on the https://charafau.github.io/json2builtvalue/ by charafau

