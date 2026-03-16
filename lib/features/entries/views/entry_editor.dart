import 'package:bandha/common/decorations/input_styles.dart';
import 'package:bandha/common/helpers/alert_helper.dart';
import 'package:bandha/features/vaults/entities/vault.dart';
import 'package:bandha/features/tags/entities/category.dart';
import 'package:bandha/features/entries/entities/entry.dart';
import 'package:bandha/features/tags/entities/label.dart';
import 'package:bandha/common/helpers/type_helper.dart';
import 'package:bandha/features/vaults/providers/vault_provider.dart';
import 'package:bandha/features/tags/providers/category_provider.dart';
import 'package:bandha/features/entries/providers/entry_provider.dart';
import 'package:bandha/features/tags/providers/label_provider.dart';
import 'package:bandha/common/types/form_data.dart';
import 'package:bandha/common/widgets/amount_form_field.dart';
import 'package:bandha/common/widgets/multi_select_form_field.dart';
import 'package:bandha/common/widgets/select_form_field.dart';
import 'package:bandha/common/widgets/when_form_field.dart';
import 'package:flutter/foundation.dart' hide Category;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class EntryEditor extends StatefulWidget {
  final String? id;
  final bool readOnly;

  const EntryEditor({super.key, this.id, this.readOnly = false});

  @override
  State<EntryEditor> createState() => _EditorState();
}

class _EditorState extends State<EntryEditor> {
  final _form = GlobalKey<FormState>();
  final FormData _d = {};

  void handleMoreTap(BuildContext context) async {
    Navigator.pushNamed(context, "/entries/${widget.id!}/menu");
  }

  void handleSubmitTap(BuildContext context) async {
    _form.currentState!.save();

    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final entryProvider = context.read<EntryProvider>();

    if (_form.currentState!.validate()) {
      try {
        if (widget.id == null) {
          await entryProvider.create(
            note: _d["note"],
            amount: _d["amount"],
            type: _d["type"],
            status: _d["status"],
            categoryId: _d["categoryId"],
            vaultId: _d["vaultId"],
            issuedAt: _d["issuedAt"].dateTime,
            labelIds: _d["labelIds"],
          );
        }

        if (widget.id != null) {
          await entryProvider.update(
            id: widget.id!,
            note: _d["note"],
            amount: _d["amount"],
            type: _d["type"],
            status: _d["status"],
            categoryId: _d["categoryId"],
            vaultId: _d["vaultId"],
            issuedAt: _d["issuedAt"].dateTime,
            labelIds: _d["labelIds"],
          );
        }

        navigator.pop();
      } catch (error, stackTrace) {
        if (kDebugMode) {
          print(error);
          print(stackTrace);
        }

        alert(messenger, "Edit entry details failed");
      }
    }
  }

  redirect(String routeName) {
    _form.currentState!.save();
    Navigator.pushNamed(context, routeName);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final entryProvider = context.read<EntryProvider>();
    final categoryProvider = context.watch<CategoryProvider>();
    final vaultProvider = context.watch<VaultProvider>();
    final labelProvider = context.watch<LabelProvider>();

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.readOnly ? "Entry details" : "Enter entry details",
          style: theme.textTheme.titleLarge,
        ),
        actions: [
          if (!widget.readOnly)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: IconButton(
                onPressed: () {
                  handleSubmitTap(context);
                },
                icon: Icon(Icons.check),
              ),
            ),

