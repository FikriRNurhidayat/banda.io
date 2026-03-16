import 'package:bandha/common/helpers/date_helper.dart';
import 'package:flutter/material.dart';

class DateTimeRangeFormField extends FormField<DateTimeRange> {
  DateTimeRangeFormField({
    super.key,
    super.onSaved,
    super.initialValue,
    super.validator,
    InputDecoration? decoration,
  }) : super(
         builder: (FormFieldState<DateTimeRange> field) {
           final state = field as _DateTimeRangeFormFieldState;

           return TextField(
             readOnly: true,
             decoration: decoration ?? InputDecoration(),
             controller: state.dateTimeController,
             onTap: () {
               state.chooseDateRange();
             },
           );
         },
       );

  @override
  FormFieldState<DateTimeRange> createState() => _DateTimeRangeFormFieldState();
}

class _DateTimeRangeFormFieldState extends FormFieldState<DateTimeRange> {
  final TextEditingController dateTimeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.initialValue != null) {
      updateTextFields(widget.initialValue!);
    }
  }

  void updateTextFields(DateTimeRange dateTimeRange) {
    dateTimeController.text = DateHelper.formatDateRange(dateTimeRange);
  }

  Future<void> chooseDateRange() async {
    final now = DateTime.now();
    final DateTimeRange? choosen = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDateRange:
          value ??
          DateTimeRange(
            start: DateTime(now.year, now.month, now.day, 0, 0, 0),
            end: DateTime(now.year, now.month, now.day, 23, 59, 999),
          ),
    );

    if (choosen == null) return;

    didChange(choosen);
    updateTextFields(choosen);
  }
}
