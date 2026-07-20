import 'package:bandha/common/decorations/input_styles.dart';
import 'package:bandha/common/helpers/future_helper.dart';
import 'package:bandha/common/types/metric.dart';
import 'package:bandha/features/entries/providers/entry_filter_provider.dart';
import 'package:bandha/features/entries/providers/entry_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class EntriesInsights extends StatelessWidget {
  const EntriesInsights({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final entryProvider = context.watch<EntryProvider>();
    final filterProvider = context.watch<EntryFilterProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Entries insights",
          style: theme.textTheme.titleMedium,
        ),
        automaticallyImplyLeading: false,
      ),
      body: FutureBuilder(
        future: entryProvider.insights(
          specification: filterProvider.get(),
        ),
        builder: futureBuilder((context, snapshot) {
          final metrics = snapshot.data as List<Metric>;
          final metricPairs = [
            for (var i = 0; i < metrics.length; i += 2)
              metrics.sublist(
                i,
                i + 2 > metrics.length ? metrics.length : i + 2,
              ),
          ];

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              spacing: 16,
              children: metricPairs.map((metricPair) {
                return Row(
                  children: metricPair.map((metric) {
                    return Expanded(
                      child: InputDecorator(
                        decoration: InputStyles.field(
                          labelText: metric.label ?? metric.name,
                        ),
                        child: Text(
                          metric.displayValue ?? metric.value.toString(),
                        ),
                      ),
                    );
                  }).toList(),
                );
              }).toList(),
            ),
          );

          // return Column(
          //   spacing: 16,
          //   children: metrics.map((metric) {
          //     return InputDecorator(
          //       decoration: InputStyles.field(
          //         labelText: metric.label ?? metric.name,
          //       ),
          //       child: Text(
          //         metric.displayValue ?? metric.value.toString(),
          //       ),
          //     );
          //   }).toList(),
          // );
        }),
      ),
    );
  }
}
