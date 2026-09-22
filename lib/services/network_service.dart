import 'dart:async';

import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

class NetworkService {
  final InternetConnection _connection = InternetConnection();

  /// Check whether the device has internet access.
  Future<bool> hasInternetAccess() async {
    try {
      return await _connection.hasInternetAccess;
    } catch (_) {
      return false;
    }
  }

  /// Listen for internet connectivity changes.
  Stream<InternetStatus> get onStatusChange {
    return _connection.onStatusChange;
  }
}