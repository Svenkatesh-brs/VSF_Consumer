import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

import '../services/network_service.dart';

class NetworkProvider extends ChangeNotifier with WidgetsBindingObserver {
  final NetworkService networkService;

  NetworkProvider({required this.networkService});

  bool _hasInternet = true;
  bool _isChecking = false;

  StreamSubscription<InternetStatus>? _subscription;

  final StreamController<void> _internetRestoredController =
      StreamController<void>.broadcast();

  bool get hasInternet => _hasInternet;
  bool get isChecking => _isChecking;

  /// Fires only when connectivity transitions from unavailable to available.
  Stream<void> get internetRestored => _internetRestoredController.stream;

  void initialize() {
    WidgetsBinding.instance.addObserver(this);

    _subscription?.cancel();

    _subscription = networkService.onStatusChange.listen(
      (status) {
        _updateInternetStatus(status == InternetStatus.connected);
      },
      onError: (_) {
        _updateInternetStatus(false);
      },
    );

    checkConnection();
  }

  /// Central place for updating the internet state.
  ///
  /// Notifies widgets and emits [internetRestored] only on the
  /// offline -> online transition, so data reloads happen exactly
  /// once per connectivity recovery.
  void _updateInternetStatus(bool hasInternet) {
    if (hasInternet == _hasInternet) {
      return;
    }

    final wasOffline = !_hasInternet;

    _hasInternet = hasInternet;
    notifyListeners();

    if (wasOffline && hasInternet) {
      _internetRestoredController.add(null);
    }
  }

  Future<void> checkConnection() async {
    if (_isChecking) return;

    _isChecking = true;
    notifyListeners();

    try {
      _updateInternetStatus(await networkService.hasInternetAccess());
    } catch (_) {
      _updateInternetStatus(false);
    } finally {
      _isChecking = false;
      notifyListeners();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      checkConnection();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _subscription?.cancel();
    _internetRestoredController.close();
    super.dispose();
  }
}
