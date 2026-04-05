import 'package:bandha/common/widgets/money_text.dart';
import 'package:bandha/features/analytics/providers/analytic_provider.dart';
import 'package:bandha/features/analytics/types/metric.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class Metrics extends StatelessWidget {
  const Metrics({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final analyticProvider = context.read<AnalyticProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Metrics",
          style: theme.textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        centerTitle: true,
      ),
      body: FutureBuilder(
        future: analyticProvider.getMetrics(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
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

          return ListView.builder(
            itemCount: snapshot.data?.length ?? 0,
            itemBuilder: (BuildContext context, int index) {
              final Metric metric = snapshot.data![index];
              return ListTile(
                title: Text(
                  metric.group,
                  style: theme.textTheme.titleSmall,
                ),
                subtitle: Text(
                  metric.name,
                  style: theme.textTheme.bodySmall,
                ),
                trailing: MoneyText(
                  metric.value.toDouble(),
                  useSymbol: false,
                ),
                dense: true,
              );
            },
          );
        },
      ),
    );
  }
}
