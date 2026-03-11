import 'package:banda/common/widgets/multi_select_form_field.dart';
import 'package:flutter/material.dart';

class GrowableMultiSelectFormField<T> extends MultiSelectFormField<T> {
  GrowableMultiSelectFormField({
    super.key,
    required super.options,
    super.initialValue,
    super.decoration,
    super.readOnly,
    super.onSaved,
    super.validator,
    VoidCallback? onRedirect,
    required String actionText,
    required String actionPath,
  }) : super(
         actionsBuilder: (context) {
           final theme = Theme.of(context);
           final navigator = Navigator.of(context);

           return [
             if (!readOnly)
               ActionChip(
                 avatar: Icon(Icons.add, color: theme.colorScheme.outline),
                 label: Text(
                   actionText,
                   style: TextStyle(
                     fontWeight: FontWeight.w100,
                     color: theme.colorScheme.outline,
                   ),
                 ),
                 onPressed: () {
                   onRedirect?.call();
                   navigator.pushNamed(actionPath);
                 },
               ),
           ];
         },
       );
}
