import 'package:bandha/common/formatters/numeric_formatter.dart';
import 'package:flutter/material.dart';

class AmountFormField extends FormField<double> {
  AmountFormField({
    super.key,
    super.initialValue,
    super.onSaved,
    super.validator,
    InputDecoration? decoration,
    AutovalidateMode autovalidateMode = AutovalidateMode.disabled,
    this.label = 'Amount',
    bool readOnly = false,
  }) : super(
         autovalidateMode: autovalidateMode,
         builder: (field) {
           final state = field as _AmountFormFieldState;

           return TextField(
             readOnly: readOnly,
             controller: state.controller,
             inputFormatters: [state.numericFormatter],
             keyboardType: const TextInputType.numberWithOptions(
               decimal: true,
               signed: false,
             ),
             decoration:
                 decoration ??
                 InputDecoration(labelText: label, errorText: state.errorText),
             onChanged: (val) {
               double? number = double.tryParse(val.replaceAll(',', ''))?.abs();
               state.didChange(number);
             },
           );
         },
       );

  final String label;

  @override
  FormFieldState<double> createState() {
    return _AmountFormFieldState();
  }
}

class _AmountFormFieldState extends FormFieldState<double> {
  final numericFormatter = NumericFormatter(
    allowFraction: true,
    fractionDigits: 2,
    thousandSeparator: ',',
  );

  final controller = TextEditingController();

  @override
  void initState() {
    super.initState();

    if (widget.initialValue != null) {
      final amountText = widget.initialValue?.abs().toString() ?? '';

      controller.text = numericFormatter.format(
        TextEditingValue.empty,
        TextEditingValue(
          text: amountText.endsWith(".0")
              ? amountText.substring(0, amountText.length - 2)
              : amountText,
        ),
      );
    }
  }
}
