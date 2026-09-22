import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

import '../services/network_service.dart';

class NetworkProvider extends ChangeNotifier {
  final NetworkService networkService;

  NetworkProvider({required this.networkService});

  bool _hasInternet = true;
  bool _isChecking = false;

  StreamSubscription<InternetStatus>? _subscription;

  bool get hasInternet => _hasInternet;
  bool get isChecking => _isChecking;

  void initialize() {
    _subscription?.cancel();

    _subscription = networkService.onStatusChange.listen(
      (status) {
        _hasInternet = status == InternetStatus.connected;
        notifyListeners();
      },
      onError: (_) {
        _hasInternet = false;
        notifyListeners();
      },
    );

    checkConnection();
  }

  Future<void> checkConnection() async {
    if (_isChecking) return;

    _isChecking = true;
    notifyListeners();

    try {
      _hasInternet = await networkService.hasInternetAccess();
    } catch (_) {
      _hasInternet = false;
    } finally {
      _isChecking = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}