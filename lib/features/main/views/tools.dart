import 'package:bandha/common/helpers/alert_helper.dart';
import 'package:bandha/common/helpers/dialog_helper.dart';
import 'package:bandha/features/main/providers/tool_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class Tools extends StatefulWidget {
  const Tools({super.key});

  @override
  State<Tools> createState() => _ToolsState();
}

class _ToolsState extends State<Tools> {
  final timestampFormat = DateFormat("yyyy-MM-dd-HH-mm-ss");

  Future<void> reset(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final toolProvider = context.read<ToolProvider>();

    await toolProvider.resetLedger();

    alert(messenger, "Ledger reset");
  }

  Future<void> restore(BuildContext context) async {
    final toolProvider = context.read<ToolProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final pickResult = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ["bandha.db"],
    );
    if (pickResult == null) {
      return;
    }

    final backupPath = pickResult.files.single.path!;
    await toolProvider.restoreLedger(backupPath);

    alert(messenger, "Ledger restored");
  }

  Future<void> doReset(BuildContext context) async {
    ask(
      context,
      title: "Reset ledger",
      content:
          "This will replace existing data with the new ledger. This action is destructive, please make sure to backup ledger first before doing this action.",
      onConfirm: (BuildContext context) async {
        reset(context);
      },
    );
  }

  Future<void> doRestore(BuildContext context) async {
    ask(
      context,
      title: "Restore ledger",
      content:
          "This will replace existing data with the new ledger. This action is destructive, please make sure to backup ledger first before doing this action.",
      onConfirm: (BuildContext context) async {
        restore(context);
      },
    );
  }

  Future<void> doBackup(BuildContext context) async {
    final toolProvider = context.read<ToolProvider>();

    final messenger = ScaffoldMessenger.of(context);
    final now = timestampFormat.format(DateTime.now());
    final backupDir = await FilePicker.platform.getDirectoryPath();
    if (backupDir == null) {
      return;
    }

    final backupPath = '$backupDir/$now.bandha.db';

    await toolProvider.backupLedger(backupPath);

    if (!mounted) {
      return;
    }

    alert(messenger, "Ledger backed up");
  }

  List<Map<String, dynamic>> menuBuilder(BuildContext context) {
    return [
      {
        "title": "Backup ledger",
        "subtitle": "Ledger will be backed-up as sqlite3 database.",
        "onTap": () {
          doBackup(context);
        },
      },
      {
        "title": "Restore ledger",
        "subtitle": "Restore sqlite3 database as ledger.",
        "onTap": () {
          doRestore(context);
        },
      },
      if (kDebugMode) ...[
        {
          "title": "Reset ledger",
          "subtitle": "Remove existing ledger.",
          "onTap": () {
            doReset(context);
          },
        },
      ],
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final menus = menuBuilder(context);

    return Scaffold(
      appBar: AppBar(
        title: Text("Tools", style: theme.textTheme.titleMedium),
      ),
      body: ListView.builder(
        itemCount: menus.length,
        itemBuilder: (context, i) {
          final menu = menus[i];
          return ListTile(
            title: Text(
              menu["title"],
              style: theme.textTheme.titleSmall,
            ),
            subtitle: Text(
              menu["subtitle"],
              style: theme.textTheme.bodySmall,
            ),
            onTap: menu["onTap"],
          );
        },
      ),
    );
  }
}
