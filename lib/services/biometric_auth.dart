import 'biometric_auth_stub.dart'
    if (dart.library.io) 'biometric_auth_io.dart'
    as implementation;

class BiometricAuth {
  Future<BiometricResult> authenticate() => implementation.authenticate();
}

enum BiometricResult { authenticated, unavailable, failed, canceled }

String? biometricLastError;
