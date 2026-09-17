import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../routes/app_routes.dart';
import '../utils/app_colors.dart';
import '../widgets/app_background.dart';

class LanguageSelectionScreen extends StatefulWidget {
  const LanguageSelectionScreen({super.key});

  @override
  State<LanguageSelectionScreen> createState() =>
      _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends State<LanguageSelectionScreen>
    with SingleTickerProviderStateMixin {
  static const _languages = [
    _LanguageOption(
      code: 'en',
      name: 'English',
      nativeName: 'English',
      subtitle: 'Continue in English',
      icon: Icons.language_rounded,
      color: AppColors.lightBlue,
    ),
    _LanguageOption(
      code: 'te',
      name: 'Telugu',
      nativeName: '\u0c24\u0c46\u0c32\u0c41\u0c17\u0c41',
      subtitle: '\u0c24\u0c46\u0c32\u0c41\u0c17\u0c41\u0c32\u0c4b \u0c15\u0c4a\u0c28\u0c38\u0c3e\u0c17\u0c3f\u0c02\u0c1a\u0c02\u0c21\u0c3f',
      icon: Icons.auto_awesome_rounded,
      color: AppColors.buttonEnd,
    ),
    _LanguageOption(
      code: 'hi',
      name: 'Hindi',
      nativeName: '\u0939\u093f\u0928\u094d\u0926\u0940',
      subtitle: '\u0939\u093f\u0928\u094d\u0926\u0940 \u092e\u0947\u0902 \u091c\u093e\u0930\u0940 \u0930\u0916\u0947\u0902',
      icon: Icons.translate_rounded,
      color: AppColors.secondary,
    ),
  ];

  late final AnimationController _entranceController;
  String _selectedCode = 'en';
  bool _isContinuing = false;

  _LanguageOption get _selectedLanguage =>
      _languages.firstWhere((language) => language.code == _selectedCode);

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1050),
    )..forward();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    if (_isContinuing) {
      return;
    }

    setState(() {
      _isContinuing = true;
    });

    await Future<void>.delayed(const Duration(milliseconds: 360));

    if (!mounted) {
      return;
    }

    Get.offNamed(
      AppRoutes.home,
      arguments: {'language': _selectedLanguage.code},
    );
  }

  Animation<double> _interval(double begin, double end) {
    return CurvedAnimation(
      parent: _entranceController,
      curve: Interval(begin, end, curve: Curves.easeOutCubic),
    );
  }

  Widget _reveal({
    required Widget child,
    required double begin,
    required double end,
    Offset offset = const Offset(0, 0.12),
  }) {
    final animation = _interval(begin, end);

    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(begin: offset, end: Offset.zero).animate(animation),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        showWatermark: true,
        showBottomImage: true,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(22, 24, 22, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _reveal(
                  begin: 0.0,
                  end: 0.38,
                  offset: const Offset(0, -0.12),
                  child: _buildBrandMark(),
                ),
                const SizedBox(height: 26),
                _reveal(
                  begin: 0.12,
                  end: 0.5,
                  child: _buildHeading(),
                ),
                const SizedBox(height: 26),
                ..._languages.asMap().entries.map(
                      (entry) => Padding(
                        padding: EdgeInsets.only(
                          bottom: entry.key == _languages.length - 1 ? 0 : 12,
                        ),
                        child: _reveal(
                          begin: 0.28 + (entry.key * 0.09),
                          end: 0.65 + (entry.key * 0.09),
                          child: _buildLanguageTile(entry.value),
                        ),
                      ),
                    ),
                const SizedBox(height: 30),
                _reveal(
                  begin: 0.62,
                  end: 0.96,
                  child: _buildContinueButton(),
                ),
                const SizedBox(height: 15),
                _reveal(
                  begin: 0.72,
                  end: 1.0,
                  child: const Text(
                    'You can change this later from your profile.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.black45,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBrandMark() {
    return Center(
      child: Container(
        width: 86,
        height: 86,
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.88),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.lightBlue.withValues(alpha: 0.16),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipOval(
          child: Image.asset(
            'assets/vsf.png',
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }

  Widget _buildHeading() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(30),
          ),
          child: const Text(
            'LANGUAGE PREFERENCE',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
              color: AppColors.lightBlue,
            ),
          ),
        ),
        const SizedBox(height: 15),
        const Text(
          'Make VSF yours',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: AppColors.lightBlue,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          'Choose the language you are most comfortable with.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            height: 1.45,
            color: Colors.black.withValues(alpha: 0.55),
          ),
        ),
      ],
    );
  }

  Widget _buildLanguageTile(_LanguageOption language) {
    final isSelected = _selectedCode == language.code;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: isSelected
            ? language.color.withValues(alpha: 0.10)
            : Colors.white.withValues(alpha: 0.66),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected
              ? language.color.withValues(alpha: 0.7)
              : Colors.white.withValues(alpha: 0.78),
          width: isSelected ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isSelected
                ? language.color.withValues(alpha: 0.14)
                : Colors.black.withValues(alpha: 0.035),
            blurRadius: isSelected ? 20 : 12,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: () {
          setState(() {
            _selectedCode = language.code;
          });
        },
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 240),
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: language.color.withValues(
                  alpha: isSelected ? 0.18 : 0.09,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                language.icon,
                color: language.color,
                size: 23,
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    language.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.lightBlue,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    language.subtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  language.nativeName,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: language.color,
                  ),
                ),
                const SizedBox(height: 6),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 240),
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: isSelected ? language.color : Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? language.color
                          : Colors.black.withValues(alpha: 0.18),
                      width: 1.5,
                    ),
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    child: isSelected
                        ? const Icon(
                            Icons.check_rounded,
                            key: ValueKey('selected'),
                            size: 14,
                            color: Colors.white,
                          )
                        : const SizedBox(key: ValueKey('unselected')),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContinueButton() {
    return SizedBox(
      height: 56,
      child: ElevatedButton(
        onPressed: _isContinuing ? null : _continue,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.buttonEnd,
          disabledBackgroundColor: AppColors.buttonEnd.withValues(alpha: 0.7),
          foregroundColor: Colors.white,
          elevation: 8,
          shadowColor: AppColors.buttonEnd.withValues(alpha: 0.28),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(17),
          ),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: _isContinuing
              ? const SizedBox(
                  key: ValueKey('loading'),
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.3,
                    color: Colors.white,
                  ),
                )
              : const Row(
                  key: ValueKey('continue'),
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Continue',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(width: 9),
                    Icon(Icons.arrow_forward_rounded, size: 20),
                  ],
                ),
        ),
      ),
    );
  }
}

class _LanguageOption {
  const _LanguageOption({
    required this.code,
    required this.name,
    required this.nativeName,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  final String code;
  final String name;
  final String nativeName;
  final String subtitle;
  final IconData icon;
  final Color color;
}
