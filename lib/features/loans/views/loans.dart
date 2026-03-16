import 'package:bandha/features/loans/entities/loan.dart';
import 'package:bandha/features/loans/providers/loan_filter_provider.dart';
import 'package:bandha/features/loans/providers/loan_provider.dart';
import 'package:bandha/features/loans/views/loan_filter.dart';
import 'package:bandha/features/loans/widgets/loan_tile.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class Loans extends StatefulWidget {
  const Loans({super.key});

  List<Widget> actionsBuilder(BuildContext context) {
    final filterProvider = context.watch<LoanFilterProvider>();
    final filter = filterProvider.get();

    return [
      if (filter != null)
        IconButton(
          onPressed: () {
            filterProvider.reset();
          },
          icon: Icon(Icons.close),
        ),
      IconButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => LoanFilter(specs: filterProvider.get()),
            ),
          );
        },
        icon: Icon(Icons.search),
      ),
    ];
  }

  @override
  State<StatefulWidget> createState() => _LoansState();

  Widget fabBuilder(BuildContext context) {
    return FloatingActionButton(
      child: Icon(Icons.add),
      onPressed: () {
        Navigator.pushNamed(context, "/loans/new");
      },
    );
  }
}

class _LoansState extends State<Loans> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loanProvider = context.watch<LoanProvider>();
    final filterProvider = context.watch<LoanFilterProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Loans",
          style: theme.textTheme.titleLarge,
          textAlign: TextAlign.center,
        ),
        centerTitle: true,
        actions: widget.actionsBuilder(context),
        actionsPadding: EdgeInsets.all(8),
      ),
      floatingActionButton: widget.fabBuilder(context),
      body: FutureBuilder(
        future: loanProvider.search(filterProvider.get()),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            if (kDebugMode) {
              print(snapshot.error);
              print(snapshot.stackTrace);
            }

            return Center(child: Text("..."));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Icon(
                Icons.dashboard_customize_outlined,
                size: theme.textTheme.displayLarge!.fontSize,
              ),
            );
          }

          return SafeArea(
            child: ListView.builder(
              itemCount: snapshot.data?.length ?? 0,
              itemBuilder: (BuildContext context, int index) {
                final Loan loan = snapshot.data![index];
                return LoanTile(loan);
              },
            ),
          );
        },
      ),
    );
  }
}
