import 'package:banda/features/main/services/tool_service.dart';
import 'package:flutter/material.dart';

class ToolProvider extends ChangeNotifier {
  final ToolService toolService;

  ToolProvider(this.toolService);

  backupLedger(String backupPath) {
    return toolService.backupLedger(backupPath);
  }

  restoreLedger(String backupPath) {
    return toolService.restoreLedger(backupPath);
  }
}
