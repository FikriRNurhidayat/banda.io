import 'package:banda/common/decorations/input_styles.dart';
import 'package:banda/common/helpers/alert_helper.dart';
import 'package:banda/common/widgets/amount_form_field.dart';
import 'package:banda/features/accounts/entities/account.dart';
import 'package:banda/features/accounts/providers/account_provider.dart';
import 'package:banda/common/types/form_data.dart';
import 'package:banda/common/widgets/select_form_field.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AccountEditor extends StatelessWidget {
  final String? id;
  final bool readOnly;

  AccountEditor({super.key, this.id, this.readOnly = false});

  final _form = GlobalKey<FormState>();

  final FormData _d = {};

  void handleMoreTap(BuildContext context) async {
    Navigator.pushNamed(context, "/accounts/${id!}/menu");
  }

  void handleSubmit(BuildContext context) async {
    final accountProvider = context.read<AccountProvider>();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    try {
      if (_form.currentState!.validate()) {
        _form.currentState!.save();

        if (id == null) {
          await accountProvider.create(
            name: _d["name"],
            holderName: _d["holderName"],
            balance: _d["balance"] ?? 0,
            kind: _d["kind"],
          );
        } else {
          await accountProvider.update(
            id!,
            name: _d["name"],
            holderName: _d["holderName"],
            balance: _d["balance"] ?? 0,
            kind: _d["kind"],
          );
        }
        navigator.pop();
      }
    } catch (error, stackTrace) {
      if (kDebugMode) {
        print(error);
        print(stackTrace);
      }

      alert(messenger, "Edit account details failed");
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accountProvider = context.read<AccountProvider>();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          !readOnly ? "Enter account details" : "Account details",
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
        future: Future.wait([if (id != null) accountProvider.get(id!)]),
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

          final account = id != null
              ? snapshot.data![0] as Account
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
                      hintText: "Enter account name...",
                    ),
                    initialValue: _d["name"] ?? account?.name,
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
                        _d["holderName"] ?? account?.holderName,
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
                    initialValue: _d["balance"] ?? account?.balance,
                    onSaved: (value) => _d["balance"] = value ?? 0,
                  ),
                  SelectFormField(
                    readOnly: readOnly,
                    initialValue: _d["kind"] ?? account?.kind,
                    onSaved: (value) => _d["kind"] = value,
                    options: AccountKind.values.map((v) {
                      return SelectItem(value: v, label: v.label);
                    }).toList(),
                    decoration: InputStyles.field(
                      labelText: "Type",
                      hintText: "Select account type...",
                    ),
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
