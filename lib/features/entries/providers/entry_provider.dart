import 'package:bandha/common/entities/controlable.dart';
import 'package:bandha/features/entries/entities/entry.dart';
import 'package:bandha/features/entries/services/entry_service.dart';
import 'package:bandha/common/types/specification.dart';
import 'package:flutter/material.dart';

class EntryProvider extends ChangeNotifier {
  final EntryService entryService;

  EntryProvider(this.entryService);

  Future<List<Entry>> search({Filter? specification}) {
    return entryService.search(specification: specification);
  }

  Future<List<Entry>> getByController(
    Controlable controlable, {
    Filter? specification,
  }) {
    Filter entrySpecification = specification ?? {};
    final controller = controlable.toController();
    entrySpecification["controller_id_is"] = controller.id;
    entrySpecification["controller_type_is"] = controller.type.label;
    return entryService.search(specification: entrySpecification);
  }

  Future<Entry?> get(String id) async {
    return entryService.get(id);
  }

  Future<void> create({
    required String note,
    required double amount,
    required EntryType type,
    required EntryStatus status,
    required DateTime issuedAt,
    required String vaultId,
    required String categoryId,
    List<String>? labelIds,
  }) async {
    await entryService.create(
      note: note,
      amount: amount,
      type: type,
      status: status,
      timestamp: issuedAt,
      vaultId: vaultId,
      categoryId: categoryId,
      labelIds: labelIds,
    );
    notifyListeners();
  }

  Future<void> update({
    required String id,
    required String note,
    required double amount,
    required EntryType type,
    required EntryStatus status,
    required DateTime issuedAt,
    required String vaultId,
    required String categoryId,
    List<String>? labelIds,
  }) async {
    await entryService.update(
      id: id,
      note: note,
      amount: amount,
      type: type,
      status: status,
      timestamp: issuedAt,
      vaultId: vaultId,
      categoryId: categoryId,
      labelIds: labelIds,
    );
    notifyListeners();
  }

  Future<void> delete(String id) async {
    await entryService.delete(id);
    notifyListeners();
  }

  Future<void> debugReminder(String id) async {
    return entryService.debugReminder(id);
  }
}
