import 'package:bandha/common/widgets/select_form_field.dart';
import 'package:flutter/material.dart';

class VaultFormField extends SelectFormField<String> {
  VaultFormField({
    super.key,
    required super.options,
    super.initialValue,
    super.decoration,
    super.readOnly,
    super.onSaved,
    super.validator,
    super.onChanged,
    VoidCallback? onRedirect,
  }) : super(
         actionsBuilder: (context) {
           final theme = Theme.of(context);
           final navigator = Navigator.of(context);

           return [
             if (!readOnly)
               ActionChip(
                 avatar: Icon(Icons.add, color: theme.colorScheme.outline),
                 label: Text(
                   "New vault",
                   style: TextStyle(
                     fontWeight: FontWeight.w100,
                     color: theme.colorScheme.outline,
                   ),
                 ),
                 onPressed: () {
                   onRedirect?.call();
                   navigator.pushNamed("/vaults/edit");
                 },
               ),
           ];
         },
       );
}
