import 'package:bandha/common/helpers/future_helper.dart';
import 'package:bandha/features/commitments/entities/commitment.dart';
import 'package:bandha/features/commitments/providers/commitment_filter_provider.dart';
import 'package:bandha/features/commitments/providers/commitment_provider.dart';
import 'package:bandha/features/commitments/views/commitment_filter.dart';
import 'package:bandha/features/commitments/widgets/commitment_tile.dart';
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
          Navigator.pushNamed(
            context,
            "/commiments/filter",
            arguments: filterProvider.get(),
          );
        },
        icon: Icon(Icons.search),
      ),
      IconButton(
        onPressed: () {
          Navigator.pushNamed(
            context,
            "/commiments/insights",
            arguments: filterProvider.get(),
          );
        },
        icon: Icon(Icons.insights),
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
        title: Text("Commitments", style: theme.textTheme.titleMedium),
        actions: widget.actionsBuilder(context),
        actionsPadding: EdgeInsets.all(8),
        automaticallyImplyLeading: false,
      ),
      floatingActionButton: widget.fabBuilder(context),
      body: FutureBuilder(
        future: commitmentProvider.search(filterProvider.get()),
        builder: futureBuilder((context, snapshot) {
          final commitments = snapshot.data as List<Commitment>;

          return SafeArea(
            child: ListView.builder(
              itemCount: commitments.length,
              itemBuilder: (BuildContext context, int index) {
                final Commitment commitment = commitments[index];
                return CommitmentTile(commitment);
              },
            ),
          );
        }),
      ),
    );
  }
}
