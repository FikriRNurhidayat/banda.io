import 'package:bandha/common/services/service.dart';
import 'package:bandha/features/analytics/types/metric.dart';
import 'package:bandha/features/entries/entities/entry.dart';
import 'package:bandha/features/entries/repositories/entry_repository.dart';
import 'package:flutter/foundation.dart' show kDebugMode;

class AnalyticService extends Service {
  final EntryRepository entryRepository;

  AnalyticService({required this.entryRepository});

  Future<List<Metric>> getMetrics() async {
    try {
      return [
        Metric(
          group: "Entries",
          name: "Avg. pending amount",
          value: await entryPendingAverageAmount(),
        ),
        Metric(
          group: "Entries",
          name: "Avg. completed amount",
          value: await entryDoneAverageAmount(),
        ),
        Metric(
          group: "Entries",
          name: "Avg. amount",
          value: await entryAverageAmount(),
        ),
        Metric(
          group: "Entries",
          name: "Total pending",
          value: await entryPendingCount(),
        ),
        Metric(
          group: "Entries",
          name: "Total completed",
          value: await entryDoneCount(),
        ),
        Metric(
          group: "Entries",
          name: "Total",
          value: await entryCount(),
        ),
        Metric(
          group: "Entries",
          name: "Total pending amount",
          value: await entryPendingAmount(),
        ),
        Metric(
          group: "Entries",
          name: "Total completed amount",
          value: await entryDoneAmount(),
        ),
        Metric(
          group: "Entries",
          name: "Total amount",
          value: await entryAmount(),
        ),
      ];
    } catch (error, stackTrace) {
      if (kDebugMode) {
        print(error);
        print(stackTrace);
      }

      return <Metric>[];
    }
  }

  Future<double> entryPendingAverageAmount() async {
    return entryRepository.average({
      "status_in": [EntryStatus.pending],
    });
  }

  Future<double> entryDoneAverageAmount() async {
    return entryRepository.average({
      "status_in": [EntryStatus.done],
    });
  }

  Future<double> entryAverageAmount() async {
    return entryRepository.average({});
  }

  Future<int> entryPendingCount() async {
    return entryRepository.count({
      "status_in": [EntryStatus.pending],
    });
  }

  Future<int> entryDoneCount() async {
    return entryRepository.count({
      "status_in": [EntryStatus.done],
    });
  }

  Future<int> entryCount() async {
    return entryRepository.count({});
  }

  Future<double> entryPendingAmount() async {
    return entryRepository.sum({
      "status_in": [EntryStatus.pending],
    });
  }

  Future<double> entryDoneAmount() async {
    return entryRepository.sum({
      "status_in": [EntryStatus.done],
    });
  }

  Future<double> entryAmount() async {
    return entryRepository.sum({});
  }
}
