import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService extends ChangeNotifier {
  static const String _pushNotificationsKey = 'push_notifications';
  static const String _emailNotificationsKey = 'email_notifications';
  
  bool _pushNotificationsEnabled = true;
  bool _emailNotificationsEnabled = false;

  bool get pushNotificationsEnabled => _pushNotificationsEnabled;
  bool get emailNotificationsEnabled => _emailNotificationsEnabled;

  NotificationService() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _pushNotificationsEnabled = prefs.getBool(_pushNotificationsKey) ?? true;
    _emailNotificationsEnabled = prefs.getBool(_emailNotificationsKey) ?? false;
    notifyListeners();
  }

  Future<void> setPushNotifications(bool enabled) async {
    _pushNotificationsEnabled = enabled;
    notifyListeners();
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_pushNotificationsKey, enabled);
    
    // TODO: Intégrer avec le service de notifications push
    if (enabled) {
      // Activer les notifications push
    } else {
      // Désactiver les notifications push
    }
  }

  Future<void> setEmailNotifications(bool enabled) async {
    _emailNotificationsEnabled = enabled;
    notifyListeners();
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_emailNotificationsKey, enabled);
    
    // TODO: Intégrer avec le service email
    if (enabled) {
      // Activer les notifications email
    } else {
      // Désactiver les notifications email
    }
  }
}
