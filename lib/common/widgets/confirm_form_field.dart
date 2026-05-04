import 'package:bandha/common/types/confirm.dart';
import 'package:bandha/common/widgets/select_form_field.dart';

class ConfirmFormField extends SelectFormField<bool?> {
  ConfirmFormField({
    super.key,
    super.initialValue,
    super.decoration,
    super.autovalidateMode,
    super.enabled,
    super.onSaved,
    super.validator,
    super.readOnly,
  }) : super(
         options: Confirm.values
             .map((i) => SelectItem(value: i.value, label: i.label))
             .toList(),
       );
}
