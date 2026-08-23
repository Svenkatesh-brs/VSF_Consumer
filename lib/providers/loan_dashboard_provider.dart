import 'package:get/get.dart';

import '../models/emi_schedule_model.dart';
import '../models/home_model.dart';
import '../models/loan_dashboard_model.dart';
import '../models/loan_details_model.dart';
import '../models/transactions_model.dart';
import '../services/loan_dashboard_service.dart';

class LoanDashboardProvider extends GetxController {
  // ============================================================
  // DATE FORMAT HELPERS
  // ============================================================

  static const List<String> _monthNames = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  // ============================================================
  // DEPENDENCIES
  //
  // The service is resolved from the locator because this
  // controller is registered by LoanDashboardBinding right after
  // LoanDashboardService itself.
  // ============================================================

  final LoanDashboardService _loanDashboardService;

  LoanDashboardProvider()
      : _loanDashboardService =
            Get.find<LoanDashboardService>();

  // ============================================================
  // UI STATE
  // ============================================================

  final isLoading = false.obs;

  final errorMessage = RxnString();

  // ============================================================
  // SELECTED LOAN
  //
  // Flat view-model consumed by the dashboard screen. Populated
  // from the API response on success, or from the navigation
  // arguments as a fallback while an error message is shown.
  // ============================================================

  final selectedLoan = Rxn<Map<String, dynamic>>();

  // ------------------------------------------------------------
  // FULL API MODELS (one response, four domain views)
  // ------------------------------------------------------------

  final dashboard = Rxn<LoanDashboardModel>();

  final loanDetails = Rxn<LoanDetailsModel>();

  final transactions = Rxn<TransactionsModel>();

  final emiSchedule = Rxn<EmiScheduleModel>();

  // ============================================================
  // LOAD SELECTED LOAN
  //
  //   GET /api/v1/consumer/loan/{loanId}
  // ============================================================

  Future<void> loadLoanDetails() async {
    if (isLoading.value) {
      return;
    }

    final arguments = Get.arguments;

    try {
      isLoading.value = true;
      errorMessage.value = null;

      // --------------------------------------------------------
      // RESOLVE LOAN ID FROM NAVIGATION ARGUMENTS
      // --------------------------------------------------------

      final loanId = _resolveLoanId(arguments);

      if (loanId.isEmpty) {
        selectedLoan.value =
            _selectedLoanFromArguments(arguments);

        errorMessage.value =
            'No loan information was found.';

        return;
      }

      // --------------------------------------------------------
      // API CALL
      // --------------------------------------------------------

      final response =
          await _loanDashboardService.getLoanById(
        loanId,
      );

      // --------------------------------------------------------
      // API FAILURE
      // --------------------------------------------------------

      if (!response.success) {
        errorMessage.value = response.message.isNotEmpty
            ? response.message
            : 'Unable to load your loan information.';

        selectedLoan.value =
            _selectedLoanFromArguments(arguments);

        return;
      }

      // --------------------------------------------------------
      // NO DATA
      // --------------------------------------------------------

      final dashboardData = response.dashboard;

      if (dashboardData == null) {
        errorMessage.value =
            'No loan information was found.';

        selectedLoan.value =
            _selectedLoanFromArguments(arguments);

        return;
      }

      // --------------------------------------------------------
      // PUBLISH DOMAIN MODELS
      // --------------------------------------------------------

      dashboard.value = dashboardData;

      loanDetails.value = response.details;

      transactions.value = response.transactions;

      emiSchedule.value = response.emiSchedule;

      // --------------------------------------------------------
      // MAP API MODEL TO EXISTING DASHBOARD UI STRUCTURE
      // --------------------------------------------------------

      selectedLoan.value = {
        'loanId': dashboardData.loanId,

        // Registration number with loan-number fallback,
        // mirroring the Home card structure.
        'loanNumber': dashboardData.vehicleNumber,

        'borrowers': <String>[
          if (dashboardData.borrowerName.isNotEmpty)
            dashboardData.borrowerName,
        ],

        'amount': dashboardData.loanAmount,

        'status': dashboardData.displayStatus,

        // Keep the original API model available for the
        // upcoming details / transactions / EMI screens.
        'loan': dashboardData,
      };
    } catch (e) {
      errorMessage.value = _getErrorMessage(e);

      selectedLoan.value =
          _selectedLoanFromArguments(arguments);
    } finally {
      isLoading.value = false;
    }
  }

