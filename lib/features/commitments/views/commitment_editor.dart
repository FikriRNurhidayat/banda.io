import 'package:bandha/common/decorations/input_styles.dart';
import 'package:bandha/common/helpers/alert_helper.dart';
import 'package:bandha/common/widgets/multi_select_form_field.dart';
import 'package:bandha/features/entries/entities/entry.dart';
import 'package:bandha/features/tags/entities/category.dart';
import 'package:bandha/features/tags/entities/label.dart';
import 'package:bandha/features/tags/providers/category_provider.dart';
import 'package:bandha/features/tags/providers/label_provider.dart';
import 'package:bandha/features/vaults/entities/vault.dart';
import 'package:bandha/features/commitments/entities/commitment.dart';
import 'package:bandha/features/tags/entities/party.dart';
import 'package:bandha/features/vaults/providers/vault_provider.dart';
import 'package:bandha/features/commitments/providers/commitment_provider.dart';
import 'package:bandha/features/tags/providers/party_provider.dart';
import 'package:bandha/common/types/form_data.dart';
import 'package:bandha/common/widgets/amount_form_field.dart';
import 'package:bandha/common/widgets/select_form_field.dart';
import 'package:bandha/common/widgets/when_form_field.dart';
import 'package:flutter/foundation.dart' hide Category;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CommitmentEditor extends StatefulWidget {
  final String? id;
  final bool readOnly;
  const CommitmentEditor({super.key, this.id, this.readOnly = false});

  @override
  State<CommitmentEditor> createState() => _CommitmentEditorState();
}

class _CommitmentEditorState extends State<CommitmentEditor> {
  final _form = GlobalKey<FormState>();
  final FormData _d = {};

  void handleMoreTap(BuildContext context) async {
    Navigator.pushNamed(context, "/commitments/${widget.id!}/menu");
  }

  void handleSubmit() {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final commitmentProvider = context.read<CommitmentProvider>();

    if (_form.currentState!.validate()) {
      _form.currentState!.save();

      Future(() async {
        if (widget.id == null) {
          await commitmentProvider.create(
            fee: _d["fee"],
            amount: _d["amount"],
            issuedAt: _d["issuedAt"].dateTime,
            settledAt: _d["settledAt"]?.dateTime,
            type: _d["type"],
            status: _d["status"],
            categoryId: _d["categoryId"],
            partyId: _d["partyId"],
            vaultId: _d["vaultId"],
            labelIds: _d["labelIds"],
          );
        }

        if (widget.id != null) {
          await commitmentProvider.update(
            widget.id!,
            fee: _d["fee"],
            amount: _d["amount"],
            issuedAt: _d["issuedAt"].dateTime,
            settledAt: _d["settledAt"]?.dateTime,
            type: _d["type"],
            status: _d["status"],
            categoryId: _d["categoryId"],
            partyId: _d["partyId"],
            vaultId: _d["vaultId"],
            labelIds: _d["labelIds"],
          );
        }
      }).then((_) => navigator.pop()).catchError((error, stackTrace) {
        if (kDebugMode) {
          print(error);
          print(stackTrace);
        }

        alert(messenger, "Edit commitment details failed");
      });
    }
  }

