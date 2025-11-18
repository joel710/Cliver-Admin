import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationProvider extends ChangeNotifier {
  static const String _pushNotificationsKey = 'push_notifications';
  static const String _emailNotificationsKey = 'email_notifications';
  
  bool _pushNotificationsEnabled = true;
  bool _emailNotificationsEnabled = false;

  bool get pushNotificationsEnabled => _pushNotificationsEnabled;
  bool get emailNotificationsEnabled => _emailNotificationsEnabled;

  NotificationProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _pushNotificationsEnabled = prefs.getBool(_pushNotificationsKey) ?? true;
      _emailNotificationsEnabled = prefs.getBool(_emailNotificationsKey) ?? false;
      notifyListeners();
    } catch (e) {
      // En cas d'erreur, utiliser les valeurs par défaut
    }
  }

  Future<void> setPushNotifications(bool enabled) async {
    _pushNotificationsEnabled = enabled;
    notifyListeners();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_pushNotificationsKey, enabled);
    } catch (e) {
      // Ignorer les erreurs de sauvegarde pour l'instant
    }
  }

  Future<void> setEmailNotifications(bool enabled) async {
    _emailNotificationsEnabled = enabled;
    notifyListeners();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_emailNotificationsKey, enabled);
    } catch (e) {
      // Ignorer les erreurs de sauvegarde pour l'instant
    }
  }
}
