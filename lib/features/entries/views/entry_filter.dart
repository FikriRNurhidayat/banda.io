import 'package:bandha/common/decorations/input_styles.dart';
import 'package:bandha/features/vaults/entities/vault.dart';
import 'package:bandha/features/tags/entities/category.dart';
import 'package:bandha/features/entries/entities/entry.dart';
import 'package:bandha/features/tags/entities/label.dart';
import 'package:bandha/features/vaults/providers/vault_provider.dart';
import 'package:bandha/features/tags/providers/category_provider.dart';
import 'package:bandha/features/entries/providers/entry_filter_provider.dart';
import 'package:bandha/features/tags/providers/label_provider.dart';
import 'package:bandha/common/types/form_data.dart';
import 'package:bandha/common/types/specification.dart';
import 'package:bandha/common/widgets/date_time_range_form_field.dart';
import 'package:bandha/common/widgets/multi_select_form_field.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class EntryFilter extends StatefulWidget {
  final Filter? specification;

  const EntryFilter({super.key, this.specification});

  @override
  State<StatefulWidget> createState() {
    return _EntryFilterState();
  }
}

class _EntryFilterState extends State<EntryFilter> {
  final _formKey = GlobalKey<FormState>();
  final FormData _formData = {};

  @override
  void initState() {
    super.initState();

    if (widget.specification != null) {
      if (widget.specification!.containsKey("category_in")) {
        _formData["category_in"] = widget.specification!["category_in"];
      }

      if (widget.specification!.containsKey("vault_in")) {
        _formData["vault_in"] = widget.specification!["vault_in"];
      }

      if (widget.specification!.containsKey("label_in")) {
        _formData["label_in"] = widget.specification!["label_in"];
      }

      if (widget.specification!.containsKey("note_regex")) {
        _formData["note_regex"] = widget.specification!["note_regex"];
      }

      if (widget.specification!.containsKey("status_in")) {
        _formData["status_in"] = widget.specification!["status_in"];
      }

      if (widget.specification!.containsKey("issued_between")) {
        _formData["issued_between"] = widget.specification!["issued_between"];
      }
    }
  }

  bool isNotNull(field) {
    return _formData[field] != null;
  }

  bool isNotEmpty(field) {
    return isNotNull(field) && _formData[field]!.isNotEmpty;
  }

  void _submit() async {
    final Filter specification = {};

    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      if (isNotEmpty("note_regex")) {
        specification["note_regex"] = _formData["note_regex"];
      }

      if (isNotEmpty("label_in")) {
        specification["label_in"] = _formData["label_in"];
      }

      if (isNotEmpty("status_in")) {
        specification["status_in"] = _formData["status_in"];
      }

      if (isNotEmpty("category_in")) {
        specification["category_in"] = _formData["category_in"];
      }

      if (isNotEmpty("vault_in")) {
        specification["vault_in"] = _formData["vault_in"];
      }

      if (isNotNull("issued_between")) {
        specification["issued_between"] = _formData["issued_between"];
      }

      context.read<EntryFilterProvider>().set(specification);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoryProvider = context.watch<CategoryProvider>();
    final vaultProvider = context.watch<VaultProvider>();
    final labelProvider = context.watch<LabelProvider>();

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const Text(
          "Filter entries",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w400),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: IconButton(onPressed: _submit, icon: Icon(Icons.check)),
          ),
        ],
      ),
      body: SafeArea(
        bottom: true,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16.0),
          child: FutureBuilder(
            future: Future.wait([
              categoryProvider.search(),
              vaultProvider.search(),
              labelProvider.search(),
            ]),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final categories = snapshot.data![0] as List<Category>;
              final vaults = snapshot.data![1] as List<Vault>;
              final labels = snapshot.data![2] as List<Label>;

              return Form(
                key: _formKey,
                child: Column(
                  spacing: 16,
                  children: [
                    TextFormField(
                      initialValue: _formData["note_regex"],
                      onSaved: (value) => _formData["note_regex"] = value,
                      decoration: InputStyles.field(
                        labelText: "Note",
                        hintText: "Search note...",
                      ),
                    ),
                    DateTimeRangeFormField(
                      initialValue: _formData["issued_between"],
                      onSaved: (value) => _formData["issued_between"] = value,
                      decoration: InputStyles.field(
                        labelText: "Issued between",
                        hintText: "Select date range...",
                      ),
                    ),
                    MultiSelectFormField<EntryStatus>(
                      initialValue: _formData["status_in"] ?? [],
                      onSaved: (value) => _formData["status_in"] = value,
                      options: EntryStatus.values
                          .where((i) => i != EntryStatus.unknown)
                          .map((i) => MultiSelectItem(value: i, label: i.label))
                          .toList(),
                      decoration: InputStyles.field(
                        labelText: "Status",
                        hintText: "Select status...",
                      ),
                    ),
                    MultiSelectFormField<String>(
                      initialValue: _formData["category_in"] ?? [],
                      onSaved: (value) => _formData["category_in"] = value,
                      options: categories
                          .map(
                            (i) => MultiSelectItem(value: i.id, label: i.name),
                          )
                          .toList(),
                      decoration: InputStyles.field(
                        labelText: "Categories",
                        hintText: "Select categories...",
                      ),
                    ),
                    if (vaults.isNotEmpty)
                      MultiSelectFormField<String>(
                        initialValue: _formData["vault_in"] ?? [],
                        onSaved: (value) => _formData["vault_in"] = value,
                        options: vaults
                            .map(
                              (i) => MultiSelectItem(
                                value: i.id,
                                label: i.displayName(),
                              ),
                            )
                            .toList(),
                        decoration: InputStyles.field(
                          labelText: "Vaults",
                          hintText: "Select vaults...",
                        ),
                      ),
                    if (labels.isNotEmpty)
                      MultiSelectFormField<String>(
                        initialValue: _formData["label_in"] ?? [],
                        onSaved: (value) => _formData["label_in"] = value,
                        options: labels
                            .map(
                              (i) =>
                                  MultiSelectItem(value: i.id, label: i.name),
                            )
                            .toList(),
                        decoration: InputStyles.field(
                          labelText: "Labels",
                          hintText: "Select labels...",
                        ),
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
