import 'package:get/get.dart';

import '../models/complaint_model.dart';
import '../services/complaint_service.dart';
import 'loan_dashboard_provider.dart';

class ComplaintProvider extends GetxController {
  // ============================================================
  // DEPENDENCIES
  // ============================================================

  ComplaintProvider({
    required ComplaintService complaintService,
  }) : _complaintService = complaintService;

  final ComplaintService _complaintService;

  // ============================================================
  // COMPLAINT LIST
  // ============================================================

  final complaints = <ComplaintModel>[].obs;

  // ============================================================
  // CREATE COMPLAINT RESULT
  // ============================================================

  final createdComplaint = Rxn<ComplaintModel>();

  // ============================================================
  // FORM STATE
  // ============================================================

  final description = ''.obs;

  final selectedIssueType =
      ComplaintCreateRequest.billingOrPayment.obs;

  final isUrgent = false.obs;

  // ============================================================
  // LIST FILTER
  // ============================================================

  final selectedStatus =
      ComplaintModel.pending.obs;

  // ============================================================
  // PAGINATION
  // ============================================================

  final currentPage = 1.obs;

  final recordsPerPage = 10.obs;

  final totalComplaints = 0.obs;

  // ============================================================
  // UI STATE
  // ============================================================

  final isLoading = false.obs;

  final isCreating = false.obs;

  final errorMessage = RxnString();

  final createErrorMessage = RxnString();

  final successMessage = RxnString();

  // ============================================================
  // FORM ACTIONS
  // ============================================================

  void setDescription(String value) {
    description.value = value;
  }

  void setIssueType(int issueType) {
    if (!ComplaintCreateRequest.issueTypeValues.contains(issueType)) {
      return;
    }

    selectedIssueType.value = issueType;
  }

  void setUrgent(bool value) {
    isUrgent.value = value;
  }

  // ============================================================
  // STATUS FILTER
  // ============================================================

  void setStatus(int status) {
    if (status < ComplaintModel.pending ||
        status > ComplaintModel.rejected) {
      return;
    }

    selectedStatus.value = status;
    currentPage.value = 1;

    loadComplaints();
  }

  // ============================================================
  // CREATE COMPLAINT
  // ============================================================

  // ------------------------------------------------------------
  // CURRENT LOAN ID
  //
  // The complaint screen is always opened from the Loan
  // Dashboard, whose provider is still alive on the navigation
  // stack. Defensively falls back to '' when unavailable.
  // ------------------------------------------------------------

  String get _currentLoanId {
    if (!Get.isRegistered<LoanDashboardProvider>()) {
      return '';
    }

    final loanProvider = Get.find<LoanDashboardProvider>();

    final loanId = loanProvider.dashboard.value?.loanId ?? '';

    if (loanId.isNotEmpty) {
      return loanId;
    }

    return loanProvider.selectedLoan.value?['loanId']?.toString() ?? '';
  }

  Future<bool> createComplaint() async {
    if (isCreating.value) {
      return false;
    }

    final trimmedDescription = description.value.trim();

    if (trimmedDescription.isEmpty) {
      createErrorMessage.value =
          'Please enter a complaint description.';
      return false;
    }

    try {
      isCreating.value = true;
      createErrorMessage.value = null;
      successMessage.value = null;

      final request = ComplaintCreateRequest(
        description: trimmedDescription,
        urgent: isUrgent.value,
        issueType: selectedIssueType.value,
        loanId: _currentLoanId,
        // No file handling exists yet; preserve the current
        // empty-string value the documentation shows for "file".
        file: '',
      );

      final response = await _complaintService.createComplaint(
        request,
      );

      if (!response.success) {
        createErrorMessage.value =
            response.message.isNotEmpty
                ? response.message
                : 'Unable to submit your complaint.';

        return false;
      }

      createdComplaint.value = response.data;

      successMessage.value =
          response.message.isNotEmpty
              ? response.message
              : 'Complaint submitted successfully.';

      // Clear the form after successful submission.
      description.value = '';
      selectedIssueType.value =
          ComplaintCreateRequest.billingOrPayment;
      isUrgent.value = false;

      return true;
    } catch (e) {
      createErrorMessage.value =
          _getErrorMessage(e);

      return false;
    } finally {
      isCreating.value = false;
    }
  }

  // ============================================================
  // LOAD COMPLAINTS
  //
  // A monotonically increasing request id guards against
  // stale responses: only the response of the MOST RECENT
  // load may update the list, error state or isLoading.
  // ============================================================

