import 'package:bandha/common/providers/tab_provider.dart';

enum CommitmentTab { payments, entries }

class CommitmentTabProvider extends TabProvider<CommitmentTab> {
  CommitmentTabProvider() : super({CommitmentTab.payments});
}
