import 'package:banda/common/decorations/input_styles.dart';
import 'package:banda/common/helpers/alert_helper.dart';
import 'package:banda/features/accounts/entities/account.dart';
import 'package:banda/features/tags/entities/label.dart';
import 'package:banda/features/funds/entities/fund.dart';
import 'package:banda/features/accounts/providers/account_provider.dart';
import 'package:banda/features/tags/providers/label_provider.dart';
import 'package:banda/features/funds/providers/fund_provider.dart';
import 'package:banda/common/types/form_data.dart';
import 'package:banda/common/widgets/amount_form_field.dart';
import 'package:banda/common/widgets/multi_select_form_field.dart';
import 'package:banda/common/widgets/select_form_field.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class FundEditor extends StatefulWidget {
  final String? id;
  final bool readOnly;

  const FundEditor({super.key, this.id, this.readOnly = false});

  @override
  State<FundEditor> createState() => _FundEditorState();
}

class _FundEditorState extends State<FundEditor> {
  final _form = GlobalKey<FormState>();
  final FormData _d = {};

  void handleMoreTap(BuildContext context) {
    Navigator.of(context).pushNamed("/funds/${widget.id}/menu");
  }

  void handleSubmit(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final fundProvider = context.read<FundProvider>();

    try {
      if (_form.currentState!.validate()) {
        _form.currentState!.save();

        if (widget.id == null) {
          await fundProvider.create(
            goal: _d["goal"],
            accountId: _d["accountId"],
            labelIds: _d["labelIds"],
            note: _d["note"],
          );
        }

        if (widget.id != null) {
          await fundProvider.update(
            widget.id!,
            goal: _d["goal"],
            labelIds: _d["labelIds"],
            note: _d["note"],
          );
        }

        navigator.pop();
      }
    } catch (error, stackTrace) {
      if (kDebugMode) {
        print(error);
        print(stackTrace);
      }

      alert(messenger, "Edit fund details failed");
    }
  }

  redirect(BuildContext context, String routeName) {
    _form.currentState!.save();
    Navigator.pushNamed(context, routeName);
  }

  appBarBuilder(BuildContext context) {
    final theme = Theme.of(context);

    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        !widget.readOnly ? "Enter fund details" : "Fund details",
        style: theme.textTheme.titleLarge,
      ),
      centerTitle: true,
      actions: [
        if (!widget.readOnly)
          IconButton(
            onPressed: () {
              handleSubmit(context);
            },
            icon: Icon(Icons.check),
          ),
        if (widget.readOnly)
          IconButton(
            onPressed: () {
              handleMoreTap(context);
            },
            icon: Icon(Icons.more_horiz),
          ),
      ],
      actionsPadding: EdgeInsets.all(8),
    );
  }

  List<Widget> fieldsBuilder(
    BuildContext context, {
    required Fund? fund,
    required List<Label> labels,
    required List<Account> accounts,
  }) {
    final theme = Theme.of(context);

    return [
      TextFormField(
        readOnly: widget.readOnly,
        decoration: InputStyles.field(
          labelText: "Note",
          hintText: "Enter note...",
        ),
        initialValue: _d["note"] ?? fund?.note,
        onSaved: (value) => _d["note"] = value,
      ),
      AmountFormField(
        readOnly: widget.readOnly,
        initialValue: _d["goal"] ?? fund?.goal,
        onSaved: (value) => _d["goal"] = value,
        decoration: InputStyles.field(
          hintText: "Enter goal...",
          labelText: "Goal",
        ),
        validator: (value) => value == null ? "Goal is required" : null,
      ),
      if (widget.readOnly)
        AmountFormField(
          readOnly: widget.readOnly,
          initialValue: _d["balance"] ?? fund?.balance,
          onSaved: (value) => _d["balance"] = value,
          decoration: InputStyles.field(
            hintText: "Enter balance...",
            labelText: "Balance",
          ),
          validator: (value) =>
              value == null ? "Balance is required" : null,
        ),
      SelectFormField<String>(
        readOnly: widget.readOnly,
        initialValue: _d["accountId"] ?? fund?.accountId,
        onSaved: (value) => _d["accountId"] = value,
        validator: (value) =>
            value == null ? "Account is required" : null,
        actions: [
          if (!widget.readOnly)
            ActionChip(
              avatar: Icon(Icons.add, color: theme.colorScheme.outline),
              label: Text(
                "New account",
                style: TextStyle(
                  fontWeight: FontWeight.w100,
                  color: theme.colorScheme.outline,
                ),
              ),
              onPressed: () {
                redirect(context, "/accounts/new");
              },
            ),
        ],
        options: accounts.map((account) {
          return SelectItem(
            value: account.id,
            label: account.displayName(),
          );
        }).toList(),
        decoration: InputStyles.field(
          labelText: "Account",
          hintText: "Select account...",
        ),
      ),
      MultiSelectFormField<String>(
        readOnly: widget.readOnly,
        initialValue: _d["labelIds"] ?? fund?.labelIds ?? [],
        onSaved: (value) => _d["labelIds"] = value,
        actions: [
          if (!widget.readOnly)
            ActionChip(
              avatar: Icon(Icons.add, color: theme.colorScheme.outline),
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
        options: labels.map((labe) {
          return MultiSelectItem(value: labe.id, label: labe.name);
        }).toList(),
        decoration: InputStyles.field(
          labelText: "Labels",
          hintText: "Select labels...",
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final fundProvider = context.read<FundProvider>();
    final accountProvider = context.watch<AccountProvider>();
    final labelProvider = context.watch<LabelProvider>();

    return Scaffold(
      appBar: appBarBuilder(context),
      body: FutureBuilder(
        future: Future.wait([
          accountProvider.search(),
          labelProvider.search(),
          if (widget.id != null) fundProvider.get(widget.id!),
        ]),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final accounts = snapshot.data![0] as List<Account>;
          final labels = snapshot.data![1] as List<Label>;
          final fund = widget.id != null
              ? (snapshot.data![2] as Fund)
              : null;

          final fields = fieldsBuilder(
            context,
            fund: fund,
            labels: labels,
            accounts: accounts,
          );

          return Container(
            padding: EdgeInsets.all(16),
            child: Form(
              key: _form,
              child: ListView.separated(
                itemBuilder: (BuildContext context, int index) {
                  return fields[index];
                },
                separatorBuilder: (BuildContext context, int index) {
                  return SizedBox(height: 16);
                },
                itemCount: fields.length,
              ),
            ),
          );
        },
      ),
    );
  }
}