  redirect(BuildContext context, String named) {
    _form.currentState!.save();
    Navigator.pushNamed(context, named);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final commitmentProvider = context.watch<CommitmentProvider>();
    final categoryProvider = context.watch<CategoryProvider>();
    final partyProvider = context.watch<PartyProvider>();
    final vaultProvider = context.watch<VaultProvider>();
    final labelProvider = context.watch<LabelProvider>();

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          !widget.readOnly
              ? "Enter commitment details"
              : "Commitment details",
          style: theme.textTheme.titleLarge,
        ),
        actions: [
          if (!widget.readOnly)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: IconButton(
                onPressed: () {
                  handleSubmit();
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
              partyProvider.search(),
              vaultProvider.search(),
              categoryProvider.search(),
              labelProvider.search(),
              if (widget.id != null) commitmentProvider.get(widget.id!),
            ]),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final parties = snapshot.data![0] as List<Party>;
              final vaults = snapshot.data![1] as List<Vault>;
              final categories = snapshot.data![2] as List<Category>;
              final labels = snapshot.data![3] as List<Label>;
              final commitment = widget.id != null
                  ? (snapshot.data![4] as Commitment)
                  : null;

              return Form(
                key: _form,
                child: Column(
                  spacing: 16,
                  children: [
                    AmountFormField(
                      readOnly: widget.readOnly,
                      initialValue:
                          _d["amount"] ?? commitment?.amount.abs(),
                      decoration: InputStyles.field(
                        hintText: "Enter amount...",
                        labelText: "Amount",
                      ),
                      onSaved: (value) => _d["amount"] = value,
                      validator: (value) =>
                          value == null ? "Amount is required" : null,
                    ),
                    AmountFormField(
                      readOnly: widget.readOnly,
                      initialValue: _d["fee"] ?? commitment?.fee,
                      decoration: InputStyles.field(
                        hintText: "Enter fee...",
                        labelText: "Fee",
                      ),
                      onSaved: (value) => _d["fee"] = value,
                    ),
                    SelectFormField<EntryType>(
                      readOnly: widget.readOnly,
                      initialValue: _d["type"] ?? commitment?.entryType,
                      onSaved: (value) => _d["type"] = value,
                      validator: (value) =>
                          value == null ? "Type is required" : null,
                      options: EntryType.values.map((v) {
                        return SelectItem(value: v, label: v.label);
                      }).toList(),
                      decoration: InputStyles.field(
                        labelText: "Type",
                        hintText: "Select commitment type...",
                      ),
                    ),
                    SelectFormField<CommitmentStatus>(
                      readOnly: widget.readOnly,
                      onSaved: (value) => _d["status"] = value,
                      initialValue:
                          _d["status"] ??
                          commitment?.status ??
                          CommitmentStatus.active,
                      validator: (value) =>
                          value == null ? "Status is required" : null,
                      options: CommitmentStatus.values.map((v) {
                        return SelectItem(value: v, label: v.label);
                      }).toList(),
                      decoration: InputStyles.field(
                        labelText: "Status",
                        hintText: "Select status type...",
                      ),
                    ),
                    SelectFormField<String>(
                      readOnly: widget.readOnly,
                      initialValue:
                          _d["categoryId"] ?? commitment?.categoryId,
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
                              redirect(context, "/categories/edit");
                            },
                          ),
                      ],
                      options: categories
                          .where((c) => widget.readOnly || !c.readOnly)
                          .map((c) {
                            return SelectItem(
                              value: c.id,
                              label: c.name,
                            );
                          })
                          .toList(),
                    ),
                    WhenFormField(
                      readOnly: widget.readOnly,
                      options: [
                        WhenOption.now,
                        WhenOption.specificTime,
                      ],
                      decoration: InputStyles.field(
                        labelText: "Issue",
                        hintText: "Select issue date & time...",
                      ),
                      dateInputDecoration: InputStyles.field(
                        labelText: "Date",
                        hintText: "Select issue date...",
                      ),
                      timeInputDecoration: InputStyles.field(
                        labelText: "Time",
                        hintText: "Select issue time...",
                      ),
                      initialValue:
                          _d["issuedAt"] ??
                          (commitment?.issuedAt != null
                              ? When.specificTime(commitment!.issuedAt)
                              : When.now()),
                      onSaved: (value) => _d["issuedAt"] = value,
                      validator: (value) => value == null
                          ? "Issue date & time is required"
                          : null,
                    ),
                    WhenFormField(
                      readOnly: widget.readOnly,
                      options: [
                        WhenOption.now,
                        WhenOption.specificTime,
                        WhenOption.whenever,
                      ],
                      decoration: InputStyles.field(
                        labelText: "Settle",
                        hintText: "Select settle date & time...",
                      ),
                      dateInputDecoration: InputStyles.field(
                        labelText: "Date",
                        hintText: "Select settle date...",
                      ),
                      timeInputDecoration: InputStyles.field(
                        labelText: "Time",
                        hintText: "Select settle time...",
                      ),
                      initialValue:
                          _d["settledAt"] ??
                          (commitment?.settledAt != null
                              ? When.specificTime(
                                  commitment!.settledAt!,
                                )
                              : When.whenever()),
                      onSaved: (value) => _d["settledAt"] = value,
                      validator: (value) => value == null
                          ? "Settle date & time is required"
                          : null,
                    ),
                    SelectFormField<String>(
                      readOnly: widget.readOnly,
                      initialValue:
                          _d["vaultId"] ?? commitment?.vaultId,
                      onSaved: (value) => _d["vaultId"] = value,
                      validator: (value) =>
                          value == null ? "Vault is required" : null,
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
                              redirect(context, "/vaults/new");
                            },
                          ),
                      ],
                      options: vaults.map((vault) {
                        return SelectItem(
                          value: vault.id,
                          label: vault.displayName(),
                        );
                      }).toList(),
                      decoration: InputStyles.field(
                        labelText: "Vault",
                        hintText: "Select vault...",
                      ),
                    ),
                    SelectFormField<String>(
                      readOnly: widget.readOnly,
                      initialValue:
                          _d["partyId"] ?? commitment?.partyId,
                      onSaved: (value) => _d["partyId"] = value,
                      validator: (value) =>
                          value == null ? "Party is required" : null,
                      actions: [
                        if (!widget.readOnly)
                          ActionChip(
                            avatar: Icon(
                              Icons.add,
                              color: theme.colorScheme.outline,
                            ),
                            label: Text(
                              "New party",
                              style: TextStyle(
                                fontWeight: FontWeight.w100,
                                color: theme.colorScheme.outline,
                              ),
                            ),
                            onPressed: () {
                              redirect(context, "/parties/edit");
                            },
                          ),
                      ],
                      options: parties.map((party) {
                        return SelectItem(
                          value: party.id,
                          label: party.name,
                        );
                      }).toList(),
                      decoration: InputStyles.field(
                        labelText: "Party",
                        hintText: "Select party...",
                      ),
                    ),
                    MultiSelectFormField<String>(
                      readOnly: widget.readOnly,
                      initialValue:
                          _d["labelIds"] ?? commitment?.labelIds ?? [],
                      onSaved: (value) => _d["labelIds"] = value,
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
                              redirect(context, "/labels/edit");
                            },
                          ),
                      ],
                      options: labels
                          .where(
                            (label) =>
                                widget.readOnly || !label.readOnly,
                          )
                          .map((label) {
                            return MultiSelectItem(
                              value: label.id,
                              label: label.name,
                            );
                          })
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
