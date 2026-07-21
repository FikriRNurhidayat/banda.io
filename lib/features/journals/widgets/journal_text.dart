import 'package:bandha/features/journals/entities/journal.dart';
import 'package:flutter/material.dart';

class JournalText extends StatelessWidget {
  final Journal journal;

  const JournalText(this.journal, {super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Text(
      journal.displayName(),
      style: theme.textTheme.bodySmall,
    );
  }
}
