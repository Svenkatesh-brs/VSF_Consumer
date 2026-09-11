import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../models/contact_update_model.dart';
import '../providers/contact_update_provider.dart';
import '../providers/loan_dashboard_provider.dart';
import '../utils/app_colors.dart';
import '../widgets/app_background.dart';
import '../widgets/app_form_card.dart';
import '../widgets/app_submit_button.dart';
import '../widgets/common/app_text_field.dart';
import '../widgets/common/screen_content_exit.dart';
import '../widgets/common/screen_transition.dart';

// ============================================================
// CONTACT UPDATE SCREEN
//
// Two tabs:
//   1. Phone Number -> OTP-based approval workflow. OTP is sent
//                      to the CURRENT number first (verified via
//                      /consumer/otp/verify, returned token
//                      ignored), then to the NEW number (verified
//                      via /consumer/phone/otp/verify, which
//                      creates the backend update request). The
//                      saved phone is never changed locally. The
//                      legacy PATCH .../me/phone API is no longer
//                      used.
//   2. Address      -> PUT   /api/v1/consumer/customer/address/:id
//
// All data comes from the live providers:
//   - Current address: LoanDashboardProvider
//     (loanDetails.value?.borrower?.address — already fetched
//     by the Loan Dashboard response; never refetched here)
//   - Current phone: LoanDashboardProvider
//     (loanDetails.value?.borrower?.phone — read-only)
//   - Updates: ContactUpdateProvider (id / cid supplied there)
//
// The screen performs no direct API calls.
// ============================================================

class ContactUpdateScreen extends StatefulWidget {
  const ContactUpdateScreen({super.key});

  @override
  State<ContactUpdateScreen> createState() =>
      _ContactUpdateScreenState();
}

