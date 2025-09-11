import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../models/molecule.dart';

class HistoryItem {
  final String objectName; // 物体名
  final DateTime viewedAt;
  final List<Molecule> molecules; // 推定分子一覧（3〜5）
  final Molecule? topMolecule; // ★ 追加：最有力（confidence最大）の分子
  final File? imageFile;

  HistoryItem({
    required this.objectName,
    required this.viewedAt,
    required this.molecules,
    required this.imageFile,
    required this.topMolecule, // ★ 追加
  });
}

class HistoryStore {
  static final ValueNotifier<List<HistoryItem>> items =
      ValueNotifier<List<HistoryItem>>([]);

  static void add(HistoryItem item) {
    final list = List<HistoryItem>.from(items.value);
    list.insert(0, item); // 新しいほど上に
    items.value = list;
  }
}
