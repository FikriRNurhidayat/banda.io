import 'package:bandha/common/decorations/input_styles.dart';
import 'package:bandha/features/journals/entities/journal.dart';
import 'package:bandha/features/obligations/entities/obligation.dart';
import 'package:bandha/features/tags/entities/party.dart';
import 'package:bandha/features/journals/providers/journal_provider.dart';
import 'package:bandha/features/obligations/providers/obligation_filter_provider.dart';
import 'package:bandha/features/tags/providers/party_provider.dart';
import 'package:bandha/common/types/form_data.dart';
import 'package:bandha/common/types/specification.dart';
import 'package:bandha/common/widgets/date_time_range_form_field.dart';
import 'package:bandha/common/widgets/multi_select_form_field.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ObligationFilter extends StatefulWidget {
  final Filter? specs;

  const ObligationFilter({super.key, this.specs});

  @override
  State<StatefulWidget> createState() {
    return _ObligationFilterState();
  }
}

class _ObligationFilterState extends State<ObligationFilter> {
  final _formKey = GlobalKey<FormState>();
  final FormData _formData = {};

  @override
  void initState() {
    super.initState();

    if (widget.specs != null) {
      if (widget.specs!.containsKey("journal_in")) {
        _formData["journal_in"] = widget.specs!["journal_in"];
      }

      if (widget.specs!.containsKey("status_in")) {
        _formData["status_in"] = widget.specs!["status_in"];
      }

      if (widget.specs!.containsKey("type_in")) {
        _formData["type_in"] = widget.specs!["type_in"];
      }

      if (_formData["party_in"] != null &&
          _formData["party_in"]!.isNotEmpty) {
        _formData["party_in"] = widget.specs!["party_in"];
      }

      if (widget.specs!.containsKey("issued_between")) {
        _formData["issued_between"] = widget.specs!["issued_between"];
      }
    }
  }

  void _submit() async {
    final Filter query = {};

    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      if (_formData["type_in"] != null &&
          _formData["type_in"]!.isNotEmpty) {
        query["type_in"] = _formData["type_in"];
      }

      if (_formData["status_in"] != null &&
          _formData["status_in"]!.isNotEmpty) {
        query["status_in"] = _formData["status_in"];
      }

      if (_formData["journal_in"] != null &&
          _formData["journal_in"]!.isNotEmpty) {
        query["journal_in"] = _formData["journal_in"];
      }

      if (_formData["party_in"] != null &&
          _formData["party_in"]!.isNotEmpty) {
        query["party_in"] = _formData["party_in"];
      }

      if (_formData["issued_between"] != null) {
        query["issued_between"] = _formData["issued_between"];
      }

      context.read<ObligationFilterProvider>().set(query);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final journalProvider = context.watch<JournalProvider>();
    final partyProvider = context.watch<PartyProvider>();

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Text(
          "Filter obligations",
          style: theme.textTheme.titleMedium,
        ),
        automaticallyImplyLeading: false,
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: IconButton(
              onPressed: _submit,
              icon: Icon(Icons.check),
            ),
          ),
        ],
      ),
      body: SafeArea(
        bottom: true,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16.0),
          child: FutureBuilder(
            future: Future.wait([
              journalProvider.search(),
              partyProvider.search(),
            ]),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final journals = snapshot.data![0] as List<Journal>;
              final parties = snapshot.data![1] as List<Party>;

              return Form(
                key: _formKey,
                child: Column(
                  spacing: 16,
                  children: [
                    DateTimeRangeFormField(
                      decoration: InputStyles.field(
                        labelText: "Date",
                        hintText: "Select date...",
                      ),
                      initialValue: _formData["issued_between"],
                      onSaved: (value) =>
                          _formData["issued_between"] = value,
                    ),
                    MultiSelectFormField<ObligationStatus>(
                      decoration: InputStyles.field(
                        labelText: "Status",
                        hintText: "Select status...",
                      ),
                      initialValue: _formData["status_in"] ?? [],
                      options: ObligationStatus.values
                          .map(
                            (i) => MultiSelectItem(
                              value: i,
                              label: i.label,
                            ),
                          )
                          .toList(),
                      onSaved: (value) =>
                          _formData["status_in"] = value,
                    ),
                    if (parties.isNotEmpty)
                      MultiSelectFormField<String>(
                        decoration: InputStyles.field(
                          labelText: "Parties",
                          hintText: "Select parties...",
                        ),
                        initialValue: _formData["party_in"] ?? [],
                        options: parties
                            .map(
                              (i) => MultiSelectItem(
                                value: i.id,
                                label: i.name,
                              ),
                            )
                            .toList(),
                        onSaved: (value) =>
                            _formData["party_in"] = value,
                      ),
                    if (journals.isNotEmpty)
                      MultiSelectFormField<String>(
                        decoration: InputStyles.field(
                          labelText: "Debit journals",
                          hintText: "Select debit journals...",
                        ),
                        initialValue: _formData["journal_in"] ?? [],
                        options: journals
                            .map(
                              (i) => MultiSelectItem(
                                value: i.id,
                                label: i.displayName(),
                              ),
                            )
                            .toList(),
                        onSaved: (value) =>
                            _formData["journal_in"] = value,
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
