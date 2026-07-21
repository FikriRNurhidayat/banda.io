import 'package:bandha/common/decorations/input_styles.dart';
import 'package:bandha/common/helpers/alert_helper.dart';
import 'package:bandha/features/assets/providers/asset_provider.dart';
import 'package:bandha/common/types/form_data.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AssetEditor extends StatelessWidget {
  final String? id;
  final bool readOnly;

  AssetEditor({super.key, this.id, this.readOnly = false});

  final _form = GlobalKey<FormState>();

  final FormData _d = {};

  void handleSubmit(BuildContext context) async {
    final assetProvider = context.read<AssetProvider>();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    try {
      if (_form.currentState!.validate()) {
        _form.currentState!.save();

        if (id == null) {
          await assetProvider.create(
            name: _d["name"],
            code: _d["code"],
          );
        } else {
          await assetProvider.update(
            id!,
            name: _d["name"],
            code: _d["code"],
          );
        }
        navigator.pop();
      }
    } catch (error, stackTrace) {
      if (kDebugMode) {
        print(error);
        print(stackTrace);
      }

      alert(messenger, "Edit asset failed");
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final assetProvider = context.read<AssetProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          !readOnly ? "Enter asset details" : "Asset details",
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
        ],
      ),
      body: FutureBuilder(
        future: id != null ? assetProvider.get(id!) : null,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text("..."));
          }

          final asset = id != null ? snapshot.data : null;

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
                      hintText: "Enter asset name...",
                    ),
                    initialValue: _d["name"] ?? asset?.name,
                    onSaved: (value) => _d["name"] = value ?? '',
                    validator: (value) => value == null || value.isEmpty
                        ? "Name is required"
                        : null,
                  ),
                  TextFormField(
                    readOnly: readOnly,
                    decoration: InputStyles.field(
                      labelText: "Code",
                      hintText: "Enter code (e.g. IDR, USD)",
                    ),
                    initialValue: _d["code"] ?? asset?.code,
                    onSaved: (value) => _d["code"] = value ?? '',
                    validator: (value) => value == null || value.isEmpty
                        ? "Code is required"
                        : null,
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
