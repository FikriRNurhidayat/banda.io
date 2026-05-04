import 'package:bandha/common/helpers/date_helper.dart';
import 'package:flutter/material.dart';

enum WhenOption {
  yesterday(-1),
  today(0),
  tomorrow(1),
  now(null),
  specificTime(null),
  whenever(null);

  final int? dayOffset;
  const WhenOption(this.dayOffset);

  static get min => [WhenOption.now, WhenOption.specificTime];
  static get notEmpty => [
    WhenOption.now,
    WhenOption.today,
    WhenOption.yesterday,
    WhenOption.tomorrow,
    WhenOption.specificTime,
  ];

  String get label {
    switch (this) {
      case WhenOption.specificTime:
        return "Specific Time";
      case WhenOption.yesterday:
        return "Yesterday";
      case WhenOption.today:
        return "Today";
      case WhenOption.tomorrow:
        return "Tomorrow";
      case WhenOption.now:
        return "Now";
      case WhenOption.whenever:
        return "Whenever";
    }
  }

  DateTime? dateTime([DateTime? base]) {
    final now = base ?? DateTime.now();
    if (dayOffset != null) {
      return DateTime(
        now.year,
        now.month,
        now.day,
      ).add(Duration(days: dayOffset!));
    }
    if (this == WhenOption.now) return now;
    if (this == WhenOption.whenever) return null;
    return null;
  }
}

class When {
  final WhenOption option;
  final DateTime? specific;

  const When(this.option, [this.specific]);

  factory When.specificTime(DateTime? value) {
    if (value == null) return When.whenever();

    return When(WhenOption.specificTime, value);
  }

  factory When.whenever() {
    return When(WhenOption.whenever);
  }

  factory When.now() {
    return When(WhenOption.now);
  }

  factory When.today() {
    return When(WhenOption.today);
  }

  factory When.tomorrow() {
    return When(WhenOption.tomorrow);
  }

  factory When.yesterday() {
    return When(WhenOption.yesterday);
  }

  DateTime? get dateTime {
    if (option == WhenOption.specificTime) return specific;
    return option.dateTime();
  }
}

class WhenFormField extends FormField<When> {
  WhenFormField({
    super.key,
    super.initialValue,
    super.onSaved,
    super.validator,
    super.autovalidateMode,
    InputDecoration? decoration,
    InputDecoration? dateInputDecoration,
    InputDecoration? timeInputDecoration,
    List<WhenOption> options = WhenOption.values,
    bool readOnly = false,
  }) : super(
         builder: (field) {
           final state = field as _WhenFormFieldState;

           return Column(
             spacing: 16,
             children: [
               if (!readOnly)
                 InputDecorator(
                   decoration: decoration ?? InputDecoration(),
                   child: Wrap(
                     spacing: 8,
                     runSpacing: 8,
                     children: options.map((option) {
                       return ChoiceChip(
                         label: Text(option.label),
                         selected: option == state.value?.option,
                         onSelected: !readOnly
                             ? (selected) {
                                 if (selected)
                                   field.didChange(When(option));
                               }
                             : null,
                       );
                     }).toList(),
                   ),
                 ),

               if (state.value?.option == WhenOption.specificTime)
                 Row(
                   spacing: 16,
                   children: [
                     Expanded(
                       child: TextField(
                         readOnly: true,
                         controller: state.dateController,
                         onTap: !readOnly ? state.chooseDate : null,
                         decoration: dateInputDecoration,
                       ),
                     ),
                     Expanded(
                       child: TextField(
                         readOnly: true,
                         controller: state.timeController,
                         onTap: !readOnly ? state.chooseTime : null,
                         decoration: timeInputDecoration,
                       ),
                     ),
                   ],
                 ),
             ],
           );
         },
       );

  @override
  FormFieldState<When> createState() => _WhenFormFieldState();
}

class _WhenFormFieldState extends FormFieldState<When> {
  final TextEditingController dateController = TextEditingController();
  final TextEditingController timeController = TextEditingController();

  @override
  void initState() {
    super.initState();

    if (widget.initialValue != null &&
        widget.initialValue!.option == WhenOption.specificTime) {
      updateTextControllers(widget.initialValue!.dateTime!);
    }
  }

  void updateTextControllers(DateTime dateTime) {
    dateController.text = DateHelper.formatDate(dateTime);
    timeController.text = DateHelper.formatTime(
      TimeOfDay.fromDateTime(dateTime),
    );
  }

  Future<void> chooseDate() async {
    final now = DateTime.now();
    final current = value?.dateTime ?? now;
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      final newValue = DateTime(
        picked.year,
        picked.month,
        picked.day,
        current.hour,
        current.minute,
      );

      didChange(When(WhenOption.specificTime, newValue));
      updateTextControllers(newValue);
    }
  }

  Future<void> chooseTime() async {
    final now = DateTime.now();
    final current = value?.dateTime ?? now;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(current),
    );

    if (!mounted) return;

    if (picked != null) {
      final newValue = DateTime(
        current.year,
        current.month,
        current.day,
        picked.hour,
        picked.minute,
      );

      didChange(When(WhenOption.specificTime, newValue));
      updateTextControllers(newValue);
    }
  }

  @override
  void dispose() {
    dateController.dispose();
    timeController.dispose();
    super.dispose();
  }
}
