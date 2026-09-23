import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:vsf_consumer/services/otp_autofill_service.dart';

class FakeSmsRetrieverPlatform implements SmsRetrieverPlatform {
  final StreamController<String> _messages = StreamController.broadcast();
  int listenCalls = 0;
  int unregisterCalls = 0;
  String? pattern;
  Completer<void>? listenGate;

  @override
  Stream<String> get codes => _messages.stream;

  void emit(String message) => _messages.add(message);

  @override
  Future<void> listenForCode(String value) async {
    listenCalls++;
    pattern = value;
    await listenGate?.future;
  }

  @override
  Future<void> unregisterListener() async {
    unregisterCalls++;
  }

  Future<void> close() => _messages.close();
}

void main() {
  late FakeSmsRetrieverPlatform platform;
  late SmsRetrieverOtpAutofillService service;
  late StreamSubscription<String> subscription;
  late List<String> received;

  setUp(() {
    platform = FakeSmsRetrieverPlatform();
    service = SmsRetrieverOtpAutofillService(platform: platform);
    received = <String>[];
    subscription = service.codes.listen(received.add);
  });

  tearDown(() async {
    await subscription.cancel();
    await service.dispose();
    await platform.close();
  });

  test('initial request can arm Retriever before the OTP arrives', () async {
    await service.arm();
    platform.emit('123456');
    await Future<void>.delayed(Duration.zero);

    expect(platform.listenCalls, 1);
    expect(platform.pattern, contains(r'\d{6}'));
    expect(received, ['123456']);
  });

  test('repeated login and resend re-arm one receiver without duplicates',
      () async {
    await service.arm();
    await service.arm(); // repeated login or a successful resend
    platform.emit('654321');
    await Future<void>.delayed(Duration.zero);

    expect(platform.listenCalls, 2);
    expect(received, ['654321']);
  });

  test('invalid or incomplete SMS content is never exposed as an OTP',
      () async {
    await service.arm();
    platform.emit('12345');
    platform.emit('1234567');
    platform.emit('message containing 123456');
    await Future<void>.delayed(Duration.zero);

    expect(received, isEmpty);
  });

  test('manual entry remains independent when Retriever is unavailable', () async {
    // No arm is required for the app's TextField/controller manual path.
    expect(received, isEmpty);
  });

  test('serialises a stop requested while native setup is still pending',
      () async {
    platform.listenGate = Completer<void>();
    final arm = service.arm();
    final stop = service.disarm();

    platform.listenGate!.complete();
    await arm;
    await stop;

    expect(platform.unregisterCalls, 2);
  });

  test('leaving OTP screen disarms the native listener and stream listener',
      () async {
    await service.arm();
    await service.disarm();
    platform.emit('123456');
    await Future<void>.delayed(Duration.zero);

    expect(received, isEmpty);
    expect(platform.unregisterCalls, greaterThanOrEqualTo(2));
  });
}
