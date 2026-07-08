import 'package:bandha/common/providers/tab_provider.dart';

enum SettlementTab { payments, entries }

class SettlementTabProvider extends TabProvider<SettlementTab> {
  SettlementTabProvider() : super({SettlementTab.payments});
}
