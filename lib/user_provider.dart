import 'package:flutter/material.dart';

class UserProvider extends ChangeNotifier {
  Map<String, dynamic>? _user;

  Map<String, dynamic>? get user => _user;

  void setUser(Map<String, dynamic> userData) {
    _user = userData;
    notifyListeners(); // triggers rebuilds where context.watch<UserProvider>() is used
  }

  void clearUser() {
    _user = null;
    notifyListeners();
  }
}