  int _listRequestId = 0;

  Future<void> loadComplaints() async {
    final requestId = ++_listRequestId;

    try {
      isLoading.value = true;
      errorMessage.value = null;

      final request = ComplaintListRequest(
        status: selectedStatus.value,
        page: currentPage.value,
        recordsPerPage: recordsPerPage.value,
        loanId: _currentLoanId,
      );

      final response =
          await _complaintService.getComplaints(
        request,
      );

      // --------------------------------------------
      // A newer request was started while this one
      // was in flight; discard the stale response.
      // --------------------------------------------

      if (requestId != _listRequestId) {
        return;
      }

      if (!response.success) {
        complaints.clear();
        totalComplaints.value = 0;

        // The backend reports "no complaints found" with
        // success:false and an empty list; that is a valid
        // empty-list state, not a technical error.
        if (response.data.isEmpty) {
          errorMessage.value = null;
          return;
        }

        errorMessage.value =
            response.message.isNotEmpty
                ? response.message
                : 'Unable to load your complaints.';

        return;
      }

      complaints.assignAll(response.data);

      currentPage.value = response.page;
      recordsPerPage.value = response.recordsPerPage;
      totalComplaints.value = response.total;
    } catch (e) {
      if (requestId != _listRequestId) {
        return;
      }

      complaints.clear();
      totalComplaints.value = 0;

      errorMessage.value =
          _getErrorMessage(e);
    } finally {
      if (requestId == _listRequestId) {
        isLoading.value = false;
      }
    }
  }

  // ============================================================
  // NEXT PAGE
  // ============================================================

  Future<void> nextPage() async {
    if (isLoading.value) {
      return;
    }

    final totalPages = _totalPages;

    if (currentPage.value >= totalPages) {
      return;
    }

    currentPage.value++;
    await loadComplaints();
  }

  // ============================================================
  // PREVIOUS PAGE
  // ============================================================

  Future<void> previousPage() async {
    if (isLoading.value) {
      return;
    }

    if (currentPage.value <= 1) {
      return;
    }

    currentPage.value--;
    await loadComplaints();
  }

  // ============================================================
  // TOTAL PAGES
  // ============================================================

  int get _totalPages {
    if (totalComplaints.value <= 0 ||
        recordsPerPage.value <= 0) {
      return 1;
    }

    return (totalComplaints.value +
            recordsPerPage.value -
            1) ~/
        recordsPerPage.value;
  }

  // ============================================================
  // PUBLIC PAGINATION GETTERS
  // ============================================================

  bool get hasNextPage {
    return currentPage.value < _totalPages;
  }

  bool get hasPreviousPage {
    return currentPage.value > 1;
  }

  // ============================================================
  // STATUS HELPERS
  // ============================================================

  String get selectedStatusLabel {
    switch (selectedStatus.value) {
      case ComplaintModel.pending:
        return 'Pending';

      case ComplaintModel.approved:
        return 'Approved';

      case ComplaintModel.rejected:
        return 'Rejected';

      default:
        return 'Unknown';
    }
  }

  // ============================================================
  // ISSUE TYPE HELPERS
  // ============================================================

  String get selectedIssueTypeLabel {
    switch (selectedIssueType.value) {
      case ComplaintCreateRequest.billingOrPayment:
        return 'Billing or Payment';

      case ComplaintCreateRequest.documents:
        return 'Documents';

      case ComplaintCreateRequest.serviceQuality:
        return 'Service Quality';

      case ComplaintCreateRequest.vehicleRelated:
        return 'Vehicle Related';

      case ComplaintCreateRequest.technicalAndStaff:
        return 'Technical & Staff';

      case ComplaintCreateRequest.other:
        return 'Other';

      default:
        return 'Unknown';
    }
  }

  // ============================================================
  // CLEAR CREATE STATE
  // ============================================================

  void clearCreateState() {
    createdComplaint.value = null;
    createErrorMessage.value = null;
    successMessage.value = null;
  }

  // ============================================================
  // CLEAR ERROR
  // ============================================================

  void clearError() {
    errorMessage.value = null;
    createErrorMessage.value = null;
  }

  // ============================================================
  // RETRY
  // ============================================================

  Future<void> retry() async {
    await loadComplaints();
  }

  // ============================================================
  // ERROR MESSAGE
  // ============================================================

  String _getErrorMessage(Object error) {
    final message = error.toString().trim();

    if (message.isEmpty) {
      return 'Unable to complete your complaint request.';
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
}