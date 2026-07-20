import 'package:bandha/common/decorations/input_styles.dart';
import 'package:bandha/common/helpers/alert_helper.dart';
import 'package:bandha/features/tags/entities/category.dart';
import 'package:bandha/features/tags/providers/category_provider.dart';
import 'package:bandha/features/journals/entities/journal.dart';
import 'package:bandha/features/tags/entities/label.dart';
import 'package:bandha/features/funds/entities/fund.dart';
import 'package:bandha/features/journals/providers/journal_provider.dart';
import 'package:bandha/features/tags/providers/label_provider.dart';
import 'package:bandha/features/funds/providers/fund_provider.dart';
import 'package:bandha/common/types/form_data.dart';
import 'package:bandha/common/widgets/amount_form_field.dart';
import 'package:bandha/common/widgets/multi_select_form_field.dart';
import 'package:bandha/common/widgets/select_form_field.dart';
import 'package:flutter/foundation.dart' hide Category;
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
            journalId: _d["journalId"],
            categoryId: _d["categoryId"],
            labelIds: _d["labelIds"],
            note: _d["note"],
          );
        }

        if (widget.id != null) {
          await fundProvider.update(
            widget.id!,
            goal: _d["goal"],
            categoryId: _d["categoryId"],
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
      automaticallyImplyLeading: false,
      title: Text(
        !widget.readOnly ? "Enter fund details" : "Fund details",
        style: theme.textTheme.titleMedium,
      ),
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
    required List<Journal> journals,
    required List<Category> categories,
  }) {
    final theme = Theme.of(context);

    return [
      if (!widget.readOnly ||
          (fund?.note != null && fund!.note!.isNotEmpty))
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
        initialValue: _d["goal"] ?? fund?.amount,
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
        readOnly: widget.readOnly || fund?.journalId != null,
        initialValue: _d["journalId"] ?? fund?.journalId,
        onSaved: (value) => _d["journalId"] = value,
        validator: (value) =>
            value == null ? "Journal is required" : null,
        actions: [
          if (!widget.readOnly)
            ActionChip(
              avatar: Icon(Icons.add, color: theme.colorScheme.outline),
              label: Text(
                "New journal",
                style: TextStyle(
                  fontWeight: FontWeight.w100,
                  color: theme.colorScheme.outline,
                ),
              ),
              onPressed: () {
                redirect(context, "/journals/new");
              },
            ),
        ],
        options: journals.map((journal) {
          return SelectItem(
            value: journal.id,
            label: journal.displayName(),
          );
        }).toList(),
        decoration: InputStyles.field(
          labelText: "Journal",
          hintText: "Select journal...",
        ),
      ),
      SelectFormField<String>(
        readOnly: widget.readOnly,
        initialValue: _d["categoryId"] ?? fund?.categoryId,
        onSaved: (value) => _d["categoryId"] = value,
        decoration: InputStyles.field(
          labelText: "Category",
          hintText: "Select category...",
        ),
        actions: [
          if (!widget.readOnly)
            ActionChip(
              avatar: Icon(Icons.add, color: theme.colorScheme.outline),
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
              return SelectItem(value: c.id, label: c.name);
            })
            .toList(),
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
        options: labels
            .where((label) => widget.readOnly || !label.readOnly)
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
    ];
  }

  @override
  Widget build(BuildContext context) {
    final fundProvider = context.read<FundProvider>();
    final journalProvider = context.watch<JournalProvider>();
    final labelProvider = context.watch<LabelProvider>();
    final categoryProvider = context.watch<CategoryProvider>();

    return Scaffold(
      appBar: appBarBuilder(context),
      body: FutureBuilder(
        future: Future.wait([
          journalProvider.search(),
          labelProvider.search(),
          categoryProvider.search(),
          if (widget.id != null) fundProvider.get(widget.id!),
        ]),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final journals = snapshot.data![0] as List<Journal>;
          final labels = snapshot.data![1] as List<Label>;
          final categories = snapshot.data![2] as List<Category>;
          final fund = widget.id != null
              ? (snapshot.data![3] as Fund)
              : null;

          final fields = fieldsBuilder(
            context,
            fund: fund,
            labels: labels,
            journals: journals,
            categories: categories,
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
