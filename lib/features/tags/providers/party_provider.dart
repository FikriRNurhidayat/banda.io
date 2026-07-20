import 'package:bandha/features/tags/entities/party.dart';
import 'package:bandha/features/tags/providers/tagable_provider.dart';
import 'package:bandha/features/tags/repositories/party_repository.dart';

class PartyProvider extends TagableProvider<Party> {
  final PartyRepository _repository;

  PartyProvider(this._repository);

  @override
  Future<List<Party>> search() async {
    return _repository.search();
  }

  @override
  Future<void> add({required String name}) async {
    await _repository.create(name: name);
    notifyListeners();
  }

  @override
  Future<void> update({
    required String id,
    required String name,
  }) async {
    await _repository.update(id: id, name: name);
    notifyListeners();
  }

  @override
  Future<void> remove(String id) async {
    await _repository.delete(id);
    notifyListeners();
  }
}
