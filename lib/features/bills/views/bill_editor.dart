import 'package:banda/common/decorations/input_styles.dart';
import 'package:banda/common/helpers/alert_helper.dart';
import 'package:banda/common/widgets/growable_multi_select_form_field.dart';
import 'package:banda/common/widgets/growable_select_form_field.dart';
import 'package:banda/features/accounts/entities/account.dart';
import 'package:banda/features/tags/entities/category.dart';
import 'package:banda/features/bills/entities/bill.dart';
import 'package:banda/features/tags/entities/label.dart';
import 'package:banda/common/helpers/type_helper.dart';
import 'package:banda/features/accounts/providers/account_provider.dart';
import 'package:banda/features/tags/providers/category_provider.dart';
import 'package:banda/features/bills/providers/bill_provider.dart';
import 'package:banda/features/tags/providers/label_provider.dart';
import 'package:banda/common/types/form_data.dart';
import 'package:banda/common/widgets/amount_form_field.dart';
import 'package:banda/common/widgets/multi_select_form_field.dart';
import 'package:banda/common/widgets/select_form_field.dart';
import 'package:banda/common/widgets/when_form_field.dart';
import 'package:flutter/foundation.dart' hide Category;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class BillEditor extends StatelessWidget {
  final String? id;
  final bool readOnly;

  BillEditor({super.key, this.id, this.readOnly = false});

  final _form = GlobalKey<FormState>();

  final FormData _d = {};

  void handleRedirect() {
    _form.currentState!.save();
  }

  void handleMoreTap(BuildContext context) async {
    Navigator.pushNamed(context, "/bills/${id!}/menu");
  }

  void handleSubmitTap(BuildContext context) async {
    _form.currentState!.save();

    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final billProvider = context.read<BillProvider>();

    if (_form.currentState!.validate()) {
      try {
        final note = _d["note"]?.isNotEmpty ? _d["note"] : null;

        if (id == null) {
          await billProvider.create(
            note: note,
            amount: _d["amount"],
            fee: _d["fee"],
            cycle: _d["cycle"],
            status: _d["status"],
            categoryId: _d["category_id"],
            accountId: _d["account_id"],
            dueAt: _d["due_at"].dateTime,
            labelIds: _d["label_ids"],
          );
        }

        if (id != null) {
          await billProvider.update(
            id!,
            note: note,
            amount: _d["amount"],
            fee: _d["fee"],
            status: _d["status"],
            cycle: _d["cycle"],
            categoryId: _d["category_id"],
            accountId: _d["account_id"],
            dueAt: _d["due_at"].dateTime,
            labelIds: _d["label_ids"],
          );
        }

        navigator.pop();
      } catch (error, stackTrace) {
        if (kDebugMode) {
          print(error);
          print(stackTrace);
        }

        alert(messenger, "Edit bill details failed!");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final billProvider = context.read<BillProvider>();
    final categoryProvider = context.watch<CategoryProvider>();
    final accountProvider = context.watch<AccountProvider>();
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
          readOnly ? "Bill details" : "Enter bill details",
          style: theme.textTheme.titleLarge,
        ),
        actions: [
          if (!readOnly)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: IconButton(
                onPressed: () {
                  handleSubmitTap(context);
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
      body: SafeArea(
        bottom: true,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16.0),
          child: FutureBuilder(
            future: Future.wait([
              categoryProvider.search(),
              accountProvider.search(),
              labelProvider.search(),
              if (id != null) billProvider.get(id!),
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
              final accounts = snapshot.data![1] as List<Account>;
              final labels = snapshot.data![2] as List<Label>;
              final bill = id != null
                  ? snapshot.data![3] as Bill
                  : null;

              return Form(
                key: _form,
                child: Column(
                  spacing: 16,
                  children: [
                    if (!readOnly ||
                        (bill?.note != null && bill!.note!.isNotEmpty))
                      TextFormField(
                        readOnly: readOnly,
                        decoration: InputStyles.field(
                          labelText: "Note",
                          hintText: "Enter note...",
                        ),
                        initialValue: _d["note"] ?? bill?.note,
                        onSaved: (value) => _d["note"] = value,
                      ),
                    AmountFormField(
                      readOnly: readOnly,
                      decoration: InputStyles.field(
                        labelText: "Amount",
                        hintText: "Enter amount...",
                      ),
                      initialValue:
                          _d["amount"]?.abs() ?? bill?.amount.abs(),
                      onSaved: (value) => _d["amount"] = value,
                      validator: (value) =>
                          value == null ? "Enter amount" : null,
                    ),
                    AmountFormField(
                      readOnly: readOnly,
                      decoration: InputStyles.field(
                        labelText: "Fee",
                        hintText: "Enter fee...",
                      ),
                      initialValue:
                          _d["fee"]?.abs() ?? bill?.fee?.abs(),
                      onSaved: (value) => _d["fee"] = value,
                    ),
                    SelectFormField<BillCycle>(
                      readOnly: readOnly,
                      initialValue:
                          _d["cycle"] ??
                          bill?.cycle ??
                          BillCycle.monthly,
                      onSaved: (value) => _d["cycle"] = value,
                      decoration: InputStyles.field(
                        labelText: "Cycle",
                        hintText: "Select cycle...",
                      ),
                      options: BillCycle.values.map((c) {
                        return SelectItem(value: c, label: c.label);
                      }).toList(),
                    ),
                    WhenFormField(
                      readOnly: readOnly,
                      options: WhenOption.min,
                      initialValue:
                          _d["due_at"] ??
                          (bill?.dueAt != null
                              ? When.specificTime(bill!.dueAt)
                              : When.now()),
                      onSaved: (value) => _d["due_at"] = value,
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
                    SelectFormField<BillStatus>(
                      readOnly: readOnly,
                      initialValue:
                          _d["status"] ??
                          bill?.status ??
                          BillStatus.pending,
                      onSaved: (value) => _d["status"] = value,
                      decoration: InputStyles.field(
                        labelText: "Status",
                        hintText: "Select status...",
                      ),
                      options: BillStatus.values.map((c) {
                        return SelectItem(value: c, label: c.label);
                      }).toList(),
                    ),
                    GrowableSelectFormField(
                      readOnly: readOnly,
                      initialValue:
                          _d["category_id"] ?? bill?.categoryId,
                      onSaved: (value) => _d["category_id"] = value,
                      decoration: InputStyles.field(
                        labelText: "Category",
                        hintText: "Select category...",
                      ),
                      actionText: "New category",
                      actionPath: "/categories/edit",
                      onRedirect: handleRedirect,
                      options: categories
                          .where((c) => readOnly || !c.readonly)
                          .map((c) {
                            return SelectItem(
                              value: c.id,
                              label: c.name,
                            );
                          })
                          .toList(),
                    ),
                    GrowableSelectFormField(
                      readOnly: readOnly,
                      decoration: InputStyles.field(
                        labelText: "Account",
                        hintText: "Select account...",
                      ),
                      actionPath: "/accounts/new",
                      actionText: "New account",
                      options: accounts.map((i) {
                        return SelectItem(
                          value: i.id,
                          label: "${i.name} — ${i.holderName}",
                        );
                      }).toList(),
                      initialValue: _d["account_id"] ?? bill?.accountId,
                      onSaved: (value) => _d["account_id"] = value,
                    ),
                    if (!readOnly || !isEmpty(bill?.labels))
                      GrowableMultiSelectFormField<String>(
                        readOnly: readOnly,
                        decoration: InputStyles.field(
                          labelText: "Labels",
                          hintText: "Select labels...",
                        ),
                        actionText: "New label",
                        actionPath: "/labels/edit",
                        onRedirect: handleRedirect,
                        initialValue:
                            _d["label_ids"] ?? bill?.labelIds ?? [],
                        onSaved: (value) => _d["label_ids"] = value,
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
