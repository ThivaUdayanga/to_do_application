import 'package:flutter/material.dart';
import '../db_helper.dart';
import '../model/user_model.dart';

class AuthController extends ChangeNotifier {
  User? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _currentUser != null;

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

  // Register new user
  Future<bool> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _setError(null);

    try {
      // Check if email already exists
      final existingUser = await _checkEmailExists(email);
      if (existingUser) {
        _setError('Email already registered');
        _setLoading(false);
        return false;
      }

      User newUser = User(
        firstName: firstName,
        lastName: lastName,
        email: email,
        password: password,
      );

      await DBHelper.registerUser(newUser);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Registration failed: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  // Login user
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _setError(null);

    try {
      User? user = await DBHelper.loginUser(email, password);

      if (user != null) {
        _currentUser = user;
        _setLoading(false);
        return true;
      } else {
        _setError('Invalid email or password');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('Login failed: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  // Logout user
  void logout() {
    _currentUser = null;
    _errorMessage = null;
    notifyListeners();
  }

  // Check if email already exists
  Future<bool> _checkEmailExists(String email) async {
    try {
      final db = await DBHelper.database;
      final result = await db.query(
        'users',
        where: 'email = ?',
        whereArgs: [email],
      );
      return result.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // Get user full name
  String getUserFullName() {
    if (_currentUser != null) {
      return '${_currentUser!.firstName} ${_currentUser!.lastName}';
    }
    return 'Guest';
  }

  // Get user initials for avatar
  String getUserInitials() {
    if (_currentUser != null) {
      String firstInitial = _currentUser!.firstName.isNotEmpty
          ? _currentUser!.firstName[0].toUpperCase()
          : '';
      String lastInitial = _currentUser!.lastName.isNotEmpty
          ? _currentUser!.lastName[0].toUpperCase()
          : '';
      return '$firstInitial$lastInitial';
    }
    return 'G';
  }
}
