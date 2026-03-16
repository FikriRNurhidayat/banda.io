import 'package:bandha/common/decorations/input_styles.dart';
import 'package:bandha/common/helpers/alert_helper.dart';
import 'package:bandha/common/widgets/amount_form_field.dart';
import 'package:bandha/features/vaults/entities/vault.dart';
import 'package:bandha/features/vaults/providers/vault_provider.dart';
import 'package:bandha/common/types/form_data.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class VaultEditor extends StatelessWidget {
  final String? id;
  final bool readOnly;

  VaultEditor({super.key, this.id, this.readOnly = false});

  final _form = GlobalKey<FormState>();

  final FormData _d = {};

  void handleMoreTap(BuildContext context) async {
    Navigator.pushNamed(context, "/vaults/${id!}/menu");
  }

  void handleSubmit(BuildContext context) async {
    final vaultProvider = context.read<VaultProvider>();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    try {
      if (_form.currentState!.validate()) {
        _form.currentState!.save();

        if (id == null) {
          await vaultProvider.create(
            name: _d["name"],
            holderName: _d["holderName"],
            balance: _d["balance"] ?? 0,
          );
        } else {
          await vaultProvider.update(
            id!,
            name: _d["name"],
            holderName: _d["holderName"],
            balance: _d["balance"] ?? 0,
          );
        }
        navigator.pop();
      }
    } catch (error, stackTrace) {
      if (kDebugMode) {
        print(error);
        print(stackTrace);
      }

      alert(messenger, "Edit vault details failed");
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final vaultProvider = context.read<VaultProvider>();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          !readOnly ? "Enter vault details" : "Vault details",
          style: theme.textTheme.titleLarge,
        ),
        centerTitle: true,
        actions: [
          if (!readOnly)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: IconButton(
                onPressed: () {
                  handleSubmit(context);
                },
                icon: Icon(Icons.check),
              ),
            ),
          if (readOnly)
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
      body: FutureBuilder(
        future: Future.wait([if (id != null) vaultProvider.get(id!)]),
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

          final vault = id != null
              ? snapshot.data![0] as Vault
              : null;

          return Padding(
            padding: EdgeInsets.all(16),
            child: Form(
              key: _form,
              child: Column(
                spacing: 16,
                children: [
                  TextFormField(
                    readOnly: readOnly,
                    decoration: InputStyles.field(
                      labelText: "Name",
                      hintText: "Enter vault name...",
                    ),
                    initialValue: _d["name"] ?? vault?.name,
                    onSaved: (value) => _d["name"] = value ?? '',
                    validator: (value) => value == null || value.isEmpty
                        ? "Name is required"
                        : null,
                  ),
                  TextFormField(
                    readOnly: readOnly,
                    decoration: InputStyles.field(
                      labelText: "Holder",
                      hintText: "Enter holder name...",
                    ),
                    initialValue:
                        _d["holderName"] ?? vault?.holderName,
                    onSaved: (value) => _d["holderName"] = value ?? '',
                    validator: (value) => value == null || value.isEmpty
                        ? "Holder is required"
                        : null,
                  ),
                  AmountFormField(
                    readOnly: readOnly,
                    decoration: InputStyles.field(
                      labelText: "Balance",
                      hintText: "Enter balance...",
                    ),
                    initialValue: _d["balance"] ?? vault?.balance,
                    onSaved: (value) => _d["balance"] = value ?? 0,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
