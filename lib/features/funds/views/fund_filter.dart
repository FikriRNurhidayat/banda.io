import 'package:bandha/common/decorations/input_styles.dart';
import 'package:bandha/common/helpers/date_helper.dart';
import 'package:bandha/features/journals/providers/journal_provider.dart';
import 'package:bandha/features/funds/providers/fund_filter_provider.dart';
import 'package:bandha/common/types/specification.dart';
import 'package:bandha/common/widgets/multi_select_form_field.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class FundFilter extends StatefulWidget {
  final Filter? specs;

  const FundFilter({super.key, this.specs});

  @override
  State<StatefulWidget> createState() {
    return _FundFilterState();
  }
}

class _FundFilterState extends State<FundFilter> {
  final _formKey = GlobalKey<FormState>();
  final _createdBetweenController = TextEditingController();

  List<String>? _journalIdIn;
  DateTimeRange? _createdBetween;

  @override
  void initState() {
    super.initState();

    if (widget.specs != null) {
      if (widget.specs!.containsKey("journal_in")) {
        _journalIdIn = widget.specs!["journal_in"];
      }

      if (widget.specs!.containsKey("created_between")) {
        final value = widget.specs!["created_between"];
        _createdBetween = DateTimeRange(start: value[0], end: value[1]);
        _createdBetweenController.text = DateHelper.formatDateRange(
          _createdBetween!,
        );
      }
    }
  }

  @override
  void dispose() {
    _createdBetweenController.dispose();
    super.dispose();
  }

  void _submit() async {
    final Filter query = {};

    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      if (_journalIdIn != null && _journalIdIn!.isNotEmpty) {
        query["journal_in"] = _journalIdIn;
      }

      if (_createdBetween != null) {
        query["created_between"] = [
          _createdBetween!.start,
          _createdBetween!.end,
        ];
      }

      context.read<FundFilterProvider>().set(query);
      Navigator.pop(context);
    }
  }

  void _pickDate() async {
    final now = DateTime.now();
    final DateTimeRange? choosenDateRange = await showDateRangePicker(
      context: context,
      initialDateRange:
          _createdBetween ??
          DateTimeRange(
            start: DateTime(now.year, now.month, now.day),
            end: DateTime(now.year, now.month, now.day, 23, 59, 59),
          ),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (!mounted || choosenDateRange == null) return;

    _createdBetween = choosenDateRange;
    _createdBetweenController.text = DateHelper.formatDateRange(
      choosenDateRange,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final journalProvider = context.watch<JournalProvider>();

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text("Filter funds", style: theme.textTheme.titleMedium),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: IconButton(
              onPressed: _submit,
              icon: Icon(Icons.check),
            ),
          ),
        ],
      ),
      body: SafeArea(
        bottom: true,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16.0),
          child: FutureBuilder(
            future: journalProvider.search(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final journals = snapshot.data!;

              return Form(
                key: _formKey,
                child: Column(
                  spacing: 16,
                  children: [
                    TextFormField(
                      readOnly: true,
                      controller: _createdBetweenController,
                      onTap: () => _pickDate(),
                      decoration: InputStyles.field(
                        labelText: "Created between",
                        hintText: "Select date range...",
                      ),
                    ),
                    if (journals.isNotEmpty)
                      MultiSelectFormField<String>(
                        decoration: InputStyles.field(
                          labelText: "Journals",
                          hintText: "Select journals...",
                        ),
                        initialValue: _journalIdIn ?? [],
                        options: journals
                            .map(
                              (i) => MultiSelectItem(
                                value: i.id,
                                label: i.displayName(),
                              ),
                            )
                            .toList(),
                        onSaved: (value) => _journalIdIn = value,
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
