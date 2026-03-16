import 'package:bandha/common/decorations/input_styles.dart';
import 'package:bandha/common/helpers/alert_helper.dart';
import 'package:bandha/features/entries/entities/entry.dart';
import 'package:bandha/features/tags/entities/label.dart';
import 'package:bandha/features/pools/entities/pool.dart';
import 'package:bandha/common/helpers/type_helper.dart';
import 'package:bandha/features/entries/providers/entry_provider.dart';
import 'package:bandha/features/tags/providers/label_provider.dart';
import 'package:bandha/features/pools/providers/pool_provider.dart';
import 'package:bandha/common/types/form_data.dart';
import 'package:bandha/common/types/transaction_type.dart';
import 'package:bandha/common/widgets/amount_form_field.dart';
import 'package:bandha/common/widgets/multi_select_form_field.dart';
import 'package:bandha/common/widgets/select_form_field.dart';
import 'package:bandha/common/widgets/when_form_field.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class PoolEntryEditor extends StatefulWidget {
  final String poolId;
  final String? entryId;
  final bool readOnly;

  const PoolEntryEditor({
    super.key,
    required this.poolId,
    this.entryId,
    this.readOnly = false,
  });

  @override
  State<PoolEntryEditor> createState() => _PoolEntryEditorState();
}

class _PoolEntryEditorState extends State<PoolEntryEditor> {
  final _form = GlobalKey<FormState>();
  final FormData _d = {};

  void handleSubmit(BuildContext context) async {
    _form.currentState!.save();

    final navigator = Navigator.of(context);
    final poolProvider = context.read<PoolProvider>();
    final messenger = ScaffoldMessenger.of(context);

    if (!_form.currentState!.validate()) {
      return;
    }

    try {
      if (isNull(widget.entryId)) {
        await poolProvider.createTransaction(
          widget.poolId,
          amount: _d["amount"],
          type: _d["type"],
          issuedAt: _d["issuedAt"].dateTime,
          labelIds: _d["labelIds"],
        );
      }

      if (!isNull(widget.entryId)) {
        await poolProvider.updateTransaction(
          widget.poolId,
          widget.entryId!,
          amount: _d["amount"],
          type: _d["type"],
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

      alert(messenger, "Edit pool entry details failed");
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
        !widget.readOnly ? "Enter entry details" : "Entry details",
        style: theme.textTheme.titleLarge,
      ),
      centerTitle: true,
      actions: [
        if (!widget.readOnly)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: IconButton(
              onPressed: () {
                handleSubmit(context);
              },
              icon: Icon(Icons.check),
            ),
          ),
      ],
    );
  }

  fieldsBuilder(
    BuildContext context, {
    required Pool pool,
    required Entry? entry,
    required List<Label> labels,
  }) {
    final theme = Theme.of(context);
    final readonlyLabelIds = pool.labelIds;

    return [
      SelectFormField<TransactionType>(
        readOnly: widget.readOnly,
        initialValue: _d["type"] ?? entry?.transactionType,
        onSaved: (value) => _d["type"] = value,
        decoration: InputStyles.field(
          labelText: "Type",
          hintText: "Select type...",
        ),
        options: TransactionType.values.map((c) {
          return SelectItem(value: c, label: c.label);
        }).toList(),
        validator: (value) => value == null ? "Type is required" : null,
      ),
      AmountFormField(
        readOnly: widget.readOnly,
        decoration: InputStyles.field(
          labelText: "Amount",
          hintText: "Enter amount...",
        ),
        initialValue: _d["amount"] ?? entry?.amount.abs(),
        onSaved: (value) => _d["amount"] = value,
        validator: (value) =>
            value == null ? "Amount is required" : null,
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
        validator: (value) =>
            value == null ? "Issue Date & time are required" : null,
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
      MultiSelectFormField<String>(
        readOnly: widget.readOnly,
        decoration: InputStyles.field(
          labelText: "Labels",
          hintText: "Select labels...",
        ),
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
        initialValue:
            _d["labelIds"] ?? entry?.labelIds ?? readonlyLabelIds ?? [],
        options: labels.map((label) {
          return MultiSelectItem(
            value: label.id,
            label: label.name,
            enabled: !readonlyLabelIds.contains(label.id),
          );
        }).toList(),
        onSaved: (value) {
          _d["labelIds"] = value!.toList();
        },
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final labelProvider = context.watch<LabelProvider>();
    final poolProvider = context.watch<PoolProvider>();
    final entryProvider = context.watch<EntryProvider>();

    return Scaffold(
      appBar: appBarBuilder(context),
      body: FutureBuilder(
        future: Future.wait([
          labelProvider.search(),
          poolProvider.get(widget.poolId),
          if (widget.entryId != null)
            entryProvider.get(widget.entryId!),
        ]),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final labels = snapshot.data![0] as List<Label>;
          final pool = snapshot.data![1] as Pool;
          final entry = widget.entryId != null
              ? snapshot.data![2] as Entry
              : null;

          final readonlyLabelIds = pool.labelIds;

          labels.sort((a, b) {
            final aReadonly = readonlyLabelIds.contains(a.id);
            final bReadonly = readonlyLabelIds.contains(b.id);

            if (aReadonly && !bReadonly) return -1;
            if (!aReadonly && bReadonly) return 1;
            return a.name.compareTo(b.name);
          });

          final fields = fieldsBuilder(
            context,
            pool: pool,
            entry: entry,
            labels: labels,
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
