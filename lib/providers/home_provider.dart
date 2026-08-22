import 'package:get/get.dart';

import '../models/home_model.dart';
import '../services/home_service.dart';

class HomeProvider extends GetxController {
  // ============================================================
  // DEPENDENCIES
  // ============================================================

  final HomeService _homeService;

  HomeProvider({
    required HomeService homeService,
  }) : _homeService = homeService;

  // ============================================================
  // LOAN DATA
  // ============================================================

  final loans = <Map<String, dynamic>>[].obs;

  // ============================================================
  // DASHBOARD SUMMARY
  // ============================================================

  final totalLoans = 0.obs;

  final pendingLoans = 0.obs;

  final completedLoans = 0.obs;

  final loggedInUserName = ''.obs;

  // ============================================================
  // CURRENTLY SELECTED LOAN FILTER
  // ============================================================

  // Possible values:
  // Total
  // Pending
  // Completed

  final selectedFilter = 'Total'.obs;

  // ============================================================
  // UI STATE
  // ============================================================

  final isLoading = false.obs;

  final errorMessage = RxnString();

  // ============================================================
  // FILTER
  // ============================================================

  void setLoanFilter(String filter) {
    selectedFilter.value = filter;
  }

  // ============================================================
  // FILTERED LOANS
  // ============================================================

  List<Map<String, dynamic>> get filteredLoans {
    switch (selectedFilter.value) {
      case 'Pending':
        return loans
            .where(
              (loan) => loan['status'] == 'Pending',
            )
            .toList();

      case 'Completed':
        return loans
            .where(
              (loan) => loan['status'] == 'Completed',
            )
            .toList();

      case 'Total':
      default:
        return loans.toList();
    }
  }

  // ============================================================
  // LOAD HOME DASHBOARD
  // ============================================================

  Future<void> loadDashboard() async {
    if (isLoading.value) {
      return;
    }

    try {
      isLoading.value = true;
      errorMessage.value = null;

      // --------------------------------------------------------
      // REQUEST
      // --------------------------------------------------------

      const request = HomeRequest(
        page: 1,
        recordsPerPage: 10,
        searchString: '',
      );

      // --------------------------------------------------------
      // API CALL
      // --------------------------------------------------------

      final response = await _homeService.getHomeData(
        request,
      );

      // --------------------------------------------------------
      // API FAILURE
      // --------------------------------------------------------

      if (!response.success) {
        errorMessage.value = response.message.isNotEmpty
            ? response.message
            : 'Unable to load your loan information.';

        loans.clear();
        _clearSummary();

        return;
      }

      // --------------------------------------------------------
      // NO DATA
      // --------------------------------------------------------

      final homeData = response.data;

      if (homeData == null) {
        loans.clear();
        _clearSummary();

        errorMessage.value =
            'No customer information was found.';

        return;
      }

      // --------------------------------------------------------
      // CUSTOMER NAME
      // --------------------------------------------------------

      loggedInUserName.value = homeData.fullName;

      // --------------------------------------------------------
      // MAP API LOANS TO EXISTING HOME UI STRUCTURE
      // --------------------------------------------------------

      final mappedLoans = homeData.loans.map(
        (loan) => _mapLoanToHomeCard(
          loan: loan,
          borrowerName: homeData.fullName,
        ),
      ).toList();

      loans.assignAll(mappedLoans);

      // --------------------------------------------------------
      // CALCULATE SUMMARY
      // --------------------------------------------------------

      _calculateSummary();
    } catch (e) {
      loans.clear();
      _clearSummary();

      errorMessage.value =
          _getErrorMessage(e);
    } finally {
      isLoading.value = false;
    }
  }

  // ============================================================
  // MAP API LOAN → EXISTING HOME CARD
  // ============================================================

  Map<String, dynamic> _mapLoanToHomeCard({
    required HomeLoan loan,
    required String borrowerName,
  }) {
    return {
      // --------------------------------------------------------
      // Vehicle Number
      // --------------------------------------------------------
      //
      // The documented Home API response does not currently
      // expose a dedicated vehicleNumber field.
      //
      // Until the backend provides the exact vehicle field,
      // loanNo is used as the display identifier.
      //
      'vehicleNumber': loan.loanNo,

      // --------------------------------------------------------
      // Borrower Name
      // --------------------------------------------------------
      //
      // The Home API returns the consumer's firstName/lastName
      // at HomeData level.
      //
      'borrowerName': borrowerName,

      // --------------------------------------------------------
      // Loan Amount
      // --------------------------------------------------------

      'amount': loan.loanAmount,

      // --------------------------------------------------------
      // Status
      // --------------------------------------------------------

      'status': loan.displayStatus,

      // --------------------------------------------------------
      // Keep original API model available
      // for future Home details navigation.
      // --------------------------------------------------------

      'loan': loan,
    };
  }

  // ============================================================
  // CALCULATE SUMMARY
  // ============================================================

  void _calculateSummary() {
    totalLoans.value = loans.length;

    pendingLoans.value = loans
        .where(
          (loan) => loan['status'] == 'Pending',
        )
        .length;

    completedLoans.value = loans
        .where(
          (loan) => loan['status'] == 'Completed',
        )
        .length;
  }

  // ============================================================
  // CLEAR SUMMARY
  // ============================================================

  void _clearSummary() {
    totalLoans.value = 0;
    pendingLoans.value = 0;
    completedLoans.value = 0;
  }

  // ============================================================
  // API ERROR MESSAGE
  // ============================================================

  String _getErrorMessage(Object error) {
    final message = error.toString().trim();

    if (message.isEmpty) {
      return 'Unable to load your loan information.';
    }

    final lowerMessage = message.toLowerCase();

    if (lowerMessage.contains('timeout')) {
      return 'Request timed out. Please try again.';
    }

    if (lowerMessage.contains('connect')) {
      return 'Unable to connect to the server.';
    }

    if (lowerMessage.contains('unauthorized') ||
        lowerMessage.contains('401')) {
      return 'Your session has expired. Please login again.';
    }

    return message;
  }

  // ============================================================
  // RETRY
  // ============================================================

  Future<void> retry() async {
    await loadDashboard();
  }

  // ============================================================
  // LIFECYCLE
  // ============================================================

  @override
  void onReady() {
    super.onReady();

    loadDashboard();
  }
}