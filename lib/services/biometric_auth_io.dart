import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';

import 'biometric_auth.dart';

Future<BiometricResult> authenticate() async {
  final auth = LocalAuthentication();
  biometricLastError = null;
  try {
    final supported = await auth.isDeviceSupported();
    final canCheck = await auth.canCheckBiometrics;
    if (!supported || !canCheck) return BiometricResult.unavailable;

    final success = await auth.authenticate(
      localizedReason:
          'Confirma tu identidad para activar la protección biométrica de MOVA',
      options: const AuthenticationOptions(
        biometricOnly: true,
        stickyAuth: true,
        useErrorDialogs: true,
      ),
    );
    return success ? BiometricResult.authenticated : BiometricResult.failed;
  } on PlatformException catch (error) {
    if (error.code == 'NotAvailable' ||
        error.code == 'PasscodeNotSet' ||
        error.code == 'NotEnrolled') {
      return BiometricResult.unavailable;
    }
    if (error.code == 'UserCanceled' || error.code == 'SystemCanceled') {
      return BiometricResult.canceled;
    }
    biometricLastError =
        '${error.code}: ${error.message ?? 'Error del sistema biométrico'}';
    return BiometricResult.failed;
  }
}
