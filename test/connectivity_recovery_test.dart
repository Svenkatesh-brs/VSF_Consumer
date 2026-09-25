import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:vsf_consumer/models/home_model.dart';
import 'package:vsf_consumer/providers/home_provider.dart';
import 'package:vsf_consumer/providers/network_provider.dart';
import 'package:vsf_consumer/services/api_service.dart';
import 'package:vsf_consumer/services/home_service.dart';
import 'package:vsf_consumer/services/network_service.dart';
import 'package:vsf_consumer/services/storage_service.dart';

/// Controllable [NetworkService] so tests can simulate connectivity loss
/// and restoration without any real network access.
class FakeNetworkService extends NetworkService {
  final _statusController = StreamController<InternetStatus>.broadcast();

  bool online = true;

  @override
  Stream<InternetStatus> get onStatusChange => _statusController.stream;

  @override
  Future<bool> hasInternetAccess() async => online;

  void simulateRestore() {
    online = true;
    _statusController.add(InternetStatus.connected);
  }

  void simulateLoss() {
    online = false;
    _statusController.add(InternetStatus.disconnected);
  }
}

/// Controllable [HomeService] that counts calls and returns a failure until
/// [succeed] is enabled.
class FakeHomeService extends HomeService {
  FakeHomeService()
    : super(
        apiService: ApiService(
          baseUrl: 'http://localhost',
          storageService: StorageService(),
        ),
      );

  int getHomeDataCalls = 0;

  bool succeed = false;

  @override
  Future<HomeResponse> getHomeData(HomeRequest request) async {
    getHomeDataCalls += 1;

    if (!succeed) {
      return const HomeResponse(
        data: null,
        message: 'offline_error',
        page: 1,
        recordsPerPage: 10,
        success: false,
        total: 0,
      );
    }

    return HomeResponse.fromJson({
      'success': true,
      'message': '',
      'page': 1,
      'recordsPerPage': 10,
      'total': 1,
      'data': {
        'firstName': 'Test',
        'lastName': 'User',
        'loans': [
          {'id': 'l1', 'loanNo': 'LN-001', 'status': 0, 'loanAmount': 1000},
        ],
      },
    });
  }

  @override
  Future<HomeResponse> getGuarantorLoans(HomeRequest request) async {
    return const HomeResponse(
      data: null,
      message: '',
      page: 1,
      recordsPerPage: 10,
      success: true,
      total: 0,
    );
  }
}

Future<void> _flush(WidgetTester tester) async {
  for (var i = 0; i < 20; i++) {
    await tester.pump();
  }
}

void main() {
  testWidgets('internet OFF -> ON automatically reloads Home data', (
    tester,
  ) async {
    final networkService = FakeNetworkService()..online = false;
    final networkProvider = NetworkProvider(networkService: networkService);
    networkProvider.initialize();

    final homeService = FakeHomeService();
    final homeProvider = HomeProvider(
      homeService: homeService,
      networkProvider: networkProvider,
    );
    homeProvider.onReady();

    await _flush(tester);

    // Offline launch: No Internet state + Home failed to load (single attempt).
    expect(networkProvider.hasInternet, isFalse);
    expect(homeProvider.errorMessage.value, isNotNull);
    expect(homeProvider.loans, isEmpty);
    expect(homeService.getHomeDataCalls, 1);

    // Internet restored -> one automatic recovery, no manual Try Again.
    homeService.succeed = true;
    networkService.simulateRestore();
    await _flush(tester);

    expect(networkProvider.hasInternet, isTrue);
    expect(homeProvider.errorMessage.value, isNull);
    expect(homeProvider.loans, isNotEmpty);
    expect(homeProvider.totalLoans.value, 1);
    expect(homeService.getHomeDataCalls, 2);

    // Already online: another connected event must NOT reload again.
    networkService.simulateRestore();
    await _flush(tester);
    expect(homeService.getHomeDataCalls, 2);

    // OFF -> ON again produces exactly one fresh recovery.
    homeService.succeed = true;
    networkService.simulateLoss();
    await _flush(tester);
    expect(networkProvider.hasInternet, isFalse);
    expect(homeService.getHomeDataCalls, 2);

    networkService.simulateRestore();
    await _flush(tester);
    expect(networkProvider.hasInternet, isTrue);
    expect(homeProvider.errorMessage.value, isNull);
    expect(homeService.getHomeDataCalls, 3);

    homeProvider.onClose();
    networkProvider.dispose();
  });

  testWidgets('internet online from the start loads Home once', (tester) async {
    final networkService = FakeNetworkService()..online = true;
    final networkProvider = NetworkProvider(networkService: networkService);
    networkProvider.initialize();

    final homeService = FakeHomeService()..succeed = true;
    final homeProvider = HomeProvider(
      homeService: homeService,
      networkProvider: networkProvider,
    );
    homeProvider.onReady();

    await _flush(tester);

    expect(networkProvider.hasInternet, isTrue);
    expect(homeProvider.errorMessage.value, isNull);
    expect(homeProvider.loans, isNotEmpty);
    expect(homeService.getHomeDataCalls, 1);

    // No connectivity transition happens, so nothing reloads.
    networkService.simulateRestore();
    await _flush(tester);
    expect(homeService.getHomeDataCalls, 1);

    homeProvider.onClose();
    networkProvider.dispose();
  });

  testWidgets('server error while online is NOT treated as no internet', (
    tester,
  ) async {
    final networkService = FakeNetworkService()..online = true;
    final networkProvider = NetworkProvider(networkService: networkService);
    networkProvider.initialize();

    final homeService = FakeHomeService(); // still failing -> error state
    final homeProvider = HomeProvider(
      homeService: homeService,
      networkProvider: networkProvider,
    );
    homeProvider.onReady();

    await _flush(tester);

    expect(networkProvider.hasInternet, isTrue);
    expect(homeProvider.errorMessage.value, isNotNull);
    expect(homeService.getHomeDataCalls, 1);

    // No offline -> online transition occurred, so no reload is triggered.
    await _flush(tester);
    expect(homeService.getHomeDataCalls, 1);

    homeProvider.onClose();
    networkProvider.dispose();
  });
}
