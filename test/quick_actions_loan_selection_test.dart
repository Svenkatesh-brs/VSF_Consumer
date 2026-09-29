// ============================================================
// PROFILE DRAWER QUICK ACTIONS — LOAN SELECTION
//
// Covers the behaviour the drawer relies on when the customer runs
// a loan-specific Quick Action from Home:
//
//   * Home has NO selected loan, so opening the provider must not
//     silently pick the first loan (onReady auto-load is gated on
//     navigation arguments).
//   * The Loan Dashboard route DOES pass a loan through the
//     navigation arguments, so it still auto-loads.
//   * selectLoan() loads exactly the chosen loan and REPLACES the
//     previously loaded models, so EMI Schedule / Transactions can
//     never show stale data from another loan.
//   * A second tap while a request is running does not duplicate
//     it.
//   * A failed selection leaves no data from the previous loan
//     behind.
// ============================================================

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

import 'package:vsf_consumer/models/home_model.dart';
import 'package:vsf_consumer/models/loan_dashboard_model.dart';
import 'package:vsf_consumer/providers/home_provider.dart';
import 'package:vsf_consumer/providers/loan_dashboard_provider.dart';
import 'package:vsf_consumer/providers/network_provider.dart';
import 'package:vsf_consumer/services/api_service.dart';
import 'package:vsf_consumer/services/home_service.dart';
import 'package:vsf_consumer/services/loan_dashboard_service.dart';
import 'package:vsf_consumer/services/network_service.dart';
import 'package:vsf_consumer/services/storage_service.dart';

/// Records every requested loan id and can be switched into a
/// failing state, so the drawer flow can be verified without a
/// network.
class FakeLoanDashboardService extends LoanDashboardService {
  FakeLoanDashboardService()
    : super(
        apiService: ApiService(
          baseUrl: 'http://localhost',
          storageService: StorageService(),
        ),
      );

  final List<String> requestedIds = <String>[];

  bool shouldFail = false;

  @override
  Future<LoanDashboardResponse> getLoanById(String loanId) async {
    requestedIds.add(loanId);

    if (shouldFail) {
      return const LoanDashboardResponse(
        success: false,
        message: 'loan_unavailable',
        dashboard: null,
        details: null,
        transactions: null,
        emiSchedule: null,
      );
    }

    return LoanDashboardResponse.fromJson(_payloadFor(loanId));
  }
}

class FakeNetworkService extends NetworkService {
  final StreamController<InternetStatus> _controller =
      StreamController<InternetStatus>.broadcast();

  @override
  Stream<InternetStatus> get onStatusChange => _controller.stream;

  @override
  Future<bool> hasInternetAccess() async => true;
}

/// Serves the two-loan "My Loans" list the picker reads.
class FakeHomeService extends HomeService {
  FakeHomeService()
    : super(
        apiService: ApiService(
          baseUrl: 'http://localhost',
          storageService: StorageService(),
        ),
      );

  @override
  Future<HomeResponse> getHomeData(HomeRequest request) async {
    return HomeResponse.fromJson({
      'success': true,
      'message': '',
      'page': 1,
      'recordsPerPage': 10,
      'total': 2,
      'data': {
        'firstName': 'Test',
        'lastName': 'User',
        'loans': [
          {'id': 'A', 'loanNo': 'LN-A', 'status': 0, 'loanAmount': 1000},
          {'id': 'B', 'loanNo': 'LN-B', 'status': 0, 'loanAmount': 2000},
        ],
      },
    });
  }
}

Map<String, dynamic> _payloadFor(String loanId) {
  return {
    'success': true,
    'message': '',
    'data': {
      'id': loanId,
      'loanNo': 'LN-$loanId',
      'status': 0,
      'installmentDues': 5000,
      'totalEMI': 2,
      'totalEMIPaid': 1,
      'lead': {
        'borrowers': [
          {'firstName': 'Test', 'lastName': loanId},
        ],
      },
      'installments': [
        {
          'id': '$loanId-emi-1',
          'dueDate': 1764892800000,
          'emi': 1804,
          'status': 'Paid',
          'totalPaid': 1804,
          'remainingAmount': 0,
        },
        {
          'id': '$loanId-emi-2',
          'dueDate': 1791181800000,
          'emi': 1804,
          'status': 'Pending',
          'totalPaid': 0,
          'remainingAmount': 1804,
        },
      ],
    },
  };
}

/// "My Loans" card exactly as HomeProvider maps it.
Map<String, dynamic> _homeCard(String loanId) {
  return {
    'loanNumber': 'LN-$loanId',
    'borrowers': <String>['Test $loanId'],
    'amount': 3608.0,
    'status': 'Active',
    'loan': HomeLoan.fromJson({'id': loanId, 'loanNo': 'LN-$loanId'}),
  };
}

