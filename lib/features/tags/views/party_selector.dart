import 'package:bandha/features/tags/entities/party.dart';
import 'package:bandha/features/tags/layouts/tagable_selector.dart';
import 'package:bandha/features/tags/providers/party_provider.dart';
import 'package:flutter/material.dart';

class PartySelector extends StatelessWidget {
  const PartySelector({super.key});

  @override
  Widget build(BuildContext context) {
    return TagableSelector<Party, PartyProvider>(
      title: "Edit parties",
      deletePromptText: "Are you sure you want to delete this party?",
      deletePromptTitle: "Delete party",
      hintText: "Create new party",
      tileIcon: Icons.person,
    );
  }
}
