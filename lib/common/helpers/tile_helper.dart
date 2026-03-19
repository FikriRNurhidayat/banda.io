import 'package:bandha/features/tags/entities/label.dart';
import 'package:flutter/material.dart';

labelsBuilder(
  BuildContext context,
  Iterable<Label> labels, {
  TextStyle? style,
}) {
  final theme = Theme.of(context);
  return Row(
    spacing: 8,
    children: [
      ...labels
          .take(2)
          .map(
            (label) => Text(
              label.name,
              overflow: TextOverflow.ellipsis,
              style: style ?? theme.textTheme.bodySmall,
            ),
          ),
      if (labels.length > 2)
        Icon(
          Icons.more_horiz,
          size: 8,
          color: theme.colorScheme.primary,
        ),
    ],
  );
}

tileBuilder(
  BuildContext context, {
  GestureTapCallback? onTap,
  GestureLongPressCallback? onLongPress,
  required Widget child,
}) {
  final theme = Theme.of(context);
  return Material(
    color: theme.cardColor,
    child: InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(padding: EdgeInsets.all(16), child: child),
    ),
  );
}

dismissibleBuilder(
  BuildContext context, {
  required dynamic key,
  required Widget child,
  required bool dismissable,
  required ConfirmDismissCallback confirmDismiss,
}) {
  final theme = Theme.of(context);
  return Dismissible(
    key: Key(key),
    background: Container(
      color: theme.colorScheme.surfaceContainer,
      alignment: Alignment.center,
      padding: EdgeInsets.symmetric(horizontal: 16),
    ),
    secondaryBackground: Container(
      color: theme.colorScheme.surfaceContainer,
      alignment: Alignment.center,
      padding: EdgeInsets.symmetric(horizontal: 16),
    ),
    direction: !dismissable
        ? DismissDirection.none
        : DismissDirection.horizontal,
    confirmDismiss: confirmDismiss,
    child: child,
  );
}
