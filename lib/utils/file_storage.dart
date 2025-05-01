import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/countdown_data.dart';
import 'package:flutter/foundation.dart';

class FileStorage {
  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<File> get _localFile async {
    final path = await _localPath;
    return File('$path/countdowns.json');
  }

  Future<List<CountdownData>> loadCountdowns() async {
    try {
      final file = await _localFile;
      if (await file.exists()) {
        final contents = await file.readAsString();
        final List<dynamic> jsonList = jsonDecode(contents);
        return jsonList.map((json) => CountdownData.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error loading countdowns: $e');
      return [];
    }
  }

  Future<void> saveCountdowns(List<CountdownData> countdowns) async {
    try {
      final file = await _localFile;
      final jsonList =
          countdowns.map((countdown) => countdown.toJson()).toList();
      await file.writeAsString(jsonEncode(jsonList));
    } catch (e) {
      debugPrint('Error saving countdowns: $e');
    }
  }
}
