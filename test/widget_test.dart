import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mhar_rueng_sang/main.dart';
import 'package:mhar_rueng_sang/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  tearDown(() {
    ApiService.resetHttpClient();
  });

  testWidgets('MharApp routes logged out users to login', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const MharApp());
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    expect(find.text('Sign in to your account'), findsOneWidget);
  });

  testWidgets('MharApp routes logged in customer to home screen', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'jwt_token': 'token',
      'user_id': 5,
      'user_role': 'CUSTOMER',
      'user_name': 'Customer',
      'user_email': 'customer@foodexpress.com',
    });
    ApiService.setHttpClient(
      MockClient((request) async {
        if (request.url.path.endsWith('/restaurants')) {
          return http.Response(
            '{"success":true,"data":{"content":[]}}',
            200,
          );
        }
        return http.Response('{"success":false}', 404);
      }),
    );

    await tester.pumpWidget(const MharApp());
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    expect(find.text('Restaurants'), findsOneWidget);
    expect(find.text('No restaurants available right now'), findsOneWidget);
  });
}
