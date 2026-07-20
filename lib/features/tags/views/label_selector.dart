import 'package:bandha/features/tags/entities/label.dart';
import 'package:bandha/features/tags/layouts/tagable_selector.dart';
import 'package:bandha/features/tags/providers/label_provider.dart';
import 'package:flutter/material.dart';

class LabelSelector extends StatelessWidget {
  const LabelSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return TagableSelector<Label, LabelProvider>(
      title: "Edit labels",
      deletePromptText: "Are you sure you want to delete this label?",
      deletePromptTitle: "Delete label",
      hintText: "Create new label",
    );
  }
}
