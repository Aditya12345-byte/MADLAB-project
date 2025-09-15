import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import 'package:uuid/uuid.dart';
import 'package:expense_tracker/models/user_model.dart';

class AuthService {
  static const String _userKey = 'user';
  static const String _usersCollectionKey = 'users';
  
  // In-memory cache for current user
  User? _currentUser;
  
  // For demo purposes, we'll use SharedPreferences to store user data
  // In a real app, this would be replaced with Firebase Auth or another backend
  
  // Get the current logged in user
  Future<User?> getCurrentUser() async {
    if (_currentUser != null) {
      return _currentUser;
    }
    
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_userKey);
    
    if (userJson != null) {
      try {
        _currentUser = User.fromJson(json.decode(userJson));
        return _currentUser;
      } catch (e) {
        debugPrint('Error parsing user data: $e');
        return null;
      }
    }
    
    return null;
  }
  
  // Register a new user
  Future<User?> register({
    required String name,
    required String email,
    required String password,
    String? phoneNumber,
  }) async {
    try {
      // Check if user already exists
      if (await _userExists(email)) {
        throw Exception('User with this email already exists');
      }
      
      // Hash the password for security
      final hashedPassword = _hashPassword(password);
      
      // Create a new user
      final now = DateTime.now();
      final user = User(
        id: const Uuid().v4(),
        name: name,
        email: email,
        phoneNumber: phoneNumber,
        createdAt: now,
        updatedAt: now,
      );
      
      // Save the user to storage
      await _saveUser(user, hashedPassword);
      
      // Set as current user
      _currentUser = user;
      
      // Save current user to preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userKey, json.encode(user.toJson()));
      
      return user;
    } catch (e) {
      debugPrint('Error registering user: $e');
      return null;
    }
  }
  
  // Login with email and password
  Future<User?> loginWithEmail(String email, String password) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final usersJson = prefs.getString(_usersCollectionKey);
      
      if (usersJson == null) {
        throw Exception('No users found');
      }
      
      final users = json.decode(usersJson) as Map<String, dynamic>;
      
      // Find user by email
      final userEntry = users.entries.firstWhere(
        (entry) {
          final userData = json.decode(entry.value) as Map<String, dynamic>;
          return userData['user']['email'] == email;
        },
        orElse: () => throw Exception('User not found'),
      );
      
      final userData = json.decode(userEntry.value) as Map<String, dynamic>;
      
      // Verify password
      final hashedPassword = _hashPassword(password);
      if (userData['password'] != hashedPassword) {
        throw Exception('Invalid password');
      }
      
      // Create user object
      final user = User.fromJson(userData['user']);
      
      // Set as current user
      _currentUser = user;
      
      // Save current user to preferences
      await prefs.setString(_userKey, json.encode(user.toJson()));
      
      return user;
    } catch (e) {
      debugPrint('Error logging in: $e');
      return null;
    }
  }
  
  // Logout the current user
  Future<bool> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userKey);
      _currentUser = null;
      return true;
    } catch (e) {
      debugPrint('Error logging out: $e');
      return false;
    }
  }
  
  // Update user profile
  Future<User?> updateProfile({
    required String userId,
    String? name,
    String? phoneNumber,
    String? profileImageUrl,
  }) async {
    try {
      // Get current user
      final currentUser = await getCurrentUser();
      if (currentUser == null || currentUser.id != userId) {
        throw Exception('Unauthorized');
      }
      
      // Update user data
      final updatedUser = currentUser.copyWith(
        name: name,
        phoneNumber: phoneNumber,
        profileImageUrl: profileImageUrl,
        updatedAt: DateTime.now(),
      );
      
      // Get all users
      final prefs = await SharedPreferences.getInstance();
      final usersJson = prefs.getString(_usersCollectionKey);
      
      if (usersJson == null) {
        throw Exception('No users found');
      }
      
      final users = json.decode(usersJson) as Map<String, dynamic>;
      
      // Find user entry
      final userEntry = users.entries.firstWhere(
        (entry) {
          final userData = json.decode(entry.value) as Map<String, dynamic>;
          return userData['user']['id'] == userId;
        },
        orElse: () => throw Exception('User not found'),
      );
      
      final userData = json.decode(userEntry.value) as Map<String, dynamic>;
      
      // Update user data
      userData['user'] = updatedUser.toJson();
      users[userEntry.key] = json.encode(userData);
      
      // Save updated users
      await prefs.setString(_usersCollectionKey, json.encode(users));
      
      // Update current user
      _currentUser = updatedUser;
      await prefs.setString(_userKey, json.encode(updatedUser.toJson()));
      
      return updatedUser;
    } catch (e) {
      debugPrint('Error updating profile: $e');
      return null;
    }
  }
  
  // Change password
  Future<bool> changePassword({
    required String userId,
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      // Get current user
      final currentUser = await getCurrentUser();
      if (currentUser == null || currentUser.id != userId) {
        throw Exception('Unauthorized');
      }
      
      // Get all users
      final prefs = await SharedPreferences.getInstance();
      final usersJson = prefs.getString(_usersCollectionKey);
      
      if (usersJson == null) {
        throw Exception('No users found');
      }
      
      final users = json.decode(usersJson) as Map<String, dynamic>;
      
      // Find user entry
      final userEntry = users.entries.firstWhere(
        (entry) {
          final userData = json.decode(entry.value) as Map<String, dynamic>;
          return userData['user']['id'] == userId;
        },
        orElse: () => throw Exception('User not found'),
      );
      
      final userData = json.decode(userEntry.value) as Map<String, dynamic>;
      
      // Verify current password
      final hashedCurrentPassword = _hashPassword(currentPassword);
      if (userData['password'] != hashedCurrentPassword) {
        throw Exception('Current password is incorrect');
      }
      
      // Update password
      final hashedNewPassword = _hashPassword(newPassword);
      userData['password'] = hashedNewPassword;
      users[userEntry.key] = json.encode(userData);
      
      // Save updated users
      await prefs.setString(_usersCollectionKey, json.encode(users));
      
      return true;
    } catch (e) {
      debugPrint('Error changing password: $e');
      return false;
    }
  }
  
  // Delete account
  Future<bool> deleteAccount(String userId, String password) async {
    try {
      // Get current user
      final currentUser = await getCurrentUser();
      if (currentUser == null || currentUser.id != userId) {
        throw Exception('Unauthorized');
      }
      
      // Get all users
      final prefs = await SharedPreferences.getInstance();
      final usersJson = prefs.getString(_usersCollectionKey);
      
      if (usersJson == null) {
        throw Exception('No users found');
      }
      
      final users = json.decode(usersJson) as Map<String, dynamic>;
      
      // Find user entry
      final userEntry = users.entries.firstWhere(
        (entry) {
          final userData = json.decode(entry.value) as Map<String, dynamic>;
          return userData['user']['id'] == userId;
        },
        orElse: () => throw Exception('User not found'),
      );
      
      final userData = json.decode(userEntry.value) as Map<String, dynamic>;
      
      // Verify password
      final hashedPassword = _hashPassword(password);
      if (userData['password'] != hashedPassword) {
        throw Exception('Invalid password');
      }
      
      // Remove user
      users.remove(userEntry.key);
      
      // Save updated users
      await prefs.setString(_usersCollectionKey, json.encode(users));
      
      // Clear current user
      await prefs.remove(_userKey);
      _currentUser = null;
      
      return true;
    } catch (e) {
      debugPrint('Error deleting account: $e');
      return false;
    }
  }
  
  // Helper method to check if a user exists
  Future<bool> _userExists(String email) async {
    final prefs = await SharedPreferences.getInstance();
    final usersJson = prefs.getString(_usersCollectionKey);
    
    if (usersJson == null) {
      return false;
    }
    
    final users = json.decode(usersJson) as Map<String, dynamic>;
    
    return users.values.any((userJson) {
      final userData = json.decode(userJson) as Map<String, dynamic>;
      return userData['user']['email'] == email;
    });
  }
  
  // Helper method to save a user
  Future<void> _saveUser(User user, String hashedPassword) async {
    final prefs = await SharedPreferences.getInstance();
    final usersJson = prefs.getString(_usersCollectionKey);
    
    final Map<String, dynamic> users = usersJson != null 
        ? json.decode(usersJson) as Map<String, dynamic> 
        : {};
    
    final userData = {
      'user': user.toJson(),
      'password': hashedPassword,
    };
    
    users[user.id] = json.encode(userData);
    
    await prefs.setString(_usersCollectionKey, json.encode(users));
  }
  
  // Helper method to hash passwords
  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}