import 'package:flutter/material.dart';
import '../db_helper.dart';
import '../model/task_model.dart';

class TaskController extends ChangeNotifier {
  List<Task> _tasks = [];
  bool _isLoading = false;
  String? _errorMessage;

  String _filterStatus = 'all'; // all, completed, pending, overdue
  String _sortBy = 'date'; // date, title, dueDate

  // Getters
  List<Task> get tasks => _getFilteredTasks();
  List<Task> get allTasks => _tasks;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get filterStatus => _filterStatus;
  String get sortBy => _sortBy;

  // Stats
  int get totalTasks => _tasks.length;
  int get completedTasks => _tasks.where((t) => t.isCompleted == 1).length;
  int get pendingTasks => _tasks.where((t) => t.isCompleted == 0).length;
  int get overdueTasks => _tasks
      .where((t) => t.isCompleted == 0 && t.dueDate.isBefore(DateTime.now()))
      .length;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // -------- DUPLICATE TITLE HANDLING --------

  String _normalizeTitle(String s) {
    return s.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }

  bool _isTitleAlreadyInTasks({
    required int ownerId,
    required String newTitle,
    int? ignoreTaskId,
  }) {
    final newNorm = _normalizeTitle(newTitle);

    return _tasks.any((t) {
      if (t.ownerId != ownerId) return false;
      if (ignoreTaskId != null && t.id == ignoreTaskId) return false;
      return _normalizeTitle(t.title) == newNorm;
    });
  }

  // -------- LOAD --------

  Future<void> loadTasks(int ownerId) async {
    _setLoading(true);
    _setError(null);

    try {
      // NOTE: DBHelper.getTasksByOwner must accept int ownerId
      _tasks = await DBHelper.getTasksByOwner(ownerId);
    } catch (e) {
      _setError('Failed to load tasks: ${e.toString()}');
    }

    _setLoading(false);
  }

  // -------- ADD --------

  Future<bool> addTask({
    required int ownerId,
    required String title,
    required String description,
    required DateTime dueDate,
  }) async {
    _setLoading(true);
    _setError(null);

    try {
      final cleanTitle = title.trim();
      final cleanDesc = description.trim();

      if (cleanTitle.isEmpty) {
        _setError('Title cannot be empty.');
        _setLoading(false);
        return false;
      }

      if (_isTitleAlreadyInTasks(ownerId: ownerId, newTitle: cleanTitle)) {
        _setError('A task with this title already exists.');
        _setLoading(false);
        return false;
      }

      final newTask = Task(
        ownerId: ownerId,
        title: cleanTitle,
        description: cleanDesc,
        createdAt: DateTime.now(),
        dueDate: dueDate,
        isCompleted: 0,
      );

      await DBHelper.insertTask(newTask);
      print('create task');
      //await loadTasks(ownerId);
      //print('load owner id');

      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to add task: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  // -------- EDIT / UPDATE --------

  Future<bool> updateTask(Task task) async {
    _setLoading(true);
    _setError(null);

    try {
      final cleanTitle = task.title.trim();
      final cleanDesc = task.description.trim();

      if (cleanTitle.isEmpty) {
        _setError('Title cannot be empty.');
        _setLoading(false);
        return false;
      }

      if (_isTitleAlreadyInTasks(
        ownerId: task.ownerId,
        newTitle: cleanTitle,
        ignoreTaskId: task.id,
      )) {
        _setError('A task with this title already exists.');
        _setLoading(false);
        return false;
      }

      final updatedTask = Task(
        id: task.id,
        ownerId: task.ownerId,
        title: cleanTitle,
        description: cleanDesc,
        createdAt: task.createdAt,
        dueDate: task.dueDate,
        isCompleted: task.isCompleted,
      );

      await DBHelper.updateTask(updatedTask);
      await loadTasks(task.ownerId);

      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to update task: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  // -------- SET COMPLETE --------

  Future<bool> setTaskComplete(Task task, bool completed) async {
    final updated = Task(
      id: task.id,
      ownerId: task.ownerId,
      title: task.title,
      description: task.description,
      createdAt: task.createdAt,
      dueDate: task.dueDate,
      isCompleted: completed ? 1 : 0,
    );

    return updateTask(updated);
  }

  Future<bool> toggleTaskCompletion(Task task) async {
    return setTaskComplete(task, task.isCompleted != 1);
  }

  // -------- DELETE --------

  Future<bool> deleteTask({
    required int id,
    required int ownerId,
  }) async {
    _setLoading(true);
    _setError(null);

    try {
      await DBHelper.deleteTask(id);
      await loadTasks(ownerId);

      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to delete task: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  // -------- FILTER / SORT --------

  void setFilter(String status) {
    _filterStatus = status;
    notifyListeners();
  }

  void setSortBy(String sortBy) {
    _sortBy = sortBy;
    notifyListeners();
  }

  List<Task> _getFilteredTasks() {
    List<Task> filtered;

    switch (_filterStatus) {
      case 'completed':
        filtered = _tasks.where((t) => t.isCompleted == 1).toList();
        break;
      case 'pending':
        filtered = _tasks.where((t) => t.isCompleted == 0).toList();
        break;
      case 'overdue':
        filtered = _tasks
            .where((t) => t.isCompleted == 0 && t.dueDate.isBefore(DateTime.now()))
            .toList();
        break;
      case 'all':
      default:
        filtered = List.from(_tasks);
    }

    switch (_sortBy) {
      case 'title':
        filtered.sort((a, b) => a.title.compareTo(b.title));
        break;
      case 'dueDate':
        filtered.sort((a, b) => a.dueDate.compareTo(b.dueDate));
        break;
      case 'date':
      default:
        break;
    }

    return filtered;
  }
}