          if (widget.readOnly)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: IconButton(
                onPressed: () {
                  handleMoreTap(context);
                },
                icon: Icon(Icons.more_horiz),
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
              categoryProvider.search(),
              vaultProvider.search(),
              labelProvider.search(),
              if (widget.id != null) entryProvider.get(widget.id!),
            ]),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return const Center(child: Text("..."));
              }

              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final categories = snapshot.data![0] as List<Category>;
              final vaults = snapshot.data![1] as List<Vault>;
              final labels = snapshot.data![2] as List<Label>;
              final entry = widget.id != null
                  ? snapshot.data![3] as Entry
                  : null;

              return Form(
                key: _form,
                child: Column(
                  spacing: 16,
                  children: [
                    if (!widget.readOnly ||
                        (entry?.note != null &&
                            entry!.note!.isNotEmpty))
                      TextFormField(
                        readOnly: widget.readOnly,
                        decoration: InputStyles.field(
                          labelText: "Note",
                          hintText: "Enter note...",
                        ),
                        initialValue: _d["note"] ?? entry?.note,
                        onSaved: (value) => _d["note"] = value ?? '',
                      ),
                    SelectFormField<EntryType>(
                      readOnly: widget.readOnly,
                      initialValue: _d["type"] ?? entry?.entryType,
                      onSaved: (value) => _d["type"] = value,
                      decoration: InputStyles.field(
                        labelText: "Type",
                        hintText: "Select type...",
                      ),
                      options: EntryType.values.map((c) {
                        return SelectItem(value: c, label: c.label);
                      }).toList(),
                    ),
                    AmountFormField(
                      readOnly: widget.readOnly,
                      decoration: InputStyles.field(
                        labelText: "Amount",
                        hintText: "Enter amount...",
                      ),
                      initialValue:
                          _d["amount"]?.abs() ?? entry?.amount.abs(),
                      onSaved: (value) => _d["amount"] = value,
                      validator: (value) =>
                          value == null ? "Enter amount" : null,
                    ),
                    WhenFormField(
                      readOnly: widget.readOnly,
                      options: WhenOption.min,
                      initialValue:
                          _d["issuedAt"] ??
                          (entry?.issuedAt != null
                              ? When.specificTime(entry!.issuedAt)
                              : When.now()),
                      onSaved: (value) => _d["issuedAt"] = value,
                      validator: (value) => value == null
                          ? "Date & time are required"
                          : null,
                      decoration: InputStyles.field(
                        hintText: "Select date & time...",
                        labelText: "Date & Time",
                      ),
                      dateInputDecoration: InputStyles.field(
                        labelText: "Date",
                        hintText: "Select date...",
                      ),
                      timeInputDecoration: InputStyles.field(
                        labelText: "Time",
                        hintText: "Select time...",
                      ),
                    ),
                    SelectFormField<EntryStatus>(
                      readOnly: widget.readOnly,
                      initialValue:
                          _d["status"] ??
                          entry?.status ??
                          EntryStatus.done,
                      onSaved: (value) => _d["status"] = value,
                      decoration: InputStyles.field(
                        labelText: "Status",
                        hintText: "Select status...",
                      ),
                      options: EntryStatus.values
                          .where((c) => c != EntryStatus.unknown)
                          .map((c) {
                            return SelectItem(value: c, label: c.label);
                          })
                          .toList(),
                    ),
                    SelectFormField<String>(
                      readOnly: widget.readOnly,
                      initialValue:
                          _d["categoryId"] ?? entry?.categoryId,
                      onSaved: (value) => _d["categoryId"] = value,
                      decoration: InputStyles.field(
                        labelText: "Category",
                        hintText: "Select category...",
                      ),
                      actions: [
                        if (!widget.readOnly)
                          ActionChip(
                            avatar: Icon(
                              Icons.add,
                              color: theme.colorScheme.outline,
                            ),
                            label: Text(
                              "New category",
                              style: TextStyle(
                                fontWeight: FontWeight.w100,
                                color: theme.colorScheme.outline,
                              ),
                            ),
                            onPressed: () {
                              redirect("/categories/edit");
                            },
                          ),
                      ],
                      options: categories
                          .where((c) => widget.readOnly || !c.readonly)
                          .map((c) {
                            return SelectItem(
                              value: c.id,
                              label: c.name,
                            );
                          })
                          .toList(),
                    ),
                    SelectFormField(
                      readOnly: widget.readOnly,
                      decoration: InputStyles.field(
                        labelText: "Vault",
                        hintText: "Select vault...",
                      ),
                      actions: [
                        if (!widget.readOnly)
                          ActionChip(
                            avatar: Icon(
                              Icons.add,
                              color: theme.colorScheme.outline,
                            ),
                            label: Text(
                              "New vault",
                              style: TextStyle(
                                fontWeight: FontWeight.w100,
                                color: theme.colorScheme.outline,
                              ),
                            ),
                            onPressed: () {
                              redirect("/vaults/new");
                            },
                          ),
                      ],
                      options: vaults.map((i) {
                        return SelectItem(
                          value: i.id,
                          label: "${i.name} — ${i.holderName}",
                        );
                      }).toList(),
                      initialValue: _d["vaultId"] ?? entry?.vaultId,
                      onSaved: (value) => _d["vaultId"] = value,
                    ),
                    if (!widget.readOnly || !isEmpty(entry?.labels))
                      MultiSelectFormField<String>(
                        readOnly: widget.readOnly,
                        decoration: InputStyles.field(
                          labelText: "Labels",
                          hintText: "Select labels...",
                        ),
                        actions: [
                          if (!widget.readOnly)
                            ActionChip(
                              avatar: Icon(
                                Icons.add,
                                color: theme.colorScheme.outline,
                              ),
                              label: Text(
                                "New label",
                                style: TextStyle(
                                  fontWeight: FontWeight.w100,
                                  color: theme.colorScheme.outline,
                                ),
                              ),
                              onPressed: () {
                                redirect("/labels/edit");
                              },
                            ),
                        ],
                        initialValue:
                            _d["labelIds"] ?? entry?.labelIds ?? [],
                        onSaved: (value) => _d["labelIds"] = value,
                        options: labels.map((l) {
                          return MultiSelectItem(
                            value: l.id,
                            label: l.name,
                          );
                        }).toList(),
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
