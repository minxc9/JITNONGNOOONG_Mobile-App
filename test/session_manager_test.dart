import 'package:flutter_test/flutter_test.dart';
import 'package:mhar_rueng_sang/utils/session_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('SessionManager tests', () {
    test('saveUser and saveToken persist values', () async {
      await SessionManager.saveToken('jwt-token');
      await SessionManager.saveUser(
        id: 12,
        name: 'Natnicha',
        email: 'nat@example.com',
        role: 'CUSTOMER',
      );

      expect(await SessionManager.getToken(), 'jwt-token');
      expect(await SessionManager.getUserId(), 12);
      expect(await SessionManager.getUserName(), 'Natnicha');
      expect(await SessionManager.getUserEmail(), 'nat@example.com');
      expect(await SessionManager.getUserRole(), 'CUSTOMER');
      expect(await SessionManager.isLoggedIn(), true);
    });

    test('logout clears all saved session data', () async {
      await SessionManager.saveToken('jwt-token');
      await SessionManager.saveUser(
        id: 1,
        name: 'Admin',
        email: 'admin@example.com',
        role: 'ADMIN',
      );

      await SessionManager.logout();

      expect(await SessionManager.getToken(), isNull);
      expect(await SessionManager.getUserId(), isNull);
      expect(await SessionManager.getUserRole(), isNull);
      expect(await SessionManager.isLoggedIn(), false);
    });
  });
}
