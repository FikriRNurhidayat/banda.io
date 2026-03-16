import 'package:bandha/common/decorations/input_styles.dart';
import 'package:bandha/common/helpers/alert_helper.dart';
import 'package:bandha/features/vaults/entities/vault.dart';
import 'package:bandha/features/transfers/entities/transfer.dart';
import 'package:bandha/features/transfers/providers/transfer_provider.dart';
import 'package:bandha/common/helpers/type_helper.dart';
import 'package:bandha/features/vaults/providers/vault_provider.dart';
import 'package:bandha/common/types/form_data.dart';
import 'package:bandha/common/widgets/amount_form_field.dart';
import 'package:bandha/common/widgets/select_form_field.dart';
import 'package:bandha/common/widgets/when_form_field.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class TransferEditor extends StatefulWidget {
  final String? id;
  final bool readOnly;

  const TransferEditor({super.key, this.id, this.readOnly = false});

  @override
  State<TransferEditor> createState() => _TransferEditorState();
}

class _TransferEditorState extends State<TransferEditor> {
  final _form = GlobalKey<FormState>();
  final FormData _d = {};

  void handleSubmit(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final transferProvider = context.read<TransferProvider>();

    try {
      if (_form.currentState!.validate()) {
        _form.currentState!.save();

        if (isNull(widget.id)) {
          await transferProvider.create(
            amount: _d["amount"],
            fee: _d["fee"],
            issuedAt: _d["issuedAt"].dateTime,
            debitVaultId: _d["debitVaultId"],
            creditVaultId: _d["creditVaultId"],
          );
        }

        if (!isNull(widget.id)) {
          await transferProvider.update(
            id: widget.id!,
            amount: _d["amount"],
            fee: _d["fee"],
            issuedAt: _d["issuedAt"].dateTime,
            debitVaultId: _d["debitVaultId"],
            creditVaultId: _d["creditVaultId"],
          );
        }

        navigator.pop();
      }
    } catch (error, stackTrace) {
      if (kDebugMode) {
        print(error);
        print(stackTrace);
      }

      alert(messenger, "Edit transfer details failed");
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  redirect(BuildContext context, String routeName) {
    _form.currentState!.save();
    Navigator.pushNamed(context, routeName);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final vaultProvider = context.watch<VaultProvider>();
    final transferProvider = context.read<TransferProvider>();

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text(
          !widget.readOnly
              ? "Enter transfer details"
              : "Transfer details",
          style: theme.textTheme.titleLarge,
        ),
        actions: [
          if (!widget.readOnly)
            IconButton(
              onPressed: () {
                handleSubmit(context);
              },
              icon: Icon(Icons.check),
            ),
        ],
        actionsPadding: EdgeInsets.all(8),
      ),
      body: SafeArea(
        bottom: true,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16.0),
          child: FutureBuilder(
            future: Future.wait([
              vaultProvider.search(),
              if (widget.id != null) transferProvider.get(widget.id!),
            ]),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final vaults = snapshot.data![0] as List<Vault>;
              final transfer = widget.id != null
                  ? snapshot.data![1] as Transfer
                  : null;

              return Form(
                key: _form,
                child: Column(
                  spacing: 16,
                  children: [
                    AmountFormField(
                      readOnly: widget.readOnly,
                      initialValue: _d["amount"] ?? transfer?.amount,
                      onSaved: (value) => _d["amount"] = value,
                      decoration: InputStyles.field(
                        hintText: "Enter amount...",
                        labelText: "Amount",
                      ),
                      validator: (value) =>
                          value == null ? "Amount is required" : null,
                    ),
                    AmountFormField(
                      readOnly: widget.readOnly,
                      initialValue: _d["fee"] ?? transfer?.fee,
                      onSaved: (value) => _d["fee"] = value,
                      decoration: InputStyles.field(
                        hintText: "Enter fee...",
                        labelText: "Fee",
                      ),
                    ),
                    WhenFormField(
                      readOnly: widget.readOnly,
                      options: WhenOption.min,
                      initialValue:
                          _d["issuedAt"] ??
                          (transfer?.issuedAt != null
                              ? When.specificTime(transfer!.issuedAt)
                              : When.now()),
                      onSaved: (value) => _d["issuedAt"] = value,
                      validator: (value) => value == null
                          ? "Issue Date & time are required"
                          : null,
                      decoration: InputStyles.field(
                        hintText: "Select issue date & time...",
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
                    SelectFormField(
                      readOnly: widget.readOnly,
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
                      initialValue:
                          _d["creditVaultId"] ??
                          transfer?.creditVaultId,
                      onSaved: (value) =>
                          _d["creditVaultId"] = value ?? '',
                      validator: (_) => null,
                      decoration: InputStyles.field(
                        labelText: "From",
                        hintText: "Select source vault...",
                      ),
                      options: vaults.map((i) {
                        return SelectItem(
                          value: i.id,
                          label: i.displayName(),
                        );
                      }).toList(),
                    ),
                    SelectFormField(
                      readOnly: widget.readOnly,
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
                      initialValue:
                          _d["debitVaultId"] ??
                          transfer?.debitVaultId,
                      onSaved: (value) =>
                          _d["debitVaultId"] = value ?? '',
                      validator: (_) => null,
                      decoration: InputStyles.field(
                        labelText: "To",
                        hintText: "Select target vault...",
                      ),
                      options: vaults.map((i) {
                        return SelectItem(
                          value: i.id,
                          label: i.displayName(),
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
