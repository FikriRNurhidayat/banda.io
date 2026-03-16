import 'package:bandha/common/providers/tab_provider.dart';

enum LoanTab { payments, entries }

class LoanTabProvider extends TabProvider<LoanTab> {
  LoanTabProvider() : super({LoanTab.payments});
}
