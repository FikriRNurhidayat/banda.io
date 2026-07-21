import 'package:bandha/common/decorations/input_styles.dart';
import 'package:bandha/common/helpers/alert_helper.dart';
import 'package:bandha/common/widgets/growable_multi_select_form_field.dart';
import 'package:bandha/common/widgets/growable_select_form_field.dart';
import 'package:bandha/features/entries/entities/entry.dart';
import 'package:bandha/features/journals/entities/journal.dart';
import 'package:bandha/features/tags/entities/category.dart';
import 'package:bandha/features/schedules/entities/schedule.dart';
import 'package:bandha/features/tags/entities/label.dart';
import 'package:bandha/common/helpers/type_helper.dart';
import 'package:bandha/features/journals/providers/journal_provider.dart';
import 'package:bandha/features/tags/providers/category_provider.dart';
import 'package:bandha/features/schedules/providers/schedule_provider.dart';
import 'package:bandha/features/tags/providers/label_provider.dart';
import 'package:bandha/common/types/form_data.dart';
import 'package:bandha/common/widgets/amount_form_field.dart';
import 'package:bandha/common/widgets/multi_select_form_field.dart';
import 'package:bandha/common/widgets/select_form_field.dart';
import 'package:bandha/common/widgets/when_form_field.dart';
import 'package:flutter/foundation.dart' hide Category;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ScheduleEditor extends StatelessWidget {
  final String? id;
  final bool readOnly;

  ScheduleEditor({super.key, this.id, this.readOnly = false});

  final _form = GlobalKey<FormState>();

  final FormData _d = {};

  void _redirect() {
    _form.currentState!.save();
  }

  void _moreTap(BuildContext context) async {
    Navigator.pushNamed(context, "/schedules/${id!}/menu");
  }

  void _submitTap(BuildContext context) async {
    _form.currentState!.save();

    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final scheduleProvider = context.read<ScheduleProvider>();

    if (_form.currentState!.validate()) {
      try {
        final note = _d["note"]?.isNotEmpty ? _d["note"] : null;

        if (id == null) {
          await scheduleProvider.create(
            note: note,
            amount: _d["amount"],
            fee: _d["fee"],
            type: _d["type"],
            cycle: _d["cycle"],
            status: _d["status"],
            categoryId: _d["category_id"],
            journalId: _d["journal_id"],
            dueAt: _d["due_at"].dateTime,
            labelIds: _d["label_ids"],
          );
        }

        if (id != null) {
          await scheduleProvider.update(
            id!,
            note: note,
            amount: _d["amount"],
            fee: _d["fee"],
            type: _d["type"],
            status: _d["status"],
            cycle: _d["cycle"],
            categoryId: _d["category_id"],
            journalId: _d["journal_id"],
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

        alert(messenger, "Edit schedule details failed!");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheduleProvider = context.read<ScheduleProvider>();
    final categoryProvider = context.watch<CategoryProvider>();
    final journalProvider = context.watch<JournalProvider>();
    final labelProvider = context.watch<LabelProvider>();

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Text(
          readOnly ? "Schedule details" : "Enter schedule details",
          style: theme.textTheme.titleMedium,
        ),
        automaticallyImplyLeading: false,
        actions: [
          if (!readOnly)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: IconButton(
                onPressed: () {
                  _submitTap(context);
                },
                icon: Icon(Icons.check),
              ),
            ),

          if (readOnly)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: IconButton(
                onPressed: () {
                  _moreTap(context);
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
              journalProvider.search(),
              labelProvider.search(),
              if (id != null) scheduleProvider.get(id!),
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
              final journals = snapshot.data![1] as List<Journal>;
              final labels = snapshot.data![2] as List<Label>;
              final schedule = id != null
                  ? snapshot.data![3] as Schedule
                  : null;

              return Form(
                key: _form,
                child: Column(
                  spacing: 16,
                  children: [
                    if (!readOnly ||
                        (schedule?.note != null &&
                            schedule!.note!.isNotEmpty))
                      TextFormField(
                        readOnly: readOnly,
                        decoration: InputStyles.field(
                          labelText: "Note",
                          hintText: "Enter note...",
                        ),
                        initialValue: _d["note"] ?? schedule?.note,
                        onSaved: (value) => _d["note"] = value,
                      ),
                    SelectFormField<EntryType>(
                      readOnly: readOnly,
                      initialValue: _d["type"] ?? schedule?.entryType,
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
                      readOnly: readOnly,
                      decoration: InputStyles.field(
                        labelText: "Amount",
                        hintText: "Enter amount...",
                      ),
                      initialValue:
                          _d["amount"]?.abs() ?? schedule?.amount.abs(),
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
                          _d["fee"]?.abs() ?? schedule?.feeAmount?.abs(),
                      onSaved: (value) => _d["fee"] = value,
                    ),
                    SelectFormField<ScheduleCycle>(
                      readOnly: readOnly,
                      initialValue:
                          _d["cycle"] ??
                          schedule?.cycle ??
                          ScheduleCycle.monthly,
                      onSaved: (value) => _d["cycle"] = value,
                      decoration: InputStyles.field(
                        labelText: "Cycle",
                        hintText: "Select cycle...",
                      ),
                      options: ScheduleCycle.values.map((c) {
                        return SelectItem(value: c, label: c.label);
                      }).toList(),
                    ),
                    WhenFormField(
                      readOnly: readOnly,
                      options: WhenOption.min,
                      initialValue:
                          _d["due_at"] ??
                          (schedule?.dueAt != null
                              ? When.specificTime(schedule!.dueAt)
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
                    SelectFormField<ScheduleStatus>(
                      readOnly: readOnly,
                      initialValue:
                          _d["status"] ??
                          schedule?.status ??
                          ScheduleStatus.pending,
                      onSaved: (value) => _d["status"] = value,
                      decoration: InputStyles.field(
                        labelText: "Status",
                        hintText: "Select status...",
                      ),
                      options: ScheduleStatus.values.map((c) {
                        return SelectItem(value: c, label: c.label);
                      }).toList(),
                    ),
                    GrowableSelectFormField(
                      readOnly: readOnly,
                      initialValue:
                          _d["category_id"] ?? schedule?.categoryId,
                      onSaved: (value) => _d["category_id"] = value,
                      decoration: InputStyles.field(
                        labelText: "Category",
                        hintText: "Select category...",
                      ),
                      actionText: "New category",
                      actionPath: "/categories/edit",
                      onRedirect: _redirect,
                      options: categories
                          .where((c) => readOnly || !c.readOnly)
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
                        labelText: "Journal",
                        hintText: "Select journal...",
                      ),
                      actionPath: "/journals/new",
                      actionText: "New journal",
                      options: journals.map((i) {
                        return SelectItem(
                          value: i.id,
                          label: "${i.name} — ${i.holderName}",
                        );
                      }).toList(),
                      initialValue: _d["journal_id"] ?? schedule?.journalId,
                      onSaved: (value) => _d["journal_id"] = value,
                    ),
                    if (!readOnly || !isEmpty(schedule?.labels))
                      GrowableMultiSelectFormField<String>(
                        readOnly: readOnly,
                        decoration: InputStyles.field(
                          labelText: "Labels",
                          hintText: "Select labels...",
                        ),
                        actionText: "New label",
                        actionPath: "/labels/edit",
                        onRedirect: _redirect,
                        initialValue:
                            _d["label_ids"] ?? schedule?.labelIds ?? [],
                        onSaved: (value) => _d["label_ids"] = value,
                        options: labels
                            .where((label) => !label.readOnly)
                            .map((l) {
                              return MultiSelectItem(
                                value: l.id,
                                label: l.name,
                              );
                            })
                            .toList(),
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