class _ContactUpdateScreenState
    extends State<ContactUpdateScreen>
    with SingleTickerProviderStateMixin {
  late final ContactUpdateProvider contactController;

  late final LoanDashboardProvider loanController;

  late final TabController _tabController;

  late final TextEditingController _phoneController;

  late final TextEditingController _otpController;

  // ------------------------------------------------------------
  // EDITABLE ADDRESS FIELDS
  // ------------------------------------------------------------

  late final TextEditingController _addressLine1Controller;
  late final TextEditingController _addressLine2Controller;
  late final TextEditingController _landmarkController;
  late final TextEditingController _pincodeController;
  late final TextEditingController _stateController;
  late final TextEditingController _cityController;
  late final TextEditingController _countryController;
  late final TextEditingController _districtController;
  late final TextEditingController _villageController;
  late final TextEditingController _houseNumberController;
  late final TextEditingController _floorNumberController;
  late final TextEditingController _streetNameController;
  late final TextEditingController _apartmentNameController;
  late final TextEditingController _buildingNameController;
  late final TextEditingController _addressTypeController;

  bool _isExiting = false;

  bool _addressSuccessHandled = false;

  bool _phoneSuccessHandled = false;

  @override
  void initState() {
    super.initState();

    // ----------------------------------------------------------
    // Reuses the live providers registered by the bindings.
    // No additional API call is made here; the address was
    // fetched once by the Loan Dashboard route.
    // ----------------------------------------------------------

    contactController =
        Get.find<ContactUpdateProvider>();

    loanController = Get.find<LoanDashboardProvider>();

    _tabController = TabController(
      length: 2,
      vsync: this,
    );

    _phoneController = TextEditingController();

    _otpController = TextEditingController();

    _prefillAddressFields();
  }

  void _prefillAddressFields() {
    final initial =
        contactController.initialAddressRequest;

    _addressLine1Controller = TextEditingController(
      text: initial?.addressLine1 ?? '',
    );

    _addressLine2Controller = TextEditingController(
      text: initial?.addressLine2 ?? '',
    );

    _landmarkController = TextEditingController(
      text: initial?.landmark ?? '',
    );

    _pincodeController = TextEditingController(
      text: initial?.pincode ?? '',
    );

    _stateController = TextEditingController(
      text: initial?.state ?? '',
    );

    _cityController = TextEditingController(
      text: initial?.city ?? '',
    );

    _countryController = TextEditingController(
      text: initial?.country ?? '',
    );

    _districtController = TextEditingController(
      text: initial?.district ?? '',
    );

    _villageController = TextEditingController(
      text: initial?.village ?? '',
    );

    _houseNumberController = TextEditingController(
      text: initial?.houseNumber ?? '',
    );

    _floorNumberController = TextEditingController(
      text: initial?.floorNumber ?? '',
    );

    _streetNameController = TextEditingController(
      text: initial?.streetName ?? '',
    );

    _apartmentNameController = TextEditingController(
      text: initial?.apartmentName ?? '',
    );

    _buildingNameController = TextEditingController(
      text: initial?.buildingName ?? '',
    );

    _addressTypeController = TextEditingController(
      text: initial?.addressType ?? '',
    );
  }

  void _clearAddressFields() {
    _houseNumberController.clear();
    _floorNumberController.clear();
    _buildingNameController.clear();
    _apartmentNameController.clear();
    _streetNameController.clear();
    _addressLine1Controller.clear();
    _addressLine2Controller.clear();
    _landmarkController.clear();
    _villageController.clear();
    _districtController.clear();
    _cityController.clear();
    _stateController.clear();
    _countryController.clear();
    _pincodeController.clear();
    _addressTypeController.clear();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _phoneController.dispose();
    _otpController.dispose();
    _addressLine1Controller.dispose();
    _addressLine2Controller.dispose();
    _landmarkController.dispose();
    _pincodeController.dispose();
    _stateController.dispose();
    _cityController.dispose();
    _countryController.dispose();
    _districtController.dispose();
    _villageController.dispose();
    _houseNumberController.dispose();
    _floorNumberController.dispose();
    _streetNameController.dispose();
    _apartmentNameController.dispose();
    _buildingNameController.dispose();
    _addressTypeController.dispose();
    super.dispose();
  }

  // ============================================================
  // BACK NAVIGATION
  //
  // Same behaviour as the Loan Details screen: play the exit
  // transition first, then pop.
  // ============================================================

  Future<void> _goBack() async {
    if (_isExiting) {
      return;
    }

    FocusManager.instance.primaryFocus?.unfocus();

    setState(() {
      _isExiting = true;
    });

    await Future.delayed(
      const Duration(milliseconds: 400),
    );

    if (!mounted) {
      return;
    }

    Get.back();
  }

  // ============================================================
  // PHONE TAB — SUBMIT OTP TO CURRENT NUMBER
  //
  // Step 1 -> Step 2. Sends the OTP to the CURRENT/OLD phone.
  // Does not call the legacy PATCH phone API.
  // ============================================================

  Future<void> _submitPhone() async {
    FocusScope.of(context).unfocus();

    final success =
        await contactController.beginPhoneUpdate(
      _phoneController.text,
    );

    if (!mounted || !success) {
      return;
    }

    setState(() {
      _otpController.clear();
    });
  }

  // ============================================================
  // PHONE TAB — VERIFY OTP
  //
  // Dispatches to the current step:
  //   Step 2 (verify current phone) -> step 3 on success
  //   Step 3 (verify new phone)     -> approval popup on success
  // ============================================================

  Future<void> _submitOtp() async {
    FocusScope.of(context).unfocus();

    final step = contactController.phoneUpdateStep.value;

    if (step == PhoneUpdateStep.verifyCurrentPhone) {
      final success =
          await contactController.verifyCurrentPhoneOtp(
        _otpController.text,
      );

      if (!mounted || !success) {
        return;
      }

      setState(() {
        _otpController.clear();
      });
      return;
    }

    if (step == PhoneUpdateStep.verifyNewPhone) {
      final success =
          await contactController.verifyNewPhoneOtp(
        _otpController.text,
      );

      if (!mounted || !success) {
        return;
      }

      _phoneSuccessHandled = true;

      _showPhoneSuccessPopup();

      if (!mounted) {
        return;
      }

      contactController.resetPhoneUpdate();

      _resetPhoneUpdateFields();
    }
  }

  // ============================================================
  // PHONE TAB — RESEND OTP
  //
  // Current-phone OTP resends through /consumer/otp/request;
  // new-phone OTP resends through /consumer/phone/otp/request.
  // ============================================================

  Future<void> _resendPhoneOtp() async {
    if (_isExiting ||
        contactController.isLoading.value) {
      return;
    }

    FocusManager.instance.primaryFocus?.unfocus();

    final step = contactController.phoneUpdateStep.value;

    final success = step == PhoneUpdateStep.verifyCurrentPhone
        ? await contactController.resendCurrentPhoneOtp()
        : await contactController.resendNewPhoneOtp();

    if (!mounted || !success) {
      return;
    }

    setState(() {
      _otpController.clear();
    });
  }

  // ============================================================
  // PHONE TAB — RESET INPUT
  //
  // Clears only the NEW-number/OTP fields after the request has
  // been submitted. The current saved phone is never modified.
  // ============================================================

  void _resetPhoneUpdateFields() {
    _phoneController.clear();
    _otpController.clear();
  }

  // ============================================================
  // SUBMIT ADDRESS
  //
  // Builds the request from the edited fields; cid and the URL
  // id come from the provider's saved LoanAddress.
  // ============================================================

  Future<void> _submitAddress() async {
    FocusScope.of(context).unfocus();

    final initial =
        contactController.initialAddressRequest;

    if (initial == null) {
      return;
    }

    final request = AddressUpdateRequest(
      cid: initial.cid,
      addressLine1: _addressLine1Controller.text.trim(),
      addressLine2: _addressLine2Controller.text.trim(),
      landmark: _landmarkController.text.trim(),
      pincode: _pincodeController.text.trim(),
      state: _stateController.text.trim(),
      city: _cityController.text.trim(),
      country: _countryController.text.trim(),
      district: _districtController.text.trim(),
      village: _villageController.text.trim(),
      houseNumber: _houseNumberController.text.trim(),
      floorNumber: _floorNumberController.text.trim(),
      streetName: _streetNameController.text.trim(),
      apartmentName:
          _apartmentNameController.text.trim(),
      buildingName:
          _buildingNameController.text.trim(),
      addressType: _addressTypeController.text.trim(),
    );

    final success =
        await contactController.updateAddress(request);

    if (!mounted || !success) {
      return;
    }

    _addressSuccessHandled = true;
    _clearAddressFields();
    _showAddressSuccessPopup();
  }

  // ============================================================
  // MESSAGES
  //
  // Backend success/error surfaces through snackbars, mirroring
  // the Complaints screen pattern.
  // ============================================================

  void _showSnackbar(String message, bool isError) {
    if (message.trim().isEmpty) {
      return;
    }

    Get.snackbar(
      isError ? 'Contact Update' : 'Contact Updated',
      message,
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(16),
      borderRadius: 14,
      backgroundColor: Colors.white,
      colorText: isError
          ? AppColors.error
          : Colors.black87,
    );
  }

  // ============================================================
  // ADDRESS SUCCESS POPUP
  //
  // Animated dialog shown after a successful address update
  // request. Uses TweenAnimationBuilder for the card entrance
  // and the check icon bounce — no extra packages needed.
  // ============================================================

  void _showAddressSuccessPopup() {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.35),
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 36,
          ),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(
              milliseconds: 400,
            ),
            curve: Curves.easeOutBack,
            builder: (context, animValue, child) {
              return Transform.scale(
                scale: animValue,
                child: child,
              );
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(
                24, 28, 24, 22,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.circular(22),
                border: Border.all(
                  color: AppColors.lightBlue
                      .withValues(alpha: 0.12),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.lightBlue
                        .withValues(alpha: 0.10),
                    blurRadius: 30,
                    offset: const Offset(0, 8),
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(
                      alpha: 0.05,
                    ),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween(
                      begin: 0.0,
                      end: 1.0,
                    ),
                    duration: const Duration(
                      milliseconds: 600,
                    ),
                    curve: Curves.elasticOut,
                    builder:
                        (
                          context,
                          iconValue,
                          child,
                        ) {
                          return Transform.scale(
                            scale: iconValue,
                            child: child,
                          );
                        },
                    child: Container(
                      width: 62,
                      height: 62,
                      decoration: BoxDecoration(
                        color: AppColors.lightBlue
                            .withValues(alpha: 0.10),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        size: 30,
                        color:
                            AppColors.lightBlue,
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  const Text(
                    'Address Request Sent',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppColors.lightBlue,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Text(
                    'Your address update request has been sent to our Customer Support team.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.5,
                      color: Colors.black
                          .withValues(alpha: 0.60),
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    'Your new address will be reflected in the app once your request is reviewed and approved.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12.5,
                      height: 1.5,
                      color: Colors.black
                          .withValues(alpha: 0.45),
                    ),
                  ),

                  const SizedBox(height: 22),

                  GestureDetector(
                    onTap: () =>
                        Navigator.of(dialogContext)
                            .pop(),
                    child: Container(
                      width: double.infinity,
                      padding:
                          const EdgeInsets.symmetric(
                            vertical: 13,
                          ),
                      decoration: BoxDecoration(
                        color:
                            AppColors.lightBlue,
                        borderRadius:
                            BorderRadius.circular(
                              14,
                            ),
                      ),
                      child: const Text(
                        'Got it',
                        textAlign:
                            TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight:
                              FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // PHONE SUCCESS POPUP
  //
  // Shown after the NEW phone OTP is verified and the backend has
  // created the phone update request. Same animation, styling,
  // typography and spacing as the Address Request Sent popup.
  // ============================================================

  void _showPhoneSuccessPopup() {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.35),
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 36,
          ),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(
              milliseconds: 400,
            ),
            curve: Curves.easeOutBack,
            builder: (context, animValue, child) {
              return Transform.scale(
                scale: animValue,
                child: child,
              );
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(
                24, 28, 24, 22,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.circular(22),
                border: Border.all(
                  color: AppColors.lightBlue
                      .withValues(alpha: 0.12),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.lightBlue
                        .withValues(alpha: 0.10),
                    blurRadius: 30,
                    offset: const Offset(0, 8),
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(
                      alpha: 0.05,
                    ),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween(
                      begin: 0.0,
                      end: 1.0,
                    ),
                    duration: const Duration(
                      milliseconds: 600,
                    ),
                    curve: Curves.elasticOut,
                    builder:
                        (
                          context,
                          iconValue,
                          child,
                        ) {
                          return Transform.scale(
                            scale: iconValue,
                            child: child,
                          );
                        },
                    child: Container(
                      width: 62,
                      height: 62,
                      decoration: BoxDecoration(
                        color: AppColors.lightBlue
                            .withValues(alpha: 0.10),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.phone_android_rounded,
                        size: 30,
                        color:
                            AppColors.lightBlue,
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  const Text(
                    'Phone Update Request Sent',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppColors.lightBlue,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Text(
                    'Your phone number update request has been sent to our Customer Support team.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.5,
                      color: Colors.black
                          .withValues(alpha: 0.60),
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    'Your new phone number will be reflected in the app once your request is reviewed and approved.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12.5,
                      height: 1.5,
                      color: Colors.black
                          .withValues(alpha: 0.45),
                    ),
                  ),

                  const SizedBox(height: 22),

                  GestureDetector(
                    onTap: () =>
                        Navigator.of(dialogContext)
                            .pop(),
                    child: Container(
                      width: double.infinity,
                      padding:
                          const EdgeInsets.symmetric(
                            vertical: 13,
                          ),
                      decoration: BoxDecoration(
                        color:
                            AppColors.lightBlue,
                        borderRadius:
                            BorderRadius.circular(
                              14,
                            ),
                      ),
                      child: const Text(
                        'Got it',
                        textAlign:
                            TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight:
                              FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: AppBackground(
        child: SafeArea(
          child: ScreenContentExit(
            isExiting: _isExiting,
            direction: ContentExitDirection.toRight,
            child: ScreenContentTransition(
              direction:
                  ContentTransitionDirection.fromLeft,
              child: Column(
                children: [
                  _buildHeader(),

                  _buildTabs(),

                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildPhoneTab(),

                        _buildAddressTab(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        16,
        12,
        20,
        12,
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: _goBack,
            icon: const Icon(
              Icons.arrow_back_rounded,
            ),
            color: AppColors.lightBlue,
          ),

          const SizedBox(width: 4),

          const Expanded(
            child: Text(
              'Contact Update',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.lightBlue,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // TABS
  // ============================================================

  Widget _buildTabs() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        16,
        4,
        16,
        12,
      ),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white.withValues(
            alpha: 0.58,
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: Colors.black.withValues(
              alpha: 0.06,
            ),
          ),
        ),
        child: TabBar(
          controller: _tabController,
          dividerColor: Colors.transparent,
          indicatorSize: TabBarIndicatorSize.tab,
          indicator: BoxDecoration(
            color: Colors.white.withValues(
              alpha: 0.92,
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(
                  alpha: 0.06,
                ),
                blurRadius: 8,
              ),
            ],
          ),
          labelColor: AppColors.lightBlue,
          unselectedLabelColor: Colors.black45,
          labelStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
          tabs: const [
            Tab(
              height: 42,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisAlignment:
                      MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.phone_outlined,
                      size: 17,
                    ),
                    SizedBox(width: 7),
                    Text('Phone Number'),
                  ],
                ),
              ),
            ),
            Tab(
              height: 42,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisAlignment:
                      MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.home_outlined,
                      size: 17,
                    ),
                    SizedBox(width: 7),
                    Text('Address'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // PHONE TAB
  // ============================================================

  Widget _buildPhoneTab() {
    return Obx(() {
      _consumeMessages();

      final isSaving =
          contactController.isLoading.value;

      final step =
          contactController.phoneUpdateStep.value;

      final currentPhone = loanController
              .loanDetails.value?.borrower?.phone ??
          '';

      return RefreshIndicator(
        onRefresh: loanController.retry,
        color: AppColors.lightBlue,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: const EdgeInsets.fromLTRB(
            20,
            8,
            20,
            28,
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              _buildCurrentContactCard(
                icon: Icons.phone_outlined,
                title: 'Registered Phone',
                rows: [
                  _buildInfoRow(
                    label: 'Current Number',
                    value: currentPhone,
                  ),
                ],
              ),

              const SizedBox(height: 16),

              if (step == PhoneUpdateStep.enterNewPhone)
                _buildNewPhoneForm(isSaving)
              else if (step ==
                  PhoneUpdateStep.verifyCurrentPhone)
                _buildCurrentPhoneOtpCard(isSaving)
              else
                _buildNewPhoneOtpCard(isSaving),
            ],
          ),
        ),
      );
    });
  }

  // ============================================================
  // PHONE TAB — STEP 1: NEW NUMBER FORM
  // ============================================================

  Widget _buildNewPhoneForm(bool isSaving) {
    return AppFormCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(
            icon: Icons.edit_outlined,
            title: 'New Phone Number',
          ),

          const SizedBox(height: 20),

          AppTextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.done,
            labelText: 'Phone Number',
            hintText: '10-digit mobile number',
            prefixIcon: const Icon(
              Icons.phone_outlined,
            ),
          ),

          const SizedBox(height: 24),

          AppSubmitButton(
            label: 'Update Phone',
            isLoading: isSaving,
            onTap: _submitPhone,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PHONE TAB — STEP 2: CURRENT-PHONE OTP
  // ============================================================

  Widget _buildCurrentPhoneOtpCard(bool isSaving) {
    return AppFormCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(
            icon: Icons.verified_user_outlined,
            title: 'Verify Current Number',
          ),

          const SizedBox(height: 12),

          Text(
            'Enter the OTP sent to your current mobile number.',
            style: TextStyle(
              fontSize: 13,
              height: 1.5,
              color: Colors.black
                  .withValues(alpha: 0.60),
            ),
          ),

          const SizedBox(height: 16),

          _buildOtpField(),

          const SizedBox(height: 24),

          AppSubmitButton(
            label: 'Verify OTP',
            isLoading: isSaving,
            onTap: _submitOtp,
          ),

          const SizedBox(height: 12),

          _buildResendOtpRow(),
        ],
      ),
    );
  }

  // ============================================================
  // PHONE TAB — STEP 3: NEW-PHONE OTP
  // ============================================================

  Widget _buildNewPhoneOtpCard(bool isSaving) {
    return AppFormCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(
            icon: Icons.phone_iphone,
            title: 'Verify New Number',
          ),

          const SizedBox(height: 12),

          Text(
            'Enter the OTP sent to your new mobile number.',
            style: TextStyle(
              fontSize: 13,
              height: 1.5,
              color: Colors.black
                  .withValues(alpha: 0.60),
            ),
          ),

          const SizedBox(height: 16),

          _buildOtpField(),

          const SizedBox(height: 24),

          AppSubmitButton(
            label: 'Verify OTP',
            isLoading: isSaving,
            onTap: _submitOtp,
          ),

          const SizedBox(height: 12),

          _buildResendOtpRow(),
        ],
      ),
    );
  }

  // ============================================================
  // PHONE TAB — OTP INPUT
  // ============================================================

  Widget _buildOtpField() {
    return AppTextField(
      controller: _otpController,
      keyboardType: TextInputType.number,
      textInputAction: TextInputAction.done,
      labelText: 'OTP',
      hintText: 'Enter 6-digit OTP',
      prefixIcon: const Icon(
        Icons.verified_outlined,
      ),
    );
  }

  // ============================================================
  // PHONE TAB — RESEND ROW
  // ============================================================

  Widget _buildResendOtpRow() {
    return Obx(() {
      final countdown =
          contactController.otpCountdown.value;

      final canResend =
          contactController.canResendOtp.value;

      return Center(
        child: canResend
            ? TextButton(
                onPressed: _resendPhoneOtp,
                child: const Text('Resend OTP'),
              )
            : Text(
                'Resend OTP in ${countdown}s',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                ),
              ),
      );
    });
  }

  // ============================================================
  // ADDRESS TAB
  // ============================================================

  Widget _buildAddressTab() {
    return Obx(() {
      _consumeMessages();

      final isSaving =
          contactController.isLoading.value;

      return RefreshIndicator(
        onRefresh: loanController.retry,
        color: AppColors.lightBlue,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: const EdgeInsets.fromLTRB(
            20,
            8,
            20,
            28,
          ),
          child: contactController.hasAddress
            ? Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  _buildSavedAddressCard(),

                  const SizedBox(height: 16),

                  _buildAddressForm(isSaving),
                ],
              )
            : _buildNoAddressCard(),
      ),
    );
    });
  }

  // ============================================================
  // SAVED ADDRESS CARD
  //
  // Read-only view over the address already parsed from the
  // Loan Dashboard response.
  // ============================================================

  Widget _buildSavedAddressCard() {
    final address =
        contactController.currentAddress;

    return _buildCurrentContactCard(
      icon: Icons.home_outlined,
      title: 'Current Saved Address',
      rows: [
        _buildInfoRow(
          label: 'House Number',
          value: address?.houseNumber ?? '',
        ),
        _buildInfoRow(
          label: 'Floor Number',
          value: address?.floorNumber ?? '',
        ),
        _buildInfoRow(
          label: 'Building Name',
          value: address?.buildingName ?? '',
        ),
        _buildInfoRow(
          label: 'Apartment Name',
          value: address?.apartmentName ?? '',
        ),
        _buildInfoRow(
          label: 'Street Name',
          value: address?.streetName ?? '',
        ),
        _buildInfoRow(
          label: 'Address Line 1',
          value: address?.addressLine1 ?? '',
        ),
        _buildInfoRow(
          label: 'Address Line 2',
          value: address?.addressLine2 ?? '',
        ),
        _buildInfoRow(
          label: 'Landmark',
          value: address?.landmark ?? '',
        ),
        _buildInfoRow(
          label: 'Village',
          value: address?.village ?? '',
        ),
        _buildInfoRow(
          label: 'District',
          value: address?.district ?? '',
        ),
        _buildInfoRow(
          label: 'City',
          value: address?.city ?? '',
        ),
        _buildInfoRow(
          label: 'State',
          value: address?.state ?? '',
        ),
        _buildInfoRow(
          label: 'Country',
          value: address?.country ?? '',
        ),
        _buildInfoRow(
          label: 'Pincode',
          value: address?.pincode ?? '',
        ),
        _buildInfoRow(
          label: 'Address Type',
          value: address?.addressType ?? '',
        ),
      ],
    );
  }

  // ============================================================
  // ADDRESS EDIT FORM
  // ============================================================

  Widget _buildAddressForm(bool isSaving) {
    return AppFormCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(
            icon: Icons.edit_location_alt_outlined,
            title: 'Edit Address',
          ),

          const SizedBox(height: 20),

          AppTextField(
            controller: _houseNumberController,
            labelText: 'House Number',
          ),

          const SizedBox(height: 14),

          AppTextField(
            controller: _floorNumberController,
            labelText: 'Floor Number',
          ),

          const SizedBox(height: 14),

          AppTextField(
            controller: _buildingNameController,
            labelText: 'Building Name',
          ),

          const SizedBox(height: 14),

          AppTextField(
            controller: _apartmentNameController,
            labelText: 'Apartment Name',
          ),

          const SizedBox(height: 14),

          AppTextField(
            controller: _streetNameController,
            labelText: 'Street Name',
          ),

          const SizedBox(height: 14),

          AppTextField(
            controller: _addressLine1Controller,
            labelText: 'Address Line 1',
          ),

          const SizedBox(height: 14),

          AppTextField(
            controller: _addressLine2Controller,
            labelText: 'Address Line 2',
          ),

          const SizedBox(height: 14),

          AppTextField(
            controller: _landmarkController,
            labelText: 'Landmark',
          ),

          const SizedBox(height: 14),

          AppTextField(
            controller: _villageController,
            labelText: 'Village',
          ),

          const SizedBox(height: 14),

          AppTextField(
            controller: _districtController,
            labelText: 'District',
          ),

          const SizedBox(height: 14),

          AppTextField(
            controller: _cityController,
            labelText: 'City',
          ),

          const SizedBox(height: 14),

          AppTextField(
            controller: _stateController,
            labelText: 'State',
          ),

          const SizedBox(height: 14),

          AppTextField(
            controller: _countryController,
            labelText: 'Country',
          ),

          const SizedBox(height: 14),

          AppTextField(
            controller: _pincodeController,
            keyboardType: TextInputType.number,
            labelText: 'Pincode',
          ),

          const SizedBox(height: 14),

          AppTextField(
            controller: _addressTypeController,
            labelText: 'Address Type',
          ),

          const SizedBox(height: 24),

          AppSubmitButton(
            label: 'Update Address',
            isLoading: isSaving,
            onTap: _submitAddress,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // NO ADDRESS FALLBACK
  // ============================================================

  Widget _buildNoAddressCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.80),
            Colors.white.withValues(alpha: 0.48),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.60),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 20,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: AppColors.lightBlue
                  .withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.location_off_outlined,
              size: 26,
              color: AppColors.lightBlue,
            ),
          ),

          const SizedBox(height: 14),

          const Text(
            'No Saved Address',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.lightBlue,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            'We could not find an address on this loan. Please contact support to update your address.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              height: 1.45,
              color: Colors.black.withValues(
                alpha: 0.55,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SHARED CARD (CURRENT VALUES)
  // ============================================================

  Widget _buildCurrentContactCard({
    required IconData icon,
    required String title,
    required List<Widget> rows,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.82),
            Colors.white.withValues(alpha: 0.48),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.60),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 20,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(
            icon: icon,
            title: title,
          ),

          const SizedBox(height: 16),

          ...rows,
        ],
      ),
    );
  }

  // ============================================================
  // SECTION TITLE
  // ============================================================

  Widget _buildSectionTitle({
    required IconData icon,
    required String title,
  }) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppColors.lightBlue.withValues(
              alpha: 0.10,
            ),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 20,
            color: AppColors.lightBlue,
          ),
        ),

        const SizedBox(width: 10),

        Flexible(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.lightBlue,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // INFO ROW (read-only label/value pair)
  // ============================================================

  Widget _buildInfoRow({
    required String label,
    required String value,
  }) {
    final displayValue =
        value.trim().isEmpty ? '-' : value.trim();

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Colors.black45,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 6,
            child: Text(
              displayValue,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: AppColors.lightBlue,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // MESSAGE CONSUMER
  //
  // Shows provider-set backend success/error messages exactly
  // once, then clears them (same post-frame pattern used by the
  // Complaints screen).
  // ============================================================

  void _consumeMessages() {
    final error =
        contactController.errorMessage.value;

    if (error != null && error.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) {
          if (!mounted) {
            return;
          }

          contactController.errorMessage.value = null;

          _showSnackbar(error, true);
        },
      );
    }

    final success =
        contactController.successMessage.value;

    if (success != null && success.isNotEmpty) {
      if (_addressSuccessHandled) {
        _addressSuccessHandled = false;
        contactController.successMessage.value = null;
        return;
      }

      if (_phoneSuccessHandled) {
        _phoneSuccessHandled = false;
        contactController.successMessage.value = null;
        return;
      }

      WidgetsBinding.instance.addPostFrameCallback(
        (_) {
          if (!mounted) {
            return;
          }

          contactController.successMessage.value =
              null;

          _showSnackbar(success, false);
        },
      );
    }
  }
}
