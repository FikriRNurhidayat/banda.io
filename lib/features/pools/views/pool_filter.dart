import 'package:bandha/common/decorations/input_styles.dart';
import 'package:bandha/common/helpers/date_helper.dart';
import 'package:bandha/features/vaults/providers/vault_provider.dart';
import 'package:bandha/features/pools/providers/pool_filter_provider.dart';
import 'package:bandha/common/types/specification.dart';
import 'package:bandha/common/widgets/multi_select_form_field.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class PoolFilter extends StatefulWidget {
  final Filter? specs;

  const PoolFilter({super.key, this.specs});

  @override
  State<StatefulWidget> createState() {
    return _PoolFilterState();
  }
}

class _PoolFilterState extends State<PoolFilter> {
  final _formKey = GlobalKey<FormState>();
  final _createdBetweenController = TextEditingController();

  List<String>? _vaultIdIn;
  DateTimeRange? _createdBetween;

  @override
  void initState() {
    super.initState();

    if (widget.specs != null) {
      if (widget.specs!.containsKey("vault_in")) {
        _vaultIdIn = widget.specs!["vault_in"];
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

      if (_vaultIdIn != null && _vaultIdIn!.isNotEmpty) {
        query["vault_in"] = _vaultIdIn;
      }

      if (_createdBetween != null) {
        query["created_between"] = [
          _createdBetween!.start,
          _createdBetween!.end,
        ];
      }

      context.read<PoolFilterProvider>().set(query);
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
    final vaultProvider = context.watch<VaultProvider>();

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Filter pool",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w400),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: IconButton(onPressed: _submit, icon: Icon(Icons.check)),
          ),
        ],
      ),
      body: SafeArea(
        bottom: true,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16.0),
          child: FutureBuilder(
            future: vaultProvider.search(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final vaults = snapshot.data!;

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
                    if (vaults.isNotEmpty)
                      MultiSelectFormField<String>(
                        decoration: InputStyles.field(
                          labelText: "Vaults",
                          hintText: "Select vaults...",
                        ),
                        initialValue: _vaultIdIn ?? [],
                        options: vaults
                            .map(
                              (i) => MultiSelectItem(
                                value: i.id,
                                label: i.displayName(),
                              ),
                            )
                            .toList(),
                        onSaved: (value) => _vaultIdIn = value,
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
