import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:canteen_food_ordering_app/models/user.dart';

class AuthNotifier extends ChangeNotifier {
  late firebase.User _user;

  firebase.User get user {
    return _user;
  }

  void setUser(firebase.User user) {
    _user = user;
    notifyListeners();
  }

  // Test
  late User _userDetails;

  User get userDetails => _userDetails;

  setUserDetails(User user) {
    _userDetails = user;
    notifyListeners();
  }
}
