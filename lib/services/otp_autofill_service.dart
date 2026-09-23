import 'dart:async';

import 'package:sms_autofill/sms_autofill.dart';

/// Narrow wrapper around the process-wide SMS Retriever plugin.
///
/// A Retriever receiver belongs to the Android activity, not an OTP widget.
/// Serialising arm/disarm calls prevents a late native setup from one login
/// session from replacing the receiver for a newer session.
abstract class OtpAutofillService {
  Stream<String> get codes;

  Future<void> arm();

  Future<void> disarm();

  Future<void> dispose();
}

abstract class SmsRetrieverPlatform {
  Stream<String> get codes;

  Future<void> listenForCode(String pattern);

  Future<void> unregisterListener();
}

class SmsAutofillPlatform implements SmsRetrieverPlatform {
  final SmsAutoFill _smsAutoFill;

  SmsAutofillPlatform({SmsAutoFill? smsAutoFill})
      : _smsAutoFill = smsAutoFill ?? SmsAutoFill();

  @override
  Stream<String> get codes => _smsAutoFill.code;

  @override
  Future<void> listenForCode(String pattern) =>
      _smsAutoFill.listenForCode(smsCodeRegexPattern: pattern);

  @override
  Future<void> unregisterListener() => _smsAutoFill.unregisterListener();
}

class SmsRetrieverOtpAutofillService implements OtpAutofillService {
  // Do not accept a six-digit substring from a longer number.
  static const _codePattern = r'(?<!\d)\d{6}(?!\d)';
  static final _sixDigits = RegExp(r'^\d{6}$');

  final SmsRetrieverPlatform _platform;
  final StreamController<String> _codes = StreamController.broadcast();

  StreamSubscription<String>? _platformSubscription;
  Future<void> _operation = Future<void>.value();
  bool _disposed = false;

  SmsRetrieverOtpAutofillService({SmsRetrieverPlatform? platform})
      : _platform = platform ?? SmsAutofillPlatform();

  @override
  Stream<String> get codes => _codes.stream;

  @override
  Future<void> arm() {
    return _enqueue(() async {
      await _disarm();
      if (_disposed) return;

      _platformSubscription = _platform.codes.listen((value) {
        // The package returns the whole SMS when its regex does not match.
        // Never pass that content on; it may contain unrelated sensitive text.
        if (!_disposed && _sixDigits.hasMatch(value)) {
          _codes.add(value);
        }
      });
      await _platform.listenForCode(_codePattern);
    });
  }

  @override
  Future<void> disarm() => _enqueue(_disarm);

  Future<void> _disarm() async {
    await _platformSubscription?.cancel();
    _platformSubscription = null;
    await _platform.unregisterListener();
  }

  Future<void> _enqueue(Future<void> Function() action) {
    final next = _operation.then((_) => action());
    // Keep the queue usable when a platform call fails; SMS autofill remains
    // optional and manual entry must continue to work.
    _operation = next.catchError((_) {});
    return next;
  }

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    await disarm();
    await _codes.close();
  }
}
