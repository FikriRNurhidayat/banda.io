import 'package:bandha/common/providers/tab_provider.dart';

enum ObligationTab { payments, entries }

class ObligationTabProvider extends TabProvider<ObligationTab> {
  ObligationTabProvider() : super({ObligationTab.payments});
}
