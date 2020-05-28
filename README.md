# json2bv

A JSON To built_value CLI Classes Generator
It generates the models from a `.json` file and a serializer file.

(you need to install the `built_value` and `built_runner`packages to your app `pubspec.yaml` from https://pub.dev/ )

To use add the `json2bv` to your PATH or copy the file on the `lib` directory of your flutter/dart app along with the `.json` file you want to model/serialize

The command generates the models from the `.json` file and inside a models folder

### To Generate run:

```
$ ./json2bv [JSON File] [Top Level Class Name]
```

### Example:
if the json file name is `input.json` and the desired model name is `Link Information` the command should be

```
./json2bv input.json "Link Information"
```
which will create
```
.
├── lib
|   ├── models
|       └── link_information.dart
|       └── serializers.dart
```
the base classes will be generated after that with errors as the related part files is missings to resolve that you should adjust your missing imports (if more than one class generated "nested objects") and run

```
flutter pub run build_runner build
```

to generate the `.g.dart` missing part files releated to each class.

### To Build run:

```
pub get
```

then

```
dart2native bin/main.dart -o bin/json2bv
```

### Note:
This is still a work on progress and based on the https://charafau.github.io/json2builtvalue/ by charafau