void main() {
  late FakeLoanDashboardService service;
  late LoanDashboardProvider provider;

  setUp(() {
    service = FakeLoanDashboardService();

    Get.put<LoanDashboardService>(service, permanent: true);

    provider = LoanDashboardProvider();
  });

  tearDown(() {
    Get.reset();
  });

  test('Home does not auto-select a loan on first use', () async {
    // Home passes no loan through the navigation arguments.
    Get.routing.args = null;

    provider.onReady();

    // The loan list Home already holds must not be turned into a
    // silent selection.
    expect(service.requestedIds, isEmpty);
    expect(provider.hasSelectedLoan, isFalse);
    expect(provider.loanNumber, '');
    expect(provider.selectedLoan.value, isNull);
  });

  test('Loan Dashboard still auto-loads the loan from its arguments', () async {
    Get.routing.args = _homeCard('A');

    provider.onReady();
    await Future<void>.delayed(Duration.zero);

    expect(service.requestedIds, ['A']);
    expect(provider.hasSelectedLoan, isTrue);
    expect(provider.loanNumber, 'LN-A');
  });

  test('selecting a loan from Home loads only that loan', () async {
    final loaded = await provider.selectLoan(_homeCard('A'));

    expect(loaded, isTrue);
    expect(service.requestedIds, ['A']);

    expect(provider.loanNumber, 'LN-A');
    expect(provider.loanId, 'A');

    // Every domain view belongs to loan A.
    expect(provider.dashboard.value?.loanId, 'A');
    expect(provider.emiSchedule.value?.totalCount, 2);
    expect(
      provider.emiSchedule.value!.emis.map((emi) => emi.id),
      ['A-emi-1', 'A-emi-2'],
    );
    expect(provider.borrowerName, 'Test A');
  });

  test('switching loans replaces every previous loan model', () async {
    await provider.selectLoan(_homeCard('A'));

    expect(provider.emiSchedule.value!.emis.first.id, 'A-emi-1');

    final loaded = await provider.selectLoan(_homeCard('B'));

    expect(loaded, isTrue);
    expect(provider.loanNumber, 'LN-B');
    expect(provider.loanId, 'B');

    // No trace of loan A is left behind.
    expect(provider.dashboard.value?.loanId, 'B');
    expect(
      provider.emiSchedule.value!.emis.map((emi) => emi.id),
      ['B-emi-1', 'B-emi-2'],
    );
    expect(provider.borrowerName, 'Test B');
    expect(provider.selectedLoan.value?['loanId'], 'B');
  });

  test('the previous loan is dropped before the new one is fetched', () async {
    await provider.selectLoan(_homeCard('A'));

    service.shouldFail = true;

    final pending = provider.selectLoan(_homeCard('B'));

    // Mid-flight: the stale EMI schedule of loan A must already be
    // gone, so no screen can render it while loan B is loading.
    expect(provider.emiSchedule.value, isNull);
    expect(provider.transactions.value, isNull);
    expect(provider.dashboard.value, isNull);
    expect(provider.loanId, 'B');

    expect(await pending, isFalse);

    // A failed switch must not resurrect loan A's data.
    expect(provider.emiSchedule.value, isNull);
    expect(provider.dashboard.value, isNull);
    expect(provider.errorMessage.value, 'loan_unavailable');
  });

  test('a second tap while loading does not duplicate the request', () async {
    final first = provider.selectLoan(_homeCard('A'));
    final second = provider.selectLoan(_homeCard('A'));

    expect(await first, isTrue);
    expect(await second, isFalse);

    expect(service.requestedIds, ['A']);
  });

  test('a loan card without an id is rejected without a request', () async {
    final loaded = await provider.selectLoan(<String, dynamic>{
      'loanNumber': 'LN-X',
    });

    expect(loaded, isFalse);
    expect(service.requestedIds, isEmpty);
    expect(provider.hasSelectedLoan, isFalse);
  });

  test('the drawer never writes into the Home "My Loans" list', () async {
    final homeProvider = HomeProvider(
      homeService: FakeHomeService(),
      networkProvider: NetworkProvider(
        networkService: FakeNetworkService(),
      ),
    );

    Get.put<HomeProvider>(homeProvider, permanent: true);

    homeProvider.onReady();
    await Future<void>.delayed(Duration.zero);

    final loansBefore = homeProvider.loans
        .map((loan) => loan['loanNumber'])
        .toList();

    expect(loansBefore, ['LN-A', 'LN-B']);

    await provider.selectLoan(_homeCard('B'));

    // The selected Quick Actions loan lives in LoanDashboardProvider
    // only — Home's list, filters and loan type are untouched.
    expect(
      homeProvider.loans.map((loan) => loan['loanNumber']),
      loansBefore,
    );
    expect(homeProvider.selectedLoanType.value, 'my_loans');
    expect(homeProvider.totalLoans.value, 2);

    homeProvider.onClose();
  });
}
