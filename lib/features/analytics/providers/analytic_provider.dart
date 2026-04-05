import 'package:bandha/features/analytics/services/analytic_service.dart';
import 'package:bandha/features/analytics/types/metric.dart';
import 'package:flutter/material.dart';

class AnalyticProvider extends ChangeNotifier {
  final AnalyticService analyticService;

  AnalyticProvider(this.analyticService);

  Future<List<Metric>> getMetrics() async {
    return await analyticService.getMetrics();
  }
}
