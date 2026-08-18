import 'package:get/get.dart';

class HomeProvider extends GetxController {
  // ------------------------------------------------------------
  // LOAN DATA
  // ------------------------------------------------------------

  final loans = <Map<String, dynamic>>[].obs;

  // ------------------------------------------------------------
  // DASHBOARD SUMMARY
  // ------------------------------------------------------------

  final totalLoans = 0.obs;
  final pendingLoans = 0.obs;
  final completedLoans = 0.obs;
  final loggedInUserName = 'Venkatesh'.obs;

  // Currently selected loan filter.
  //
  // Possible values:
  // Total
  // Pending
  // Completed
  final selectedFilter = 'Total'.obs;

  // ------------------------------------------------------------
  // UI STATE
  // ------------------------------------------------------------

  final isLoading = false.obs;
  final errorMessage = RxnString();

  // ------------------------------------------------------------
  // FILTER
  // ------------------------------------------------------------

  void setLoanFilter(String filter) {
    selectedFilter.value = filter;
  }

  // ------------------------------------------------------------
  // FILTERED LOANS
  // ------------------------------------------------------------

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



  // ------------------------------------------------------------
  // LOAD STATIC DASHBOARD DATA
  // ------------------------------------------------------------

  Future<void> loadDashboard() async {
    try {
      isLoading.value = true;
      errorMessage.value = null;

      // Simulate a small loading delay.
      await Future.delayed(
        const Duration(milliseconds: 600),
      );

      final staticLoans = <Map<String, dynamic>>[
        {
          'vehicleNumber': 'AP 05 AB 1234',
          'borrowerName': 'Ravi Kumar',
          'amount': 250000.0,
          'status': 'Pending',
        },
        {
          'vehicleNumber': 'AP 16 CD 5678',
          'borrowerName': 'Suresh Kumar',
          'amount': 400000.0,
          'status': 'Completed',
        },
        {
          'vehicleNumber': 'AP 39 EF 9876',
          'borrowerName': 'Kumar Rao',
          'amount': 320000.0,
          'status': 'Pending',
        },
        {
          'vehicleNumber': 'AP 40 GH 4567',
          'borrowerName': 'Rajesh Kumar',
          'amount': 500000.0,
          'status': 'Completed',
        },
      ];

      loans.assignAll(staticLoans);

      _calculateSummary();
    } catch (e) {
      errorMessage.value =
          'Unable to load your loan information.';
    } finally {
      isLoading.value = false;
    }
  }

  // ------------------------------------------------------------
  // CALCULATE SUMMARY
  // ------------------------------------------------------------

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

  // ------------------------------------------------------------
  // RETRY
  // ------------------------------------------------------------

  Future<void> retry() async {
    await loadDashboard();
  }

  // ------------------------------------------------------------
  // LIFECYCLE
  // ------------------------------------------------------------

  @override
  void onReady() {
    super.onReady();

    loadDashboard();
  }
}