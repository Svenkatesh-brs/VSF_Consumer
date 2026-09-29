// ============================================================
// PROFILE DRAWER — QUICK ACTIONS CONTEXT
//
// The drawer is opened from two places and must behave differently
// without any "opened from" flag, purely off the shared selected
// loan in LoanDashboardProvider:
//
//   HOME
//     * no loan is selected -> no loan number on the header
//     * a loan-specific action opens the loan picker FIRST and does
//       NOT navigate while asking
//     * once a loan is picked, the pending action continues
//     * dismissing the picker aborts the action
//     * a failed load aborts the action and surfaces an error
//     * Help & Support needs no loan and opens straight away
//
//   LOAN DASHBOARD
//     * the loan number is shown on the header
//     * a loan-specific action opens immediately, no picker
//     * tapping the number reopens the picker to switch loans
//     * switching replaces the previously loaded loan's data
// ============================================================

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

import 'package:vsf_consumer/models/home_model.dart';
import 'package:vsf_consumer/models/loan_dashboard_model.dart';
import 'package:vsf_consumer/providers/home_provider.dart';
import 'package:vsf_consumer/providers/loan_dashboard_provider.dart';
import 'package:vsf_consumer/providers/network_provider.dart';
import 'package:vsf_consumer/routes/app_routes.dart';
import 'package:vsf_consumer/services/api_service.dart';
import 'package:vsf_consumer/services/home_service.dart';
import 'package:vsf_consumer/services/loan_dashboard_service.dart';
import 'package:vsf_consumer/services/network_service.dart';
import 'package:vsf_consumer/services/storage_service.dart';
import 'package:vsf_consumer/translations/language_selection_translations.dart';
import 'package:vsf_consumer/utils/app_theme.dart';
import 'package:vsf_consumer/widgets/loan_dashboard/profile_drawer.dart';

class FakeNetworkService extends NetworkService {
  final StreamController<InternetStatus> _controller =
      StreamController<InternetStatus>.broadcast();

  @override
  Stream<InternetStatus> get onStatusChange => _controller.stream;

  @override
  Future<bool> hasInternetAccess() async => true;
}

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
          {'id': 'A', 'loanNo': 'LN111111', 'status': 0, 'loanAmount': 1000},
          {'id': 'B', 'loanNo': 'LN222222', 'status': 0, 'loanAmount': 2000},
        ],
      },
    });
  }
}

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
        message: 'error_unable_load',
        dashboard: null,
        details: null,
        transactions: null,
        emiSchedule: null,
      );
    }

    return LoanDashboardResponse.fromJson({
      'success': true,
      'message': '',
      'data': {
        'id': loanId,
        'loanNo': 'LN${loanId == 'A' ? '111111' : '222222'}',
        'status': 0,
        'totalEMI': 1,
        'totalEMIPaid': 0,
        'lead': {
          'borrowers': [
            {'firstName': 'Test', 'lastName': loanId},
          ],
        },
        'installments': [
          {
            'id': '$loanId-emi-1',
            'dueDate': 1791181800000,
            'emi': 1804,
            'status': 'Pending',
            'remainingAmount': 1804,
          },
        ],
      },
    });
  }
}

