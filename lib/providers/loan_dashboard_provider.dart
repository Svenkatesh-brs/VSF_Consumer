import 'package:get/get.dart';

import '../models/emi_schedule_model.dart';
import '../models/home_model.dart';
import '../models/loan_dashboard_model.dart';
import '../models/loan_details_model.dart';
import '../models/transactions_model.dart';
import 'home_provider.dart';
import '../services/loan_dashboard_service.dart';

class LoanDashboardProvider extends GetxController {
  // ============================================================
  // DEPENDENCIES
  //
  // The service is resolved from the locator because this
  // controller is registered by LoanDashboardBinding right after
  // LoanDashboardService itself.
  // ============================================================

  final LoanDashboardService _loanDashboardService;

  LoanDashboardProvider()
    : _loanDashboardService = Get.find<LoanDashboardService>();

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

    print('[LOAN PROVIDER] Get.arguments: $arguments');

    try {
      isLoading.value = true;
      errorMessage.value = null;

      // --------------------------------------------------------
      // RESOLVE LOAN ID FROM NAVIGATION ARGUMENTS
      // --------------------------------------------------------

      final loanId = _resolveLoanId(arguments);

      print('[LOAN PROVIDER] Resolved loanId: $loanId');

      if (loanId.isEmpty) {
        if (selectedLoan.value == null) {
          selectedLoan.value = _selectedLoanFromArguments(arguments);
        }

        errorMessage.value = 'No loan information was found.';

        return;
      }

      // --------------------------------------------------------
      // API CALL
      // --------------------------------------------------------

      print('[LOAN PROVIDER] Loading loan: $loanId');

      final response = await _loanDashboardService.getLoanById(loanId);

      print('[LOAN PROVIDER] API success: ${response.success}');

      // --------------------------------------------------------
      // API FAILURE
      // --------------------------------------------------------

      if (!response.success) {
        errorMessage.value = response.message.isNotEmpty
            ? response.message
            : 'Unable to load your loan information.';

        if (selectedLoan.value == null) {
          selectedLoan.value = _selectedLoanFromArguments(arguments);
        }

        return;
      }

      // --------------------------------------------------------
      // NO DATA
      // --------------------------------------------------------

      final dashboardData = response.dashboard;

      if (dashboardData == null) {
        errorMessage.value = 'No loan information was found.';

        if (selectedLoan.value == null) {
          selectedLoan.value = _selectedLoanFromArguments(arguments);
        }

        return;
      }

      // --------------------------------------------------------
      // PUBLISH DOMAIN MODELS
      // --------------------------------------------------------

      dashboard.value = dashboardData;

      loanDetails.value = response.details;

      transactions.value = response.transactions;

      emiSchedule.value = response.emiSchedule;

      print(
        '[LOAN PROVIDER] EMI schedule available: '
        '${response.emiSchedule != null}',
      );

      // --------------------------------------------------------
      // MAP API MODEL TO EXISTING DASHBOARD UI STRUCTURE
      // --------------------------------------------------------

      selectedLoan.value = {
        'loanId': dashboardData.loanId,

        // Registration number with loan-number fallback,
        // mirroring the Home card structure.
        'loanNumber': dashboardData.loanNo,

        'borrowers': <String>[
          if (dashboardData.borrowerName.isNotEmpty) dashboardData.borrowerName,
        ],

        'amount': dashboardData.loanAmount,

        'status': dashboardData.displayStatus,

        // Keep the original API model available for the
        // upcoming details / transactions / EMI screens.
        'loan': dashboardData,
      };
    } catch (e) {
      errorMessage.value = _getErrorMessage(e);

      if (selectedLoan.value == null) {
        selectedLoan.value = _selectedLoanFromArguments(arguments);
      }
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
  // accepted defensively. When no arguments carry an id (e.g. the
  // sub-screens pushed after the dashboard), the already-loaded
  // selectedLoan is used so pull-to-refresh still targets the
  // correct loan.
  // ============================================================

  String _resolveLoanId(dynamic arguments) {
    var loanId = _loanIdFromArguments(arguments);

    if (loanId.isEmpty) {
      loanId = _loanIdFromArguments(selectedLoan.value);
    }

    if (loanId.isEmpty && Get.isRegistered<HomeProvider>()) {
      final homeProvider = Get.find<HomeProvider>();
      if (homeProvider.loans.isNotEmpty) {
        final firstLoan = homeProvider.loans.first;
        loanId = _loanIdFromArguments(firstLoan);
        if (selectedLoan.value == null) {
          selectedLoan.value = _selectedLoanFromArguments(firstLoan);
        }
      }
    }

    return loanId;
  }

  String _loanIdFromArguments(dynamic arguments) {
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

  Map<String, dynamic> _selectedLoanFromArguments(dynamic arguments) {
    if (arguments is Map<String, dynamic>) {
      return arguments;
    }

    return <String, dynamic>{};
  }

  // ============================================================
  // CONVENIENCE GETTERS
  // ============================================================

  /// Complete loan number of the currently selected loan, or an
  /// empty string when no loan has been selected yet.
  ///
  /// This is the single "selected loan" of the whole loan feature:
  /// the Dashboard, EMI Schedule, Transactions, Contact Update,
  /// Complaints and the Profile Drawer's Quick Actions all resolve
  /// it from here, so none of them can drift onto another loan.
  String get loanNumber {
    final fromSelected =
        selectedLoan.value?['loanNumber']?.toString().trim() ?? '';

    if (fromSelected.isNotEmpty) {
      return fromSelected;
    }

    return dashboard.value?.loanNo.trim() ?? '';
  }

  /// True only once a loan has actually been selected (either by
  /// opening the Loan Dashboard or through the Quick Actions loan
  /// picker). Home intentionally has no selected loan.
  bool get hasSelectedLoan => loanNumber.isNotEmpty;

  /// Backend id of the selected loan; empty when none is selected.
  String get loanId {
    final fromDashboard = dashboard.value?.loanId.trim() ?? '';

    if (fromDashboard.isNotEmpty) {
      return fromDashboard;
    }

    return selectedLoan.value?['loanId']?.toString().trim() ?? '';
  }

  String get vehicleNumber =>
      selectedLoan.value?['loanNumber']?.toString() ?? '';

  String get borrowerName {
    final borrowers = selectedLoan.value?['borrowers'] as List?;

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

  double get outstandingAmount => dashboard.value?.outstandingAmount ?? 0;

  double get emiAmount => dashboard.value?.emiAmount ?? 0;

  /// Repayment progress as a 0.0 - 1.0 fraction
  /// (totalEMIPaid / totalEMI).
  double get repaymentProgress => dashboard.value?.repaymentProgress ?? 0;

  int? get nextEmiDueDateMs => dashboard.value?.nextEmiDueDateMs;

  /// EMI schedule summary for the Loan Overview Card.
  int get totalEmis => emiSchedule.value?.totalCount ?? 0;

  int get paidEmis => emiSchedule.value?.paidCount ?? 0;

  int get upcomingEmis => emiSchedule.value?.upcomingCount ?? 0;

  int get overdueEmis => emiSchedule.value?.overdueCount ?? 0;

  /// Formatted "dd MMM yyyy"; a dash when no upcoming EMI
  /// exists (all paid or not provided by the API).
  String get nextEmiDueDate => formatDateMs(nextEmiDueDateMs);

  /// Formats epoch milliseconds as "dd MMM yyyy" using
  /// [_monthNames]; returns a dash when the value is null.
  String formatDateMs(int? ms) {
    if (ms == null) {
      return '-';
    }

    final date = DateTime.fromMillisecondsSinceEpoch(ms);

    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }

  String get guarantorName => _firstGuarantor()?.name ?? '';

  String get guarantorRelation => _firstGuarantor()?.relation ?? '';

  String get guarantorMobile => _firstGuarantor()?.phone ?? '';

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
  // SELECT A SPECIFIC LOAN
  //
  //   GET /api/v1/consumer/loan/{loanId}
  //
  // Used by the Profile Drawer's Quick Actions when the customer
  // picks a loan from the "My Loans" list. It reuses the exact same
  // endpoint, service and models as [loadLoanDetails] — there is no
  // second loan store anywhere in the app.
  //
  // DATA ISOLATION: the previously selected loan's models are
  // cleared BEFORE the request starts, so EMI Schedule, Transactions
  // and Contact Update can never render another loan's data while
  // this one is loading (or after a failure).
  //
  // Returns false when the loan could not be loaded; the caller then
  // keeps the user where they are instead of navigating.
  // ============================================================

  Future<bool> selectLoan(Map<String, dynamic> loan) async {
    final loanId = _loanIdFromArguments(loan);

    if (loanId.isEmpty) {
      errorMessage.value = 'No loan information was found.';
      return false;
    }

    // A loan request is already running. Returning early keeps the
    // drawer from firing duplicate requests for the same loan.
    if (isLoading.value) {
      return false;
    }

    try {
      isLoading.value = true;
      errorMessage.value = null;

      // --------------------------------------------------------
      // DROP THE PREVIOUS LOAN
      // --------------------------------------------------------

      selectedLoan.value = <String, dynamic>{...loan, 'loanId': loanId};

      dashboard.value = null;
      loanDetails.value = null;
      transactions.value = null;
      emiSchedule.value = null;

      // --------------------------------------------------------
      // API CALL
      // --------------------------------------------------------

      final response = await _loanDashboardService.getLoanById(loanId);

      if (!response.success || response.dashboard == null) {
        errorMessage.value = response.message.isNotEmpty
            ? response.message
            : 'Unable to load your loan information.';

        return false;
      }

      final dashboardData = response.dashboard!;

      dashboard.value = dashboardData;

      loanDetails.value = response.details;

      transactions.value = response.transactions;

      emiSchedule.value = response.emiSchedule;

      // --------------------------------------------------------
      // MAP TO THE EXISTING VIEW-MODEL SHAPE
      // --------------------------------------------------------

      selectedLoan.value = {
        ...loan,
        'loanId': dashboardData.loanId,
        'loanNumber': dashboardData.loanNo,
        'amount': dashboardData.loanAmount,
        'status': dashboardData.displayStatus,
        'borrowers': <String>[
          if (dashboardData.borrowerName.isNotEmpty)
            dashboardData.borrowerName,
        ],
        'loan': dashboardData,
      };

      return true;
    } catch (e) {
      errorMessage.value = _getErrorMessage(e);

      return false;
    } finally {
      isLoading.value = false;
    }
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

    if (lowerMessage.contains('unauthorized') || lowerMessage.contains('401')) {
      return 'Your session has expired. Please login again.';
    }

    return message;
  }

  // ============================================================
  // LIFECYCLE
  //
  // Auto-load ONLY when the route that created this controller
  // supplied a loan through the navigation arguments:
  //
  //   * Loan Dashboard  -> Home passes the tapped "My Loans" card
  //   * EMI Schedule /
  //     Transactions   -> notification deep links pass a loan id
  //
  // The Profile Drawer on Home resolves the very same controller,
  // but Home has no selected loan. Nothing is loaded there, so
  // Quick Actions asks the customer to pick a loan from the picker
  // instead of silently falling back to the first loan.
  // ============================================================

  @override
  void onReady() {
    super.onReady();

    if (_loanIdFromArguments(Get.arguments).isNotEmpty) {
      loadLoanDetails();
    }
  }
}
