import 'package:banda/common/types/widget_list_builder.dart';
import 'package:flutter/material.dart';

class SelectItem<T> {
  final T value;
  final String label;
  final WidgetStateProperty<Color?>? color;
  final Color? backgroundColor;

  SelectItem({
    required this.value,
    required this.label,
    this.backgroundColor,
    this.color,
  });
}

class SelectFormField<T> extends FormField<T> {
  SelectFormField({
    super.key,
    required List<SelectItem<T>> options,
    super.initialValue,
    InputDecoration? decoration,
    List<Widget>? actions,
    WidgetListBuilder? actionsBuilder,
    super.autovalidateMode,
    super.enabled,
    super.onSaved,
    super.validator,
    FormFieldSetter<T>? onChanged,
    bool readOnly = false,
  }) : super(
         builder: (state) {
           List<Widget> chips = !readOnly
               ? options.map((option) {
                   final selected = state.value == option.value;
                   return ChoiceChip(
                         color: option.color,
                         backgroundColor: option.backgroundColor,
                         label: Text(option.label),
                         selected: selected,
                         onSelected: (!readOnly && enabled)
                             ? (_) {
                                 state.didChange(option.value);
                                 onChanged?.call(option.value);
                               }
                             : null,
                       )
                       as Widget;
                 }).toList()
               : options.where((option) => state.value == option.value).map((
                   option,
                 ) {
                   return Text(option.label) as Widget;
                 }).toList();

           if (actions != null) {
             chips.addAll(actions);
           }

           if (actionsBuilder != null) {
             final actions = actionsBuilder(state.context);
             chips.addAll(actions);
           }

           return InputDecorator(
             decoration:
                 decoration ??
                 InputDecoration(
                   errorText: state.errorText,
                   border: OutlineInputBorder(),
                   enabled: enabled,
                 ),
             child: Wrap(
               alignment: WrapAlignment.start,
               runAlignment: WrapAlignment.center,
               spacing: 8,
               runSpacing: 8,
               children: chips,
             ),
           );
         },
       );
}