void main() {
  late FakeLoanDashboardService loanService;
  late HomeProvider homeProvider;
  late LoanDashboardProvider loanProvider;

  setUp(() {
    Get.testMode = true;

    loanService = FakeLoanDashboardService();

    Get.put<LoanDashboardService>(loanService, permanent: true);

    homeProvider = HomeProvider(
      homeService: FakeHomeService(),
      networkProvider: NetworkProvider(
        networkService: FakeNetworkService(),
      ),
    );

    Get.put<HomeProvider>(homeProvider, permanent: true);

    loanProvider = LoanDashboardProvider();

    Get.put<LoanDashboardProvider>(loanProvider, permanent: true);
  });

  tearDown(Get.reset);

  /// Opens the drawer inside a real (test-mode) navigator so the
  /// Quick Actions and the loan picker can both be driven.
  Future<void> openDrawer(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      GetMaterialApp(
        debugShowCheckedModeBanner: false,
        translations: LanguageSelectionTranslations(),
        locale: const Locale('en', 'US'),
        fallbackLocale: const Locale('en', 'US'),
        theme: AppTheme.light,
        initialRoute: AppRoutes.home,
        getPages: [
          GetPage(
            name: AppRoutes.home,
            page: () => Scaffold(
              body: Center(
                child: Builder(
                  builder: (context) => ElevatedButton(
                    onPressed: () => ProfileDrawer.show(context),
                    child: const Text('menu'),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    await tester.tap(find.text('menu'));
    await tester.pumpAndSettle();
  }

  Future<void> expandQuickActions(WidgetTester tester) async {
    await tester.tap(find.text('Quick Actions'));
    await tester.pumpAndSettle();
  }

  testWidgets('Home: a loan-specific action asks for a loan before navigating', (
    tester,
  ) async {
    homeProvider.onReady();
    await Future<void>.delayed(Duration.zero);

    await openDrawer(tester);

    // No loan is selected yet, so the header shows no loan number.
    expect(find.text('Quick Actions'), findsOneWidget);
    expect(find.text('LN111111'), findsNothing);
    expect(find.text('LN222222'), findsNothing);

    await expandQuickActions(tester);

    await tester.tap(find.text('EMI Schedule'));
    await tester.pumpAndSettle();

    // The picker opened and the app did NOT navigate yet.
    expect(find.text('Select Loan'), findsOneWidget);
    expect(find.text('LN111111'), findsOneWidget);
    expect(find.text('LN222222'), findsOneWidget);
  });

  testWidgets('Home: picking a loan loads it, then continues to the action', (
    tester,
  ) async {
    homeProvider.onReady();
    await Future<void>.delayed(Duration.zero);

    await openDrawer(tester);
    await expandQuickActions(tester);

    await tester.tap(find.text('Transactions'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('LN222222'));
    await tester.pumpAndSettle();

    // Exactly the tapped loan was fetched, and it became the
    // selected loan behind the whole loan feature.
    expect(loanService.requestedIds, ['B']);
    expect(loanProvider.loanNumber, 'LN222222');
    expect(loanProvider.loanId, 'B');
    expect(loanProvider.dashboard.value?.loanId, 'B');
    expect(loanProvider.emiSchedule.value?.totalCount, 1);
  });

  testWidgets('Home: dismissing the picker aborts the action', (
    tester,
  ) async {
    homeProvider.onReady();
    await Future<void>.delayed(Duration.zero);

    await openDrawer(tester);
    await expandQuickActions(tester);

    await tester.tap(find.text('Complaints'));
    await tester.pumpAndSettle();

    expect(find.text('Select Loan'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    // No request was made and no loan became selected.
    expect(loanService.requestedIds, isEmpty);
    expect(loanProvider.hasSelectedLoan, isFalse);
  });

  testWidgets('Home: a failed load aborts the action and shows an error', (
    tester,
  ) async {
    homeProvider.onReady();
    await Future<void>.delayed(Duration.zero);

    loanService.shouldFail = true;

    await openDrawer(tester);
    await expandQuickActions(tester);

    await tester.tap(find.text('Contact Update'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('LN111111'));
    await tester.pumpAndSettle();

    // The failure is surfaced and the loan is not selected.
    expect(loanService.requestedIds, ['A']);
    expect(loanProvider.hasSelectedLoan, isFalse);
    expect(loanProvider.errorMessage.value, 'error_unable_load');
  });

  testWidgets('Home: Help opens directly because it needs no loan', (
    tester,
  ) async {
    homeProvider.onReady();
    await Future<void>.delayed(Duration.zero);

    await openDrawer(tester);
    await expandQuickActions(tester);

    await tester.tap(find.text('Help & Support'));
    await tester.pumpAndSettle();

    // No picker, and no loan was needed.
    expect(find.text('Select Loan'), findsNothing);
    expect(loanService.requestedIds, isEmpty);
  });

  testWidgets('Dashboard: the selected loan is shown and used immediately', (
    tester,
  ) async {
    homeProvider.onReady();
    await Future<void>.delayed(Duration.zero);

    // The dashboard already preselected a loan through its route.
    await loanProvider.selectLoan({
      'loanNumber': 'LN111111',
      'loan': HomeLoan.fromJson({'id': 'A', 'loanNo': 'LN111111'}),
    });

    await openDrawer(tester);

    // The header now carries the active loan number.
    expect(find.text('LN111111'), findsOneWidget);

    await expandQuickActions(tester);

    // No refetch is needed just to open the drawer.
    expect(loanService.requestedIds, ['A']);

    await tester.tap(find.text('EMI Schedule'));
    await tester.pumpAndSettle();

    // The action went straight through with the existing selection.
    expect(find.text('Select Loan'), findsNothing);
    expect(loanService.requestedIds, ['A']);
  });

  testWidgets('Dashboard: tapping the number switches the active loan', (
    tester,
  ) async {
    homeProvider.onReady();
    await Future<void>.delayed(Duration.zero);

    await loanProvider.selectLoan({
      'loanNumber': 'LN111111',
      'loan': HomeLoan.fromJson({'id': 'A', 'loanNo': 'LN111111'}),
    });

    await openDrawer(tester);
    await expandQuickActions(tester);

    await tester.tap(find.text('LN111111'));
    await tester.pumpAndSettle();

    // The picker opens again, with the current loan marked.
    expect(find.text('Select Loan'), findsOneWidget);
    expect(find.byIcon(Icons.radio_button_checked_rounded), findsOneWidget);

    await tester.tap(find.text('LN222222'));
    await tester.pumpAndSettle();

    // The switch replaced every previous model.
    expect(loanService.requestedIds, ['A', 'B']);
    expect(loanProvider.loanNumber, 'LN222222');
    expect(loanProvider.dashboard.value?.loanId, 'B');
    expect(
      loanProvider.emiSchedule.value!.emis.single.id,
      'B-emi-1',
    );
  });

  testWidgets('Home: the drawer never writes into the My Loans list', (
    tester,
  ) async {
    homeProvider.onReady();
    await Future<void>.delayed(Duration.zero);

    await openDrawer(tester);
    await expandQuickActions(tester);

    await tester.tap(find.text('Complaints'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('LN222222'));
    await tester.pumpAndSettle();

    // Home keeps its own list, loan type and count untouched.
    expect(
      homeProvider.loans.map((loan) => loan['loanNumber']),
      ['LN111111', 'LN222222'],
    );
    expect(homeProvider.selectedLoanType.value, 'my_loans');
    expect(homeProvider.totalLoans.value, 2);
  });
}
