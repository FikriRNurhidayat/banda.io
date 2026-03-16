import 'package:bandha/features/tags/entities/tagable.dart';
import 'package:flutter/material.dart';

abstract class TagableProvider<I extends Tagable> extends ChangeNotifier {
  Future<List<I>> search();
  Future<void> add({required String name});
  Future<void> update({required String id, required String name});
  Future<void> remove(String id);
}