  // ============================================================
  // RESOLVE LOAN ID
  //
  // Home navigates with its mapped card map whose 'loan' entry
  // keeps the original HomeLoan API model; its id identifies the
  // loan on the backend. Direct ids and raw strings are also
  // accepted defensively.
  // ============================================================

  String _resolveLoanId(dynamic arguments) {
    if (arguments is HomeLoan) {
      return arguments.id;
    }

    if (arguments is Map) {
      final loan = arguments['loan'];

      if (loan is HomeLoan) {
        return loan.id;
      }

      final loanId = arguments['loanId'] ?? arguments['id'];

      if (loanId != null) {
        return loanId.toString();
      }
    }

    if (arguments is String) {
      return arguments;
    }

    return '';
  }

  // ============================================================
  // FALLBACK VIEW-MODEL FROM NAVIGATION ARGUMENTS
  //
  // Used while the API fails or returns nothing so the screen
  // still renders the data Home already provided instead of
  // spinning forever.
  // ============================================================

  Map<String, dynamic> _selectedLoanFromArguments(
    dynamic arguments,
  ) {
    if (arguments is Map<String, dynamic>) {
      return arguments;
    }

    return <String, dynamic>{};
  }

  // ============================================================
  // CONVENIENCE GETTERS
  // ============================================================

  String get vehicleNumber =>
      selectedLoan.value?['loanNumber']?.toString() ?? '';

  String get borrowerName {
    final borrowers =
        selectedLoan.value?['borrowers'] as List?;

    if (borrowers == null || borrowers.isEmpty) {
      return '';
    }

    return borrowers
        .map((borrower) => borrower?.toString() ?? '')
        .where((borrower) => borrower.isNotEmpty)
        .join(', ');
  }

  String get status => selectedLoan.value?['status']?.toString() ?? '';

  double get amount {
    final value = selectedLoan.value?['amount'];

    if (value is num) {
      return value.toDouble();
    }

    return 0;
  }

  // ------------------------------------------------------------
  // OVERVIEW CARD VALUES
  //
  // Sourced from LoanDashboardModel. All access is null-safe;
  // missing values resolve to zero / dash, never to invented
  // business values.
  // ------------------------------------------------------------

  double get outstandingAmount =>
      dashboard.value?.outstandingAmount ?? 0;

  double get emiAmount => dashboard.value?.emiAmount ?? 0;

  /// Repayment progress as a 0.0 - 1.0 fraction
  /// (totalEMIPaid / totalEMI).
  double get repaymentProgress =>
      dashboard.value?.repaymentProgress ?? 0;

  int? get nextEmiDueDateMs =>
      dashboard.value?.nextEmiDueDateMs;

  /// Formatted "dd MMM yyyy"; a dash when no upcoming EMI
  /// exists (all paid or not provided by the API).
  String get nextEmiDueDate =>
      formatDateMs(nextEmiDueDateMs);

  /// Formats epoch milliseconds as "dd MMM yyyy" using
  /// [_monthNames]; returns a dash when the value is null.
  String formatDateMs(int? ms) {
    if (ms == null) {
      return '-';
    }

    final date =
        DateTime.fromMillisecondsSinceEpoch(ms);

    final day = date.day.toString().padLeft(2, '0');

    return '$day ${_monthNames[date.month - 1]} '
        '${date.year}';
  }

  String get guarantorName =>
      _firstGuarantor()?.name ?? '';

  String get guarantorRelation =>
      _firstGuarantor()?.relation ?? '';

  String get guarantorMobile =>
      _firstGuarantor()?.phone ?? '';

  LoanGuarantorDetail? _firstGuarantor() {
    final guarantors = loanDetails.value?.guarantors;

    if (guarantors == null || guarantors.isEmpty) {
      return null;
    }

    return guarantors.first;
  }

  // ============================================================
  // RETRY
  // ============================================================

  Future<void> retry() async {
    await loadLoanDetails();
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
  // LIFECYCLE
  // ============================================================

  @override
  void onReady() {
    super.onReady();

    loadLoanDetails();
  }
}
