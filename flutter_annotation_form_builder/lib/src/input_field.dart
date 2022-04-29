enum InputType {
  DateTimePicker,
}

class InputField {
  final InputType inputType;
  final Map<String, String>? options;

  const InputField(this.inputType,{
    this.options,
  });
}
