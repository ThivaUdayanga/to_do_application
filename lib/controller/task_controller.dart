import 'package:flutter/material.dart';
import '../db_helper.dart';
import '../model/task_model.dart';

class TaskController extends ChangeNotifier {
  List<Task> _tasks = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _filterStatus = 'all'; // 'all', 'completed', 'pending'
  String _sortBy = 'date'; // 'date', 'title', 'priority'

  // Getters
  List<Task> get tasks => _getFilteredTasks();
  List<Task> get allTasks => _tasks;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get filterStatus => _filterStatus;
  String get sortBy => _sortBy;

  // Task statistics
  int get totalTasks => _tasks.length;
  int get completedTasks => _tasks.where((task) => task.isCompleted == 1).length;
  int get pendingTasks => _tasks.where((task) => task.isCompleted == 0).length;
  int get overdueTasks => _tasks.where((task) {
        return task.isCompleted == 0 && task.dueDate.isBefore(DateTime.now());
      }).length;

  // Set loading state
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  // Set error message
  void _setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  // Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Load all tasks from database
  Future<void> loadTasks() async {
    _setLoading(true);
    _setError(null);

    try {
      _tasks = await DBHelper.getTasks();
      _setLoading(false);
    } catch (e) {
      _setError('Failed to load tasks: ${e.toString()}');
      _setLoading(false);
    }
  }

  // Add new task
  Future<bool> addTask({
    required String title,
    required String description,
    required DateTime dueDate,
  }) async {
    _setLoading(true);
    _setError(null);

    try {
      Task newTask = Task(
        title: title,
        description: description,
        createdAt: DateTime.now(),
        dueDate: dueDate,
        isCompleted: 0,
      );

      await DBHelper.insertTask(newTask);
      await loadTasks(); // Reload tasks after adding
      return true;
    } catch (e) {
      _setError('Failed to add task: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  // Update task
  Future<bool> updateTask(Task task) async {
    _setLoading(true);
    _setError(null);

    try {
      await DBHelper.updateTask(task);
      await loadTasks(); // Reload tasks after updating
      return true;
    } catch (e) {
      _setError('Failed to update task: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  // Toggle task completion
  Future<bool> toggleTaskCompletion(Task task) async {
    try {
      Task updatedTask = Task(
        id: task.id,
        title: task.title,
        description: task.description,
        createdAt: task.createdAt,
        dueDate: task.dueDate,
        isCompleted: task.isCompleted == 1 ? 0 : 1,
      );

      return await updateTask(updatedTask);
    } catch (e) {
      _setError('Failed to toggle task: ${e.toString()}');
      return false;
    }
  }

  // Delete task
  Future<bool> deleteTask(int id) async {
    _setLoading(true);
    _setError(null);

    try {
      await DBHelper.deleteTask(id);
      await loadTasks(); // Reload tasks after deleting
      return true;
    } catch (e) {
      _setError('Failed to delete task: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  // Set filter status
  void setFilter(String status) {
    _filterStatus = status;
    notifyListeners();
  }

  // Set sort by
  void setSortBy(String sortBy) {
    _sortBy = sortBy;
    notifyListeners();
  }

  // Get filtered tasks
  List<Task> _getFilteredTasks() {
    List<Task> filtered = [];

    // Apply filter
    switch (_filterStatus) {
      case 'completed':
        filtered = _tasks.where((task) => task.isCompleted == 1).toList();
        break;
      case 'pending':
        filtered = _tasks.where((task) => task.isCompleted == 0).toList();
        break;
      case 'overdue':
        filtered = _tasks.where((task) {
          return task.isCompleted == 0 && task.dueDate.isBefore(DateTime.now());
        }).toList();
        break;
      default:
        filtered = List.from(_tasks);
    }

    // Apply sorting
    switch (_sortBy) {
      case 'title':
        filtered.sort((a, b) => a.title.compareTo(b.title));
        break;
      case 'dueDate':
        filtered.sort((a, b) => a.dueDate.compareTo(b.dueDate));
        break;
      case 'date':
      default:
        // Already sorted by ID DESC from database
        break;
    }

    return filtered;
  }

  // Search tasks by title or description
  List<Task> searchTasks(String query) {
    if (query.isEmpty) return tasks;

    return _tasks.where((task) {
      return task.title.toLowerCase().contains(query.toLowerCase()) ||
          task.description.toLowerCase().contains(query.toLowerCase());
    }).toList();
  }

  // Get tasks due today
  List<Task> getTasksDueToday() {
    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);
    DateTime tomorrow = today.add(const Duration(days: 1));

    return _tasks.where((task) {
      return task.dueDate.isAfter(today) &&
          task.dueDate.isBefore(tomorrow) &&
          task.isCompleted == 0;
    }).toList();
  }

  // Get tasks due this week
  List<Task> getTasksDueThisWeek() {
    DateTime now = DateTime.now();
    DateTime startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    DateTime endOfWeek = startOfWeek.add(const Duration(days: 7));

    return _tasks.where((task) {
      return task.dueDate.isAfter(startOfWeek) &&
          task.dueDate.isBefore(endOfWeek) &&
          task.isCompleted == 0;
    }).toList();
  }

  // Clear all completed tasks
  Future<bool> clearCompletedTasks() async {
    _setLoading(true);
    _setError(null);

    try {
      List<Task> completedTasks = _tasks.where((task) => task.isCompleted == 1).toList();
      
      for (Task task in completedTasks) {
        await DBHelper.deleteTask(task.id!);
      }

      await loadTasks();
      return true;
    } catch (e) {
      _setError('Failed to clear completed tasks: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }
}
