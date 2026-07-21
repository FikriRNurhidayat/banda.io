import 'package:bandha/common/decorations/input_styles.dart';
import 'package:bandha/common/helpers/alert_helper.dart';
import 'package:bandha/common/widgets/amount_form_field.dart';
import 'package:bandha/common/widgets/select_form_field.dart';
import 'package:bandha/features/journals/entities/journal.dart';
import 'package:bandha/features/journals/providers/journal_provider.dart';
import 'package:bandha/features/assets/entities/asset.dart';
import 'package:bandha/features/assets/providers/asset_provider.dart';
import 'package:bandha/common/types/form_data.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class JournalEditor extends StatelessWidget {
  final String? id;
  final bool readOnly;

  JournalEditor({super.key, this.id, this.readOnly = false});

  final _form = GlobalKey<FormState>();

  final FormData _d = {};

  void handleMoreTap(BuildContext context) async {
    Navigator.pushNamed(context, "/journals/${id!}/menu");
  }

  void handleSubmit(BuildContext context) async {
    final journalProvider = context.read<JournalProvider>();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    try {
      if (_form.currentState!.validate()) {
        _form.currentState!.save();

        if (id == null) {
          await journalProvider.create(
            name: _d["name"],
            holderName: _d["holderName"],
            balance: _d["balance"] ?? 0,
            assetId: _d["assetId"],
          );
        } else {
          await journalProvider.update(
            id!,
            name: _d["name"],
            holderName: _d["holderName"],
            balance: _d["balance"] ?? 0,
            assetId: _d["assetId"],
          );
        }
        navigator.pop();
      }
    } catch (error, stackTrace) {
      if (kDebugMode) {
        print(error);
        print(stackTrace);
      }

      alert(messenger, "Edit journal details failed");
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final journalProvider = context.read<JournalProvider>();
    final assetProvider = context.read<AssetProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          !readOnly ? "Enter journal details" : "Journal details",
          style: theme.textTheme.titleMedium,
        ),
        automaticallyImplyLeading: false,
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
        future: Future.wait([
          if (id != null) journalProvider.get(id!),
          assetProvider.search(),
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

          final journal = id != null
              ? snapshot.data![0] as Journal
              : null;
          final List<Asset> assets = id != null
              ? snapshot.data![1] as List<Asset>
              : snapshot.data![0] as List<Asset>;

          return SingleChildScrollView(
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
                      hintText: "Enter journal name...",
                    ),
                    initialValue: _d["name"] ?? journal?.name,
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
                        _d["holderName"] ?? journal?.holderName,
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
                    initialValue: _d["balance"] ?? journal?.balance,
                    onSaved: (value) => _d["balance"] = value ?? 0,
                  ),
                  if (!readOnly)
                    SelectFormField<String>(
                      readOnly: readOnly,
                      decoration: InputStyles.field(
                        labelText: "Asset",
                        hintText: "Select asset...",
                      ),
                      actions: [
                        if (!readOnly)
                          ActionChip(
                            avatar: Icon(
                              Icons.add,
                              color: theme.colorScheme.outline,
                            ),
                            label: Text(
                              "New asset",
                              style: TextStyle(
                                fontWeight: FontWeight.w100,
                                color: theme.colorScheme.outline,
                              ),
                            ),
                            onPressed: () {
                              _form.currentState!.save();
                              Navigator.pushNamed(
                                context,
                                "/assets/new",
                              );
                            },
                          ),
                      ],
                      initialValue: _d["assetId"] ?? journal?.assetId,
                      onSaved: (value) => _d["assetId"] = value,
                      validator: (value) =>
                          value == null || value.isEmpty
                          ? "Asset is required"
                          : null,
                      options: assets.map((a) {
                        return SelectItem(
                          label: a.name,
                          sublabel: a.code,
                          value: a.id,
                        );
                      }).toList(),
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
