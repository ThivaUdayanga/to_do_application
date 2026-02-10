import 'package:flutter/material.dart';
import '../db_helper.dart';
import '../model/user_model.dart';

class AuthController extends ChangeNotifier {
  User? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  // ===== Getters =====
  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _currentUser != null;

  // ===== Private helpers to update state =====

  // Controls loading spinner in UI
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  // Saves error message for UI or debugging
  void _setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  // Clears error message manually (optional use in UI)
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // ===== SnackBar helper =====
  void _showSnackBar(
      BuildContext context, {
        required String message,
        required Color color,
      }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
      ),
    );
  }

  // ===== Registration =====
  Future<bool> register({
    required BuildContext context,
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _setError(null);

    try {
      // 1) Check if this email already exists in database
      final emailExists = await _checkEmailExists(email);

      if (emailExists) {
        _setError('Email already registered');
        _showSnackBar(
          context,
          message: _errorMessage!,
          color: Colors.red,
        );
        _setLoading(false);
        return false;
      }

      // 2) Create user model
      final newUser = User(
        firstName: firstName,
        lastName: lastName,
        email: email,
        password: password,
      );

      // 3) Save user to DB
      await DBHelper.registerUser(newUser);

      // 4) Success feedback
      _showSnackBar(
        context,
        message: 'Registration successful! Please login.',
        color: Colors.green,
      );

      _setLoading(false);
      return true;
    } catch (e) {
      // Any unexpected error comes here
      _setError('Registration failed: ${e.toString()}');

      _showSnackBar(
        context,
        message: _errorMessage!,
        color: Colors.red,
      );

      _setLoading(false);
      return false;
    }
  }

  // ===== Login =====
  Future<bool> login({
    required BuildContext context, //why
    required String email,
    required String password,
  }) async {
    _setLoading(true);  //why
    _setError(null);  //why

    try {
      // 1) Try login via DB helper
      final user = await DBHelper.loginUser(email, password);

      if (user == null) {
        _setError('Invalid email or password');
        _showSnackBar(
          context,
          message: _errorMessage!,
          color: Colors.red,
        );
        _setLoading(false);
        return false;
      }

      // 2) Save logged-in user in memory
      _currentUser = user;

      // 3) Success feedback
      _showSnackBar(
        context,
        message: 'Login successful!',
        color: Colors.green,
      );

      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Login failed: ${e.toString()}');

      _showSnackBar(
        context,
        message: _errorMessage!,
        color: Colors.red,
      );

      _setLoading(false);
      return false;
    }
  }

  // ===== Logout =====
  void logout() {
    _currentUser = null;
    _errorMessage = null;
    notifyListeners();  //why
  }

  // ===== Database helper: check email exists =====
  Future<bool> _checkEmailExists(String email) async {
    try {
      final db = await DBHelper.database;

      // Query by email, if a row exists then email is already registered
      final result = await db.query(
        'users',
        where: 'email = ?',
        whereArgs: [email],
      );

      return result.isNotEmpty;
    } catch (_) {
      // If DB fails, return false (safe fallback)
      return false;
    }
  }

  // ===== Extra helpers (optional for UI like profile avatar) =====
  String getUserFullName() {
    if (_currentUser == null) return 'Guest';
    return '${_currentUser!.firstName} ${_currentUser!.lastName}';
  }

  String getUserInitials() {
    if (_currentUser == null) return 'G';

    final firstInitial = _currentUser!.firstName.isNotEmpty
        ? _currentUser!.firstName[0].toUpperCase()
        : '';
    final lastInitial = _currentUser!.lastName.isNotEmpty
        ? _currentUser!.lastName[0].toUpperCase()
        : '';

    return '$firstInitial$lastInitial';
  }
}
