import 'dart:async';
import 'dart:ffi';
import 'package:flutter_annotation_form_builder/flutter_annotation_form_builder.dart';
import 'package:generator/src/code_chunks.dart';
import 'package:generator/src/config.dart';
import 'package:generator/src/entity_info.dart';
import 'package:path/path.dart' as path;
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

import 'package:dart_style/dart_style.dart';

class FormGenerator extends Builder {
  final _formBuilderEntityChecker =
      const TypeChecker.fromRuntime(FormBuilderEntity);
  final _inputFieldChecker = const TypeChecker.fromRuntime(InputField);

  final Config _config = Config();

  String _dir(BuildStep buildStep) => path.dirname(buildStep.inputId.path);

  String _outDir(BuildStep buildStep) {
    var dir = _dir(buildStep);
    if (dir.endsWith('test')) {
      return dir + '/' + _config.outDirTest;
    } else if (dir.endsWith('lib')) {
      return dir + '/' + _config.outDirLib;
    } else {
      throw Exception('Unrecognized path being generated: $dir');
    }
  }

  @override
  Future<void> build(BuildStep buildStep) async {
    final resolver = buildStep.resolver;
    if (!await resolver.isLibrary(buildStep.inputId)) return;
    final libReader = LibraryReader(await buildStep.inputLibrary);
    // if (libReader.annotatedWith(_formBuilderEntityChecker)){
    var elements = libReader.allElements;
    if (elements.isEmpty) return;
    if (libReader.annotatedWith(_formBuilderEntityChecker).length != 1) {
      log.severe("More than 1 entity annotation per file");
      return;
    }
    if (elements.length > 1) {
      log.severe("More than 1 class in file");
      return;
    }

    var annotatedEL =
        libReader.annotatedWith(_formBuilderEntityChecker).elementAt(0);
    var annotation = (annotatedEL.annotation as ConstantReader);

    var element = elements.elementAt(0);
    EntityInfo entityInfo = EntityInfo();

    entityInfo.name = annotatedEL.element.name!;
    entityInfo.shouldBePopulatedWithEntity =
        annotation.read("shouldBePopulatedWithEntity").boolValue;

    if (entityInfo.shouldBePopulatedWithEntity) {
      entityInfo.imports.add(annotatedEL.element.librarySource!.uri.toString());
    }
    var inputs = getInputs(annotatedEL.element);
    String code = CodeChunks.createFile(entityInfo, inputs);
    try {
      code = DartFormatter().format(code);
    } finally {
      final codeId =
          AssetId(buildStep.inputId.package, "lib/teste/unFisier.x.dart");
      await buildStep.writeAsString(codeId, code);
    }
  }

  List<Map<String, dynamic>> getInputs(element) {
    List<Map<String, dynamic>> list = [];
    for (var f in element.fields) {
      if (_inputFieldChecker.hasAnnotationOfExact(f)) {
        list.add(extractInfo(f));
      }
    }
    return list;
  }

  Map<String, dynamic> extractInfo(f) {
    var options = _inputFieldChecker.annotationsOf(f).single;
    Map<String, dynamic> s = {};
    // TODO: UGLY AS FUCK, CHECK IF BETTER ALTERNATIVE AVAILABLE
    var inputTypeIndex =
        options.getField("inputType")?.getField("index")?.toIntValue();
    s["inputType"] = InputType.values[inputTypeIndex!].name;
    s["propertyName"] = f.name;
    s["options"] = options.getField("options")?.toMapValue()?.map((key, value) =>
        MapEntry(key?.toStringValue(), value?.toStringValue()));
    return s;
  }

  @override
  Map<String, List<String>> get buildExtensions => {
        ".dart": [".x.dart"]
      };
}
