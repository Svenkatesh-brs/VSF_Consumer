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

  final activeLoans = 0.obs;

  final inactiveLoans = 0.obs;

  final loggedInUserName = ''.obs;

  // ============================================================
  // CURRENTLY SELECTED LOAN FILTER
  // ============================================================

  // Possible values:
  // Total
  // Active
  // Inactive

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
      case 'Active':
        return loans
            .where(
              (loan) => loan['status'] == 'Active',
            )
            .toList();

      case 'Inactive':
        return loans
            .where(
              (loan) => loan['status'] == 'Inactive',
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
    await _loadDashboard(showLoading: true);
  }

  // ============================================================
  // REFRESH HOME DASHBOARD
  //
  // Same API call and data updates as loadDashboard, but keeps
  // the current content on screen while the RefreshIndicator
  // provides the progress feedback. Used for pull-to-refresh.
  // ============================================================

  Future<void> refreshDashboard() async {
    await _loadDashboard(showLoading: false);
  }

  Future<void> _loadDashboard({
    required bool showLoading,
  }) async {
    if (isLoading.value) {
      return;
    }

    try {
      if (showLoading) {
        isLoading.value = true;
        errorMessage.value = null;
      }

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
      //
      // On refresh the current data stays on screen; only the
      // initial load clears it and surfaces the error view.
      // --------------------------------------------------------

      if (!response.success) {
        if (showLoading) {
          errorMessage.value = response.message.isNotEmpty
              ? response.message
              : 'Unable to load your loan information.';

          loans.clear();
          _clearSummary();
        }

        return;
      }

      // --------------------------------------------------------
      // NO DATA
      // --------------------------------------------------------

      final homeData = response.data;

      if (homeData == null) {
        if (showLoading) {
          loans.clear();
          _clearSummary();

          errorMessage.value =
              'No customer information was found.';
        }

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
        (loan) {
          // ------------------------------------------------------
          // Borrower names come from each borrower's nested
          // consumer record. If the API returns no usable names,
          // fall back to the consumer's own full name so the
          // card never renders an empty value.
          // ------------------------------------------------------

          final borrowerNames = loan.borrowerNames;

          return _mapLoanToHomeCard(
            loan: loan,
            borrowerNames: borrowerNames.isEmpty
                ? <String>[homeData.fullName]
                : borrowerNames,
          );
        },
      ).toList();

      loans.assignAll(mappedLoans);

      // --------------------------------------------------------
      // CALCULATE SUMMARY
      // --------------------------------------------------------

      _calculateSummary();
    } catch (e) {
      if (showLoading) {
        loans.clear();
        _clearSummary();

        errorMessage.value =
            _getErrorMessage(e);
      }
    } finally {
      if (showLoading) {
        isLoading.value = false;
      }
    }
  }

  // ============================================================
  // MAP API LOAN → EXISTING HOME CARD
  // ============================================================

  Map<String, dynamic> _mapLoanToHomeCard({
    required HomeLoan loan,
    required List<String> borrowerNames,
  }) {
    return {
      // --------------------------------------------------------
      // Loan Number (complete, exactly as returned by the API)
      // --------------------------------------------------------

      'loanNumber': loan.loanNumber,

      // --------------------------------------------------------
      // Borrowers (complete borrower names)
      // --------------------------------------------------------

      'borrowers': borrowerNames,

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

    activeLoans.value = loans
        .where(
          (loan) => loan['status'] == 'Active',
        )
        .length;

    inactiveLoans.value = loans
        .where(
          (loan) => loan['status'] == 'Inactive',
        )
        .length;
  }

  // ============================================================
  // CLEAR SUMMARY
  // ============================================================

  void _clearSummary() {
    totalLoans.value = 0;
    activeLoans.value = 0;
    inactiveLoans.value = 0;
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