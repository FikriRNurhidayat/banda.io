import 'package:banda/common/helpers/future_helper.dart';
import 'package:banda/features/bills/entities/bill.dart';
import 'package:banda/features/bills/providers/bill_provider.dart';
import 'package:banda/features/bills/widgets/bill_tile.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class Bills extends StatelessWidget {
  const Bills({super.key});

  Widget fabBuilder(BuildContext context) {
    return FloatingActionButton(
      child: Icon(Icons.add),
      onPressed: () {
        Navigator.pushNamed(context, "/bills/new");
      },
    );
  }

  PreferredSizeWidget appBarBuilder(BuildContext context) {
    final theme = Theme.of(context);

    return AppBar(
      title: Text(
        "Bills",
        style: theme.textTheme.titleLarge,
        textAlign: TextAlign.center,
      ),
      centerTitle: true,
      actionsPadding: EdgeInsets.all(8),
    );
  }

  @override
  Widget build(BuildContext context) {
    final billProvider = context.watch<BillProvider>();

    return Scaffold(
      appBar: appBarBuilder(context),
      floatingActionButton: fabBuilder(context),
      body: FutureBuilder(
        future: billProvider.search(),
        builder: futureBuilder((context, snapshot) {
          final bills = snapshot.data! as List<Bill>;

          return ListView.builder(
            itemCount: bills.length,
            itemBuilder: (context, index) {
              final bill = bills[index];
              return BillTile(bill);
            },
          );
        }),
      ),
    );
  }
}
