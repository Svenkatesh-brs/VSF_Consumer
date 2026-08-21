import 'package:get/get.dart';

class LoanDashboardProvider extends GetxController {
  // ------------------------------------------------------------
  // SELECTED LOAN
  // ------------------------------------------------------------

  final selectedLoan = Rxn<Map<String, dynamic>>();

  // ------------------------------------------------------------
  // LOAD SELECTED LOAN
  // ------------------------------------------------------------

  void loadLoanDetails() {
    final arguments = Get.arguments;

    if (arguments is Map<String, dynamic>) {
      selectedLoan.value = arguments;
    }
  }

  // ------------------------------------------------------------
  // CONVENIENCE GETTERS
  // ------------------------------------------------------------

  String get vehicleNumber =>
      selectedLoan.value?['vehicleNumber']?.toString() ?? '';

  String get borrowerName =>
      selectedLoan.value?['borrowerName']?.toString() ?? '';

  String get status => selectedLoan.value?['status']?.toString() ?? '';

  double get amount {
    final value = selectedLoan.value?['amount'];

    if (value is num) {
      return value.toDouble();
    }

    return 0;
  }

  String get guarantorName => 'Srinivas Rao';

  String get guarantorRelation => 'Guarantor';

  String get guarantorMobile => '+91 98765 43210';

  // ------------------------------------------------------------
  // LIFECYCLE
  // ------------------------------------------------------------

  @override
  void onReady() {
    super.onReady();

    loadLoanDetails();
  }
}
