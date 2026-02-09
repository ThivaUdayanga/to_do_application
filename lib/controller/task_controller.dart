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

  // ✅ Load tasks only for this owner
  Future<void> loadTasks(String ownerId) async {
    _setLoading(true);
    _setError(null);

    try {
      _tasks = await DBHelper.getTasksByOwner(ownerId);
    } catch (e) {
      _setError('Failed to load tasks: ${e.toString()}');
    }

    _setLoading(false);
  }

  // ✅ Add new task for owner
  Future<bool> addTask({
    required String ownerId,
    required String title,
    required String description,
    required DateTime dueDate,
  }) async {
    _setLoading(true);
    _setError(null);

    try {
      final newTask = Task(
        ownerId: ownerId,
        title: title,
        description: description,
        createdAt: DateTime.now(),
        dueDate: dueDate,
        isCompleted: 0,
      );

      await DBHelper.insertTask(newTask);
      await loadTasks(ownerId);
      return true;
    } catch (e) {
      _setError('Failed to add task: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  // ✅ Update and reload only that owner's tasks
  Future<bool> updateTask(Task task) async {
    _setLoading(true);
    _setError(null);

    try {
      await DBHelper.updateTask(task);
      await loadTasks(task.ownerId);
      return true;
    } catch (e) {
      _setError('Failed to update task: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  // ✅ Toggle keeps ownerId
  Future<bool> toggleTaskCompletion(Task task) async {
    try {
      final updated = Task(
        id: task.id,
        ownerId: task.ownerId,
        title: task.title,
        description: task.description,
        createdAt: task.createdAt,
        dueDate: task.dueDate,
        isCompleted: task.isCompleted == 1 ? 0 : 1,
      );

      return await updateTask(updated);
    } catch (e) {
      _setError('Failed to toggle task: ${e.toString()}');
      return false;
    }
  }

  // ✅ Delete then reload owner tasks
  Future<bool> deleteTask({required int id, required String ownerId}) async {
    _setLoading(true);
    _setError(null);

    try {
      await DBHelper.deleteTask(id);
      await loadTasks(ownerId);
      return true;
    } catch (e) {
      _setError('Failed to delete task: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

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
            .where(
              (t) => t.isCompleted == 0 && t.dueDate.isBefore(DateTime.now()),
            )
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

  List<Task> searchTasks(String query) {
    if (query.isEmpty) return tasks;

    final q = query.toLowerCase();
    return _tasks.where((t) {
      return t.title.toLowerCase().contains(q) ||
          t.description.toLowerCase().contains(q);
    }).toList();
  }

  List<Task> getTasksDueToday() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    return _tasks.where((t) {
      return t.isCompleted == 0 &&
          t.dueDate.isAfter(today) &&
          t.dueDate.isBefore(tomorrow);
    }).toList();
  }

  List<Task> getTasksDueThisWeek() {
    final now = DateTime.now();
    final startOfWeek = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 7));

    return _tasks.where((t) {
      return t.isCompleted == 0 &&
          t.dueDate.isAfter(startOfWeek) &&
          t.dueDate.isBefore(endOfWeek);
    }).toList();
  }

  Future<bool> clearCompletedTasks(String ownerId) async {
    _setLoading(true);
    _setError(null);

    try {
      final completed = _tasks.where((t) => t.isCompleted == 1).toList();

      for (final t in completed) {
        if (t.id != null) {
          await DBHelper.deleteTask(t.id!);
        }
      }

      await loadTasks(ownerId);
      return true;
    } catch (e) {
      _setError('Failed to clear completed tasks: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }
}
