import 'package:bandha/features/commitments/entities/commitment.dart';
import 'package:bandha/features/commitments/providers/commitment_filter_provider.dart';
import 'package:bandha/features/commitments/providers/commitment_provider.dart';
import 'package:bandha/features/commitments/views/commitment_filter.dart';
import 'package:bandha/features/commitments/widgets/commitment_tile.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class Commitments extends StatefulWidget {
  const Commitments({super.key});

  List<Widget> actionsBuilder(BuildContext context) {
    final filterProvider = context.watch<CommitmentFilterProvider>();
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
              builder: (_) => CommitmentFilter(specs: filterProvider.get()),
            ),
          );
        },
        icon: Icon(Icons.search),
      ),
    ];
  }

  @override
  State<StatefulWidget> createState() => _CommitmentsState();

  Widget fabBuilder(BuildContext context) {
    return FloatingActionButton(
      child: Icon(Icons.add),
      onPressed: () {
        Navigator.pushNamed(context, "/commitments/new");
      },
    );
  }
}

class _CommitmentsState extends State<Commitments> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final commitmentProvider = context.watch<CommitmentProvider>();
    final filterProvider = context.watch<CommitmentFilterProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Commitments",
          style: theme.textTheme.titleLarge,
          textAlign: TextAlign.center,
        ),
        centerTitle: true,
        actions: widget.actionsBuilder(context),
        actionsPadding: EdgeInsets.all(8),
      ),
      floatingActionButton: widget.fabBuilder(context),
      body: FutureBuilder(
        future: commitmentProvider.search(filterProvider.get()),
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
                final Commitment commitment = snapshot.data![index];
                return CommitmentTile(commitment);
              },
            ),
          );
        },
      ),
    );
  }
}
