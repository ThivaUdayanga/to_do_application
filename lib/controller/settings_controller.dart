import 'package:flutter/material.dart';
import '../db_helper.dart';
import '../model/settings_model.dart';

class SettingsController extends ChangeNotifier {
  SettingsModel? _settings;

  bool _isLoading = false;
  String? _errorMessage;

  SettingsModel? get settings => _settings;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  int get deleteBlockTime => _settings?.deleteBlockTime ?? 24;
  int get maxTasksPerDay => _settings?.maxTasksPerDay ?? 2;

  void _setLoading(bool v) {
    _isLoading = v;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> loadSettings(int ownerId) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      _settings = await DBHelper.getSettingsByOwner(ownerId);
    } catch (e) {
      _errorMessage = 'Failed to load settings: $e';
    }

    _setLoading(false);
  }

  Future<bool> saveSettings({
    required int ownerId,
    required int deleteBlockTime,
    required int maxTasksPerDay,
  }) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final model = SettingsModel(
        id: _settings?.id,
        ownerId: ownerId,
        deleteBlockTime: deleteBlockTime,
        maxTasksPerDay: maxTasksPerDay,
      );

      await DBHelper.saveSettings(model);
      _settings = model;

      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = 'Failed to save settings: $e';
      _setLoading(false);
      return false;
    }
  }

  void resetToDefaults(int ownerId) {
    _settings = SettingsModel(
      id: _settings?.id,
      ownerId: ownerId,
      deleteBlockTime: 24,
      maxTasksPerDay: 2,
    );
    notifyListeners();
  }
}
