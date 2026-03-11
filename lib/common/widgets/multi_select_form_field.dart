import 'package:banda/common/types/widget_list_builder.dart';
import 'package:flutter/material.dart';

class MultiSelectItem<T> {
  final T value;
  final String label;
  final bool enabled;

  MultiSelectItem({
    required this.value,
    required this.label,
    this.enabled = true,
  });
}

class MultiSelectFormField<T> extends FormField<List<T>> {
  MultiSelectFormField({
    super.key,
    required List<MultiSelectItem<T>> options,
    super.initialValue,
    InputDecoration? decoration,
    List<Widget>? actions,
    WidgetListBuilder? actionsBuilder,
    super.autovalidateMode,
    super.enabled,
    super.onSaved,
    super.validator,
    bool readOnly = false,
  }) : super(
         builder: (state) {
           final theme = Theme.of(state.context);

           List<Widget> chips = !readOnly
               ? options.map((option) {
                   final selected = state.value!.contains(option.value);
                   return FilterChip(
                         label: Text(option.label),
                         selected: option.enabled ? selected : true,
                         onSelected: option.enabled
                             ? (bool value) {
                                 final newValue = List<T>.from(state.value!);
                                 if (value) {
                                   newValue.add(option.value);
                                 } else {
                                   newValue.remove(option.value);
                                 }
                                 state.didChange(newValue);
                               }
                             : null,
                       )
                       as Widget;
                 }).toList()
               : options
                     .where((option) => state.value!.contains(option.value))
                     .map((option) {
                       return Chip(
                             label: Text(
                               option.label,
                               style: TextStyle(
                                 color: theme.colorScheme.onInverseSurface,
                               ),
                             ),
                             backgroundColor: theme.colorScheme.inverseSurface,
                           )
                           as Widget;
                     })
                     .toList();

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
