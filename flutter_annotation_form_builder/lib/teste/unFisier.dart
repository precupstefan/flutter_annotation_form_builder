import 'package:flutter_annotation_form_builder/flutter_annotation_form_builder.dart';
import 'package:flutter_annotation_form_builder/src/input_field.dart';

@FormBuilderEntity(shouldBePopulatedWithEntity: true)
class UnFisier {
  String a = "!23";

  @InputField(InputType.DateTimePicker,
      options: {"inputType": "InputType.time"})
  int b = 4;
}
